import 'dart:convert';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../kazan_tesisat_calculator.dart';
import '../localization/app_locale.dart';
import '../services/expansion_tank_calculator.dart';
import '../services/hydrofor_tank_transfer.dart';

// ---------------------------------------------------------------------------
// 1. PDF SERVICE
// ---------------------------------------------------------------------------
class PdfService {
  static Future<void> generateAndShare(
      {required String title, required Map<String, String> data}) async {
    final logoData = await rootBundle.load('assets/pomeka-png-1757403926.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    const PdfColor pdfPrimary = PdfColor.fromInt(0xFF0052FF);
    const PdfColor pdfLightGrey = PdfColor.fromInt(0xFFF4F6F8);

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (pw.Context context) {
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoImage, AppLocale.t('report_title'), pdfPrimary),
              pw.SizedBox(height: 30),
              pw.Center(
                  child: pw.Text(title.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: pdfPrimary,
                          letterSpacing: 1.2))),
              pw.SizedBox(height: 30),
              _buildTable(data, pdfPrimary, pdfLightGrey),
              pw.Spacer(),
              _buildFooter(pdfPrimary),
            ]);
      },
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Pomeka_${title.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateMultiReport(
      List<Map<String, dynamic>> items) async {
    final logoData = await rootBundle.load('assets/pomeka-png-1757403926.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    const PdfColor pdfPrimary = PdfColor.fromInt(0xFF0052FF);
    const PdfColor pdfLightGrey = PdfColor.fromInt(0xFFF4F6F8);

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      header: (context) => _buildHeader(
          logoImage, AppLocale.t('multi_report_title'), pdfPrimary),
      footer: (context) => _buildFooter(pdfPrimary),
      build: (context) => [
        pw.SizedBox(height: 20),
        ...items.map((item) {
          final type = item['type'] ?? '';
          final date = item['time'] != null
              ? item['time']
                  .toString()
                  .substring(0, 16)
                  .replaceAll('T', ' ')
              : '-';
          final inputs = item['inputs'] ?? '';
          final result = item['res'] ?? '';
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.white),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                        color: pdfLightGrey,
                        borderRadius:
                            pw.BorderRadius.vertical(top: pw.Radius.circular(8))),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(type,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: pdfPrimary)),
                          pw.Text(date,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey700)),
                        ]),
                  ),
                  pw.Divider(height: 1, color: PdfColors.grey300),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${AppLocale.t('inputs')}:',
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(inputs,
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.SizedBox(height: 8),
                          pw.Text('${AppLocale.t('results')}:',
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(result,
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: pdfPrimary)),
                        ]),
                  ),
                ]),
          );
        }),
      ],
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'Pomeka_Toplu_Rapor.pdf');
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
              pw.Text(title,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: color)),
              pw.SizedBox(height: 4),
              pw.Text(
                  '${AppLocale.t('date')}: ${DateTime.now().toString().substring(0, 10)}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ])
          ]),
      pw.SizedBox(height: 10),
      pw.Container(height: 2, width: double.infinity, color: color),
    ]);
  }

  static pw.Widget _buildFooter(PdfColor color) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("POMEKA Mobile Tools",
            style: pw.TextStyle(
                fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(AppLocale.t('pdf_footer'),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ])
    ]);
  }

  static pw.Widget _buildTable(
      Map<String, String> data, PdfColor primary, PdfColor bg) {
    return pw.Container(
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
          color: bg),
      child: pw.Column(children: data.entries.map((e) {
        final index = data.keys.toList().indexOf(e.key);
        final isLast = index == data.length - 1;
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: pw.BoxDecoration(
              border: isLast
                  ? null
                  : const pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300)),
              color: index % 2 == 0 ? PdfColors.white : bg),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e.key,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.grey800)),
                pw.Text(e.value,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: primary)),
              ]),
        );
      }).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. CHART WIDGETS
// ---------------------------------------------------------------------------

class ResultChart extends StatelessWidget {
  final double q;
  final double hm;
  final bool isDark;

