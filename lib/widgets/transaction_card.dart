// lib/widgets/transaction_card.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/category_store.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import 'glass_card.dart';

class TransactionCard extends StatefulWidget {
  final Transaction transaction;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool isDark;

  const TransactionCard({
    super.key,
    required this.transaction,
    required this.onEdit,
    required this.onDelete,
    this.isDark = true,
  });

  @override
  State<TransactionCard> createState() => _TransactionCardState();
}

class _TransactionCardState extends State<TransactionCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _opacity;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 350));
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  String _fmtAmount(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000) return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = widget.transaction.type == TransactionType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final catStore = context.watch<CategoryStore>();
    final cat = catStore.findByName(widget.transaction.category, isIncome);
    final icon = cat?.icon ?? Icons.circle_rounded;
    final d = widget.isDark;

    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: GlassCard(
          borderColor: color.withOpacity(0.4),
          glowIntensity: 4,
          padding: const EdgeInsets.all(16),
          isDark: d,
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.3)),
                  boxShadow: d ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)] : null,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.transaction.name, style: TextStyle(
                      color: AppColors.textPrimaryOf(d), fontSize: 14, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 3),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(widget.transaction.category,
                          style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
                      ),
                      const SizedBox(width: 6),
                      Text(DateFormat('dd MMM yyyy').format(widget.transaction.date),
                        style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 11)),
                    ]),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${isIncome ? '+' : '-'}${_fmtAmount(widget.transaction.amount)}',
                    style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 6),
                  Row(children: [
                    _iconBtn(Icons.edit_rounded, AppColors.neonBlue, widget.onEdit),
                    const SizedBox(width: 4),
                    _iconBtn(Icons.delete_rounded, AppColors.neonPink, widget.onDelete),
                  ]),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 13),
      ),
    );
  }
}