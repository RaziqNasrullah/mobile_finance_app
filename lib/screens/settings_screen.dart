// lib/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../utils/theme_notifier.dart';
import '../utils/pdf_export.dart';
import '../utils/transaction_store.dart';
import 'manage_categories_screen.dart';
import 'manage_wallets_screen.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDark;
  const SettingsScreen({super.key, required this.isDark});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  bool _exporting = false;
  final _budgetCtrl = TextEditingController();
  double? _budgetLimit;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _budgetCtrl.dispose();
    super.dispose();
  }

  Future<void> _exportPdf(List<Transaction> txs) async {
    if (txs.isEmpty) {
      _showSnack('Tidak ada data untuk diekspor', AppColors.neonYellow);
      return;
    }
    setState(() => _exporting = true);
    try {
      await PdfExport.exportTransactions(txs);
    } catch (e) {
      _showSnack('Gagal ekspor: $e', AppColors.neonPink);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color.withOpacity(0.9),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showBudgetDialog() {
    _budgetCtrl.text = _budgetLimit?.toStringAsFixed(0) ?? '';
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cardOf(widget.isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Budget Limit Bulanan',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimaryOf(widget.isDark),
                  fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text('Kamu akan dapat peringatan jika pengeluaran mendekati limit.',
                style: TextStyle(color: AppColors.textSecondaryOf(widget.isDark), fontSize: 12)),
              const SizedBox(height: 16),
              TextField(
                controller: _budgetCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(color: AppColors.textPrimaryOf(widget.isDark)),
                decoration: InputDecoration(
                  hintText: 'Contoh: 5000000',
                  hintStyle: TextStyle(color: AppColors.textSecondaryOf(widget.isDark)),
                  prefixText: 'Rp ',
                  prefixStyle: const TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: AppColors.surfaceOf(widget.isDark),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.neonBlue.withOpacity(0.4)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.cardBorderOf(widget.isDark)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: TextButton(
                  onPressed: () {
                    setState(() => _budgetLimit = null);
                    Navigator.pop(context);
                  },
                  child: Text('Hapus', style: TextStyle(color: AppColors.textSecondaryOf(widget.isDark))),
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    final v = double.tryParse(_budgetCtrl.text);
                    if (v != null && v > 0) setState(() => _budgetLimit = v);
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan'),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final store = context.watch<TransactionStore>();
    final themeNotifier = context.watch<ThemeNotifier>();

    // Budget alert check
    final now = DateTime.now();
    final monthExpense = store.transactions
        .where((t) => t.type == TransactionType.expense && t.date.month == now.month && t.date.year == now.year)
        .fold(0.0, (s, t) => s + t.amount);
    final budgetPct = _budgetLimit != null ? monthExpense / _budgetLimit! : 0.0;
    final showBudgetAlert = _budgetLimit != null && budgetPct >= 0.8;

    String _fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Pengaturan', style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimaryOf(d), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            )),
            const SizedBox(height: 4),
            Text('Kelola preferensi aplikasi', style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13)),
            const SizedBox(height: 24),

            // Budget alert banner
            if (showBudgetAlert) ...[
              _alertBanner(budgetPct, monthExpense, _budgetLimit!, d, _fmt),
              const SizedBox(height: 16),
            ],

            // Appearance
            _sectionLabel('TAMPILAN', d),
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.neonBlue.withOpacity(0.3),
              isDark: d,
              padding: EdgeInsets.zero,
              child: Column(children: [
                _settingRow(
                  icon: d ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                  iconColor: AppColors.neonBlue,
                  title: 'Mode Gelap',
                  subtitle: d ? 'Aktif' : 'Nonaktif',
                  isDark: d,
                  trailing: _neonSwitch(themeNotifier.isDark, (_) => themeNotifier.toggle(), AppColors.neonBlue),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // Kategori
            _sectionLabel('KATEGORI', d),
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.neonBlue.withOpacity(0.3),
              isDark: d,
              padding: EdgeInsets.zero,
              child: _settingRow(
                icon: Icons.category_rounded,
                iconColor: AppColors.neonGreen,
                title: 'Kelola Kategori',
                subtitle: 'Tambah, edit, atau hapus kategori',
                isDark: d,
                trailing: _actionBtn('Kelola', AppColors.neonGreen, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ManageCategoriesScreen(isDark: d),
                  ));
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Dompet
            _sectionLabel('DOMPET', d),
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.neonBlue.withOpacity(0.3),
              isDark: d,
              padding: EdgeInsets.zero,
              child: _settingRow(
                icon: Icons.account_balance_wallet_rounded,
                iconColor: AppColors.neonBlue,
                title: 'Kelola Dompet',
                subtitle: 'Tambah, edit, atau hapus dompet',
                isDark: d,
                trailing: _actionBtn('Kelola', AppColors.neonBlue, () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ManageWalletsScreen(isDark: d),
                  ));
                }),
              ),
            ),
            const SizedBox(height: 16),

            // Budget
            _sectionLabel('ANGGARAN', d),
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.neonBlue.withOpacity(0.3),
              isDark: d,
              padding: EdgeInsets.zero,
              child: _settingRow(
                icon: Icons.savings_rounded,
                iconColor: AppColors.neonYellow,
                title: 'Budget Limit Bulanan',
                subtitle: _budgetLimit != null ? _fmt(_budgetLimit!) : 'Belum diatur',
                isDark: d,
                trailing: _actionBtn('Atur', AppColors.neonYellow, _showBudgetDialog),
              ),
            ),
            if (_budgetLimit != null) ...[
              const SizedBox(height: 8),
              _budgetProgress(budgetPct, monthExpense, _budgetLimit!, d, _fmt),
            ],
            const SizedBox(height: 16),

            // Export
            _sectionLabel('DATA', d),
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.neonBlue.withOpacity(0.3),
              isDark: d,
              padding: EdgeInsets.zero,
              child: Column(children: [
                _settingRow(
                  icon: Icons.picture_as_pdf_rounded,
                  iconColor: AppColors.neonGreen,
                  title: 'Ekspor ke PDF',
                  subtitle: '${store.transactions.length} transaksi tersedia',
                  isDark: d,
                  trailing: _exporting
                    ? const SizedBox(width: 72, height: 32, child: Center(child: SizedBox(width: 40, height: 3, child: LinearProgressIndicator(color: AppColors.neonGreen, backgroundColor: Colors.transparent))))
                    : _actionBtn('Ekspor', AppColors.neonGreen, () => _exportPdf(store.transactions)),
                ),
                Divider(height: 1, color: AppColors.cardBorderOf(d)),
                _settingRow(
                  icon: Icons.delete_sweep_rounded,
                  iconColor: AppColors.neonPink,
                  title: 'Hapus Semua Data',
                  subtitle: 'Tidak dapat dikembalikan',
                  isDark: d,
                  trailing: _actionBtn('Hapus', AppColors.neonPink, () => _confirmClearAll(context, store)),
                ),
              ]),
            ),
            const SizedBox(height: 16),

            // App info
            _sectionLabel('TENTANG', d),
            const SizedBox(height: 8),
            GlassCard(
              borderColor: AppColors.cardBorderOf(d),
              isDark: d,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.incomeGradient,
                      boxShadow: [BoxShadow(color: AppColors.neonGreen.withOpacity(0.3), blurRadius: 16)],
                    ),
                    child: const Icon(Icons.account_balance_wallet_rounded, color: Colors.white, size: 26),
                  ),
                  const SizedBox(height: 10),
                  Text('Keuangan Ku', style: TextStyle(
                    color: AppColors.textPrimaryOf(d), fontSize: 16, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 2),
                  Text('Versi 2.0.0', style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 12)),
                  const SizedBox(height: 2),
                  Text('Custom widgets • No boring UI', style: TextStyle(color: AppColors.neonBlue.withOpacity(0.7), fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _alertBanner(double pct, double current, double limit, bool d, String Function(double) fmt) {
    final over = pct >= 1.0;
    final color = over ? AppColors.neonPink : AppColors.neonYellow;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(over ? Icons.warning_rounded : Icons.info_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                over ? 'Budget Terlampaui!' : 'Mendekati Batas Budget!',
                style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
              ),
              Text(
                '${fmt(current)} dari ${fmt(limit)} (${(pct * 100).toStringAsFixed(0)}%)',
                style: TextStyle(color: color.withOpacity(0.8), fontSize: 11),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _budgetProgress(double pct, double current, double limit, bool d, String Function(double) fmt) {
    final clampedPct = pct.clamp(0.0, 1.0);
    final color = pct >= 1.0 ? AppColors.neonPink : pct >= 0.8 ? AppColors.neonYellow : AppColors.neonGreen;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(fmt(current), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            Text(fmt(limit), style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 11)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(children: [
              Container(height: 6, color: AppColors.cardBorderOf(d)),
              FractionallySizedBox(
                widthFactor: clampedPct,
                child: Container(height: 6, decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 4)],
                )),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        padding: const EdgeInsets.symmetric(vertical: 7),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Text(label,
          textAlign: TextAlign.center,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _sectionLabel(String text, bool d) => Text(
    text,
    style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2),
  );

  Widget _settingRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required Widget trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withOpacity(0.12),
              border: Border.all(color: iconColor.withOpacity(0.25)),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: AppColors.textPrimaryOf(isDark), fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle, style: TextStyle(color: AppColors.textSecondaryOf(isDark), fontSize: 11)),
            ],
          )),
          trailing,
        ],
      ),
    );
  }

  Widget _neonSwitch(bool value, ValueChanged<bool> onChanged, Color color) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        width: 46, height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(13),
          color: value ? color.withOpacity(0.2) : AppColors.cardBorder,
          border: Border.all(color: value ? color.withOpacity(0.6) : Colors.transparent),
          boxShadow: value ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)] : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? color : AppColors.textSecondary,
                boxShadow: value ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)] : null,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmClearAll(BuildContext context, TransactionStore store) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cardOf(widget.isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonPink.withOpacity(0.12),
                  border: Border.all(color: AppColors.neonPink.withOpacity(0.3)),
                ),
                child: const Icon(Icons.delete_forever_rounded, color: AppColors.neonPink, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Hapus Semua Data?',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              const Text('Semua transaksi akan dihapus permanen. Tidak bisa dikembalikan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(context, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.neonBlue.withOpacity(0.4)),
                      color: AppColors.neonBlue.withOpacity(0.08),
                    ),
                    child: const Text('Batal', textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.neonBlue, fontWeight: FontWeight.w600)),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(context, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: AppColors.expenseGradient,
                      boxShadow: [BoxShadow(color: AppColors.neonPink.withOpacity(0.3), blurRadius: 12)],
                    ),
                    child: const Text('Hapus Semua', textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                )),
              ]),
            ],
          ),
        ),
      ),
    );
    if (ok == true) {
      for (final t in store.transactions.toList()) {
        await store.delete(t.id);
      }
      if (mounted) _showSnack('Semua data berhasil dihapus', AppColors.neonGreen);
    }
  }
}