  const ResultChart(
      {super.key, required this.q, required this.hm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const Color lineColor = Color(0xFF0052FF);
    final Color gridColor = isDark ? Colors.white10 : Colors.black12;
    final Color textColor = isDark ? Colors.grey : Colors.black54;

    List<FlSpot> spots = [];
    double maxQ = q * 1.5;
    if (maxQ == 0) maxQ = 10;
    double kVal = (q > 0) ? hm / (q * q) : 0;

    for (double i = 0; i <= maxQ; i += maxQ / 20) {
      spots.add(FlSpot(i, kVal * i * i));
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: gridColor, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: gridColor, strokeWidth: 1)),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: maxQ / 5,
                        getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1),
                            style: TextStyle(color: textColor, fontSize: 10)))),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: hm / 4,
                        getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0),
                            style: TextStyle(color: textColor, fontSize: 10)))),
              ),
              borderData: FlBorderData(
                  show: true, border: Border.all(color: gridColor)),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: lineColor.withValues(alpha: 0.1)),
                ),
                LineChartBarData(
                  spots: [FlSpot(q, hm)],
                  color: Colors.red,
                  barWidth: 0,
                  dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                              radius: 6,
                              color: Colors.red,
                              strokeWidth: 2,
                              strokeColor:
                                  isDark ? Colors.white : Colors.black)),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                          'Q: ${barSpot.x.toStringAsFixed(1)}\nHm: ${barSpot.y.toStringAsFixed(1)}',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold));
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BoilerChart extends StatelessWidget {
  final double volume;
  final bool isDark;

  const BoilerChart({super.key, required this.volume, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const Color lineColor = Colors.orange;
    final Color gridColor = isDark ? Colors.white10 : Colors.black12;
    final Color textColor = isDark ? Colors.grey : Colors.black54;

    double idealP = (3.48 * volume) / 45.0;
    if (idealP < 5) idealP = 5;

    double minP = idealP * 0.2;
    double maxP = idealP * 2.5;

    List<FlSpot> spots = [];
    for (double p = minP; p <= maxP; p += (maxP - minP) / 20) {
      double t = (3.48 * volume) / p;
      spots.add(FlSpot(p, t));
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                  '${AppLocale.t('chart_boiler_x')} / ${AppLocale.t('chart_boiler_y')}',
                  style: TextStyle(fontSize: 10, color: textColor)),
              const SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: (maxP - minP) / 5,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                    ),
                    borderData: FlBorderData(
                        show: true, border: Border.all(color: gridColor)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: 0.1)),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.orangeAccent,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            return LineTooltipItem(
                                '${barSpot.x.toStringAsFixed(1)} kW\n${barSpot.y.toStringAsFixed(0)} dk',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold));
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TankChart extends StatelessWidget {
  final double waterVolume;
  final double maxTemp;
  final bool isDark;

  const TankChart(
      {super.key,
      required this.waterVolume,
      required this.maxTemp,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    const Color lineColor = Colors.purple;
    final Color gridColor = isDark ? Colors.white10 : Colors.black12;
    final Color textColor = isDark ? Colors.grey : Colors.black54;

    List<FlSpot> spots = [];
    for (double t = 20; t <= maxTemp + 10; t += 5) {
      double n = (0.00029 * t * t - 0.0037 * t + 0.06);
      if (n < 0) n = 0;
      double expVol = waterVolume * n / 100;
      spots.add(FlSpot(t, expVol));
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                  '${AppLocale.t('chart_tank_x')} / ${AppLocale.t('chart_tank_y')}',
                  style: TextStyle(fontSize: 10, color: textColor)),
              const SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 20,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                    ),
                    borderData: FlBorderData(
                        show: true, border: Border.all(color: gridColor)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: 0.1)),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.purple,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            return LineTooltipItem(
                                '${barSpot.x.toStringAsFixed(0)} °C\n${barSpot.y.toStringAsFixed(1)} L',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold));
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. CALCULATOR TABS
// ---------------------------------------------------------------------------

class UnitConverterTab extends StatefulWidget {
  const UnitConverterTab({super.key});
  @override
  State<UnitConverterTab> createState() => _UnitConverterTabState();
}

