// lib/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../utils/theme.dart';

class NeonBorderPainter extends CustomPainter {
  final Color color;
  final double borderRadius;
  final double glowIntensity;
  final double strokeWidth;

  NeonBorderPainter({
    required this.color,
    this.borderRadius = 20,
    this.glowIntensity = 8,
    this.strokeWidth = 1.2,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(strokeWidth / 2, strokeWidth / 2, size.width - strokeWidth, size.height - strokeWidth),
      Radius.circular(borderRadius),
    );
    for (int i = 4; i >= 1; i--) {
      canvas.drawRRect(rect, Paint()
        ..color = color.withOpacity(0.05 * i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + (i * glowIntensity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowIntensity * i * 0.5));
    }
    canvas.drawRRect(rect, Paint()
      ..color = color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth);
  }

  @override
  bool shouldRepaint(NeonBorderPainter old) => old.color != color;
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final double glowIntensity;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool isDark;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor = AppColors.neonBlue,
    this.borderRadius = 20,
    this.padding = const EdgeInsets.all(20),
    this.glowIntensity = 6,
    this.gradient,
    this.onTap,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: CustomPaint(
        painter: NeonBorderPainter(
          color: borderColor,
          borderRadius: borderRadius,
          glowIntensity: isDark ? glowIntensity : glowIntensity * 0.3,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(borderRadius),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                gradient: gradient ?? LinearGradient(
                  colors: isDark
                    ? [AppColors.card.withOpacity(0.85), AppColors.surface.withOpacity(0.9)]
                    : [AppColors.cardLight.withOpacity(0.95), AppColors.surfaceLight.withOpacity(0.98)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

class GlowDot extends StatelessWidget {
  final Color color;
  final double size;
  const GlowDot({super.key, required this.color, this.size = 8});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle, color: color,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.8), blurRadius: 8, spreadRadius: 2),
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 4),
        ],
      ),
    );
  }
}

class NeonButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;
  final bool isOutlined;
  final double? width;

  const NeonButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color = AppColors.neonGreen,
    this.icon,
    this.isOutlined = false,
    this.width,
  });

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween(begin: 1.0, end: 0.95).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: widget.width,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: widget.isOutlined ? null : LinearGradient(
              colors: [widget.color, widget.color.withBlue((widget.color.blue + 40).clamp(0, 255))],
              begin: Alignment.topLeft, end: Alignment.bottomRight,
            ),
            border: widget.isOutlined ? Border.all(color: widget.color, width: 1.5) : null,
            color: widget.isOutlined ? widget.color.withOpacity(0.08) : null,
            boxShadow: widget.isOutlined ? null : [
              BoxShadow(color: widget.color.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 4)),
              BoxShadow(color: widget.color.withOpacity(0.2), blurRadius: 40, offset: const Offset(0, 8)),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: widget.isOutlined ? widget.color : AppColors.bg, size: 18),
                const SizedBox(width: 8),
              ],
              Text(widget.label, style: TextStyle(
                color: widget.isOutlined ? widget.color : AppColors.bg,
                fontWeight: FontWeight.w700, fontSize: 15, letterSpacing: 0.5,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class TransactionTypeToggle extends StatelessWidget {
  final bool isIncome;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  const TransactionTypeToggle({
    super.key,
    required this.isIncome,
    required this.onChanged,
    this.isDark = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorderOf(isDark)),
      ),
      child: Row(children: [
        Expanded(child: _tab('Pemasukan', true, AppColors.neonGreen)),
        Expanded(child: _tab('Pengeluaran', false, AppColors.neonPink)),
      ]),
    );
  }

  Widget _tab(String label, bool value, Color color) {
    final active = isIncome == value;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active ? color.withOpacity(0.15) : Colors.transparent,
          border: active ? Border.all(color: color.withOpacity(0.5), width: 1) : null,
          boxShadow: active ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)] : null,
        ),
        child: Text(label, textAlign: TextAlign.center, style: TextStyle(
          color: active ? color : AppColors.textSecondaryOf(isDark),
          fontWeight: active ? FontWeight.w700 : FontWeight.w500, fontSize: 13,
        )),
      ),
    );
  }
}

class NeonTextField extends StatefulWidget {
  final String hint;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final String? Function(String?)? validator;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool isDark;

  const NeonTextField({
    super.key,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
    this.isDark = true,
  });

  @override
  State<NeonTextField> createState() => _NeonTextFieldState();
}

class _NeonTextFieldState extends State<NeonTextField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() { _focus.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused ? AppColors.neonBlue : AppColors.cardBorderOf(widget.isDark);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
        color: AppColors.surfaceOf(widget.isDark),
        boxShadow: _focused ? [BoxShadow(color: AppColors.neonBlue.withOpacity(0.15), blurRadius: 20)] : null,
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focus,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        validator: widget.validator,
        style: TextStyle(color: AppColors.textPrimaryOf(widget.isDark), fontSize: 15),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: AppColors.textSecondaryOf(widget.isDark), fontSize: 14),
          prefixIcon: Icon(widget.prefixIcon,
            color: _focused ? AppColors.neonBlue : AppColors.textSecondaryOf(widget.isDark), size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        ),
      ),
    );
  }
}
