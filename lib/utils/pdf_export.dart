// lib/utils/pdf_export.dart
import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';

class PdfExport {
  static Future<void> exportTransactions(List<Transaction> transactions) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy').format(now);

    double totalIncome = transactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (s, t) => s + t.amount);
    double totalExpense = transactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (s, t) => s + t.amount);
    double balance = totalIncome - totalExpense;

    String fmt(double v) => 'Rp ${v.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (ctx) => [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: const PdfColor.fromInt(0xFF0A0E1A),
              borderRadius: pw.BorderRadius.circular(12),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('LAPORAN KEUANGAN',
                    style: pw.TextStyle(
                      color: PdfColors.white,
                      fontSize: 20,
                      fontWeight: pw.FontWeight.bold,
                    )),
                pw.SizedBox(height: 4),
                pw.Text('Diekspor pada $dateStr',
                    style: const pw.TextStyle(color: PdfColors.grey, fontSize: 11)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Summary cards
          pw.Row(children: [
            pw.Expanded(child: _summaryBox('Total Saldo', fmt(balance), PdfColors.blue800)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _summaryBox('Pemasukan', fmt(totalIncome), PdfColors.green800)),
            pw.SizedBox(width: 12),
            pw.Expanded(child: _summaryBox('Pengeluaran', fmt(totalExpense), PdfColors.red800)),
          ]),
          pw.SizedBox(height: 24),

          // Table header
          pw.Text('Riwayat Transaksi (${transactions.length} transaksi)',
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(2),
            },
            children: [
              // Table header row
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: ['Nama', 'Jenis', 'Nominal', 'Tanggal'].map((h) =>
                  pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    child: pw.Text(h, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  ),
                ).toList(),
              ),
              // Data rows
              ...transactions.map((t) {
                final isIncome = t.type == TransactionType.income;
                return pw.TableRow(children: [
                  _cell(t.name),
                  _cell(isIncome ? 'Pemasukan' : 'Pengeluaran',
                    color: isIncome ? PdfColors.green700 : PdfColors.red700),
                  _cell('${isIncome ? '+' : '-'}${fmt(t.amount)}',
                    color: isIncome ? PdfColors.green700 : PdfColors.red700),
                  _cell(DateFormat('dd/MM/yyyy').format(t.date)),
                ]);
              }),
            ],
          ),

          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text('Keuangan Ku App • Generated $dateStr',
              style: const pw.TextStyle(color: PdfColors.grey, fontSize: 9)),
        ],
      ),
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/laporan_keuangan_${DateFormat('yyyyMMdd').format(now)}.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Laporan Keuangan - $dateStr',
    );
  }

  static pw.Widget _summaryBox(String label, String value, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: pw.TextStyle(color: color, fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text(value, style: pw.TextStyle(color: color, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static pw.Widget _cell(String text, {PdfColor? color}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      child: pw.Text(text,
        style: pw.TextStyle(fontSize: 9, color: color ?? PdfColors.black),
        overflow: pw.TextOverflow.clip),
    );
  }
}