class _UnitConverterTabState extends State<UnitConverterTab> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _selectedCategory = 'cat_press';
  String _fromUnit = 'Bar';
  String _toUnit = 'mSS';
  double _result = 0.0;

  final Map<String, Map<String, double>> _units = {
    'cat_press': {
      'Bar': 1.0,
      'mSS': 0.0980665,
      'Psi': 0.0689476,
      'Pa': 0.00001,
      'Atm': 1.01325
    },
    'cat_flow': {'m³/h': 1.0, 'lt/s': 3.6, 'lt/dk': 0.06, 'gpm': 0.22712},
    'cat_power': {
      'kW': 1.0,
      'HP': 0.7457,
      'kcal/h': 0.001162,
      'btu/h': 0.000293
    },
    'cat_len': {
      'm': 1.0,
      'cm': 0.01,
      'mm': 0.001,
      'inch': 0.0254,
      'ft': 0.3048
    },
    'cat_vol': {'Litre': 1.0, 'm³': 1000.0, 'Galon': 3.78541},
  };

  @override
  void initState() {
    super.initState();
    _resetUnits();
  }

  void _resetUnits() {
    final catKey = _selectedCategory;
    final keys = _units[catKey]!.keys.toList();
    setState(() {
      _fromUnit = keys[0];
      _toUnit = keys.length > 1 ? keys[1] : keys[0];
      _calculate();
    });
  }

  void _calculate() {
    double val = double.tryParse(_inputCtrl.text) ?? 0.0;
    double baseVal = val * _units[_selectedCategory]![_fromUnit]!;
    double res = baseVal / _units[_selectedCategory]![_toUnit]!;
    setState(() => _result = res);
  }

  @override
  Widget build(BuildContext context) {
    final catKeys = [
      'cat_press',
      'cat_flow',
      'cat_power',
      'cat_len',
      'cat_vol'
    ];
    final currentUnitKeys = _units[_selectedCategory]!.keys.toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultColor =
        isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;
    final iconColor = isDark ? Colors.white : Theme.of(context).primaryColor;
    final borderColor = isDark
        ? Colors.white24
        : Theme.of(context).primaryColor.withValues(alpha: 0.2);
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF252628) : Colors.white,
                icon: Icon(Icons.unfold_more, color: iconColor, size: 28),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                    _resetUnits();
                  }
                },
                items: catKeys
                    .map((e) => DropdownMenuItem(
                        value: e,
                        child: Text(AppLocale.t(e),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: textColor))))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 4,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      flex: 2,
                      child: TextField(
                          controller: _inputCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => _calculate(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                              labelText: AppLocale.t('val_input'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                          initialValue: _fromUnit,
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                          isExpanded: true,
                          onChanged: (val) {
                            setState(() => _fromUnit = val!);
                            _calculate();
                          },
                          items: currentUnitKeys
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(AppLocale.t(e),
                                      style: const TextStyle(fontSize: 14))))
                              .toList())),
                ]),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Icon(Icons.arrow_downward, color: Colors.grey)),
                Row(children: [
                  Expanded(
                      flex: 2,
                      child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                              _result == 0 ? "0" : _result.toStringAsFixed(4),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: resultColor)))),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                          initialValue: _toUnit,
                          decoration:
                              const InputDecoration(border: InputBorder.none),
                          isExpanded: true,
                          onChanged: (val) {
                            setState(() => _toUnit = val!);
                            _calculate();
                          },
                          items: currentUnitKeys
                              .map((e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(AppLocale.t(e),
                                      style: const TextStyle(fontSize: 14))))
                              .toList())),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class HydroforTab extends StatefulWidget {
  final Function(String, String)? onRes;
  final ValueChanged<HydroforTankTransfer>? onTransferToTank;
  const HydroforTab({super.key, this.onRes, this.onTransferToTank});
  @override
  State<HydroforTab> createState() => _HydroforTabState();
}

class _HydroforTabState extends State<HydroforTab> {
  final _dCtrl = TextEditingController();
  final _kCtrl = TextEditingController();
  String? _qR, _hR, _type;
  bool _load = false;

  @override
  void initState() {
    super.initState();
    _type = 't_konut';
  }

  void _clear() {
    setState(() {
      _dCtrl.clear();
      _kCtrl.clear();
      _type = 't_konut';
      _qR = null;
      _hR = null;
      _load = false;
    });
  }

