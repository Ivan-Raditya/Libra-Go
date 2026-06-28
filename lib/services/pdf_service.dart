import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class PdfService {
  static Future<void> generateAndShareTripReport({
    required Map<String, dynamic> trip,
    required List<Map<String, dynamic>> itineraries,
    required List<Map<String, dynamic>> expenses,
  }) async {
    final pdf = pw.Document();

    final title = trip['name'] ?? 'Trip Report';
    final destination = trip['destination'] ?? 'Destinasi';
    final date = trip['start_date'] ?? 'TBD';

    int totalExpenses = 0;
    for (var e in expenses) {
      totalExpenses += (e['amount'] as num).toInt();
    }

    final budget = (trip['budget'] as num?)?.toInt() ?? 0;
    final remaining = budget - totalExpenses;

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(title, destination, date),
            pw.SizedBox(height: 20),
            _buildSummary(budget, totalExpenses, remaining),
            pw.SizedBox(height: 30),
            if (itineraries.isNotEmpty) _buildItinerarySection(itineraries),
            pw.SizedBox(height: 30),
            if (expenses.isNotEmpty) _buildExpenseSection(expenses),
          ];
        },
      ),
    );

    // Save and Share
    final output = await getTemporaryDirectory();
    final file = File('${output.path}/Trip_Report_$title.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Berikut adalah laporan itinerary dan patungan (Split Bill) untuk trip $title ke $destination!',
    );
  }

  static pw.Widget _buildHeader(String title, String destination, String date) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('LIBRA GO - TRAVEL REPORT', style: pw.TextStyle(color: PdfColors.teal, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 8),
        pw.Text(title, style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
        pw.SizedBox(height: 4),
        pw.Text('$destination • $date', style: const pw.TextStyle(fontSize: 14, color: PdfColors.blueGrey500)),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _buildSummary(int budget, int expenses, int remaining) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          _summaryBox('Anggaran', _formatRupiah(budget)),
          _summaryBox('Terpakai', _formatRupiah(expenses), color: PdfColors.red700),
          _summaryBox('Sisa', _formatRupiah(remaining), color: PdfColors.teal700),
        ],
      ),
    );
  }

  static pw.Widget _summaryBox(String label, String value, {PdfColor color = PdfColors.blueGrey900}) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey500)),
        pw.SizedBox(height: 4),
        pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: color)),
      ],
    );
  }

  static pw.Widget _buildItinerarySection(List<Map<String, dynamic>> itineraries) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('JADWAL PERJALANAN (ITINERARY)', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
        pw.SizedBox(height: 12),
        ...itineraries.map((item) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 12),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 60,
                  child: pw.Text('Hari ${item['day_number']}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.teal)),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(item['title'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      if (item['description'] != null && item['description'].toString().isNotEmpty)
                        pw.Text(item['description'], style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      if (item['location'] != null && item['location'].toString().isNotEmpty)
                        pw.Text('📍 ${item['location']}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.blueGrey500)),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  static pw.Widget _buildExpenseSection(List<Map<String, dynamic>> expenses) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('RINCIAN PENGELUARAN', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.blueGrey900)),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          border: null,
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
          cellStyle: const pw.TextStyle(fontSize: 10),
          cellPadding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          headers: ['Tanggal', 'Kategori', 'Nama', 'Nominal (IDR)'],
          data: expenses.map((e) {
            final date = e['date'] != null ? e['date'].toString().split('T')[0] : '-';
            final cat = e['category'] ?? '-';
            final name = e['name'] ?? '-';
            final amt = _formatRupiah((e['amount'] as num).toInt());
            return [date, cat, name, amt];
          }).toList(),
        ),
      ],
    );
  }

  static String _formatRupiah(int amount) {
    String result = amount.toString();
    // A simple regex approach for dart string replacement
    // In actual dart without intl it can be done simply by looping
    String formatted = '';
    for (int i = 0; i < result.length; i++) {
      if (i > 0 && (result.length - i) % 3 == 0) {
        formatted += '.';
      }
      formatted += result[i];
    }
    return 'Rp $formatted';
  }
}
