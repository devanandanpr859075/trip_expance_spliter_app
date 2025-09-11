// lib/screens/trip_list_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../settlement.dart';
import '../trip_provider.dart';
import '../models.dart';
import 'add_trip_screen.dart';
import 'trip_detail_screen.dart';

class TripListScreen extends StatelessWidget {
  const TripListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TripProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Trips'),
        actions: [
          if (prov.trips.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.upload_file),
              tooltip: 'Export all trips (PDF)',
              onPressed: () async {
                final pdf = pw.Document();
                for (final t in prov.trips) {
                  pdf.addPage(
                    pw.MultiPage(
                      pageFormat: PdfPageFormat.a4,
                      margin: const pw.EdgeInsets.all(20),
                      build: (ctx) => _buildTripPdfContent(t),
                    ),
                  );
                }
                await Printing.layoutPdf(
                  onLayout: (PdfPageFormat fmt) async => pdf.save(),
                );
              },
            ),
        ],
      ),
      body: prov.trips.isEmpty
          ? const Center(
        child: Text(
          'No trips yet.\nTap + to add a new trip.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: prov.trips.length,
        itemBuilder: (context, i) {
          final t = prov.trips[i];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            child: ListTile(
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: Text(
                t.name,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${t.destination} • ${DateFormat.yMMMd().format(t.startDate)} - ${DateFormat.yMMMd().format(t.endDate)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              leading: CircleAvatar(
                backgroundColor: Colors.blue.shade100,
                child: Text(
                  t.name[0].toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              trailing: SizedBox(
                width: 160,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        '₹${t.totalCost().toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.receipt_long, size: 22),
                      tooltip: 'Settlement',
                      onPressed: () => _showSettlementDialog(context, t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.picture_as_pdf,
                          size: 22, color: Colors.blue),
                      tooltip: "Download PDF",
                      onPressed: () => _generatePdf(context, t),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 22, color: Colors.red),
                      tooltip: "Delete",
                      onPressed: () => _confirmDelete(context, prov, t),
                    ),
                  ],
                ),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TripDetailScreen(tripId: t.id),
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        tooltip: 'Add Trip',
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddTripScreen(),
            ),
          );
        },
      ),
    );
  }

  List<pw.Widget> _buildTripPdfContent(Trip t) {
    return [
      pw.Header(
        level: 0,
        child: pw.Text(
          "Trip Statement",
          style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
        ),
      ),
      pw.SizedBox(height: 8),
      pw.Text("Trip Name: ${t.name}"),
      pw.Text("Destination: ${t.destination}"),
      pw.Text(
          "Duration: ${DateFormat.yMMMd().format(t.startDate)} - ${DateFormat.yMMMd().format(t.endDate)}"),
      pw.SizedBox(height: 8),
      pw.Text("Total Cost: ₹${t.totalCost().toStringAsFixed(2)}",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 12),
      pw.Text("Members:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      if (t.members.isEmpty)
        pw.Text("No members added.")
      else
        pw.Column(
            children: t.members
                .map((m) => pw.Text("${m.name} (${m.id})"))
                .toList()),
      pw.SizedBox(height: 12),
      pw.Text("Expenses:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      if (t.expenses.isEmpty)
        pw.Text("No expenses recorded.")
      else
        pw.Table.fromTextArray(
          headers: ["Title", "Amount", "Paid By", "Split Count"],
          data: t.expenses
              .map((e) => [
            e.title,
            "₹${e.amount.toStringAsFixed(2)}",
            t.memberName(e.paidById),
            "${e.splitWithIds.length}"
          ])
              .toList(),
        ),
      pw.SizedBox(height: 12),
      pw.Text("Settlement (who pays who):",
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.SizedBox(height: 6),
      pw.Column(
        children: () {
          final net = t.netPerMember();
          final transfers = settleBalances(net);
          if (transfers.isEmpty) {
            return [pw.Text("All settled. No transfers needed.")];
          }
          return transfers
              .map((tr) => pw.Text(
              "${t.memberName(tr['from'] as String)} → ${t.memberName(tr['to'] as String)} : ₹${(tr['amount'] as double).toStringAsFixed(2)}"))
              .toList();
        }(),
      ),
    ];
  }

  Future<void> _generatePdf(BuildContext context, Trip t) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) => _buildTripPdfContent(t),
      ),
    );

    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }

  void _confirmDelete(BuildContext ctx, TripProvider prov, Trip t) {
    showDialog(
      context: ctx,
      builder: (dctx) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: Text('Are you sure you want to delete "${t.name}" and all its data?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await prov.deleteTrip(t.id);
              Navigator.pop(dctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSettlementDialog(BuildContext context, Trip t) {
    final net = t.netPerMember();
    final transfers = settleBalances(net);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Settlement'),
        content: transfers.isEmpty
            ? const Text('All settled — no transfers required.')
            : SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...transfers.map((tr) => Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.swap_horiz, color: Colors.blue),
                  title: Text("${t.memberName(tr['from'] as String)} → ${t.memberName(tr['to'] as String)}"),
                  trailing: Text("₹${(tr['amount'] as double).toStringAsFixed(2)}"),
                ),
              )),
              const Divider(),
              const SizedBox(height: 6),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Net per member:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
              const SizedBox(height: 6),
              ...t.netPerMember().entries.map((e) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t.memberName(e.key)),
                  Text("₹${e.value.toStringAsFixed(2)}"),
                ],
              )),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