  void _calc() async {
    if (_dCtrl.text.isEmpty || _kCtrl.text.isEmpty || _type == null) return;
    setState(() => _load = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final d = int.parse(_dCtrl.text);
    final k = int.parse(_kCtrl.text);

    double tuketim = 150.0;
    switch (_type) {
      case 't_konut':
        tuketim = 150.0;
        break;
      case 'l_konut':
        tuketim = 200.0;
        break;
      case 'l_villa':
        tuketim = 225.0;
        break;
      case 'misafir':
        tuketim = 100.0;
        break;
      case 'otel':
        tuketim = 150.0;
        break;
      case 'hasta':
        tuketim = 200.0;
        break;
      case 'buro':
        tuketim = 80.0;
        break;
      case 'okul':
        tuketim = 20.0;
        break;
      case 'y_okul':
        tuketim = 100.0;
        break;
      case 'avm':
        tuketim = 50.0;
        break;
    }

    double esZaman = 0.25;
    if (d <= 4) {
      esZaman = 0.66;
    } else if (d <= 10) {
      esZaman = 0.45;
    } else if (d <= 20) {
      esZaman = 0.40;
    } else if (d <= 50) {
      esZaman = 0.35;
    } else if (d <= 100) {
      esZaman = 0.30;
    }

    double q = (d * 4.0 * tuketim * esZaman) / 1000.0;
    double hm = (k * 3.0) + 40.0;

    setState(() {
      _qR = '${q.toStringAsFixed(2)} ${AppLocale.t('flow_unit')}';
      _hR = '${hm.toStringAsFixed(2)} ${AppLocale.t('press_unit')}';
      _load = false;
    });

    widget.onRes?.call(q.toStringAsFixed(2), hm.toStringAsFixed(2));

    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getStringList('calculation_history') ?? [];
    h.add(jsonEncode({
      'type': AppLocale.t('hydrofor'),
      'res': '$_qR / $_hR',
      'time': DateTime.now().toString(),
      'inputs': '${AppLocale.t('units')}: ${_dCtrl.text}, ...'
    }));
    await prefs.setStringList('calculation_history', h);
  }

  double _parseDouble(String value) {
    if (value.trim().isEmpty) {
      return double.nan;
    }
    return double.tryParse(value.replaceAll(',', '.')) ?? double.nan;
  }

  void _handleTransfer() {
    if (widget.onTransferToTank == null || _hR == null) {
      return;
    }

    final systemHeight = _parseDouble(_hR!.split(' ').first);
    if (systemHeight.isNaN) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocale.t('transfer_missing'))),
      );
      return;
    }

    final flowRate = _qR != null
        ? _parseDouble(_qR!.split(' ').first)
        : double.nan;

    widget.onTransferToTank!(
      HydroforTankTransfer(
        systemHeightM: systemHeight,
        flowRateQ: flowRate.isNaN ? null : flowRate,
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocale.t('transfer_success'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  TextField(
                      controller: _dCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('units'),
                          prefixIcon: const Icon(Icons.people))),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('b_type'),
                        prefixIcon: const Icon(Icons.business)),
                    onChanged: (v) => setState(() => _type = v),
                    items: [
                      't_konut',
                      'l_konut',
                      'l_villa',
                      'misafir',
                      'otel',
                      'hasta',
                      'buro',
                      'okul',
                      'y_okul',
                      'avm'
                    ]
                        .map((e) => DropdownMenuItem(
                            value: e, child: Text(AppLocale.t(e))))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _kCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('floors'),
                          prefixIcon: const Icon(Icons.apartment))),
                  const SizedBox(height: 32),
                  ElevatedButton(
                      onPressed: _calc,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('calculate'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('clean'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]))),
        if (_load)
          const Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
        if (_qR != null && !_load) _buildResCard(),
      ]),
    );
  }

  Widget _buildResCard() {
    double qVal = double.tryParse(_qR!.split(' ')[0]) ?? 0;
    double hVal = double.tryParse(_hR!.split(' ')[0]) ?? 0;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF0052FF), width: 2),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _row(AppLocale.t('res_flow'), _qR!, Icons.water_drop_outlined),
        const Divider(height: 24),
        _row(AppLocale.t('res_press'), _hR!, Icons.speed_outlined),
        const SizedBox(height: 24),
        ResultChart(
            q: qVal,
            hm: hVal,
            isDark: Theme.of(context).brightness == Brightness.dark),
        const SizedBox(height: 20),
        if (widget.onTransferToTank != null)
          ElevatedButton(
              onPressed: _hR == null ? null : _handleTransfer,
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0052FF),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.send_to_mobile),
                  const SizedBox(width: 8),
                  Text(AppLocale.t('go_tank'))
                ],
              )),
        const SizedBox(height: 10),
        OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(AppLocale.t('share_pdf')),
            onPressed: () => PdfService.generateAndShare(
                title: AppLocale.t('hydrofor'),
                data: {
                  AppLocale.t('res_flow'): _qR!,
                  AppLocale.t('res_press'): _hR!
                }))
      ]),
    );
  }

  Widget _row(String l, String v, IconData i) => Row(children: [
        Icon(i, color: const Color(0xFF0052FF), size: 28),
        const SizedBox(width: 15),
        Expanded(
            child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                    style: Theme.of(context).textTheme.titleLarge,
                    children: [
                      TextSpan(
                          text: '$l: ',
                          style: const TextStyle(color: Colors.grey)),
                      TextSpan(
                          text: v,
                          style: const TextStyle(fontWeight: FontWeight.bold))
                    ])))
      ]);
}

