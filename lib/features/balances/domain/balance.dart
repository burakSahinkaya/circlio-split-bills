/// Represents a directed debt: [fromUserId] owes [toUserId] a given [amount].
class Balance {
  final String fromUserId;
  final String toUserId;
  final double amount;

  const Balance({
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
  });
}

/// Engine that calculates balances and generates settlement suggestions.
class BalanceEngine {
  BalanceEngine._();

  /// Calculate net balances for each user from a list of expenses.
  /// Returns a map of userId -> net balance (positive = owed money, negative = owes money).
  static Map<String, double> calculateNetBalances(
    List<dynamic> expenses,
    String Function(dynamic) getPaidById,
    double Function(dynamic) getAmount,
    List<dynamic> Function(dynamic) getSplits,
    String Function(dynamic) getSplitUserId,
    double Function(dynamic) getSplitAmount,
  ) {
    final balances = <String, double>{};

    for (final expense in expenses) {
      final paidById = getPaidById(expense);
      final amount = getAmount(expense);
      final splits = getSplits(expense);

      // The payer gains credit
      balances[paidById] = (balances[paidById] ?? 0) + amount;

      // Each split member owes their share
      for (final split in splits) {
        final userId = getSplitUserId(split);
        final splitAmount = getSplitAmount(split);
        balances[userId] = (balances[userId] ?? 0) - splitAmount;
      }
    }

    return balances;
  }

  /// Calculate individual debt relationships from expenses
  /// Returns a map: fromUserId -> toUserId -> amount owed
  /// Automatically nets out debts between each pair of users
  static Map<String, Map<String, double>> calculateIndividualDebts(
    List<dynamic> expenses,
    String Function(dynamic) getPaidById,
    double Function(dynamic) getAmount,
    List<dynamic> Function(dynamic) getSplits,
    String Function(dynamic) getSplitUserId,
    double Function(dynamic) getSplitAmount,
  ) {
    final debts =
        <String, Map<String, double>>{}; // fromUser -> toUser -> amount

    for (final expense in expenses) {
      final paidById = getPaidById(expense);
      final splits = getSplits(expense);

      for (final split in splits) {
        final owesUserId = getSplitUserId(split);
        final owesAmount = getSplitAmount(split);

        // Skip if the payer is also the one who owes (they paid for themselves)
        if (owesUserId == paidById) continue;

        // Add debt relationship: owesUserId owes paidById
        debts.putIfAbsent(owesUserId, () => {});
        debts[owesUserId]![paidById] =
            (debts[owesUserId]![paidById] ?? 0) + owesAmount;
      }
    }

    // Net out debts between each pair of users
    return _netOutDebts(debts);
  }

  /// Net out debts between each pair of users
  /// If A owes B $X and B owes A $Y, then:
  /// - If X > Y: A owes B (X-Y), B owes A 0
  /// - If Y > X: B owes A (Y-X), A owes B 0
  /// - If X = Y: Both owe 0
  static Map<String, Map<String, double>> _netOutDebts(
    Map<String, Map<String, double>> debts,
  ) {
    final nettedDebts = <String, Map<String, double>>{};

    // Copy all debts to nettedDebts
    for (final entry in debts.entries) {
      nettedDebts[entry.key] = Map.from(entry.value);
    }

    // Net out each pair of debts
    final processedPairs = <String>{};

    for (final fromUser in debts.keys) {
      for (final toUser in debts[fromUser]!.keys) {
        final pairKey1 = '$fromUser-$toUser';
        final pairKey2 = '$toUser-$fromUser';

        // Skip if we've already processed this pair
        if (processedPairs.contains(pairKey1) ||
            processedPairs.contains(pairKey2)) {
          continue;
        }

        // Check if there's a reverse debt
        final amountFromTo = debts[fromUser]![toUser] ?? 0.0;
        final amountToFrom = debts[toUser]?[fromUser] ?? 0.0;

        if (amountToFrom > 0.01) {
          // Net out the debts
          if (amountFromTo > amountToFrom) {
            // A owes B more than B owes A
            nettedDebts[fromUser]![toUser] = amountFromTo - amountToFrom;
            nettedDebts[toUser]!.remove(fromUser);
          } else if (amountToFrom > amountFromTo) {
            // B owes A more than A owes B
            nettedDebts[toUser]![fromUser] = amountToFrom - amountFromTo;
            nettedDebts[fromUser]!.remove(toUser);
          } else {
            // They owe each other the same amount
            nettedDebts[fromUser]!.remove(toUser);
            nettedDebts[toUser]!.remove(fromUser);
          }
        }

        // Mark this pair as processed
        processedPairs.add(pairKey1);
        processedPairs.add(pairKey2);
      }
    }

    return nettedDebts;
  }

