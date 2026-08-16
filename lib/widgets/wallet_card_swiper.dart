// lib/widgets/wallet_card_swiper.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/wallet.dart';
import '../utils/theme.dart';

class WalletCardSwiper extends StatefulWidget {
  final List<Wallet> wallets;
  final Map<String, double> balances;   // walletId -> balance
  final Map<String, double> incomes;
  final Map<String, double> expenses;
  final int selectedIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onAddWallet;

  const WalletCardSwiper({
    super.key,
    required this.wallets,
    required this.balances,
    required this.incomes,
    required this.expenses,
    required this.selectedIndex,
    required this.onPageChanged,
    required this.onAddWallet,
  });

  @override
  State<WalletCardSwiper> createState() => _WalletCardSwiperState();
}

class _WalletCardSwiperState extends State<WalletCardSwiper>
    with SingleTickerProviderStateMixin {
  late PageController _pageCtrl;
  late AnimationController _orbitCtrl;

  @override
  void initState() {
    super.initState();
    _pageCtrl = PageController(
      initialPage: widget.selectedIndex,
      viewportFraction: 0.88,
    );
    _orbitCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 8))
          ..repeat();
  }

  @override
  void didUpdateWidget(WalletCardSwiper old) {
    super.didUpdateWidget(old);
    if (old.selectedIndex != widget.selectedIndex &&
        _pageCtrl.hasClients) {
      _pageCtrl.animateToPage(
        widget.selectedIndex,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // +1 for the "Add Wallet" card
    final itemCount = widget.wallets.length + 1;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageCtrl,
            itemCount: itemCount,
            onPageChanged: (i) {
              HapticFeedback.selectionClick();
              widget.onPageChanged(i);
            },
            itemBuilder: (_, i) {
              if (i == widget.wallets.length) {
                return _AddWalletCard(
                  onTap: widget.onAddWallet,
                );
              }
              final wallet = widget.wallets[i];
              final balance = widget.balances[wallet.id] ?? 0;
              final income  = widget.incomes[wallet.id]  ?? 0;
              final expense = widget.expenses[wallet.id] ?? 0;
              return AnimatedBuilder(
                animation: _orbitCtrl,
                builder: (_, __) => _WalletCard(
                  wallet: wallet,
                  balance: balance,
                  income: income,
                  expense: expense,
                  orbitValue: _orbitCtrl.value,
                  isSelected: i == widget.selectedIndex,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dot indicators
        _DotIndicator(
          count: itemCount,
          current: widget.selectedIndex,
          wallets: widget.wallets,
        ),
      ],
    );
  }
}

// ── Single wallet card ────────────────────────────────────────────────────────
class _WalletCard extends StatelessWidget {
  final Wallet wallet;
  final double balance;
  final double income;
  final double expense;
  final double orbitValue;
  final bool isSelected;

  const _WalletCard({
    required this.wallet,
    required this.balance,
    required this.income,
    required this.expense,
    required this.orbitValue,
    required this.isSelected,
  });

  String _fmt(double v) {
    if (v >= 1000000) return 'Rp ${(v / 1000000).toStringAsFixed(1)}Jt';
    if (v >= 1000)    return 'Rp ${(v / 1000).toStringAsFixed(0)}K';
    return 'Rp ${v.toStringAsFixed(0)}';
  }

  String _fmtFull(double v) {
    final s = v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    return 'Rp $s';
  }

  @override
  Widget build(BuildContext context) {
    final color = wallet.color;
    final darkColor = Color.lerp(color, Colors.black, 0.4)!;
    final lightColor = Color.lerp(color, Colors.white, 0.2)!;

    return AnimatedScale(
      scale: isSelected ? 1.0 : 0.95,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              colors: [darkColor, color.withOpacity(0.85)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                  color: color.withOpacity(isSelected ? 0.35 : 0.15),
                  blurRadius: isSelected ? 30 : 12,
                  offset: const Offset(0, 10)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Stack(
              children: [
                // Grid lines
                Positioned.fill(child: CustomPaint(
                  painter: _CardGridPainter(color: Colors.white.withOpacity(0.06)),
                )),
                // Orbit
                Positioned(
                  right: -30, top: -10,
                  child: CustomPaint(
                    size: const Size(160, 160),
                    painter: _OrbitPainter(
                      animValue: orbitValue,
                      color: Colors.white,
                    ),
                  ),
                ),
                // Border
                Positioned.fill(child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.15), width: 1),
                  ),
                )),
                // Content
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.25)),
                            ),
                            child: Row(children: [
                              Icon(wallet.icon,
                                  color: Colors.white, size: 12),
                              const SizedBox(width: 5),
                              Text(wallet.name,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600)),
                            ]),
                          ),
                          const Spacer(),
                          Icon(
                            _walletTypeIcon(wallet.type),
                            color: Colors.white.withOpacity(0.5),
                            size: 16,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Balance
                      Text(_fmtFull(balance),
                          style: GoogleFonts.spaceGrotesk(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                          )),
                      const Spacer(),
                      // Income / expense chips
                      Row(children: [
                        _chip(Icons.arrow_downward_rounded, 'Masuk',
                            _fmt(income), lightColor),
                        const SizedBox(width: 12),
                        _chip(Icons.arrow_upward_rounded, 'Keluar',
                            _fmt(expense), lightColor),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String label, String val, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 10),
        ),
        const SizedBox(width: 6),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 9,
                  fontWeight: FontWeight.w500)),
          Text(val,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700)),
        ]),
      ]),
    );
  }

  IconData _walletTypeIcon(WalletType t) {
    switch (t) {
      case WalletType.cash:       return Icons.payments_rounded;
      case WalletType.bank:       return Icons.account_balance_rounded;
      case WalletType.ewallet:    return Icons.phone_android_rounded;
      case WalletType.investment: return Icons.trending_up_rounded;
      case WalletType.other:      return Icons.more_horiz_rounded;
    }
  }
}

