// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../utils/theme.dart';
import '../utils/theme_notifier.dart';
import '../utils/transaction_store.dart';
import '../widgets/balance_card.dart';
import '../widgets/glass_card.dart';
import '../widgets/transaction_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'transaction_form.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';

// ─── Filter enum ─────────────────────────────────────────────────────────────
enum TxFilter { all, income, expense }

// ─── Grouped data model ───────────────────────────────────────────────────────
class _TxGroup {
  final String label;      // "Hari ini", "Kemarin", "12 Mei 2025"
  final List<Transaction> items;
  _TxGroup(this.label, this.items);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _headerCtrl;
  late AnimationController _pageCtrl;
  late Animation<double> _headerFade;
  late Animation<double> _pageFade;

  int _navIndex = 0;
  // Search + filter state
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  TxFilter _filter = TxFilter.all;
  bool _searchOpen = false;

  @override
  void initState() {
    super.initState();
    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _pageCtrl   = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOut);
    _pageFade   = CurvedAnimation(parent: _pageCtrl,   curve: Curves.easeOut);
    _headerCtrl.forward();
    _pageCtrl.forward();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _pageCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────

  List<Transaction> _applyFilters(List<Transaction> all) {
    var list = all;
    if (_filter == TxFilter.income)  list = list.where((t) => t.type == TransactionType.income).toList();
    if (_filter == TxFilter.expense) list = list.where((t) => t.type == TransactionType.expense).toList();
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((t) =>
        t.name.toLowerCase().contains(q) ||
        t.category.toLowerCase().contains(q),
      ).toList();
    }
    return list;
  }

  List<_TxGroup> _groupByDate(List<Transaction> txs) {
    if (txs.isEmpty) return [];
    final map = <String, List<Transaction>>{};
    final now = DateTime.now();
    final today    = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    for (final t in txs) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      String label;
      if (d == today)     label = 'Hari ini';
      else if (d == yesterday) label = 'Kemarin';
      else if (d.year == now.year) label = DateFormat('d MMMM', 'id').format(t.date);
      else label = DateFormat('d MMMM yyyy', 'id').format(t.date);
      (map[label] ??= []).add(t);
    }
    return map.entries.map((e) => _TxGroup(e.key, e.value)).toList();
  }

  void _switchTab(int index) {
    if (_navIndex == index) return;
    HapticFeedback.selectionClick();
    _pageCtrl.reverse().then((_) {
      setState(() => _navIndex = index);
      _pageCtrl.forward();
    });
  }

  Future<void> _openForm(BuildContext ctx, {Transaction? editing, required bool isDark}) async {
    HapticFeedback.mediumImpact();
    final store = ctx.read<TransactionStore>();
    final result = await showModalBottomSheet<Map>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => TransactionForm(editing: editing, isDark: isDark),
    );
    if (result != null) {
      HapticFeedback.lightImpact();
      editing != null
        ? await store.update(editing.id, result['name'], result['type'], result['amount'], result['date'], result['category'])
        : await store.add(result['name'], result['type'], result['amount'], result['date'], result['category']);
    }
  }

  Future<void> _confirmDelete(BuildContext ctx, Transaction t, bool isDark) async {
    HapticFeedback.mediumImpact();
    final store = ctx.read<TransactionStore>();
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (_) => _DeleteDialog(transaction: t, isDark: isDark),
    );
    if (ok == true) {
      HapticFeedback.heavyImpact();
      await store.delete(t.id);
    }
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final d = context.watch<ThemeNotifier>().isDark;
    return Scaffold(
      backgroundColor: AppColors.bgOf(d),
      body: Stack(
        children: [
          if (d) ...[
            Positioned(top: -80,  right: -60, child: _blob(200, AppColors.neonBlue.withOpacity(0.06))),
            Positioned(top: 220,  left:  -80, child: _blob(180, AppColors.neonGreen.withOpacity(0.04))),
            Positioned(bottom: 120, right: -40, child: _blob(160, AppColors.neonPink.withOpacity(0.04))),
          ] else ...[
            Positioned(top: -80,  right: -60, child: _blob(200, AppColors.neonBlue.withOpacity(0.08))),
            Positioned(bottom: 120, left: -40, child: _blob(160, AppColors.neonGreen.withOpacity(0.06))),
          ],

          SafeArea(
            child: FadeTransition(
              opacity: _headerFade,
              child: Consumer<TransactionStore>(
                builder: (ctx, store, _) => GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final v = details.primaryVelocity ?? 0;
                    if (v < -300 && _navIndex < 2) _switchTab(_navIndex + 1);
                    if (v >  300 && _navIndex > 0) _switchTab(_navIndex - 1);
                  },
                  child: FadeTransition(
                    opacity: _pageFade,
                    child: _buildPage(store, d),
                  ),
                ),
              ),
            ),
          ),

          if (_navIndex == 0)
            Positioned(
              right: 20, bottom: 20,
              child: Consumer<ThemeNotifier>(
                builder: (_, tn, __) => _CustomFAB(
                  onTap: () => _openForm(context, isDark: tn.isDark),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(d),
    );
  }

  Widget _buildPage(TransactionStore store, bool d) {
    switch (_navIndex) {
      case 1: return StatsScreen(transactions: store.transactions.toList(), isDark: d);
      case 2: return SettingsScreen(isDark: d);
      default: return _buildHome(store, d);
    }
  }

  // ── HOME TAB ──────────────────────────────────────────────────────────────

  Widget _buildHome(TransactionStore store, bool d) {
    final filtered = _applyFilters(store.transactions.toList());
    final groups   = _groupByDate(filtered);

    // Build flat sliver items: [groupHeader, card, card, groupHeader, card, ...]
    // We'll use a single SliverList with a pre-built item list for simplicity
    final List<Widget> listItems = [];
    for (final group in groups) {
      listItems.add(_GroupHeader(label: group.label, isDark: d));
      for (final t in group.items) {
        listItems.add(
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: TransactionCard(
              transaction: t,
              isDark: d,
              onEdit:   () => _openForm(context, editing: t, isDark: d),
              onDelete: () => _confirmDelete(context, t, d),
            ),
          ),
        );
      }
    }

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(child: _buildHeader(d)),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Balance card
        SliverToBoxAdapter(
          child: BalanceCard(
            balance: store.balance,
            income:  store.totalIncome,
            expense: store.totalExpense,
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // Section header + search bar
        SliverToBoxAdapter(child: _buildListHeader(store.transactions.length, filtered.length, d)),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Search bar (animated)
        SliverToBoxAdapter(child: _buildSearchBar(d)),

        // Filter chips
        SliverToBoxAdapter(child: _buildFilterChips(d)),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),

        // Empty states
        if (store.transactions.isEmpty)
          SliverToBoxAdapter(child: _buildEmpty(d))
        else if (filtered.isEmpty)
          SliverToBoxAdapter(child: _buildNoResult(d))
        else
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (_, i) => listItems[i],
              childCount: listItems.length,
            ),
          ),

        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }

  // ── widgets ───────────────────────────────────────────────────────────────

  Widget _blob(double size, Color color) =>
      Container(width: size, height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color));

  Widget _buildHeader(bool d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Keuangan Ku', style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimaryOf(d), fontSize: 24,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
              const SizedBox(height: 2),
              Text('Pantau keuanganmu setiap hari',
                style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13)),
            ],
          ),
          const Spacer(),
          Consumer<ThemeNotifier>(
            builder: (_, tn, __) => ThemeToggleButton(isDark: tn.isDark, onToggle: tn.toggle),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(int total, int shown, bool d) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text('Riwayat Transaksi', style: TextStyle(
            color: AppColors.textPrimaryOf(d), fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          if (total > 0) _countBadge(
            shown < total ? '$shown/$total' : '$total', d),
          const Spacer(),
          // Search toggle button
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                _searchOpen = !_searchOpen;
                if (!_searchOpen) {
                  _searchCtrl.clear();
                  _searchQuery = '';
                }
              });
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34, height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _searchOpen
                  ? AppColors.neonBlue.withOpacity(0.15)
                  : AppColors.cardOf(d),
                border: Border.all(
                  color: _searchOpen
                    ? AppColors.neonBlue.withOpacity(0.5)
                    : AppColors.cardBorderOf(d)),
              ),
              child: Icon(
                _searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: _searchOpen ? AppColors.neonBlue : AppColors.textSecondaryOf(d),
                size: 17,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool d) {
    return AnimatedCrossFade(
      duration: const Duration(milliseconds: 250),
      crossFadeState: _searchOpen ? CrossFadeState.showSecond : CrossFadeState.showFirst,
      firstChild: const SizedBox(height: 0),
      secondChild: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(d),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.neonBlue.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: AppColors.neonBlue.withOpacity(0.08), blurRadius: 12)],
          ),
          child: TextField(
            controller: _searchCtrl,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimaryOf(d), fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Cari nama atau kategori...',
              hintStyle: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13),
              prefixIcon: Icon(Icons.search_rounded,
                color: AppColors.neonBlue, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips(bool d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
      child: Row(
        children: [
          _filterChip('Semua',       TxFilter.all,     d),
          const SizedBox(width: 8),
          _filterChip('Pemasukan',   TxFilter.income,  d),
          const SizedBox(width: 8),
          _filterChip('Pengeluaran', TxFilter.expense, d),
        ],
      ),
    );
  }

  Widget _filterChip(String label, TxFilter value, bool d) {
    final active = _filter == value;
    final color = value == TxFilter.income
      ? AppColors.income
      : value == TxFilter.expense
        ? AppColors.expense
        : AppColors.neonBlue;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: active ? color.withOpacity(0.15) : AppColors.cardOf(d),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? color.withOpacity(0.5) : AppColors.cardBorderOf(d),
            width: active ? 1.5 : 1,
          ),
          boxShadow: active
            ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8)]
            : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (active) ...[
              Container(width: 6, height: 6,
                decoration: BoxDecoration(shape: BoxShape.circle, color: color)),
              const SizedBox(width: 5),
            ],
            Text(label, style: TextStyle(
              color: active ? color : AppColors.textSecondaryOf(d),
              fontSize: 12,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            )),
          ],
        ),
      ),
    );
  }

  Widget _countBadge(String text, bool d) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.neonBlue.withOpacity(0.12),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: AppColors.neonBlue.withOpacity(0.3)),
    ),
    child: Text(text, style: const TextStyle(
      color: AppColors.neonBlue, fontSize: 11, fontWeight: FontWeight.w600)),
  );

  Widget _buildEmpty(bool d) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonBlue.withOpacity(0.07),
              border: Border.all(color: AppColors.neonBlue.withOpacity(0.15)),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: AppColors.neonBlue, size: 40),
          ),
          const SizedBox(height: 16),
          Text('Belum ada transaksi', style: TextStyle(
            color: AppColors.textPrimaryOf(d), fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Ketuk + untuk menambahkan',
            style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNoResult(bool d) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.neonYellow.withOpacity(0.07),
              border: Border.all(color: AppColors.neonYellow.withOpacity(0.2)),
            ),
            child: const Icon(Icons.search_off_rounded, color: AppColors.neonYellow, size: 36),
          ),
          const SizedBox(height: 16),
          Text('Tidak ada hasil', style: TextStyle(
            color: AppColors.textPrimaryOf(d), fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text('Coba kata kunci atau filter lain',
            style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool d) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(d),
        border: Border(top: BorderSide(color: AppColors.cardBorderOf(d), width: 1)),
        boxShadow: d
          ? [const BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4))]
          : null,
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 6, top: 14),
      child: Row(children: [
        _navItem(0, Icons.home_rounded,      'Beranda',    d),
        _navItem(1, Icons.bar_chart_rounded, 'Statistik',  d),
        _navItem(2, Icons.settings_rounded,  'Pengaturan', d),
      ]),
    );
  }

  Widget _navItem(int index, IconData icon, String label, bool d) {
    final active = _navIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => _switchTab(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: active ? AppColors.neonBlue.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon,
                color: active ? AppColors.neonBlue : AppColors.textSecondaryOf(d), size: 22),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(
              color: active ? AppColors.neonBlue : AppColors.textSecondaryOf(d),
              fontSize: 10, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        ),
      ),
    );
  }
}

