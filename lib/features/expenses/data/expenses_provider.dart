import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/expense.dart';
import '../domain/activity.dart';
import '../../balances/domain/balance.dart';

final _firestore = FirebaseFirestore.instance;

// ─── Firestore expense operations ────────────────────────────────

/// Adds a new expense document to the group's `expenses` subcollection.
Future<void> addExpenseToFirestore({
  required String groupId,
  required String description,
  required double amount,
  required String paidById,
  required List<ExpenseSplit> splits,
  DateTime? date,
  String? category,
  bool consumeRight = true,
  int? newRightsCount,
}) async {
  final expense = Expense(
    id: '', // Firestore will assign the ID
    groupId: groupId,
    description: description,
    amount: amount,
    paidById: paidById,
    splits: splits,
    date: date ?? DateTime.now(),
    category: category,
  );

  final json = expense.toJson();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    json['createdBy'] = uid;
  }

  final batch = _firestore.batch();

  final expenseRef = _firestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .doc();

  batch.set(expenseRef, json);

  if (consumeRight && newRightsCount != null) {
    final groupRef = _firestore.collection('groups').doc(groupId);
    batch.update(groupRef, {
      'expenseRights': newRightsCount,
    });
  }
  
  await batch.commit();
}

/// Deletes an expense document from Firestore.
Future<void> deleteExpenseFromFirestore({
  required String groupId,
  required String expenseId,
}) async {
  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .doc(expenseId)
      .delete();
}

/// Adds a payment document (User A paid User B).
/// Stored as a special expense in the same subcollection.
/// Pass [autoConfirm] = true when either party is a dummy member so the payment
/// is confirmed immediately (there is no real user to confirm on their behalf).
Future<void> addPaymentToFirestore({
  required String groupId,
  required String fromUserId,
  required String toUserId,
  required double amount,
  DateTime? date,
  bool autoConfirm = false,
}) async {
  final payment = Expense(
    id: '',
    groupId: groupId,
    description: 'Payment',
    amount: amount,
    paidById: fromUserId,
    splits: [ExpenseSplit(userId: toUserId, amount: amount)],
    date: date ?? DateTime.now(),
    isPayment: true,
    isConfirmed: autoConfirm, // Auto-confirmed for dummy members; pending for real users
  );

  final json = payment.toJson();
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    json['createdBy'] = uid;
  }

  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .add(json);
}

/// Confirms a payment (marks it as confirmed)
Future<void> confirmPaymentInFirestore({
  required String groupId,
  required String expenseId,
}) async {
  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .doc(expenseId)
      .update({'isConfirmed': true});
}

/// Cancels/deletes a payment
Future<void> cancelPaymentInFirestore({
  required String groupId,
  required String expenseId,
}) async {
  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .doc(expenseId)
      .delete();
}

// ─── Activity operations ───────────────────────────────────

/// Adds a new activity document to the group's `activities` subcollection.
Future<void> addActivityToFirestore({
  required String groupId,
  required ActivityType type,
  required String description,
  String? userId,
  String? userName,
  double? amount,
  Map<String, dynamic>? metadata,
}) async {
  final activity = Activity(
    id: '', // Firestore will assign the ID
    groupId: groupId,
    type: type,
    description: description,
    amount: amount,
    userId: userId,
    userName: userName,
    date: DateTime.now(),
    metadata: metadata,
  );

  await _firestore
      .collection('groups')
      .doc(groupId)
      .collection('activities')
      .add(activity.toJson());
}

/// Adds a member left activity to the group.
Future<void> addMemberLeftActivity({
  required String groupId,
  required String userId,
  required String userName,
}) async {
  await addActivityToFirestore(
    groupId: groupId,
    type: ActivityType.memberLeft,
    description: '$userName left the group',
    userId: userId,
    userName: userName,
  );
}

// ─── Reactive stream providers ───────────────────────────────────

/// Streams all expenses for a given group, sorted by date (newest first).
final groupExpensesProvider = StreamProvider.family<List<Expense>, String>((
  ref,
  groupId,
) {
  ref.keepAlive();
  return _firestore
      .collection('groups')
      .doc(groupId)
      .collection('expenses')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Expense.fromJson(doc.data(), id: doc.id))
            .toList();
      });
});

// ─── Derived providers (balances, settlements, totals) ───────────

/// Net balances for a group, derived reactively from the expense stream.
/// Only includes confirmed payments in balance calculations.
final groupNetBalancesProvider = Provider.family<Map<String, double>, String>((
  ref,
  groupId,
) {
  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final expenses = expensesAsync.value ?? [];

  // Filter out unconfirmed payments
  final confirmedExpenses = expenses
      .where((e) => !e.isPayment || e.isConfirmed)
      .toList();

  return BalanceEngine.calculateNetBalances(
    confirmedExpenses,
    (e) => (e as Expense).paidById,
    (e) => (e as Expense).amount,
    (e) => (e as Expense).splits,
    (s) => (s as ExpenseSplit).userId,
    (s) => (s as ExpenseSplit).amount,
  );
});

/// Individual debt relationships for a group, derived reactively from the expense stream.
/// Tracks who owes whom based on individual expense splits.
final groupIndividualDebtsProvider =
    Provider.family<Map<String, Map<String, double>>, String>((ref, groupId) {
      final expensesAsync = ref.watch(groupExpensesProvider(groupId));
      final expenses = expensesAsync.value ?? [];

      // Filter out unconfirmed payments
      final confirmedExpenses = expenses
          .where((e) => !e.isPayment || e.isConfirmed)
          .toList();

      return BalanceEngine.calculateIndividualDebts(
        confirmedExpenses,
        (e) => (e as Expense).paidById,
        (e) => (e as Expense).amount,
        (e) => (e as Expense).splits,
        (s) => (s as ExpenseSplit).userId,
        (s) => (s as ExpenseSplit).amount,
      );
    });

/// Settlement suggestions for a group.
final groupSettlementsProvider = Provider.family<List<Balance>, String>((
  ref,
  groupId,
) {
  final netBalances = ref.watch(groupNetBalancesProvider(groupId));
  return BalanceEngine.calculateSettlements(netBalances);
});

/// Total spending for a group.
/// Only includes confirmed expenses (excludes unconfirmed payments).
final groupTotalSpendingProvider = Provider.family<double, String>((
  ref,
  groupId,
) {
  final expensesAsync = ref.watch(groupExpensesProvider(groupId));
  final expenses = expensesAsync.value ?? [];
  final confirmedExpenses = expenses
      .where((e) => !e.isPayment || e.isConfirmed)
      .toList();
  return confirmedExpenses
      .where((e) => !e.isPayment)
      .fold(0.0, (sum, e) => sum + e.amount);
});

/// Streams all activities for a given group, sorted by date (newest first).
final groupActivitiesProvider = StreamProvider.family<List<Activity>, String>((
  ref,
  groupId,
) {
  ref.keepAlive();
  return _firestore
      .collection('groups')
      .doc(groupId)
      .collection('activities')
      .orderBy('date', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs
            .map((doc) => Activity.fromJson(doc.data(), id: doc.id))
            .toList();
      });
});
