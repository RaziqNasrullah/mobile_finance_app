// lib/screens/transaction_form.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../utils/wallet_store.dart';
import '../utils/category_store.dart';
import 'package:provider/provider.dart';
import '../utils/theme.dart';
import '../widgets/glass_card.dart';

class TransactionForm extends StatefulWidget {
  final Transaction? editing;
  final bool isDark;
  final String? initialWalletId;

  const TransactionForm({super.key, this.editing, this.isDark = true, this.initialWalletId});

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();

  bool _isIncome = true;
  DateTime _date = DateTime.now();
  String _category = 'General';
  String _walletId = 'cash';
  List<AppCategory> _availableCategories = [];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _ctrl.forward();

    if (widget.editing != null) {
      final e = widget.editing!;
      _nameCtrl.text = e.name;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _isIncome = e.type == TransactionType.income;
      _date = e.date;
      _category = e.category;
    }
    _walletId = widget.editing?.walletId ?? widget.initialWalletId ?? 'cash';
    _dateCtrl.text = DateFormat('dd MMMM yyyy').format(_date);
    // Load categories after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshCategories());
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _dateCtrl.dispose();
    super.dispose();
  }

  void _refreshCategories() {
    if (!mounted) return;
    final store = context.read<CategoryStore>();
    final cats = _isIncome ? store.incomeCategories : store.expenseCategories;
    setState(() {
      _availableCategories = cats;
      if (!cats.any((c) => c.name == _category)) {
        _category = cats.isNotEmpty ? cats.first.name : 'General';
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'name': _nameCtrl.text.trim(),
      'type': _isIncome ? TransactionType.income : TransactionType.expense,
      'amount': double.parse(_amountCtrl.text),
      'date': _date,
      'category': _category,
      'walletId': _walletId,
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: AppColors.neonBlue, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateCtrl.text = DateFormat('dd MMMM yyyy').format(_date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.isDark;
    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(d),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: AppColors.cardBorderOf(d), borderRadius: BorderRadius.circular(2)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  Text(widget.editing != null ? 'Edit Transaksi' : 'Tambah Transaksi',
                    style: GoogleFonts.spaceGrotesk(
                      color: AppColors.textPrimaryOf(d), fontSize: 20, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.cardOf(d),
                        border: Border.all(color: AppColors.cardBorderOf(d)),
                      ),
                      child: Icon(Icons.close, color: AppColors.textSecondaryOf(d), size: 16),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TransactionTypeToggle(
                        isIncome: _isIncome,
                        isDark: d,
                        onChanged: (v) {
                          setState(() {
                            _isIncome = v;
                          });
                          _refreshCategories();
                        },
                      ),
                      const SizedBox(height: 20),
                      _label('Nama Transaksi', d),
                      const SizedBox(height: 8),
                      NeonTextField(
                        hint: 'Contoh: Gaji Bulanan',
                        controller: _nameCtrl,
                        prefixIcon: Icons.label_rounded,
                        isDark: d,
                        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      _label('Nominal (Rp)', d),
                      const SizedBox(height: 8),
                      NeonTextField(
                        hint: '0',
                        controller: _amountCtrl,
                        prefixIcon: Icons.attach_money_rounded,
                        keyboardType: TextInputType.number,
                        isDark: d,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Wajib diisi';
                          if (double.tryParse(v) == null) return 'Masukkan angka';
                          if (double.parse(v) <= 0) return 'Harus lebih dari 0';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _label('Tanggal', d),
                      const SizedBox(height: 8),
                      NeonTextField(
                        hint: 'Pilih tanggal',
                        controller: _dateCtrl,
                        prefixIcon: Icons.calendar_today_rounded,
                        readOnly: true,
                        isDark: d,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      _label('Dompet', d),
                      const SizedBox(height: 8),
                      _walletSelector(d),
                      const SizedBox(height: 16),
                      _label('Kategori', d),
                      const SizedBox(height: 8),
                      _categoryGrid(d),
                      const SizedBox(height: 28),
                      NeonButton(
                        label: widget.editing != null ? 'Simpan Perubahan' : 'Tambah Transaksi',
                        onTap: _submit,
                        icon: widget.editing != null ? Icons.save_rounded : Icons.add_rounded,
                        width: double.infinity,
                        color: _isIncome ? AppColors.neonGreen : AppColors.neonPink,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text, bool d) => Text(text, style: TextStyle(
    color: AppColors.textSecondaryOf(d), fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.5));

  Widget _walletSelector(bool d) {
    final wallets = context.read<WalletStore>().wallets;
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: wallets.map((w) {
        final active = _walletId == w.id;
        return GestureDetector(
          onTap: () => setState(() => _walletId = w.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? w.color.withOpacity(0.15) : AppColors.cardOf(d),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? w.color.withOpacity(0.5) : AppColors.cardBorderOf(d)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(w.icon, color: active ? w.color : AppColors.textSecondaryOf(d), size: 14),
              const SizedBox(width: 6),
              Text(w.name, style: TextStyle(
                color: active ? w.color : AppColors.textSecondaryOf(d),
                fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              )),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _categoryGrid(bool d) {
    final color = _isIncome ? AppColors.neonGreen : AppColors.neonPink;
    if (_availableCategories.isEmpty) {
      return Text('Memuat kategori...',
        style: TextStyle(color: AppColors.textSecondaryOf(d), fontSize: 13));
    }
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _availableCategories.map((cat) {
        final active = _category == cat.name;
        return GestureDetector(
          onTap: () => setState(() => _category = cat.name),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: active ? color.withOpacity(0.15) : AppColors.cardOf(d),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active ? color.withOpacity(0.5) : AppColors.cardBorderOf(d)),
              boxShadow: active
                ? [BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)]
                : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(cat.icon, color: active ? color : AppColors.textSecondaryOf(d), size: 14),
                const SizedBox(width: 6),
                Text(cat.name, style: TextStyle(
                  color: active ? color : AppColors.textSecondaryOf(d),
                  fontSize: 12, fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}