class BoilerTab extends StatefulWidget {
  const BoilerTab({super.key});
  @override
  State<BoilerTab> createState() => _BoilerTabState();
}

class BoilerInstallationTab extends StatefulWidget {
  const BoilerInstallationTab({super.key});

  @override
  State<BoilerInstallationTab> createState() => _BoilerInstallationTabState();
}

class _BoilerInstallationTabState extends State<BoilerInstallationTab> {
  final List<_BoilerZoneController> _zones = [];
  BoilerInstallationResult? _result;

  final List<_BoilerZoneDefinition> _definitions = const [
    _BoilerZoneDefinition('zone_pool', 15),
    _BoilerZoneDefinition('zone_floor', 10),
    _BoilerZoneDefinition('zone_boiler', 20),
    _BoilerZoneDefinition('zone_radiator', 20),
    _BoilerZoneDefinition('zone_hamam', 10),
    _BoilerZoneDefinition('zone_air_handler', 15),
    _BoilerZoneDefinition('zone_heat_recovery', 15),
  ];

  @override
  void initState() {
    super.initState();
    for (final def in _definitions) {
      _zones.add(_BoilerZoneController(
        labelKey: def.labelKey,
        loadController: TextEditingController(),
        deltaController:
            TextEditingController(text: def.defaultDeltaT.toString()),
        defaultDeltaT: def.defaultDeltaT,
      ));
    }
  }

  @override
  void dispose() {
    for (final zone in _zones) {
      zone.loadController.dispose();
      zone.deltaController.dispose();
    }
    super.dispose();
  }

  void _calculate() {
    final inputs = <BoilerZoneInput>[];
    for (final zone in _zones) {
      final load = _parseDouble(zone.loadController.text);
      final deltaT = _parseDouble(zone.deltaController.text,
          fallback: zone.defaultDeltaT);
      if (load < 0) {
        _showError(AppLocale.t('err_negative'));
        return;
      }
      if (deltaT <= 0) {
        _showError(AppLocale.t('err_delta_t'));
        return;
      }
      inputs.add(BoilerZoneInput(
        labelKey: zone.labelKey,
        loadKcalPerHour: load,
        deltaT: deltaT,
      ));
    }

    setState(() {
      _result = BoilerInstallationCalculator.calculate(inputs);
    });
  }

  void _clear() {
    for (final zone in _zones) {
      zone.loadController.clear();
      zone.deltaController.text = zone.defaultDeltaT.toString();
    }
    setState(() => _result = null);
  }

  double _parseDouble(String value, {double fallback = 0}) {
    if (value.trim().isEmpty) {
      return fallback;
    }
    return double.tryParse(value.replaceAll(',', '.')) ?? fallback;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  for (final zone in _zones) ...[
                    _BoilerZoneInputRow(zone: zone),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocale.t('clean')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _calculate,
                          style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              backgroundColor: const Color(0xFF0052FF),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocale.t('calculate')),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _BoilerResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _BoilerZoneDefinition {
  final String labelKey;
  final double defaultDeltaT;

  const _BoilerZoneDefinition(this.labelKey, this.defaultDeltaT);
}

class _BoilerZoneController {
  final String labelKey;
  final TextEditingController loadController;
  final TextEditingController deltaController;
  final double defaultDeltaT;

  _BoilerZoneController({
    required this.labelKey,
    required this.loadController,
    required this.deltaController,
    required this.defaultDeltaT,
  });
}

class _BoilerZoneInputRow extends StatelessWidget {
  final _BoilerZoneController zone;

  const _BoilerZoneInputRow({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocale.t(zone.labelKey),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextField(
                controller: zone.loadController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocale.t('heat_load_kcal'),
                  suffixText: 'kcal/h',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: zone.deltaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocale.t('delta_t'),
                  suffixText: '°C',
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _BoilerResultCard extends StatelessWidget {
  final BoilerInstallationResult result;

  const _BoilerResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0052FF), width: 2),
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0052FF).withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _BoilerResultRow(
            label: AppLocale.t('total_heat_load'),
            value: '${result.totalLoadKcalPerHour.toStringAsFixed(0)} kcal/h',
            isMain: true,
          ),
          _BoilerResultRow(
            label: AppLocale.t('boiler_capacity_kw'),
            value: '${result.boilerCapacityKw} kW',
          ),
          _BoilerResultRow(
            label: AppLocale.t('boiler_capacity_kcal'),
            value:
                '${result.boilerCapacityKcalPerHour.toStringAsFixed(0)} kcal/h',
          ),
          const Divider(height: 24),
          for (final zone in result.zones)
            _BoilerResultRow(
              label: AppLocale.t(zone.labelKey),
              value: '${zone.flowM3PerHour.toStringAsFixed(3)} m³/h',
            ),
          const Divider(height: 24),
          _BoilerResultRow(
            label: AppLocale.t('total_flow'),
            value: '${result.totalFlowM3PerHour.toStringAsFixed(3)} m³/h',
            isMain: true,
          ),
        ],
      ),
    );
  }
}

