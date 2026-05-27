// lib/widgets/theme_toggle_button.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/theme.dart';

/// Custom painter — draws a sun with animated rays
class _SunPainter extends CustomPainter {
  final double progress; // 0 = hidden, 1 = fully shown
  final Color color;

  _SunPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.22 * progress;
    final rayLen = size.width * 0.14 * progress;
    final rayStart = size.width * 0.28;

    final paint = Paint()
      ..color = color.withOpacity(progress)
      ..strokeWidth = 1.8 * progress
      ..strokeCap = StrokeCap.round;

    // Core circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = color.withOpacity(progress)
      ..style = PaintingStyle.fill);

    // 8 rays rotating in
    for (int i = 0; i < 8; i++) {
      final angle = (i * pi / 4) + (1 - progress) * pi * 0.25;
      final x1 = cx + rayStart * cos(angle);
      final y1 = cy + rayStart * sin(angle);
      final x2 = cx + (rayStart + rayLen) * cos(angle);
      final y2 = cy + (rayStart + rayLen) * sin(angle);
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(_SunPainter old) => old.progress != progress;
}

/// Custom painter — draws a crescent moon
class _MoonPainter extends CustomPainter {
  final double progress; // 0 = hidden, 1 = fully shown
  final Color color;

  _MoonPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.28 * progress;

    final path = Path();

    // Full circle
    path.addOval(Rect.fromCircle(center: Offset(cx, cy), radius: r));

    // Cut out crescent
    final cutX = cx + r * 0.35;
    final cutR = r * 0.82;
    path.addOval(Rect.fromCircle(center: Offset(cutX, cy - r * 0.05), radius: cutR));

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withOpacity(progress)
        ..style = PaintingStyle.fill
        ..blendMode = BlendMode.srcOver,
    );

    // Crescent cutout
    canvas.drawOval(
      Rect.fromCircle(center: Offset(cutX, cy - r * 0.05), radius: cutR),
      Paint()
        ..color = Colors.transparent
        ..blendMode = BlendMode.clear,
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.progress != progress;
}

class ThemeToggleButton extends StatefulWidget {
  final bool isDark;
  final VoidCallback onToggle;

  const ThemeToggleButton({
    super.key,
    required this.isDark,
    required this.onToggle,
  });

  @override
  State<ThemeToggleButton> createState() => _ThemeToggleButtonState();
}

class _ThemeToggleButtonState extends State<ThemeToggleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  // 0.0 = dark (moon shown), 1.0 = light (sun shown)
  late Animation<double> _rotation;
  late Animation<double> _sunProgress;
  late Animation<double> _moonProgress;
  late Animation<double> _bgScale;
  late Animation<Color?> _bgColor;
  late Animation<Color?> _borderColor;
  late Animation<Color?> _glowColor;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
      value: widget.isDark ? 0.0 : 1.0,
    );
    _buildAnimations();
  }

  void _buildAnimations() {
    _rotation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOutCubic),
    );

    // Sun appears in second half, moon disappears in first half
    _moonProgress = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.0, 0.5, curve: Curves.easeIn)),
    );
    _sunProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0.5, 1.0, curve: Curves.easeOut)),
    );

    _bgScale = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.05), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _bgColor = ColorTween(
      begin: AppColors.card,
      end: const Color(0xFFFFF8E7),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _borderColor = ColorTween(
      begin: AppColors.cardBorder,
      end: const Color(0xFFFFCC44).withOpacity(0.6),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));

    _glowColor = ColorTween(
      begin: AppColors.neonBlue.withOpacity(0.0),
      end: AppColors.neonYellow.withOpacity(0.4),
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(ThemeToggleButton old) {
    super.didUpdateWidget(old);
    if (old.isDark != widget.isDark) {
      if (widget.isDark) {
        _ctrl.reverse();
      } else {
        _ctrl.forward();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.selectionClick();
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final moonCol = AppColors.neonBlue;
          final sunCol = AppColors.neonYellow;

          return ScaleTransition(
            scale: _bgScale,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _bgColor.value,
                border: Border.all(color: _borderColor.value ?? AppColors.cardBorder, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: _glowColor.value ?? Colors.transparent,
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                  if (!widget.isDark)
                    BoxShadow(
                      color: AppColors.neonYellow.withOpacity(0.15 * _ctrl.value),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: ClipOval(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Rotating container for both icons
                    Transform.rotate(
                      angle: _rotation.value * pi,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Moon (shown when dark, hides when going light)
                          Opacity(
                            opacity: _moonProgress.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.8 + 0.2 * _moonProgress.value,
                              child: CustomPaint(
                                size: const Size(42, 42),
                                painter: _MoonIconPainter(
                                  progress: _moonProgress.value,
                                  color: moonCol,
                                ),
                              ),
                            ),
                          ),

                          // Sun (hidden when dark, shows when going light)
                          Opacity(
                            opacity: _sunProgress.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: 0.8 + 0.2 * _sunProgress.value,
                              child: CustomPaint(
                                size: const Size(42, 42),
                                painter: _SunIconPainter(
                                  progress: _sunProgress.value,
                                  color: sunCol,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Ripple flash on transition midpoint
                    if (_ctrl.value > 0.45 && _ctrl.value < 0.55)
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(
                            (0.3 - ((_ctrl.value - 0.5).abs() * 6)).clamp(0.0, 0.3),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Clean sun painter for the button
class _SunIconPainter extends CustomPainter {
  final double progress;
  final Color color;
  _SunIconPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;
    final cx = size.width / 2;
    final cy = size.height / 2;
    final coreR = size.width * 0.18 * progress;
    final rayInner = size.width * 0.24;
    final rayOuter = size.width * 0.34 * progress;

    final corePaint = Paint()
      ..color = color.withOpacity(progress)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(cx, cy), coreR, corePaint);

    final rayPaint = Paint()
      ..color = color.withOpacity(progress * 0.9)
      ..strokeWidth = 2.0 * progress
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 8; i++) {
      final angle = i * pi / 4;
      canvas.drawLine(
        Offset(cx + rayInner * cos(angle), cy + rayInner * sin(angle)),
        Offset(cx + rayOuter * cos(angle), cy + rayOuter * sin(angle)),
        rayPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SunIconPainter old) => old.progress != progress;
}

/// Clean moon painter for the button
class _MoonIconPainter extends CustomPainter {
  final double progress;
  final Color color;
  _MoonIconPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01) return;
    final cx = size.width / 2 - 1;
    final cy = size.height / 2;
    final r = size.width * 0.22 * progress;

    // Use saveLayer for proper blendMode cutout
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // Draw full circle
    canvas.drawCircle(Offset(cx, cy), r, Paint()
      ..color = color.withOpacity(progress));

    // Cut crescent
    canvas.drawCircle(
      Offset(cx + r * 0.45, cy - r * 0.05),
      r * 0.78,
      Paint()
        ..color = Colors.white
        ..blendMode = BlendMode.clear,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(_MoonIconPainter old) => old.progress != progress;
}