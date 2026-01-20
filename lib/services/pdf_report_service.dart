import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/widgets.dart' show PdfGoogleFonts;
import 'package:printing/printing.dart';

import '../localization/app_locale.dart';
import '../models/calculation_history_record.dart';

class PdfReportService {
  static Future<void> generateSingleReport({
    required String formulaName,
    required Map<String, dynamic> inputs,
    required Map<String, dynamic> outputs,
    DateTime? createdAt,
  }) async {
    final logoData = await rootBundle.load('assets/pomeka-png-1757403926.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    const PdfColor pdfPrimary = PdfColor.fromInt(0xFF0052FF);
    const PdfColor pdfLightGrey = PdfColor.fromInt(0xFFF4F6F8);
    final reportTime = createdAt ?? DateTime.now();

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (pw.Context context) {
        return pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logoImage, AppLocale.t('report_title'), pdfPrimary),
            pw.SizedBox(height: 24),
            pw.Center(
              child: pw.Text(
                formulaName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: pdfPrimary,
                ),
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Center(
              child: pw.Text(
                '${AppLocale.t('date')}: ${_formatDateTime(reportTime)}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ),
            pw.SizedBox(height: 24),
            _buildSection(
              title: AppLocale.t('inputs'),
              data: inputs,
              primary: pdfPrimary,
              bg: pdfLightGrey,
            ),
            pw.SizedBox(height: 16),
            _buildSection(
              title: AppLocale.t('results'),
              data: outputs,
              primary: pdfPrimary,
              bg: pdfLightGrey,
            ),
            pw.Spacer(),
            _buildFooter(pdfPrimary),
          ],
        );
      },
    ));
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: _buildFileName(formulaName),
    );
  }

  static Future<void> generateMultiReport(
      List<CalculationHistoryRecord> items) async {
    if (items.isEmpty) return;
    final logoData = await rootBundle.load('assets/pomeka-png-1757403926.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    const PdfColor pdfPrimary = PdfColor.fromInt(0xFF0052FF);
    const PdfColor pdfLightGrey = PdfColor.fromInt(0xFFF4F6F8);
    final now = DateTime.now();

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (context) => pw.Container(
        padding: const pw.EdgeInsets.all(32),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Image(logoImage, height: 48),
            pw.SizedBox(height: 40),
            pw.Text(
              AppLocale.t('calculation_report_title'),
              style: pw.TextStyle(
                fontSize: 28,
                fontWeight: pw.FontWeight.bold,
                color: pdfPrimary,
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text(
              '${AppLocale.t('date')}: ${_formatDateTime(now)}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 8),
            pw.Text(
              '${AppLocale.t('selected_count')}: ${items.length}',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.Spacer(),
            _buildFooter(pdfPrimary),
          ],
        ),
      ),
    ));

    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      header: (context) =>
          _buildHeader(logoImage, AppLocale.t('multi_report_title'), pdfPrimary),
      footer: (context) => _buildFooter(pdfPrimary),
      build: (context) => [
        pw.SizedBox(height: 12),
        ...items.asMap().entries.map((entry) {
          final index = entry.key + 1;
          final record = entry.value;
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.white,
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(14),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '${AppLocale.t('record')} #$index',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: pdfPrimary,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    record.formulaName,
                    style: const pw.TextStyle(fontSize: 13),
                  ),
                  pw.Text(
                    '${AppLocale.t('date')}: ${_formatDateTime(record.createdAt)}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                  pw.SizedBox(height: 12),
                  _buildSection(
                    title: AppLocale.t('inputs'),
                    data: record.inputs,
                    primary: pdfPrimary,
                    bg: pdfLightGrey,
                  ),
                  pw.SizedBox(height: 10),
                  _buildSection(
                    title: AppLocale.t('results'),
                    data: record.outputs,
                    primary: pdfPrimary,
                    bg: pdfLightGrey,
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    ));
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: _buildBatchFileName(now),
    );
  }

  static pw.Widget _buildHeader(
      pw.MemoryImage logo, String title, PdfColor color) {
    return pw.Column(children: [
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Image(logo, height: 40),
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
            pw.Text(
              title,
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              '${AppLocale.t('date')}: ${DateTime.now().toString().substring(0, 10)}',
              style: const pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey700,
              ),
            ),
          ])
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Container(height: 2, width: double.infinity, color: color),
    ]);
  }

  static pw.Widget _buildFooter(PdfColor color) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text(
          "POMEKA Mobile Tools",
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: color,
          ),
        ),
        pw.Text(
          AppLocale.t('pdf_footer'),
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ])
    ]);
  }

  static pw.Widget _buildSection({
    required String title,
    required Map<String, dynamic> data,
    required PdfColor primary,
    required PdfColor bg,
  }) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            fontSize: 12,
            color: primary,
          ),
        ),
        pw.SizedBox(height: 6),
        _buildTable(data, primary, bg),
      ],
    );
  }

  static pw.Widget _buildTable(
      Map<String, dynamic> data, PdfColor primary, PdfColor bg) {
    final entries = data.entries.toList();
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300, width: 1),
        borderRadius: pw.BorderRadius.circular(8),
        color: bg,
      ),
      child: pw.Column(
        children: entries.isEmpty
            ? [
                pw.Padding(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: pw.Text('-'),
                )
              ]
            : entries.map((entry) {
                final index = entries.indexOf(entry);
                final isLast = index == entries.length - 1;
                return pw.Container(
                  padding:
                      const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: pw.BoxDecoration(
                    border: isLast
                        ? null
                        : const pw.Border(
                            bottom: pw.BorderSide(color: PdfColors.grey300),
                          ),
                    color: index % 2 == 0 ? PdfColors.white : bg,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                        flex: 3,
                        child: pw.Text(
                          entry.key,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 11,
                            color: PdfColors.grey800,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      pw.Expanded(
                        flex: 2,
                        child: pw.Text(
                          _formatValue(entry.value),
                          textAlign: pw.TextAlign.right,
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 12,
                            color: primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
      ),
    );
  }

  static String _formatValue(dynamic value) {
    if (value == null) return '-';
    if (value is String) return value;
    return value.toString();
  }

  static String _buildBatchFileName(DateTime time) {
    return 'Hesaplama_Raporu_${_formatFileTimestamp(time)}.pdf';
  }

  static String _buildFileName(String formulaName) {
    return 'Hesaplama_${_sanitizeFileName(formulaName)}_${_formatFileTimestamp(DateTime.now())}.pdf';
  }

  static String _formatFileTimestamp(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$y$m$d' '_' '$hh$mm';
  }

  static String _formatDateTime(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  static String _sanitizeFileName(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9-_]+'), '_');
  }
}
