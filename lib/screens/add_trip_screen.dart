// lib/screens/add_trip_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../trip_provider.dart';
import 'package:intl/intl.dart';

class AddTripScreen extends StatefulWidget {
  final Trip? editTrip;
  const AddTripScreen({this.editTrip, super.key});

  @override
  State<AddTripScreen> createState() => _AddTripScreenState();
}

class _AddTripScreenState extends State<AddTripScreen> {
  final _name = TextEditingController();
  final _destination = TextEditingController();
  DateTime? _start;
  DateTime? _end;

  @override
  void initState() {
    super.initState();
    if (widget.editTrip != null) {
      _name.text = widget.editTrip!.name;
      _destination.text = widget.editTrip!.destination;
      _start = widget.editTrip!.startDate;
      _end = widget.editTrip!.endDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<TripProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.editTrip == null ? 'Create Trip' : 'Edit Trip'),
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
                    controller: _name,
                    decoration: InputDecoration(
                      labelText: 'Trip Name',
                      prefixIcon: const Icon(Icons.card_travel),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _destination,
                    decoration: InputDecoration(
                      labelText: 'Destination',
                      prefixIcon: const Icon(Icons.location_on),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDatePickerRow('Start Date', _start, _pickStart),
                  const SizedBox(height: 12),
                  _buildDatePickerRow('End Date', _end, _pickEnd),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: Text(widget.editTrip == null ? 'Create Trip' : 'Save Trip'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  final name = _name.text.trim();
                  final dest = _destination.text.trim();
                  if (name.isEmpty || dest.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name & Destination are required')),
                    );
                    return;
                  }

                  final trip = widget.editTrip != null
                      ? widget.editTrip!.copyWith(
                    name: name,
                    destination: dest,
                    startDate: _start ?? widget.editTrip!.startDate,
                    endDate: _end ?? widget.editTrip!.endDate,
                  )
                      : Trip(
                    name: name,
                    destination: dest,
                    startDate: _start ?? DateTime.now(),
                    endDate: _end ?? DateTime.now().add(const Duration(days: 1)),
                  );

                  if (widget.editTrip != null) prov.updateTrip(trip);
                  else prov.addTrip(trip);

                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePickerRow(String label, DateTime? date, VoidCallback onPick) {
    return InkWell(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, color: Colors.blue),
            const SizedBox(width: 12),
            Text(
              '$label: ${date != null ? DateFormat.yMMMd().format(date) : '-'}',
              style: const TextStyle(fontSize: 16),
            ),
            const Spacer(),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  Future<void> _pickStart() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _pickEnd() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _end = d);
  }

  Widget _buildCard({required Widget child}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

extension TripCopy on Trip {
  Trip copyWith({String? name, String? destination, DateTime? startDate, DateTime? endDate}) {
    return Trip(
      id: id,
      name: name ?? this.name,
      destination: destination ?? this.destination,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      members: members,
      expenses: expenses,
    );
  }
}
