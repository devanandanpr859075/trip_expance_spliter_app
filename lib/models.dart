// lib/models.dart
import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class Member {
  String id;
  String name;
  String? contact;
  String? photoPath;

  Member({
    String? id,
    required this.name,
    this.contact,
    this.photoPath,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'contact': contact,
    'photoPath': photoPath,
  };

  factory Member.fromMap(Map<String, dynamic> m) => Member(
    id: (m['id'] as String?) ?? _uuid.v4(),
    name: (m['name'] as String?) ?? 'Unnamed',
    contact: m['contact'] as String?,
    photoPath: m['photoPath'] as String?,
  );
}

class Expense {
  String id;
  String title;
  double amount;
  String paidById; // member.id of payer
  List<String> splitWithIds; // member ids who share this expense
  String category;
  DateTime date;

  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.paidById,
    required this.splitWithIds,
    required this.category,
    DateTime? date,
  })  : id = id ?? _uuid.v4(),
        date = date ?? DateTime.now();

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'amount': amount,
    'paidById': paidById,
    'splitWithIds': splitWithIds,
    'category': category,
    'date': date.toIso8601String(),
  };

  factory Expense.fromMap(Map<String, dynamic> m) => Expense(
    id: (m['id'] as String?) ?? _uuid.v4(),
    title: (m['title'] as String?) ?? '',
    amount: (m['amount'] as num?)?.toDouble() ?? 0.0,
    paidById: (m['paidById'] as String?) ?? '',
    splitWithIds: List<String>.from(m['splitWithIds'] ?? const []),
    category: (m['category'] as String?) ?? 'Misc',
    date:
    DateTime.tryParse((m['date'] as String?) ?? '') ?? DateTime.now(),
  );

  double sharePerPerson() =>
      splitWithIds.isEmpty ? 0.0 : amount / splitWithIds.length;
}

class Trip {
  String id;
  String name;
  String destination;
  DateTime startDate;
  DateTime endDate;
  List<Member> members;
  List<Expense> expenses;

  Trip({
    String? id,
    required this.name,
    required this.destination,
    required this.startDate,
    required this.endDate,
    List<Member>? members,
    List<Expense>? expenses,
  })  : id = id ?? _uuid.v4(),
        members = members ?? [],
        expenses = expenses ?? [];

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'destination': destination,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'members': members.map((m) => m.toMap()).toList(),
    'expenses': expenses.map((e) => e.toMap()).toList(),
  };

  factory Trip.fromMap(Map<String, dynamic> m) => Trip(
    id: (m['id'] as String?) ?? _uuid.v4(),
    name: (m['name'] as String?) ?? 'Untitled',
    destination: (m['destination'] as String?) ?? '',
    startDate: DateTime.tryParse((m['startDate'] as String?) ?? '') ??
        DateTime.now(),
    endDate:
    DateTime.tryParse((m['endDate'] as String?) ?? '') ?? DateTime.now(),
    members: (m['members'] as List? ?? [])
        .map((x) => Member.fromMap(Map<String, dynamic>.from(x as Map)))
        .toList(),
    expenses: (m['expenses'] as List? ?? [])
        .map((x) => Expense.fromMap(Map<String, dynamic>.from(x as Map)))
        .toList(),
  );

  double totalCost() => expenses.fold(0.0, (s, e) => s + e.amount);

  /// Get member name from ID (returns "Unknown" if not found)
  String memberName(String id) {
    return members
        .firstWhere((m) => m.id == id, orElse: () => Member(name: "Unknown"))
        .name;
  }

  /// Map of memberId -> total amount they paid
  Map<String, double> totalPaidPerMember() {
    final Map<String, double> paid = {};
    for (final m in members) paid[m.id] = 0.0;
    for (final e in expenses) {
      paid[e.paidById] = (paid[e.paidById] ?? 0) + e.amount;
    }
    paid.updateAll((k, v) => double.parse(v.toStringAsFixed(2)));
    return paid;
  }

  /// Map of memberId -> total share they should pay (sum of their shares)
  Map<String, double> totalSharePerMember() {
    final Map<String, double> share = {};
    for (final m in members) share[m.id] = 0.0;
    for (final e in expenses) {
      final sp = e.sharePerPerson();
      for (final pid in e.splitWithIds) {
        share[pid] = (share[pid] ?? 0) + sp;
      }
    }
    share.updateAll((k, v) => double.parse(v.toStringAsFixed(2)));
    return share;
  }

  /// Net per member (positive => should receive, negative => owes)
  Map<String, double> netPerMember() {
    final paid = totalPaidPerMember();
    final share = totalSharePerMember();
    final Map<String, double> net = {};
    for (final m in members) {
      net[m.id] = double.parse(((paid[m.id] ?? 0) - (share[m.id] ?? 0))
          .toStringAsFixed(2));
    }
    return net;
  }
}
