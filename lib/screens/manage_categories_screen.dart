// lib/screens/manage_categories_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/category.dart';
import '../utils/category_store.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class ManageCategoriesScreen extends StatefulWidget {
  final bool isDark;
  const ManageCategoriesScreen({super.key, required this.isDark});

  @override
  State<ManageCategoriesScreen> createState() => _ManageCategoriesScreenState();
}

class _ManageCategoriesScreenState extends State<ManageCategoriesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
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
        title: Text('Kelola Kategori',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimaryOf(d),
                fontSize: 18,
                fontWeight: FontWeight.w700)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => _openForm(context, isIncome: _tabCtrl.index == 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.incomeGradient,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.neonGreen.withOpacity(0.3),
                        blurRadius: 10)
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.add_rounded,
                        color: AppColors.bg, size: 16),
                    const SizedBox(width: 4),
                    Text('Tambah',
                        style: const TextStyle(
                            color: AppColors.bg,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.cardOf(d),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.cardBorderOf(d)),
            ),
            child: TabBar(
              controller: _tabCtrl,
              indicator: BoxDecoration(
                color: AppColors.neonBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: AppColors.neonBlue.withOpacity(0.4)),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: AppColors.neonBlue,
              unselectedLabelColor: AppColors.textSecondaryOf(d),
              labelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Pemasukan'),
                Tab(text: 'Pengeluaran'),
              ],
            ),
          ),
        ),
      ),
      body: Consumer<CategoryStore>(
        builder: (_, store, __) => TabBarView(
          controller: _tabCtrl,
          children: [
            _CategoryList(
                categories: store.incomeCategories,
                isIncome: true,
                isDark: d,
                onEdit: (c) => _openForm(context, editing: c, isIncome: true),
                onDelete: (c) => _confirmDelete(context, store, c)),
            _CategoryList(
                categories: store.expenseCategories,
                isIncome: false,
                isDark: d,
                onEdit: (c) => _openForm(context, editing: c, isIncome: false),
                onDelete: (c) => _confirmDelete(context, store, c)),
          ],
        ),
      ),
    );
  }

  Future<void> _openForm(BuildContext context,
      {AppCategory? editing, required bool isIncome}) async {
    final store = context.read<CategoryStore>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryForm(
        isDark: widget.isDark,
        isIncome: isIncome,
        editing: editing,
        onSave: (name, iconKey) async {
          if (editing != null) {
            await store.update(editing.id, name, iconKey);
          } else {
            await store.add(name, iconKey, isIncome);
          }
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, CategoryStore store, AppCategory cat) async {
    HapticFeedback.mediumImpact();
    final d = widget.isDark;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.cardOf(d),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                  border:
                      Border.all(color: AppColors.neonPink.withOpacity(0.3)),
                ),
                child: const Icon(Icons.delete_rounded,
                    color: AppColors.neonPink, size: 26),
              ),
              const SizedBox(height: 16),
              Text('Hapus Kategori?',
                  style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimaryOf(d),
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('"${cat.name}" akan dihapus permanen.',
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
            ],
          ),
        ),
      ),
    );
    if (ok == true) await store.delete(cat.id);
  }
}

// ── Category list ─────────────────────────────────────────────────────────────
class _CategoryList extends StatelessWidget {
  final List<AppCategory> categories;
  final bool isIncome;
  final bool isDark;
  final void Function(AppCategory) onEdit;
  final void Function(AppCategory) onDelete;

