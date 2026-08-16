// lib/models/transaction.dart

enum TransactionType { income, expense }

class Transaction {
  final String id;
  final String name;
  final TransactionType type;
  final double amount;
  final DateTime date;
  final String category;
  final String walletId; // default 'cash' for legacy transactions

  Transaction({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.date,
    this.category = 'General',
    this.walletId = 'cash',
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.index,
    'amount': amount,
    'date': date.toIso8601String(),
    'category': category,
    'walletId': walletId,
  };

  factory Transaction.fromMap(Map<String, dynamic> map) => Transaction(
    id: map['id'],
    name: map['name'],
    type: TransactionType.values[map['type']],
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.parse(map['date']),
    category: map['category'] ?? 'General',
    walletId: map['walletId'] ?? 'cash', // backward compat
  );
}