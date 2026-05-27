// lib/widgets/custom_charts.dart
import 'dart:math';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

// ─── Donut Chart ────────────────────────────────────────────────────────────

class DonutChartPainter extends CustomPainter {
  final double income;
  final double expense;
  final double animValue;
  final bool isDark;

  DonutChartPainter({
    required this.income,
    required this.expense,
    required this.animValue,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = min(cx, cy) - 12;
    final strokeW = 22.0;
    final total = income + expense;

    // Background ring
    canvas.drawCircle(
      Offset(cx, cy),
      radius,
      Paint()
        ..color = AppColors.cardBorderOf(isDark)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeW,
    );

    if (total == 0) return;

    final incomeAngle = (income / total) * 2 * pi * animValue;
    final expenseAngle = (expense / total) * 2 * pi * animValue;
    final startAngle = -pi / 2;

    void drawArc(double start, double sweep, Color color) {
      if (sweep <= 0) return;
      // Soft outer ring — no blur, just opacity trick for glow-like look
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        start, sweep, false,
        Paint()
          ..color = color.withOpacity(0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW + 10
          ..strokeCap = StrokeCap.round,
      );
      // Core
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: radius),
        start, sweep, false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeW
          ..strokeCap = StrokeCap.round,
      );
    }

    drawArc(startAngle, incomeAngle, AppColors.income);
    drawArc(startAngle + incomeAngle + 0.02, expenseAngle, AppColors.expense);
  }

  @override
  bool shouldRepaint(DonutChartPainter old) => old.animValue != animValue || old.isDark != isDark;
}

class DonutChart extends StatefulWidget {
  final double income;
  final double expense;
  final bool isDark;

  const DonutChart({super.key, required this.income, required this.expense, required this.isDark});

  @override
  State<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends State<DonutChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(DonutChart old) {
    super.didUpdateWidget(old);
    if (old.income != widget.income || old.expense != widget.expense) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.income + widget.expense;
    final incPct = total > 0 ? (widget.income / total * 100).toStringAsFixed(0) : '0';
    final expPct = total > 0 ? (widget.expense / total * 100).toStringAsFixed(0) : '0';

    return Column(
      children: [
        SizedBox(
          width: 200,
          height: 200,
          child: AnimatedBuilder(
            animation: _anim,
            builder: (_, __) => CustomPaint(
              painter: DonutChartPainter(
                income: widget.income,
                expense: widget.expense,
                animValue: _anim.value,
                isDark: widget.isDark,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Total', style: TextStyle(color: AppColors.textSecondaryOf(widget.isDark), fontSize: 11)),
                    const SizedBox(height: 2),
                    Text(
                      _fmt(total),
                      style: TextStyle(
                        color: AppColors.textPrimaryOf(widget.isDark),
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legend(AppColors.income, 'Pemasukan', '$incPct%', _fmt(widget.income)),
            const SizedBox(width: 24),
            _legend(AppColors.expense, 'Pengeluaran', '$expPct%', _fmt(widget.expense)),
          ],
        ),
      ],
    );
  }

  Widget _legend(Color color, String label, String pct, String amount) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(
          shape: BoxShape.circle, color: color,
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)],
        )),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: AppColors.textSecondaryOf(widget.isDark), fontSize: 10)),
            Text('$pct  $amount', style: TextStyle(
              color: color, fontSize: 11, fontWeight: FontWeight.w700,
            )),
          ],
        ),
      ],
    );
  }
}

// ─── Bar Chart ───────────────────────────────────────────────────────────────

class BarChartPainter extends CustomPainter {
  final List<_BarData> bars;
  final double animValue;
  final bool isDark;
  final double maxVal;

