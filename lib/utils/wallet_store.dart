// lib/utils/wallet_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';

class WalletStore extends ChangeNotifier {
  static const _key = 'wallets';
  final _uuid = const Uuid();

  List<Wallet> _wallets = [];

  List<Wallet> get wallets => List.unmodifiable(_wallets);

  Wallet? findById(String id) {
    try { return _wallets.firstWhere((w) => w.id == id); }
    catch (_) { return null; }
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _wallets = decoded.map((e) => Wallet.fromMap(e)).toList();
    } else {
      // First launch — seed defaults
      _wallets = List.from(kDefaultWallets);
      await _save();
    }
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_wallets.map((w) => w.toMap()).toList()));
  }

  Future<void> add(String name, WalletType type, String iconKey, int colorValue) async {
    _wallets.add(Wallet(
      id: _uuid.v4(),
      name: name,
      type: type,
      iconKey: iconKey,
      colorValue: colorValue,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> update(String id, String name, WalletType type, String iconKey, int colorValue) async {
    final idx = _wallets.indexWhere((w) => w.id == id);
    if (idx != -1) {
      _wallets[idx] = _wallets[idx].copyWith(
        name: name, type: type, iconKey: iconKey, colorValue: colorValue);
      await _save();
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    _wallets.removeWhere((w) => w.id == id);
    await _save();
    notifyListeners();
  }
}