// ── Add wallet card ───────────────────────────────────────────────────────────
class _AddWalletCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AddWalletCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: AppColors.card,
            border: Border.all(
              color: AppColors.neonBlue.withOpacity(0.3),
              width: 1.5,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 52, height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.neonBlue.withOpacity(0.1),
                  border: Border.all(
                      color: AppColors.neonBlue.withOpacity(0.3)),
                ),
                child: const Icon(Icons.add_rounded,
                    color: AppColors.neonBlue, size: 26),
              ),
              const SizedBox(height: 10),
              const Text('Tambah Dompet',
                  style: TextStyle(
                      color: AppColors.neonBlue,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Dot indicator ─────────────────────────────────────────────────────────────
class _DotIndicator extends StatelessWidget {
  final int count;
  final int current;
  final List<Wallet> wallets;

  const _DotIndicator({
    required this.count,
    required this.current,
    required this.wallets,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        final color = i < wallets.length
            ? wallets[i].color
            : AppColors.neonBlue;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 20 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: active ? color : color.withOpacity(0.3),
            boxShadow: active
                ? [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)]
                : null,
          ),
        );
      }),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────────────────────
class _CardGridPainter extends CustomPainter {
  final Color color;
  _CardGridPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..strokeWidth = 0.5;
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_CardGridPainter old) => false;
}

class _OrbitPainter extends CustomPainter {
  final double animValue;
  final Color color;
  _OrbitPainter({required this.animValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Rings
    for (final r in [40.0, 65.0]) {
      canvas.drawCircle(Offset(cx, cy), r, Paint()
        ..color = color.withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1);
    }

    // Dots on ring 1
    for (int i = 0; i < 5; i++) {
      final angle = animValue * 2 * pi + i * 2 * pi / 5;
      final dx = cx + 40 * cos(angle);
      final dy = cy + 40 * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2.5,
          Paint()..color = color.withOpacity(0.6));
    }

    // Dots on ring 2
    for (int i = 0; i < 3; i++) {
      final angle = -animValue * 1.5 * 2 * pi + i * 2 * pi / 3;
      final dx = cx + 65 * cos(angle);
      final dy = cy + 65 * sin(angle);
      canvas.drawCircle(Offset(dx, dy), 2,
          Paint()..color = color.withOpacity(0.4));
    }
  }

  @override
  bool shouldRepaint(_OrbitPainter old) => old.animValue != animValue;
}