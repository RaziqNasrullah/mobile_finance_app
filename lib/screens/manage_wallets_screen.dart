// lib/screens/manage_wallets_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/wallet.dart';
import '../utils/wallet_store.dart';
import '../utils/transaction_store.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class ManageWalletsScreen extends StatelessWidget {
  final bool isDark;
  const ManageWalletsScreen({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return Scaffold(
      backgroundColor: AppColors.bgOf(d),
      appBar: AppBar(
        backgroundColor: AppColors.surfaceOf(d),
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimaryOf(d), size: 22),
        ),
        title: Text('Kelola Dompet',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimaryOf(d),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openForm(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.incomeGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.neonGreen.withOpacity(0.3),
                        blurRadius: 10)
                  ],
                ),
                child: const Row(children: [
                  Icon(Icons.add_rounded, color: AppColors.bg, size: 16),
                  SizedBox(width: 4),
                  Text('Tambah',
                      style: TextStyle(
                          color: AppColors.bg,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ]),
              ),
            ),
          ),
        ],
      ),
      body: Consumer<WalletStore>(
        builder: (_, store, __) {
          final wallets = store.wallets;
          if (wallets.isEmpty) {
            return Center(
              child: Text('Tidak ada dompet',
                  style: TextStyle(
                      color: AppColors.textSecondaryOf(d), fontSize: 14)),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: wallets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final w = wallets[i];
              final balance =
                  context.watch<TransactionStore>().walletBalance(w.id);
              return _WalletTile(
                wallet: w,
                balance: balance,
                isDark: d,
                onEdit: () => _openForm(context, editing: w),
                onDelete: w.isDefault
                    ? null
                    : () => _confirmDelete(context, w),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Wallet? editing}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletForm(isDark: isDark, editing: editing),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Wallet w) async {
    HapticFeedback.mediumImpact();
    final d = isDark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cardOf(d),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.neonPink.withOpacity(0.12),
                border:
                    Border.all(color: AppColors.neonPink.withOpacity(0.3)),
              ),
              child: const Icon(Icons.delete_rounded,
                  color: AppColors.neonPink, size: 26),
            ),
            const SizedBox(height: 16),
            Text('Hapus Dompet?',
                style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimaryOf(d),
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
                '"${w.name}" dan semua transaksinya akan dihapus permanen.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: AppColors.textSecondaryOf(d), fontSize: 13)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: NeonButton(
                      label: 'Batal',
                      onTap: () => Navigator.pop(context, false),
                      color: AppColors.neonBlue,
                      isOutlined: true)),
              const SizedBox(width: 12),
              Expanded(
                  child: NeonButton(
                      label: 'Hapus',
                      onTap: () => Navigator.pop(context, true),
                      color: AppColors.neonPink)),
            ]),
          ]),
        ),
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<TransactionStore>().deleteByWallet(w.id);
      await context.read<WalletStore>().delete(w.id);
    }
  }
}

// ── Wallet tile ───────────────────────────────────────────────────────────────
class _WalletTile extends StatelessWidget {
  final Wallet wallet;
  final double balance;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  const _WalletTile({
    required this.wallet,
    required this.balance,
    required this.isDark,
    required this.onEdit,
    this.onDelete,
  });

  String _fmt(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $s';
  }

  @override
  Widget build(BuildContext context) {
    final color = wallet.color;
    return GlassCard(
      borderColor: color.withOpacity(0.35),
      glowIntensity: 3,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      isDark: isDark,
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.35)),
          ),
          child: Icon(wallet.icon, color: color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(wallet.name,
                  style: TextStyle(
                      color: AppColors.textPrimaryOf(isDark),
                      fontSize: 14,
                      fontWeight: FontWeight.w600)),
              const SizedBox(width: 6),
              if (wallet.isDefault)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.textSecondaryOf(isDark).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Default',
                      style: TextStyle(
                          color: AppColors.textSecondaryOf(isDark),
                          fontSize: 9,
                          fontWeight: FontWeight.w500)),
                ),
            ]),
            const SizedBox(height: 3),
            Text(_fmt(balance),
                style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ]),
        ),
        _iconBtn(Icons.edit_rounded, AppColors.neonBlue, onEdit),
        const SizedBox(width: 6),
        if (onDelete != null)
          _iconBtn(Icons.delete_rounded, AppColors.neonPink, onDelete!)
        else
          const SizedBox(width: 30),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30, height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
            border: Border.all(color: color.withOpacity(0.25)),
          ),
          child: Icon(icon, color: color, size: 14),
        ),
      );
}

// ── Wallet form ───────────────────────────────────────────────────────────────
class _WalletForm extends StatefulWidget {
  final bool isDark;
  final Wallet? editing;
  const _WalletForm({required this.isDark, this.editing});

