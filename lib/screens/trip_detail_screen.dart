import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../trip_provider.dart';
import '../models.dart';
import 'add_member_dialog.dart';
import 'add_expense_screen.dart';
import '../settlement.dart';
import 'package:fl_chart/fl_chart.dart';

class TripDetailScreen extends StatefulWidget {
  final String tripId;
  const TripDetailScreen({required this.tripId, super.key});

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TripProvider>(context);
    final trip = prov.getById(widget.tripId);
    if (trip == null) return Scaffold(body: Center(child: Text('Trip not found')));

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.name),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expenses', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Members', icon: Icon(Icons.group)),
            Tab(text: 'Summary', icon: Icon(Icons.summarize)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _expensesTab(trip, prov),
          _membersTab(trip, prov),
          _summaryTab(trip),
        ],
      ),
      floatingActionButton: _tabController.index == 0
          ? FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text("Add Expense"),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddExpenseScreen(tripId: trip.id)),
        ),
      )
          : null,
    );
  }

  /// ---------------- EXPENSES TAB ----------------
  Widget _expensesTab(Trip trip, TripProvider prov) {
    if (trip.expenses.isEmpty) {
      return const Center(child: Text('No expenses yet.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trip.expenses.length,
      itemBuilder: (context, i) {
        final e = trip.expenses[i];
        final payer = trip.members
            .firstWhere((m) => m.id == e.paidById, orElse: () => Member(name: 'Unknown', contact: ''));

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColorLight,
              child: Text(e.category[0], style: const TextStyle(color: Colors.white)),
            ),
            title: Text(e.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('${e.category} • ${e.date.toLocal().toString().split(' ')[0]}'),
            trailing: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('₹${e.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text('Paid by ${payer.name}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  /// ---------------- MEMBERS TAB ----------------
  Widget _membersTab(Trip trip, TripProvider prov) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 70),
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: trip.members.length,
            itemBuilder: (context, i) {
              final m = trip.members[i];
              final contribution = trip.expenses
                  .where((e) => e.paidById == m.id)
                  .fold<double>(0.0, (s, e) => s + e.amount);
              return Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(child: Text(m.name[0])),
                  title: Text(m.name),
                  subtitle: Text('Contributed: ₹${contribution.toStringAsFixed(2)}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => prov.deleteMember(trip.id, m.id),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Add Member'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () async {
                final newMember = await showDialog<Member?>(
                  context: context,
                  builder: (_) => const AddMemberDialog(),
                );
                if (newMember != null) prov.addMember(trip.id, newMember);
              },
            ),
          ),
        ),
      ],
    );
  }

  /// ---------------- SUMMARY TAB ----------------
  Widget _summaryTab(Trip trip) {
    final netMap = computeNetMap(trip);
    final transfers = settleBalances(netMap);

    final Map<String, double> catTotals = {};
    for (final e in trip.expenses) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }
    final pieSections = catTotals.entries.map((entry) {
      return PieChartSectionData(
        title: '${entry.key}\n₹${entry.value.toStringAsFixed(0)}',
        value: entry.value,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
      );
    }).toList();

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _summaryCard(title: 'Total Cost', value: '₹${trip.totalCost().toStringAsFixed(2)}'),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: pieSections.isEmpty
              ? const Center(child: Text('No expenses to show chart'))
              : PieChart(PieChartData(sections: pieSections, sectionsSpace: 2, centerSpaceRadius: 0)),
        ),
        const SizedBox(height: 16),
        const Text('Per-Person Net Balances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...trip.members.map((m) {
          final net = netMap[m.id] ?? 0.0;
          return _summaryCard(
            title: m.name,
            value: net >= 0 ? 'Gets ₹${net.toStringAsFixed(2)}' : 'Owes ₹${(-net).toStringAsFixed(2)}',
            leading: CircleAvatar(child: Text(m.name[0])),
          );
        }).toList(),
        const SizedBox(height: 12),
        const Text('Suggested Transfers', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...transfers.map((t) {
          final fromName = trip.members.firstWhere((m) => m.id == t['from']).name;
          final toName = trip.members.firstWhere((m) => m.id == t['to']).name;
          return _summaryCard(
            title: '$fromName → $toName',
            value: '₹${(t['amount'] as double).toStringAsFixed(2)}',
            leading: const Icon(Icons.swap_horiz, color: Colors.blue),
          );
        }).toList(),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _summaryCard({required String title, required String value, Widget? leading}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 2,
      child: ListTile(
        leading: leading,
        title: Text(title),
        trailing: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
