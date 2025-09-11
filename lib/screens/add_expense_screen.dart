// lib/screens/add_expense_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../trip_provider.dart';
import 'package:intl/intl.dart';

class AddExpenseScreen extends StatefulWidget {
  final String tripId;
  const AddExpenseScreen({required this.tripId, super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  String? _paidById;
  final Set<String> _splitWith = {};
  String _category = 'Misc';
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TripProvider>(context);
    final trip = prov.getById(widget.tripId)!;

    if (_paidById == null && trip.members.isNotEmpty) {
      _paidById = trip.members.first.id;
    }
    if (_splitWith.isEmpty && trip.members.isNotEmpty) {
      _splitWith.addAll(trip.members.map((m) => m.id));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Expense"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildCard(
              child: Column(
                children: [
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(
                      labelText: "Expense Title",
                      prefixIcon: Icon(Icons.edit),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amount,
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: "Amount",
                      prefixIcon: Icon(Icons.currency_rupee),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _paidById,
                    items: trip.members
                        .map((m) =>
                        DropdownMenuItem(value: m.id, child: Text(m.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _paidById = v),
                    decoration: const InputDecoration(
                      labelText: "Paid by",
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Split Between",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  ...trip.members.map((m) {
                    return CheckboxListTile(
                      value: _splitWith.contains(m.id),
                      title: Text(m.name),
                      controlAffinity: ListTileControlAffinity.leading,
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _splitWith.add(m.id);
                          } else {
                            _splitWith.remove(m.id);
                          }
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildCard(
              child: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _category,
                    items: ['Food', 'Travel', 'Stay', 'Misc']
                        .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c),
                    ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _category = v ?? 'Misc'),
                    decoration: const InputDecoration(
                      labelText: "Category",
                      prefixIcon: Icon(Icons.category),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today,
                          color: Theme.of(context).primaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Date: ${DateFormat.yMMMd().format(_date)}",
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: _pickDate,
                        child: const Text("Change"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text("Save Expense"),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final amt = double.tryParse(_amount.text) ?? 0.0;
                  if (_title.text.trim().isEmpty ||
                      amt <= 0 ||
                      _paidById == null ||
                      _splitWith.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please complete fields")),
                    );
                    return;
                  }

                  final e = Expense(
                    title: _title.text.trim(),
                    amount: amt,
                    paidById: _paidById!,
                    splitWithIds: _splitWith.toList(),
                    category: _category,
                    date: _date,
                  );
                  prov.addExpense(widget.tripId, e);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}