  const _CategoryList({
    required this.categories,
    required this.isIncome,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = isIncome ? AppColors.income : AppColors.expense;
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: categories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) {
        final cat = categories[i];
        return GlassCard(
          borderColor: color.withOpacity(0.3),
          glowIntensity: 3,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          isDark: isDark,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(cat.icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat.name,
                        style: TextStyle(
                            color: AppColors.textPrimaryOf(isDark),
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: cat.isDefault
                            ? AppColors.textSecondaryOf(isDark).withOpacity(0.1)
                            : color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        cat.isDefault ? 'Default' : 'Custom',
                        style: TextStyle(
                            color: cat.isDefault
                                ? AppColors.textSecondaryOf(isDark)
                                : color,
                            fontSize: 10,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              if (!cat.isDefault) ...[
                _iconBtn(Icons.edit_rounded, AppColors.neonBlue,
                    () => onEdit(cat)),
                const SizedBox(width: 6),
                _iconBtn(Icons.delete_rounded, AppColors.neonPink,
                    () => onDelete(cat)),
              ] else
                Icon(Icons.lock_outline_rounded,
                    color: AppColors.textSecondaryOf(isDark).withOpacity(0.4),
                    size: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Icon(icon, color: color, size: 14),
      ),
    );
  }
}

// ── Category form (bottom sheet) ──────────────────────────────────────────────
class _CategoryForm extends StatefulWidget {
  final bool isDark;
  final bool isIncome;
  final AppCategory? editing;
  final Future<void> Function(String name, String iconKey) onSave;

  const _CategoryForm({
    required this.isDark,
    required this.isIncome,
    required this.onSave,
    this.editing,
  });

  @override
  State<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends State<_CategoryForm> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'circle';
  bool _saving = false;

  // Icon groups for the picker
  static const Map<String, List<String>> _iconGroups = {
    'Keuangan': [
      'payments', 'wallet', 'savings', 'trending_up', 'trending_down',
      'attach_money', 'currency_exchange', 'receipt', 'credit_card', 'bank',
    ],
    'Pekerjaan': [
      'laptop', 'work', 'business', 'handshake', 'school',
    ],
    'Makanan': [
      'restaurant', 'fastfood', 'coffee', 'cake', 'grocery',
    ],
    'Transport': [
      'car', 'motorcycle', 'bus', 'flight', 'local_taxi',
    ],
    'Belanja': [
      'shopping_bag', 'store', 'checkroom', 'redeem',
    ],
    'Kesehatan': [
      'favorite', 'medical', 'fitness', 'spa',
    ],
    'Hiburan': [
      'movie', 'music', 'sports', 'travel', 'camera', 'book',
    ],
    'Rumah': [
      'home', 'build', 'electricity', 'water', 'wifi',
    ],
    'Lainnya': [
      'pets', 'child', 'gift', 'charity', 'circle',
    ],
  };

  @override
  void initState() {
    super.initState();
    if (widget.editing != null) {
      _nameCtrl.text = widget.editing!.name;
      _selectedIcon = widget.editing!.iconKey;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await widget.onSave(_nameCtrl.text.trim(), _selectedIcon);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    final color = widget.isIncome ? AppColors.income : AppColors.expense;
    final isEdit = widget.editing != null;

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(d),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: AppColors.cardBorderOf(d),
                  borderRadius: BorderRadius.circular(2)),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Row(
                children: [
                  Text(isEdit ? 'Edit Kategori' : 'Kategori Baru',
                      style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textPrimaryOf(d),
                          fontSize: 18,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.cardOf(d),
                          border:
                              Border.all(color: AppColors.cardBorderOf(d))),
                      child: Icon(Icons.close,
                          color: AppColors.textSecondaryOf(d), size: 15),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(24),
                children: [
                  // Jenis badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: color.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                            widget.isIncome
                                ? Icons.arrow_downward_rounded
                                : Icons.arrow_upward_rounded,
                            color: color,
                            size: 13),
                        const SizedBox(width: 5),
                        Text(
                            widget.isIncome ? 'Pemasukan' : 'Pengeluaran',
                            style: TextStyle(
                                color: color,
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Name field
                  Text('Nama Kategori',
                      style: TextStyle(
                          color: AppColors.textSecondaryOf(d),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 8),
                  _NameField(
                      ctrl: _nameCtrl,
                      isDark: d,
                      selectedIcon: _selectedIcon,
                      iconColor: color),
                  const SizedBox(height: 24),

                  // Icon picker
                  Text('Pilih Icon',
                      style: TextStyle(
                          color: AppColors.textSecondaryOf(d),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5)),
                  const SizedBox(height: 12),

                  // Groups
                  ..._iconGroups.entries.map((entry) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(children: [
                              Text(entry.key,
                                  style: TextStyle(
                                      color: AppColors.textSecondaryOf(d)
                                          .withOpacity(0.7),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.8)),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: AppColors.cardBorderOf(d))),
                            ]),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: entry.value.map((key) {
                              final active = _selectedIcon == key;
                              final ico = kCategoryIconMap[key] ??
                                  Icons.circle_rounded;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedIcon = key);
                                },
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 160),
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: active
                                        ? color.withOpacity(0.18)
                                        : AppColors.cardOf(d),
                                    border: Border.all(
                                      color: active
                                          ? color.withOpacity(0.6)
                                          : AppColors.cardBorderOf(d),
                                      width: active ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Icon(ico,
                                      color: active
                                          ? color
                                          : AppColors.textSecondaryOf(d),
                                      size: 20),
                                ),
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 16),
                        ],
                      )),

                  const SizedBox(height: 8),

                  // Save button
                  NeonButton(
                    label: isEdit ? 'Simpan Perubahan' : 'Buat Kategori',
                    onTap: _saving ? () {} : _save,
                    icon: isEdit
                        ? Icons.save_rounded
                        : Icons.add_rounded,
                    width: double.infinity,
                    color: color,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Name field with icon preview ──────────────────────────────────────────────
class _NameField extends StatefulWidget {
  final TextEditingController ctrl;
  final bool isDark;
  final String selectedIcon;
  final Color iconColor;

  const _NameField({
    required this.ctrl,
    required this.isDark,
    required this.selectedIcon,
    required this.iconColor,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  final _focus = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() => _focused = _focus.hasFocus));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        _focused ? AppColors.neonBlue : AppColors.cardBorderOf(widget.isDark);
    final icon =
        kCategoryIconMap[widget.selectedIcon] ?? Icons.circle_rounded;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: _focused ? 1.5 : 1),
        color: AppColors.surfaceOf(widget.isDark),
        boxShadow: _focused
            ? [
                BoxShadow(
                    color: AppColors.neonBlue.withOpacity(0.12),
                    blurRadius: 16)
              ]
            : null,
      ),
      child: Row(
        children: [
          // Icon preview
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(13)),
              color: widget.iconColor.withOpacity(0.1),
              border: Border(
                  right: BorderSide(color: AppColors.cardBorderOf(widget.isDark))),
            ),
            child: Icon(icon, color: widget.iconColor, size: 22),
          ),
          Expanded(
            child: TextField(
              controller: widget.ctrl,
              focusNode: _focus,
              style: TextStyle(
                  color: AppColors.textPrimaryOf(widget.isDark), fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Nama kategori...',
                hintStyle: TextStyle(
                    color: AppColors.textSecondaryOf(widget.isDark),
                    fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}