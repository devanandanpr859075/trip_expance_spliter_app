// lib/settlement.dart
import 'models.dart';

/// Compute net balances for a trip:
/// positive => this member should receive money
/// negative => this member owes money
Map<String, double> computeNetMap(Trip t) {
  final net = <String, double>{};
  for (final m in t.members) net[m.id] = 0.0;

  for (final e in t.expenses) {
    final share = e.sharePerPerson();
    for (final pid in e.splitWithIds) {
      net[pid] = (net[pid] ?? 0) - share;
    }
    net[e.paidById] = (net[e.paidById] ?? 0) + e.amount;
  }

  // Round small float errors
  net.updateAll((k, v) => double.parse(v.toStringAsFixed(2)));
  return net;
}

/// Greedy settlement optimizer: returns list of transfers {from, to, amount}
List<Map<String, dynamic>> settleBalances(Map<String, double> netMap) {
  final transfers = <Map<String, dynamic>>[];

  final debtors = <Map<String, dynamic>>[];
  final creditors = <Map<String, dynamic>>[];

  netMap.forEach((id, net) {
    if (net < -0.01) debtors.add({'id': id, 'amt': -net});
    else if (net > 0.01) creditors.add({'id': id, 'amt': net});
  });

  debtors.sort((a, b) => (b['amt'] as double).compareTo(a['amt'] as double));
  creditors.sort((a, b) => (b['amt'] as double).compareTo(a['amt'] as double));

  int i = 0, j = 0;
  while (i < debtors.length && j < creditors.length) {
    final d = debtors[i];
    final c = creditors[j];
    final double dAmt = d['amt'] as double;
    final double cAmt = c['amt'] as double;
    final repay = dAmt < cAmt ? dAmt : cAmt;

    transfers.add({
      'from': d['id'],
      'to': c['id'],
      'amount': double.parse(repay.toStringAsFixed(2)),
    });

    d['amt'] = (d['amt'] as double) - repay;
    c['amt'] = (c['amt'] as double) - repay;

    if ((d['amt'] as double) < 0.01) i++;
    if ((c['amt'] as double) < 0.01) j++;
  }

  return transfers;
}
