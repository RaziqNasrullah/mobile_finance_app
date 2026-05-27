// lib/models/category.dart

import 'package:flutter/material.dart';

class AppCategory {
  final String id;
  final String name;
  final String iconKey; // key into kCategoryIconMap
  final bool isIncome;
  final bool isDefault;

  const AppCategory({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.isIncome,
    this.isDefault = false,
  });

  IconData get icon => kCategoryIconMap[iconKey] ?? Icons.circle_rounded;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'iconKey': iconKey,
    'isIncome': isIncome,
    'isDefault': isDefault,
  };

  factory AppCategory.fromMap(Map<String, dynamic> m) => AppCategory(
    id: m['id'],
    name: m['name'],
    iconKey: m['iconKey'] ?? 'circle',
    isIncome: m['isIncome'],
    isDefault: m['isDefault'] ?? false,
  );

  AppCategory copyWith({String? name, String? iconKey}) => AppCategory(
    id: id,
    name: name ?? this.name,
    iconKey: iconKey ?? this.iconKey,
    isIncome: isIncome,
    isDefault: isDefault,
  );
}

// ── Available icons for picker ────────────────────────────────────────────────
const Map<String, IconData> kCategoryIconMap = {
  // Finance & money
  'payments':         Icons.payments_rounded,
  'wallet':           Icons.account_balance_wallet_rounded,
  'savings':          Icons.savings_rounded,
  'trending_up':      Icons.trending_up_rounded,
  'trending_down':    Icons.trending_down_rounded,
  'attach_money':     Icons.attach_money_rounded,
  'currency_exchange':Icons.currency_exchange_rounded,
  'receipt':          Icons.receipt_long_rounded,
  'credit_card':      Icons.credit_card_rounded,
  'bank':             Icons.account_balance_rounded,
  // Work
  'laptop':           Icons.laptop_rounded,
  'work':             Icons.work_rounded,
  'business':         Icons.business_center_rounded,
  'handshake':        Icons.handshake_rounded,
  'school':           Icons.school_rounded,
  // Food
  'restaurant':       Icons.restaurant_rounded,
  'fastfood':         Icons.fastfood_rounded,
  'coffee':           Icons.coffee_rounded,
  'cake':             Icons.cake_rounded,
  'grocery':          Icons.local_grocery_store_rounded,
  // Transport
  'car':              Icons.directions_car_rounded,
  'motorcycle':       Icons.two_wheeler_rounded,
  'bus':              Icons.directions_bus_rounded,
  'flight':           Icons.flight_rounded,
  'local_taxi':       Icons.local_taxi_rounded,
  // Shopping
  'shopping_bag':     Icons.shopping_bag_rounded,
  'store':            Icons.store_rounded,
  'checkroom':        Icons.checkroom_rounded,
  'redeem':           Icons.redeem_rounded,
  // Health
  'favorite':         Icons.favorite_rounded,
  'medical':          Icons.medical_services_rounded,
  'fitness':          Icons.fitness_center_rounded,
  'spa':              Icons.spa_rounded,
  // Entertainment
  'movie':            Icons.movie_rounded,
  'music':            Icons.music_note_rounded,
  'sports':           Icons.sports_esports_rounded,
  'travel':           Icons.travel_explore_rounded,
  'camera':           Icons.camera_alt_rounded,
  'book':             Icons.menu_book_rounded,
  // Home
  'home':             Icons.home_rounded,
  'build':            Icons.build_rounded,
  'electricity':      Icons.bolt_rounded,
  'water':            Icons.water_drop_rounded,
  'wifi':             Icons.wifi_rounded,
  // Other
  'pets':             Icons.pets_rounded,
  'child':            Icons.child_care_rounded,
  'gift':             Icons.card_giftcard_rounded,
  'charity':          Icons.volunteer_activism_rounded,
  'circle':           Icons.circle_rounded,
};

// ── Default categories ────────────────────────────────────────────────────────
List<AppCategory> kDefaultCategories = [
  // Income
  const AppCategory(id: 'gaji',      name: 'Gaji',      iconKey: 'payments',    isIncome: true,  isDefault: true),
  const AppCategory(id: 'freelance', name: 'Freelance', iconKey: 'laptop',      isIncome: true,  isDefault: true),
  const AppCategory(id: 'investasi', name: 'Investasi', iconKey: 'trending_up', isIncome: true,  isDefault: true),
  const AppCategory(id: 'gen_in',    name: 'General',   iconKey: 'circle',      isIncome: true,  isDefault: true),
  // Expense
  const AppCategory(id: 'makanan',   name: 'Makanan',   iconKey: 'restaurant',  isIncome: false, isDefault: true),
  const AppCategory(id: 'transport', name: 'Transport', iconKey: 'car',         isIncome: false, isDefault: true),
  const AppCategory(id: 'belanja',   name: 'Belanja',   iconKey: 'shopping_bag',isIncome: false, isDefault: true),
  const AppCategory(id: 'hiburan',   name: 'Hiburan',   iconKey: 'movie',       isIncome: false, isDefault: true),
  const AppCategory(id: 'kesehatan', name: 'Kesehatan', iconKey: 'favorite',    isIncome: false, isDefault: true),
  const AppCategory(id: 'gen_ex',    name: 'General',   iconKey: 'circle',      isIncome: false, isDefault: true),
];