  BarChartPainter({
    required this.bars,
    required this.animValue,
    required this.isDark,
    required this.maxVal,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;
    final barW = (size.width / bars.length) * 0.35;
    final gap = (size.width / bars.length) * 0.15;
    final maxH = size.height - 32;
    final textStyle = TextStyle(color: AppColors.textSecondaryOf(isDark), fontSize: 9);

    for (int i = 0; i < bars.length; i++) {
      final b = bars[i];
      final slotX = (size.width / bars.length) * i;
      final centerX = slotX + (size.width / bars.length) / 2;

      // Income bar
      final incH = maxVal > 0 ? (b.income / maxVal) * maxH * animValue : 0.0;
      final incX = centerX - barW - gap / 2;
      _drawBar(canvas, incX, size.height - 24, barW, incH, AppColors.income);

      // Expense bar
      final expH = maxVal > 0 ? (b.expense / maxVal) * maxH * animValue : 0.0;
      final expX = centerX + gap / 2;
      _drawBar(canvas, expX, size.height - 24, barW, expH, AppColors.expense);

      // Label
      final tp = TextPainter(
        text: TextSpan(text: b.label, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(centerX - tp.width / 2, size.height - 18));
    }
  }

  void _drawBar(Canvas canvas, double x, double bottom, double w, double h, Color color) {
    if (h <= 0) return;
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, bottom - h, w, h),
      const Radius.circular(6),
    );
    // Soft outer glow — no maskFilter, use slightly wider rect with low opacity
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(x - 2, bottom - h - 2, w + 4, h + 4), const Radius.circular(8)),
      Paint()..color = color.withOpacity(0.15),
    );
    // Bar with gradient
    canvas.drawRRect(rect, Paint()
      ..shader = LinearGradient(
        colors: [color, color.withOpacity(0.55)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(x, bottom - h, w, h)));
  }

  @override
  bool shouldRepaint(BarChartPainter old) => old.animValue != animValue || old.bars != bars;
}

class _BarData {
  final String label;
  final double income;
  final double expense;
  _BarData(this.label, this.income, this.expense);
}

class WeeklyBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final bool isDark;

  const WeeklyBarChart({super.key, required this.data, required this.isDark});

  @override
  State<WeeklyBarChart> createState() => _WeeklyBarChartState();
}

class _WeeklyBarChartState extends State<WeeklyBarChart> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.data.map((d) => _BarData(
      d['label'] as String,
      (d['income'] as double),
      (d['expense'] as double),
    )).toList();

    final maxVal = bars.isEmpty ? 1.0 : bars.fold(0.0, (m, b) => max(m, max(b.income, b.expense)));

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => CustomPaint(
        size: const Size(double.infinity, 160),
        painter: BarChartPainter(
          bars: bars,
          animValue: _anim.value,
          isDark: widget.isDark,
          maxVal: maxVal == 0 ? 1 : maxVal,
        ),
      ),
    );
  }
}

// ─── Category Breakdown ──────────────────────────────────────────────────────

class CategoryBreakdown extends StatelessWidget {
  final Map<String, double> categories;
  final double total;
  final bool isDark;

  const CategoryBreakdown({
    super.key,
    required this.categories,
    required this.total,
    required this.isDark,
  });

  static const List<Color> _palette = [
    AppColors.neonBlue,
    AppColors.neonPink,
    AppColors.neonGreen,
    AppColors.neonYellow,
    Color(0xFFAA66FF),
    Color(0xFFFF8C42),
  ];

  @override
  Widget build(BuildContext context) {
    final sorted = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sorted.asMap().entries.map((entry) {
        final i = entry.key;
        final e = entry.value;
        final pct = total > 0 ? e.value / total : 0.0;
        final color = _palette[i % _palette.length];

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _CategoryRow(
            label: e.key,
            amount: e.value,
            pct: pct,
            color: color,
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }
}

class _CategoryRow extends StatefulWidget {
  final String label;
  final double amount;
  final double pct;
  final Color color;
  final bool isDark;

  const _CategoryRow({
    required this.label,
    required this.amount,
    required this.pct,
    required this.color,
    required this.isDark,
  });

  @override
  State<_CategoryRow> createState() => _CategoryRowState();
}

class _CategoryRowState extends State<_CategoryRow> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle, color: widget.color,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(widget.label,
                style: TextStyle(color: AppColors.textPrimaryOf(widget.isDark), fontSize: 12, fontWeight: FontWeight.w500)),
            ),
            Text(
              '${(widget.pct * 100).toStringAsFixed(0)}%  ${_fmt(widget.amount)}',
              style: TextStyle(color: widget.color, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: _anim,
          builder: (_, __) => ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Stack(
              children: [
                Container(height: 5, color: AppColors.cardBorderOf(widget.isDark)),
                FractionallySizedBox(
                  widthFactor: widget.pct * _anim.value,
                  child: Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: widget.color,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}