  @override
  State<_WalletForm> createState() => _WalletFormState();
}

class _WalletFormState extends State<_WalletForm> {
  final _nameCtrl = TextEditingController();
  WalletType _type = WalletType.cash;
  String _iconKey = 'wallet';
  int _colorValue = 0xFF0099CC;

  static const Map<WalletType, String> _typeLabels = {
    WalletType.cash:       'Tunai',
    WalletType.bank:       'Bank',
    WalletType.ewallet:    'E-Wallet',
    WalletType.investment: 'Investasi',
    WalletType.other:      'Lainnya',
  };

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      final e = widget.editing!;
      _nameCtrl.text = e.name;
      _type = e.type;
      _iconKey = e.iconKey;
      _colorValue = e.colorValue;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final store = context.read<WalletStore>();
    if (widget.editing != null) {
      await store.update(widget.editing!.id, _nameCtrl.text.trim(),
          _type, _iconKey, _colorValue);
    } else {
      await store.add(_nameCtrl.text.trim(), _type, _iconKey, _colorValue);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final color = Color(_colorValue);
    final isEdit = widget.editing != null;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(d),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: AppColors.cardBorderOf(d),
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              // Title
              Row(children: [
                Text(isEdit ? 'Edit Dompet' : 'Dompet Baru',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimaryOf(d),
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardOf(d),
                        border: Border.all(color: AppColors.cardBorderOf(d))),
                    child: Icon(Icons.close,
                        color: AppColors.textSecondaryOf(d), size: 15),
                  ),
                ),
              ]),
              const SizedBox(height: 20),

              // Name field with icon preview
              _label('Nama Dompet', d),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorderOf(d)),
                  color: AppColors.cardOf(d),
                ),
                child: Row(children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(13)),
                      color: color.withOpacity(0.15),
                      border: Border(
                          right: BorderSide(
                              color: AppColors.cardBorderOf(d))),
                    ),
                    child: Icon(
                        kWalletIconMap[_iconKey] ??
                            Icons.account_balance_wallet_rounded,
                        color: color, size: 22),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _nameCtrl,
                      style: TextStyle(
                          color: AppColors.textPrimaryOf(d), fontSize: 15),
                      decoration: InputDecoration(
                        hintText: 'Nama dompet...',
                        hintStyle: TextStyle(
                            color: AppColors.textSecondaryOf(d),
                            fontSize: 14),
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14),
                      ),
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 20),

              // Wallet type
              _label('Jenis Dompet', d),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: WalletType.values.map((t) {
                  final active = _type == t;
                  return GestureDetector(
                    onTap: () => setState(() => _type = t),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: active
                            ? color.withOpacity(0.15)
                            : AppColors.cardOf(d),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: active
                                ? color.withOpacity(0.5)
                                : AppColors.cardBorderOf(d)),
                      ),
                      child: Text(_typeLabels[t]!,
                          style: TextStyle(
                              color: active
                                  ? color
                                  : AppColors.textSecondaryOf(d),
                              fontSize: 12,
                              fontWeight: active
                                  ? FontWeight.w600
                                  : FontWeight.w400)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Icon picker
              _label('Icon', d),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: kWalletIconMap.entries.map((e) {
                  final active = _iconKey == e.key;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _iconKey = e.key);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: active
                            ? color.withOpacity(0.18)
                            : AppColors.cardOf(d),
                        border: Border.all(
                            color: active
                                ? color.withOpacity(0.6)
                                : AppColors.cardBorderOf(d),
                            width: active ? 1.5 : 1),
                      ),
                      child: Icon(e.value,
                          color: active
                              ? color
                              : AppColors.textSecondaryOf(d),
                          size: 20),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Color picker
              _label('Warna', d),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10, runSpacing: 10,
                children: kWalletColors.map((cv) {
                  final active = _colorValue == cv;
                  final c = Color(cv);
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _colorValue = cv);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: c,
                        border: Border.all(
                            color: active
                                ? Colors.white.withOpacity(0.8)
                                : Colors.transparent,
                            width: 2.5),
                        boxShadow: active
                            ? [BoxShadow(
                                color: c.withOpacity(0.5), blurRadius: 8)]
                            : null,
                      ),
                      child: active
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 28),

              NeonButton(
                label: isEdit ? 'Simpan Perubahan' : 'Buat Dompet',
                onTap: _save,
                icon: isEdit ? Icons.save_rounded : Icons.add_rounded,
                width: double.infinity,
                color: color,
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text, bool d) => Text(text,
      style: TextStyle(
          color: AppColors.textSecondaryOf(d),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5));
}