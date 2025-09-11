// lib/trip_provider.dart
import 'package:flutter/foundation.dart';
import 'models.dart';
import 'storage_service.dart';
import 'settlement.dart';

class TripProvider extends ChangeNotifier {
  TripProvider() {
    _load();
  }

  final List<Trip> _trips = [];

  List<Trip> get trips => List.unmodifiable(_trips);

  Future<void> _load() async {
    try {
      _trips
        ..clear()
        ..addAll(StorageService.allTrips());
    } catch (e) {
      // ignore
    }
    notifyListeners();
  }

  Future<void> addTrip(Trip t) async {
    _trips.add(t);
    await StorageService.saveTrip(t);
    notifyListeners();
  }

  Future<void> updateTrip(Trip t) async {
    final idx = _trips.indexWhere((x) => x.id == t.id);
    if (idx != -1) {
      _trips[idx] = t;
    } else {
      _trips.add(t);
    }
    await StorageService.saveTrip(t);
    notifyListeners();
  }

  Future<void> deleteTrip(String id) async {
    _trips.removeWhere((t) => t.id == id);
    await StorageService.deleteTrip(id);
    notifyListeners();
  }

  Trip? getById(String id) {
    try {
      return _trips.firstWhere((t) => t.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> addMember(String tripId, Member m) async {
    final t = getById(tripId);
    if (t == null) return;
    t.members.add(m);
    await updateTrip(t);
  }

  Future<void> addExpense(String tripId, Expense e) async {
    final t = getById(tripId);
    if (t == null) return;
    t.expenses.add(e);
    await updateTrip(t);
  }

  Future<void> deleteExpense(String tripId, String expenseId) async {
    final t = getById(tripId);
    if (t == null) return;
    t.expenses.removeWhere((ex) => ex.id == expenseId);
    await updateTrip(t);
  }

  Future<void> deleteMember(String tripId, String memberId) async {
    final t = getById(tripId);
    if (t == null) return;
    t.members.removeWhere((m) => m.id == memberId);
    for (final ex in t.expenses) {
      ex.splitWithIds.removeWhere((id) => id == memberId);
      // keep paidById as-is; UI can display 'Unknown' via memberName
    }
    await updateTrip(t);
  }

  /// Convenience: returns mapping memberId -> net amount
  Map<String, double>? netMapForTrip(String tripId) {
    final t = getById(tripId);
    if (t == null) return null;
    return computeNetMap(t);
  }

  /// Convenience: returns settlement transfers with ids and amounts.
  /// Each transfer is {'from': debtorId, 'to': creditorId, 'amount': double}
  List<Map<String, dynamic>>? settlementForTrip(String tripId) {
    final net = netMapForTrip(tripId);
    if (net == null) return null;
    return settleBalances(net);
  }

  /// Convenience: returns settlement transfers with names (for UI)
  List<Map<String, dynamic>>? settlementWithNames(String tripId) {
    final t = getById(tripId);
    final transfers = settlementForTrip(tripId);
    if (t == null || transfers == null) return null;
    return transfers
        .map((tr) => {
      'fromId': tr['from'],
      'toId': tr['to'],
      'amount': tr['amount'],
      'fromName': t.memberName(tr['from'] as String),
      'toName': t.memberName(tr['to'] as String),
    })
        .toList();
  }
}