  /// Calculate how much a specific user owes to each other member
  /// Returns a map of userId -> amount owed (0 if no debt)
  static Map<String, double> calculateUserDebts(
    Map<String, double> netBalances,
    String userId,
  ) {
    final userDebts = <String, double>{};
    final userBalance = netBalances[userId] ?? 0.0;

    // If user has positive balance, they are owed money, not in debt
    if (userBalance >= -0.01) {
      return userDebts;
    }

    // User owes money (negative balance), distribute to creditors
    final creditors = <MapEntry<String, double>>[];

    for (final entry in netBalances.entries) {
      if (entry.key != userId && entry.value > 0.01) {
        creditors.add(entry);
      }
    }

    // Sort creditors by amount owed to them
    creditors.sort((a, b) => b.value.compareTo(a.value));

    double remainingDebt = -userBalance; // Make positive

    for (final creditor in creditors) {
      if (remainingDebt <= 0.01) break;

      final amountToPay = remainingDebt < creditor.value
          ? remainingDebt
          : creditor.value;

      userDebts[creditor.key] = double.parse(amountToPay.toStringAsFixed(2));
      remainingDebt -= amountToPay;
    }

    return userDebts;
  }

  /// Calculate how much a specific user owes to each other member using individual debt relationships
  /// This is the CORRECT method that tracks actual expense relationships
  static Map<String, double> calculateUserDebtsFromIndividual(
    Map<String, Map<String, double>> individualDebts,
    String userId,
  ) {
    return individualDebts[userId] ?? {};
  }

  /// Given net balances, calculate the minimum set of transactions to settle all debts.
  /// Uses a greedy algorithm: repeatedly match the largest creditor with the largest debtor.
  static List<Balance> calculateSettlements(Map<String, double> netBalances) {
    final settlements = <Balance>[];

    // Separate into creditors (positive balance) and debtors (negative balance)
    final creditors = <MapEntry<String, double>>[];
    final debtors = <MapEntry<String, double>>[];

    for (final entry in netBalances.entries) {
      if (entry.value > 0.01) {
        creditors.add(entry);
      } else if (entry.value < -0.01) {
        debtors.add(MapEntry(entry.key, -entry.value)); // Make positive
      }
    }

    // Sort descending by amount
    creditors.sort((a, b) => b.value.compareTo(a.value));
    debtors.sort((a, b) => b.value.compareTo(a.value));

    // Mutable copies
    final creditAmounts = {for (var e in creditors) e.key: e.value};
    final debtAmounts = {for (var e in debtors) e.key: e.value};

    while (creditAmounts.isNotEmpty && debtAmounts.isNotEmpty) {
      // Find largest creditor and debtor
      final creditorId = creditAmounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;
      final debtorId = debtAmounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key;

      final creditAmount = creditAmounts[creditorId]!;
      final debtAmount = debtAmounts[debtorId]!;
      final settleAmount = creditAmount < debtAmount
          ? creditAmount
          : debtAmount;

      settlements.add(
        Balance(
          fromUserId: debtorId,
          toUserId: creditorId,
          amount: double.parse(settleAmount.toStringAsFixed(2)),
        ),
      );

      // Update amounts
      creditAmounts[creditorId] = creditAmount - settleAmount;
      debtAmounts[debtorId] = debtAmount - settleAmount;

      // Remove if settled
      if (creditAmounts[creditorId]! < 0.01) {
        creditAmounts.remove(creditorId);
      }
      if (debtAmounts[debtorId]! < 0.01) {
        debtAmounts.remove(debtorId);
      }
    }

    return settlements;
  }
}
