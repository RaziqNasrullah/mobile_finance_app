// lib/models/wallet.dart
import 'package:flutter/material.dart';

enum WalletType { cash, bank, ewallet, investment, other }

class Wallet {
  final String id;
  final String name;
  final WalletType type;
  final String iconKey;
  final int colorValue; // stored as int
  final bool isDefault;

  const Wallet({
    required this.id,
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    this.isDefault = false,
  });

  Color get color => Color(colorValue);
  IconData get icon => kWalletIconMap[iconKey] ?? Icons.account_balance_wallet_rounded;

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'type': type.index,
    'iconKey': iconKey,
    'colorValue': colorValue,
    'isDefault': isDefault,
  };

  factory Wallet.fromMap(Map<String, dynamic> m) => Wallet(
    id: m['id'],
    name: m['name'],
    type: WalletType.values[m['type'] ?? 0],
    iconKey: m['iconKey'] ?? 'wallet',
    colorValue: m['colorValue'] ?? 0xFF0099CC,
    isDefault: m['isDefault'] ?? false,
  );

  Wallet copyWith({String? name, WalletType? type, String? iconKey, int? colorValue}) =>
    Wallet(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      isDefault: isDefault,
    );
}

// ── Available icons ───────────────────────────────────────────────────────────
const Map<String, IconData> kWalletIconMap = {
  'wallet':      Icons.account_balance_wallet_rounded,
  'bank':        Icons.account_balance_rounded,
  'cash':        Icons.payments_rounded,
  'card':        Icons.credit_card_rounded,
  'savings':     Icons.savings_rounded,
  'trending_up': Icons.trending_up_rounded,
  'phone':       Icons.phone_android_rounded,
  'store':       Icons.store_rounded,
  'diamond':     Icons.diamond_rounded,
  'star':        Icons.star_rounded,
};

// ── Preset colors ─────────────────────────────────────────────────────────────
const List<int> kWalletColors = [
  0xFF0099CC, // neon blue
  0xFF00C07A, // neon green
  0xFFE0008A, // neon pink
  0xFFFFD60A, // yellow
  0xFFAA66FF, // purple
  0xFFFF8C42, // orange
  0xFF00D4FF, // cyan
  0xFFFF3CAC, // hot pink
  0xFF4CAF50, // green
  0xFF2196F3, // blue
];

// ── Default wallets ───────────────────────────────────────────────────────────
final List<Wallet> kDefaultWallets = [
  const Wallet(
    id: 'cash',
    name: 'Tunai',
    type: WalletType.cash,
    iconKey: 'cash',
    colorValue: 0xFF00C07A,
    isDefault: true,
  ),
  const Wallet(
    id: 'bank',
    name: 'Bank',
    type: WalletType.bank,
    iconKey: 'bank',
    colorValue: 0xFF0099CC,
    isDefault: true,
  ),
];