class _BoilerResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMain;

  const _BoilerResultRow({
    required this.label,
    required this.value,
    this.isMain = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
                color: isMain ? const Color(0xFF0052FF) : null,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMain ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BoilerTabState extends State<BoilerTab> {
  final _hCtrl = TextEditingController();
  final _pCtrl = TextEditingController(text: '3');
  double? _c;
  String? _res;
  bool _load = false;
  double? _numericRes;
  bool _isError = false;

  void _clear() {
    setState(() {
      _hCtrl.clear();
      _pCtrl.clear();
      _c = null;
      _res = null;
      _numericRes = null;
      _load = false;
      _isError = false;
    });
  }

  void _calc() async {
    final n = int.tryParse(_hCtrl.text);
    final k = int.tryParse(_pCtrl.text);
    if (n == null || _c == null) return;
    setState(() {
      _load = true;
      _isError = false;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    double val = n * k! * 0.4 * 50 * 0.583 * _c!;

    if (_c == 1.0 && val < 500) {
      setState(() {
        _res = AppLocale.t('err_boiler_500');
        _numericRes = null;
        _isError = true;
        _load = false;
      });
      return;
    }

    setState(() {
      _numericRes = val;
      _res = '${val.toStringAsFixed(2)} L';
      _load = false;
    });
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getStringList('calculation_history') ?? [];
    h.add(jsonEncode({
      'type': AppLocale.t('boiler'),
      'res': _res,
      'time': DateTime.now().toString(),
      'inputs': '...'
    }));
    await prefs.setStringList('calculation_history', h);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  TextField(
                      controller: _hCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('units'),
                          prefixIcon: const Icon(Icons.house_outlined))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _pCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('people'),
                          prefixIcon: const Icon(Icons.people_outline))),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    initialValue: _c,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('coil'),
                        prefixIcon: const Icon(Icons.sync_alt)),
                    onChanged: (v) => setState(() => _c = v),
                    items: [
                      DropdownMenuItem(
                          value: 1.15, child: Text(AppLocale.t('single'))),
                      DropdownMenuItem(
                          value: 1.0, child: Text(AppLocale.t('double')))
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                      onPressed: _calc,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('calculate'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('clean'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]))),
        if (_load)
          const Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
        if (_res != null && !_load)
          Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: _isError ? Colors.red : const Color(0xFF0052FF),
                      width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: _isError ? Colors.red.withValues(alpha: 0.1) : null),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                      _isError ? Icons.error_outline : Icons.thermostat_auto,
                      color: _isError ? Colors.red : const Color(0xFF0052FF),
                      size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                      child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              style: Theme.of(context).textTheme.titleLarge,
                              children: [
                                if (!_isError)
                                  TextSpan(
                                      text: '${AppLocale.t('res_vol')}: ',
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                TextSpan(
                                    text: _res!,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isError ? Colors.red : null))
                              ])))
                ]),
                const SizedBox(height: 24),
                if (_numericRes != null && !_isError) ...[
                  BoilerChart(
                      volume: _numericRes!,
                      isDark: Theme.of(context).brightness == Brightness.dark),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(AppLocale.t('share_pdf')),
                      onPressed: () => PdfService.generateAndShare(
                          title: AppLocale.t('boiler'),
                          data: {AppLocale.t('res_vol'): _res!}))
                ]
              ]))
      ]),
    );
  }
}

class TankTab extends StatefulWidget {
  final double? initialSystemHeightM;
  final double? initialFlowQ;
  const TankTab({super.key, this.initialSystemHeightM, this.initialFlowQ});
  @override
  State<TankTab> createState() => _TankTabState();
}

class _TankTabState extends State<TankTab> {
  late TextEditingController _kwCtrl;
  late TextEditingController _hCtrl;
  final ExpansionTankCalculator _calculator = ExpansionTankCalculator();
  HeaterTypeOption? _heaterType;
  ExpansionTankResult? _result;

