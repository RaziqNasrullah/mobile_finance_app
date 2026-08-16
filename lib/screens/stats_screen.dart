// lib/screens/stats_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_charts.dart';

class StatsScreen extends StatefulWidget {
  final List<Transaction> transactions;
  final bool isDark;

  const StatsScreen({super.key, required this.transactions, required this.isDark});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  int _selectedPeriod = 0; // 0=minggu, 1=bulan, 2=semua

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
    super.dispose();
  }

  List<Transaction> get _filtered {
    final now = DateTime.now();
    if (_selectedPeriod == 0) {
      final start = now.subtract(const Duration(days: 7));
      return widget.transactions.where((t) => t.date.isAfter(start)).toList();
    } else if (_selectedPeriod == 1) {
      return widget.transactions.where((t) => t.date.month == now.month && t.date.year == now.year).toList();
    }
    return widget.transactions;
  }

  double get _income => _filtered
      .where((t) => t.type == TransactionType.income)
      .fold(0.0, (s, t) => s + t.amount);

  double get _expense => _filtered
      .where((t) => t.type == TransactionType.expense)
      .fold(0.0, (s, t) => s + t.amount);

  Map<String, double> get _categoryBreakdown {
    final map = <String, double>{};
    for (final t in _filtered.where((t) => t.type == TransactionType.expense)) {
      map[t.category] = (map[t.category] ?? 0) + t.amount;
    }
    return map;
  }



  String _fmt(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    return FadeTransition(
      opacity: _fade,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text('Statistik', style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimaryOf(d), fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5,
            )),
            const SizedBox(height: 4),
            Text('Analisis keuanganmu', style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13)),
            const SizedBox(height: 20),

            // Period toggle
            _periodToggle(d),
            const SizedBox(height: 20),

            // Summary row
            Row(children: [
              Expanded(child: _summaryCard('Pemasukan', _income, AppColors.income, Icons.arrow_downward_rounded, d)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Pengeluaran', _expense, AppColors.expense, Icons.arrow_upward_rounded, d)),
            ]),
            const SizedBox(height: 16),

            // Donut chart
            GlassCard(
              borderColor: AppColors.neonBlue.withOpacity(0.4),
              isDark: d,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Distribusi', style: TextStyle(
                    color: AppColors.textPrimaryOf(d), fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 20),
                  DonutChart(income: _income, expense: _expense, isDark: d),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Category breakdown
            if (_categoryBreakdown.isNotEmpty)
              GlassCard(
                borderColor: AppColors.neonPink.withOpacity(0.4),
                isDark: d,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kategori Pengeluaran', style: TextStyle(
                      color: AppColors.textPrimaryOf(d), fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    CategoryBreakdown(
                      categories: _categoryBreakdown,
                      total: _expense,
                      isDark: d,
                    ),
                  ],
                ),
              ),

            // Top transactions
            const SizedBox(height: 16),
            GlassCard(
              borderColor: AppColors.neonYellow.withOpacity(0.4),
              isDark: d,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Transaksi Terbesar', style: TextStyle(
                    color: AppColors.textPrimaryOf(d), fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  if (_filtered.isEmpty)
                    Center(child: Text('Tidak ada data', style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13)))
                  else
                    ...(_filtered.toList()
                      ..sort((a, b) => b.amount.compareTo(a.amount)))
                        .take(5)
                        .map((t) => _topTxRow(t, d)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dot(Color c) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(shape: BoxShape.circle, color: c,
      boxShadow: [BoxShadow(color: c.withOpacity(0.4), blurRadius: 4)]),
  );

  Widget _periodToggle(bool d) {
    final labels = ['Minggu Ini', 'Bulan Ini', 'Semua'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(d),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.cardBorderOf(d)),
      ),
      child: Row(
        children: List.generate(3, (i) {
          final active = _selectedPeriod == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedPeriod = i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: active ? AppColors.neonBlue.withOpacity(0.15) : Colors.transparent,
                  border: active ? Border.all(color: AppColors.neonBlue.withOpacity(0.4)) : null,
                ),
                child: Text(labels[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: active ? AppColors.neonBlue : AppColors.textSecondaryOf(d),
                    fontSize: 11, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                  )),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _summaryCard(String label, double value, Color color, IconData icon, bool d) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 11, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 8),
          Text(_fmt(value), style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _topTxRow(Transaction t, bool d) {
    final isIncome = t.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.12),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(t.name,
            style: TextStyle(color: AppColors.textPrimaryOf(d), fontSize: 12, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          )),
          Text(
            '${isIncome ? '+' : '-'}${_fmt(t.amount)}',
            style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}