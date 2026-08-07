import 'package:flutter_test/flutter_test.dart';
import 'package:split_circle/features/balances/domain/balance.dart';

void main() {
  group('BalanceEngine', () {
    test('calculateNetBalances computes correct balances', () {
      // Simulate: User A pays $100, split 3 ways with A, B, C
      final expenses = [
        {
          'paidById': 'A',
          'amount': 100.0,
          'splits': [
            {'userId': 'A', 'amount': 33.33},
            {'userId': 'B', 'amount': 33.33},
            {'userId': 'C', 'amount': 33.34},
          ],
        },
      ];

      final balances = BalanceEngine.calculateNetBalances(
        expenses,
        (e) => (e as Map)['paidById'] as String,
        (e) => (e as Map)['amount'] as double,
        (e) => (e as Map)['splits'] as List,
        (s) => (s as Map)['userId'] as String,
        (s) => (s as Map)['amount'] as double,
      );

      // A paid $100 but owes $33.33 → net +$66.67
      expect(balances['A']!, closeTo(66.67, 0.01));
      // B owes $33.33
      expect(balances['B']!, closeTo(-33.33, 0.01));
      // C owes $33.34
      expect(balances['C']!, closeTo(-33.34, 0.01));
    });

    test('calculateSettlements minimizes transactions', () {
      final netBalances = {
        'A': 50.0,  // A is owed $50
        'B': -30.0, // B owes $30
        'C': -20.0, // C owes $20
      };

      final settlements = BalanceEngine.calculateSettlements(netBalances);

      // Should produce 2 settlements
      expect(settlements.length, 2);

      // Total settled should equal total debt
      final totalSettled = settlements.fold(0.0, (sum, s) => sum + s.amount);
      expect(totalSettled, closeTo(50.0, 0.01));
    });
  });
}
