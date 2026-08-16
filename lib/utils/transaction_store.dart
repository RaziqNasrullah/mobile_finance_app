// lib/utils/transaction_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/transaction.dart';

class TransactionStore extends ChangeNotifier {
  static const _key = 'transactions';
  final _uuid = const Uuid();
  List<Transaction> _transactions = [];

  List<Transaction> get transactions =>
      List.unmodifiable(_transactions..sort((a, b) => b.date.compareTo(a.date)));

  // All wallets combined
  double get totalIncome => _transactions
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get totalExpense => _transactions
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double get balance => totalIncome - totalExpense;

  // Per-wallet helpers
  List<Transaction> byWallet(String walletId) =>
      _transactions.where((t) => t.walletId == walletId).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  double walletIncome(String walletId) => byWallet(walletId)
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double walletExpense(String walletId) => byWallet(walletId)
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  double walletBalance(String walletId) =>
      walletIncome(walletId) - walletExpense(walletId);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _transactions = decoded.map((e) => Transaction.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _key, jsonEncode(_transactions.map((t) => t.toMap()).toList()));
  }

  Future<void> add(String name, TransactionType type, double amount,
      DateTime date, String category, String walletId) async {
    _transactions.add(Transaction(
      id: _uuid.v4(),
      name: name,
      type: type,
      amount: amount,
      date: date,
      category: category,
      walletId: walletId,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> update(String id, String name, TransactionType type,
      double amount, DateTime date, String category, String walletId) async {
    final idx = _transactions.indexWhere((t) => t.id == id);
    if (idx != -1) {
      _transactions[idx] = Transaction(
        id: id, name: name, type: type, amount: amount,
        date: date, category: category, walletId: walletId,
      );
      await _save();
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    await _save();
    notifyListeners();
  }

  // Delete all transactions for a wallet (when wallet is deleted)
  Future<void> deleteByWallet(String walletId) async {
    _transactions.removeWhere((t) => t.walletId == walletId);
    await _save();
    notifyListeners();
  }
}