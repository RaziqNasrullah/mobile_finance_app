// lib/utils/category_store.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/category.dart';

class CategoryStore extends ChangeNotifier {
  static const _key = 'custom_categories';
  final _uuid = const Uuid();

  // Custom (user-created) categories only
  List<AppCategory> _custom = [];

  // All = defaults + custom
  List<AppCategory> get all => [...kDefaultCategories, ..._custom];

  List<AppCategory> get incomeCategories =>
      all.where((c) => c.isIncome).toList();

  List<AppCategory> get expenseCategories =>
      all.where((c) => !c.isIncome).toList();

  List<AppCategory> get customCategories => List.unmodifiable(_custom);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      final List decoded = jsonDecode(raw);
      _custom = decoded.map((e) => AppCategory.fromMap(e)).toList();
      notifyListeners();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_custom.map((c) => c.toMap()).toList()));
  }

  Future<void> add(String name, String iconKey, bool isIncome) async {
    _custom.add(AppCategory(
      id: _uuid.v4(),
      name: name,
      iconKey: iconKey,
      isIncome: isIncome,
    ));
    await _save();
    notifyListeners();
  }

  Future<void> update(String id, String name, String iconKey) async {
    final idx = _custom.indexWhere((c) => c.id == id);
    if (idx != -1) {
      _custom[idx] = _custom[idx].copyWith(name: name, iconKey: iconKey);
      await _save();
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    _custom.removeWhere((c) => c.id == id);
    await _save();
    notifyListeners();
  }

  // Lookup by name (for backwards compat with existing transactions)
  AppCategory? findByName(String name, bool isIncome) {
    try {
      return all.firstWhere((c) => c.name == name && c.isIncome == isIncome);
    } catch (_) {
      return null;
    }
  }
}