  @override
  void initState() {
    super.initState();
    _kwCtrl = TextEditingController();
    _hCtrl = TextEditingController(
        text: widget.initialSystemHeightM != null
            ? widget.initialSystemHeightM!.toStringAsFixed(2)
            : '');
    _heaterType = ExpansionTankCalculator.heaterTypes.first;
  }

  void _clear() {
    setState(() {
      _kwCtrl.clear();
      _hCtrl.clear();
      _heaterType = ExpansionTankCalculator.heaterTypes.first;
      _result = null;
    });
  }

  double _parseDouble(String value) {
    if (value.trim().isEmpty) {
      return double.nan;
    }
    return double.tryParse(value.replaceAll(',', '.')) ?? double.nan;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _calc() async {
    final kw = _parseDouble(_kwCtrl.text);
    final h = _parseDouble(_hCtrl.text);
    final heaterType = _heaterType;

    if (kw.isNaN || h.isNaN || heaterType == null) {
      _showError(AppLocale.t('err_tank_invalid_input'));
      return;
    }

    try {
      final result = _calculator.calculate(
        capacityKw: kw,
        systemHeightM: h,
        heaterType: heaterType,
      );
      setState(() => _result = result);

      final prefs = await SharedPreferences.getInstance();
      final hist = prefs.getStringList('calculation_history') ?? [];
      final recommendedText =
          '${result.recommendedVolume.toStringAsFixed(0)} L';
      hist.add(jsonEncode({
        'type': AppLocale.t('tank'),
        'res': recommendedText,
        'time': DateTime.now().toString(),
        'inputs':
            'kW: $kw, H: $h m, ${AppLocale.t('heat_type')}: ${AppLocale.t(heaterType.labelKey)}'
      }));
      await prefs.setStringList('calculation_history', hist);
    } on ExpansionTankCalculationException catch (e) {
      setState(() => _result = null);
      switch (e.error) {
        case ExpansionTankCalculationError.invalidInput:
          _showError(AppLocale.t('err_tank_invalid_input'));
          break;
        case ExpansionTankCalculationError.invalidPressureRange:
          _showError(AppLocale.t('err_tank_invalid_pressure'));
          break;
        case ExpansionTankCalculationError.invalidResult:
          _showError(AppLocale.t('err_tank_invalid_result'));
          break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        if (widget.initialFlowQ != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF0052FF)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${AppLocale.t('transfer_flow')}: ${widget.initialFlowQ!.toStringAsFixed(2)} ${AppLocale.t('flow_unit')}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        Card(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _kwCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: AppLocale.t('heat_cap'),
                                prefixIcon: const Icon(Icons.bolt)))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextField(
                            controller: _hCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: AppLocale.t('sys_h'),
                                prefixIcon: const Icon(Icons.height)))),
                  ]),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    initialValue: _heaterType?.coefficient,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('heat_type'),
                        prefixIcon: const Icon(Icons.whatshot)),
                    onChanged: (value) => setState(() {
                      _heaterType = ExpansionTankCalculator.heaterTypes
                          .firstWhere((type) => type.coefficient == value);
                    }),
                    items: ExpansionTankCalculator.heaterTypes
                        .map((type) => DropdownMenuItem(
                            value: type.coefficient,
                            child: Text(AppLocale.t(type.labelKey))))
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                      onPressed: _calc,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('calculate'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('clean'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]))),
        if (_result != null)
          Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0052FF), width: 2),
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                _resRow(
                    AppLocale.t('tank_required'),
                    '${_result!.requiredVolume.toStringAsFixed(1)} L',
                    isMain: true),
                _resRow(
                    AppLocale.t('tank_recommended'),
                    '${_result!.recommendedVolume.toStringAsFixed(0)} L',
                    isMain: true),
                const Divider(),
                ExpansionTile(
                  title: Text(AppLocale.t('details')),
                  children: [
                    _resRow(
                        AppLocale.t('res_water_vol'),
                        '${_result!.systemVolume.toStringAsFixed(1)} L'),
                    _resRow(
                        AppLocale.t('res_exp_vol'),
                        '${_result!.expansionVolume.toStringAsFixed(1)} L'),
                    _resRow(
                        AppLocale.t('res_reserve_vol'),
                        '${_result!.reserveVolume.toStringAsFixed(1)} L'),
                    _resRow(
                        AppLocale.t('res_safety'),
                        '${_result!.safetyValvePressure.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}'),
                    _resRow(
                        AppLocale.t('res_max_pressure'),
                        '${_result!.maxOperatingPressure.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}'),
                    _resRow(
                        AppLocale.t('res_static'),
                        '${_result!.staticPressure.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}'),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(AppLocale.t('share_pdf')),
                    onPressed: () => PdfService.generateAndShare(
                        title: AppLocale.t('tank'),
                        data: {
                          AppLocale.t('heat_cap'): _kwCtrl.text,
                          AppLocale.t('res_static'):
                              '${_result!.staticPressure.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
                          AppLocale.t('res_safety'):
                              '${_result!.safetyValvePressure.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
                          AppLocale.t('tank_required'):
                              '${_result!.requiredVolume.toStringAsFixed(1)} L',
                          AppLocale.t('tank_recommended'):
                              '${_result!.recommendedVolume.toStringAsFixed(0)} L'
                        }))
              ]))
      ]),
    );
  }

  Widget _resRow(String label, String val, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: isMain ? const Color(0xFF0052FF) : Colors.grey,
                    fontWeight: isMain ? FontWeight.w900 : FontWeight.normal,
                    fontSize: isMain ? 18 : 14)),
          ),
          const SizedBox(width: 8),
          Text(val,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: isMain ? 20 : 16)),
        ],
      ),
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> h = prefs.getStringList('calculation_history') ?? [];
    if (!mounted) return;
    setState(() {
      _history = h
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _handleDelete() async {
    if (_selectedIndices.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> keptHistory = [];

      for (int i = 0; i < _history.length; i++) {
        if (!_selectedIndices.contains(i)) {
          keptHistory.add(_history[i]);
        }
      }

      final saveList = keptHistory.reversed.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('calculation_history', saveList);

      setState(() {
        _history = keptHistory;
        _selectedIndices.clear();
      });
    } else {
      _showDeleteAllDialog();
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.t('delete_confirm_title')),
        content: Text(AppLocale.t('delete_confirm_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocale.t('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('calculation_history');
              if (mounted) {
                setState(() {
                  _history = [];
                  _selectedIndices.clear();
                });
              }
            },
            child: Text(AppLocale.t('delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _exportSelected() {
    if (_selectedIndices.isEmpty) return;
    List<Map<String, dynamic>> selectedItems = [];
    for (int index in _selectedIndices) {
      selectedItems.add(_history[index]);
    }
    PdfService.generateMultiReport(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t('history_title'), style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(
              _selectedIndices.isEmpty
                  ? Icons.delete_forever_outlined
                  : Icons.delete,
              color: _selectedIndices.isEmpty ? Colors.grey : Colors.red,
            ),
            onPressed: _handleDelete,
            tooltip: _selectedIndices.isNotEmpty
                ? 'Seçilenleri Sil'
                : 'Geçmişi Temizle',
          ),
        ],
      ),
      floatingActionButton: _selectedIndices.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: _exportSelected,
              backgroundColor: const Color(0xFF0052FF),
              icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
              label: Text(
                '${AppLocale.t('export_selected')} (${_selectedIndices.length})',
                style: const TextStyle(color: Colors.white),
              ),
            )
          : null,
      body: _history.isEmpty
          ? Center(
              child: Text(AppLocale.t('no_data'),
                  style: GoogleFonts.poppins(color: Colors.grey)))
          : ListView.builder(
              padding: const EdgeInsets.only(
                  left: 16, right: 16, top: 16, bottom: 80),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final item = _history[index];
                final dateStr = item['time'] != null
                    ? item['time']
                        .toString()
                        .substring(0, 16)
                        .replaceAll('T', ' ')
                    : '---';
                final inputs = item['inputs'] ?? '---';
                final isSelected = _selectedIndices.contains(index);

                return GestureDetector(
                  onTap: () => _toggleSelection(index),
                  child: Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    color: isSelected
                        ? const Color(0xFF0052FF).withValues(alpha: 0.08)
                        : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? const Color(0xFF0052FF)
                            : Colors.grey.withValues(alpha: 0.2),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(item['type'] ?? 'Hesap',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0052FF))),
                              ),
                              Row(
                                children: [
                                  Text(dateStr,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.grey)),
                                  const SizedBox(width: 8),
                                  Transform.scale(
                                    scale: 1.2,
                                    child: Checkbox(
                                      value: isSelected,
                                      activeColor: const Color(0xFF0052FF),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4)),
                                      onChanged: (v) =>
                                          _toggleSelection(index),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Text('${AppLocale.t('inputs')}:',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          Text(inputs,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 12),
                          Text('${AppLocale.t('results')}:',
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[600])),
                          Text(item['res'] ?? '---',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
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
