// lib/widgets/balance_card.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../utils/theme_notifier.dart';

class CircleOrbitPainter extends CustomPainter {
  final double animValue;
  final bool isDark;

  CircleOrbitPainter(this.animValue, {this.isDark = true});

  // Light mode uses warm accent colors
  Color get _primaryOrbit => isDark ? AppColors.neonBlue : const Color(0xFF0077CC);
  Color get _secondaryOrbit => isDark ? AppColors.neonGreen : const Color(0xFF00AA66);

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width * 0.85;
    final cy = size.height * 0.5;

    _drawGlowRing(canvas, cx, cy, 60, _primaryOrbit.withOpacity(isDark ? 0.18 : 0.22), 2);
    _drawGlowRing(canvas, cx, cy, 90, _secondaryOrbit.withOpacity(isDark ? 0.10 : 0.14), 1.5);

    for (int i = 0; i < 5; i++) {
      final angle = (animValue * 2 * pi) + (i * 2 * pi / 5);
      final dx = cx + 65 * cos(angle);
      final dy = cy + 65 * sin(angle);
      _drawGlowDot(canvas, dx, dy, 3, _primaryOrbit.withOpacity(isDark ? 0.7 : 0.85));
    }

    for (int i = 0; i < 3; i++) {
      final angle = -(animValue * 1.5 * 2 * pi) + (i * 2 * pi / 3);
      final dx = cx + 90 * cos(angle);
      final dy = cy + 90 * sin(angle);
      _drawGlowDot(canvas, dx, dy, 2.5, _secondaryOrbit.withOpacity(isDark ? 0.6 : 0.75));
    }

    _drawGlowDot(canvas, cx, cy, 6, _primaryOrbit.withOpacity(isDark ? 0.5 : 0.6));
  }

  void _drawGlowRing(Canvas canvas, double cx, double cy, double r, Color color, double width) {
    canvas.drawCircle(
      Offset(cx, cy), r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );
  }

  void _drawGlowDot(Canvas canvas, double x, double y, double r, Color color) {
    canvas.drawCircle(Offset(x, y), r, Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 1.5));
    canvas.drawCircle(Offset(x, y), r * 0.6, Paint()..color = color);
  }

  @override
  bool shouldRepaint(CircleOrbitPainter old) =>
      old.animValue != animValue || old.isDark != isDark;
}

class _GridPainter extends CustomPainter {
  final bool isDark;
  _GridPainter({this.isDark = true});

  @override
  void paint(Canvas canvas, Size size) {
    final color = isDark
        ? AppColors.neonBlue.withOpacity(0.04)
        : const Color(0xFF0077CC).withOpacity(0.06);
    final paint = Paint()..color = color..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_GridPainter old) => old.isDark != isDark;
}

class BalanceCard extends StatefulWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> with SingleTickerProviderStateMixin {
  late AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();
    _orbitCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
  }

  @override
  void dispose() {
    _orbitCtrl.dispose();
    super.dispose();
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  String _fmtFull(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $s';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<ThemeNotifier>().isDark;

    // Light mode: clean white-blue gradient
    final cardGradient = isDark
        ? const LinearGradient(
            colors: [Color(0xFF0D1B35), Color(0xFF091226), Color(0xFF0A1A2E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [Color(0xFFE8F4FF), Color(0xFFD0EAFF), Color(0xFFBFDFFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final borderColor = isDark
        ? AppColors.neonBlue.withOpacity(0.3)
        : const Color(0xFF0077CC).withOpacity(0.35);

    final shadowColor1 = isDark
        ? AppColors.neonBlue.withOpacity(0.15)
        : const Color(0xFF0077CC).withOpacity(0.18);

    final shadowColor2 = isDark
        ? AppColors.neonGreen.withOpacity(0.08)
        : const Color(0xFF00AA66).withOpacity(0.10);

    final textColor = isDark ? AppColors.textPrimary : const Color(0xFF0A1F3C);
    final accentBlue = isDark ? AppColors.neonBlue : const Color(0xFF0077CC);

    return AnimatedBuilder(
      animation: _orbitCtrl,
      builder: (_, __) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 20),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: cardGradient,
            boxShadow: [
              BoxShadow(color: shadowColor1, blurRadius: 40, offset: const Offset(0, 12)),
              BoxShadow(color: shadowColor2, blurRadius: 60, offset: const Offset(0, 20)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: CircleOrbitPainter(_orbitCtrl.value, isDark: isDark),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(painter: _GridPainter(isDark: isDark)),
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: borderColor, width: 1),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accentBlue.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: accentBlue.withOpacity(0.35)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.account_balance_wallet_rounded, color: accentBlue, size: 12),
                                const SizedBox(width: 5),
                                Text('Total Saldo', style: TextStyle(
                                  color: accentBlue, fontSize: 11, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _fmtFull(widget.balance),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                        ),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          _statChip(Icons.arrow_downward_rounded, 'Masuk', widget.income, AppColors.income),
                          const SizedBox(width: 16),
                          _statChip(Icons.arrow_upward_rounded, 'Keluar', widget.expense, AppColors.expense),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _statChip(IconData icon, String label, double value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 12),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                  color: color.withOpacity(0.85), fontSize: 10, fontWeight: FontWeight.w500)),
              Text(_fmt(value), style: TextStyle(
                  color: color, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}