// ── Group date header ─────────────────────────────────────────────────────────
class _GroupHeader extends StatelessWidget {
  final String label;
  final bool isDark;
  const _GroupHeader({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
      child: Row(
        children: [
          Text(label, style: TextStyle(
            color: AppColors.textSecondaryOf(isDark),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          )),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: AppColors.cardBorderOf(isDark))),
        ],
      ),
    );
  }
}

// ── Delete Dialog ─────────────────────────────────────────────────────────────
class _DeleteDialog extends StatelessWidget {
  final Transaction transaction;
  final bool isDark;
  const _DeleteDialog({required this.transaction, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = isDark;
    return Dialog(
      backgroundColor: AppColors.cardOf(d),
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
              child: const Icon(Icons.delete_rounded, color: AppColors.neonPink, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Hapus Transaksi?', style: GoogleFonts.spaceGrotesk(
              color: AppColors.textPrimaryOf(d), fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Transaksi "${transaction.name}" akan dihapus permanen.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: NeonButton(
                label: 'Batal', onTap: () => Navigator.pop(context, false),
                color: AppColors.neonBlue, isOutlined: true,
              )),
              const SizedBox(width: 12),
              Expanded(child: NeonButton(
                label: 'Hapus', onTap: () => Navigator.pop(context, true),
                color: AppColors.neonPink,
              )),
            ]),
          ],
        ),
      ),
    );
  }
}

// ── Custom FAB ────────────────────────────────────────────────────────────────
class _CustomFAB extends StatefulWidget {
  final VoidCallback onTap;
  const _CustomFAB({required this.onTap});
  @override
  State<_CustomFAB> createState() => _CustomFABState();
}

class _CustomFABState extends State<_CustomFAB> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 150));
    _scale = Tween(begin: 1.0, end: 0.9)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown:  (_) => _ctrl.forward(),
      onTapUp:    (_) { _ctrl.reverse(); widget.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 58, height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.incomeGradient,
            boxShadow: [
              BoxShadow(color: AppColors.neonGreen.withOpacity(0.4), blurRadius: 20),
              BoxShadow(color: AppColors.neonGreen.withOpacity(0.2), blurRadius: 40),
            ],
          ),
          child: const Icon(Icons.add_rounded, color: AppColors.bg, size: 28),
        ),
      ),
    );
  }
}