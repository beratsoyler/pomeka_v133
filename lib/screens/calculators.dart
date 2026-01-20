import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../kazan_tesisat_calculator.dart';
import '../localization/app_locale.dart';
import '../models/calculation_history_record.dart';
import '../models/formula_transfer_data.dart';
import '../services/calculation_history_service.dart';
import '../services/fan_coil_calculator.dart';
import '../services/pdf_report_service.dart';
import '../services/pump_expansion_calculator.dart';
import '../state/app_state.dart';
import '../widgets/focus_label_text_field.dart';
import '../widgets/readable_text.dart';
import '../widgets/tappable_label.dart';
// ---------------------------------------------------------------------------
// 1. CHART WIDGETS
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
                    child: FocusLabelTextField(
                      controller: _inputCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      onChanged: (_) => _calculate(),
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      labelText: AppLocale.t('val_input'),
                    ),
                  ),
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

Map<String, dynamic> buildTransferFromHydrofor({
  required double? flowM3h,
  required double? headMeter,
}) {
  final data = <String, dynamic>{};
  if (flowM3h != null && flowM3h.isFinite) {
    data['flow_m3h'] = flowM3h;
  }
  if (headMeter != null && headMeter.isFinite) {
    data['head_m'] = headMeter;
  }
  return data;
}

bool applyTransferToPumpTankForm({
  required FormulaTransferData transferData,
  required TextEditingController capacityController,
  required TextEditingController systemHeightController,
}) {
  if (transferData.targetFormulaId != 'tank') {
    return false;
  }
  final data = transferData.data;
  var applied = false;

  final flow = data['flow_m3h'];
  if (flow is num && flow.isFinite) {
    capacityController.text = flow.toStringAsFixed(2);
    applied = true;
  }

  final head = data['head_m'];
  if (head is num && head.isFinite) {
    systemHeightController.text = head.toStringAsFixed(2);
    applied = true;
  }

  return applied;
}

class HydroforTab extends StatefulWidget {
  final Function(String, String)? onRes;
  final void Function(FormulaTransferData)? toTank;
  const HydroforTab({super.key, this.onRes, this.toTank});
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

    final createdAt = DateTime.now();
    await CalculationHistoryService.append(
      CalculationHistoryRecord(
        id: createdAt.microsecondsSinceEpoch.toString(),
        formulaId: 'hydrofor',
        formulaName: AppLocale.t('hydrofor'),
        createdAt: createdAt,
        inputs: {
          AppLocale.t('units'): _dCtrl.text,
          AppLocale.t('b_type'): AppLocale.t(_type ?? 't_konut'),
          AppLocale.t('floors'): _kCtrl.text,
        },
        outputs: {
          AppLocale.t('res_flow'): _qR ?? '-',
          AppLocale.t('res_press'): _hR ?? '-',
        },
      ),
    );
  }

  void _handleTransfer() {
    final canTransfer = _qR != null && _hR != null && !_load;
    if (!canTransfer) {
      _showInfo(AppLocale.t('transfer_requires_calc'));
      return;
    }
    final qVal = double.tryParse(_qR!.split(' ')[0]);
    final hVal = double.tryParse(_hR!.split(' ')[0]);
    final data = buildTransferFromHydrofor(flowM3h: qVal, headMeter: hVal);
    if (data.isEmpty) {
      _showInfo(AppLocale.t('transfer_requires_calc'));
      return;
    }
    final transfer = FormulaTransferData(
      sourceFormulaId: 'hydrofor',
      targetFormulaId: 'tank',
      createdAt: DateTime.now(),
      data: data,
    );
    widget.toTank?.call(transfer);
  }

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
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
                  FocusLabelTextField(
                    controller: _dCtrl,
                    keyboardType: TextInputType.number,
                    labelText: AppLocale.t('units'),
                    prefixIcon: const Icon(Icons.people),
                  ),
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
                  FocusLabelTextField(
                    controller: _kCtrl,
                    keyboardType: TextInputType.number,
                    labelText: AppLocale.t('floors'),
                    prefixIcon: const Icon(Icons.apartment),
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
                      child: ReadableText(
                        text: AppLocale.t('calculate'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: ReadableText(
                        text: AppLocale.t('clean'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
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
        const SizedBox(height: 10),
        OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: ReadableText(text: AppLocale.t('share_pdf')),
            onPressed: () => PdfReportService.generateSingleReport(
                  formulaName: AppLocale.t('hydrofor'),
                  inputs: {
                    AppLocale.t('units'): _dCtrl.text,
                    AppLocale.t('b_type'): AppLocale.t(_type ?? 't_konut'),
                    AppLocale.t('floors'): _kCtrl.text,
                  },
                  outputs: {
                    AppLocale.t('res_flow'): _qR ?? '-',
                    AppLocale.t('res_press'): _hR ?? '-',
                  },
                ))
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
                          child: ReadableText(text: AppLocale.t('clean')),
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
                          child: ReadableText(text: AppLocale.t('calculate')),
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
        ReadableText(
          text: AppLocale.t(zone.labelKey),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: FocusLabelTextField(
                controller: zone.loadController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                labelText: AppLocale.t('heat_load_kcal'),
                suffixText: 'kcal/h',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FocusLabelTextField(
                controller: zone.deltaController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                labelText: AppLocale.t('delta_t'),
                suffixText: '°C',
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
            child: ReadableText(
              text: label,
              style: TextStyle(
                fontWeight: isMain ? FontWeight.bold : FontWeight.w500,
                color: isMain ? const Color(0xFF0052FF) : null,
              ),
            ),
          ),
          Flexible(
            child: ReadableText(
              text: value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: isMain ? 16 : 14,
              ),
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
    final createdAt = DateTime.now();
    await CalculationHistoryService.append(
      CalculationHistoryRecord(
        id: createdAt.microsecondsSinceEpoch.toString(),
        formulaId: 'boiler_installation',
        formulaName: AppLocale.t('boiler'),
        createdAt: createdAt,
        inputs: {
          AppLocale.t('units'): _hCtrl.text,
          AppLocale.t('people'): _pCtrl.text,
          AppLocale.t('coil'): _c == 1.0
              ? AppLocale.t('double')
              : AppLocale.t('single'),
        },
        outputs: {
          AppLocale.t('res_vol'): _res ?? '-',
        },
      ),
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
                  FocusLabelTextField(
                    controller: _hCtrl,
                    keyboardType: TextInputType.number,
                    labelText: AppLocale.t('units'),
                    prefixIcon: const Icon(Icons.house_outlined),
                  ),
                  const SizedBox(height: 16),
                  FocusLabelTextField(
                    controller: _pCtrl,
                    keyboardType: TextInputType.number,
                    labelText: AppLocale.t('people'),
                    prefixIcon: const Icon(Icons.people_outline),
                  ),
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
                      child: ReadableText(
                        text: AppLocale.t('calculate'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: ReadableText(
                        text: AppLocale.t('clean'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
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
                      label: ReadableText(text: AppLocale.t('share_pdf')),
                      onPressed: () => PdfReportService.generateSingleReport(
                            formulaName: AppLocale.t('boiler'),
                            inputs: {
                              AppLocale.t('units'): _hCtrl.text,
                              AppLocale.t('people'): _pCtrl.text,
                              AppLocale.t('coil'): _c == 1.0
                                  ? AppLocale.t('double')
                                  : AppLocale.t('single'),
                            },
                            outputs: {AppLocale.t('res_vol'): _res ?? '-'},
                          ))
                ]
              ]))
      ]),
    );
  }
}

class TankTab extends StatefulWidget {
  final String? q, h;
  const TankTab({super.key, this.q, this.h});
  @override
  State<TankTab> createState() => _TankTabState();
}

class _TankTabState extends State<TankTab> {
  late TextEditingController _kwCtrl;
  late TextEditingController _widthCtrl;
  late TextEditingController _lengthCtrl;
  late TextEditingController _heightCtrl;
  final PumpExpansionCalculator _calculator = PumpExpansionCalculator();
  PumpExpansionHeatingType? _heatingType;
  PumpExpansionResult? _result;
  bool _transferApplied = false;

  @override
  void initState() {
    super.initState();
    _kwCtrl = TextEditingController(text: widget.q);
    _widthCtrl = TextEditingController();
    _lengthCtrl = TextEditingController();
    _heightCtrl = TextEditingController(text: widget.h ?? '');
    _heatingType = PumpExpansionCalculator.heatingTypes.first;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_transferApplied) {
      return;
    }
    final transfer =
        AppStateScope.of(context).consumeTransfer(targetFormulaId: 'tank');
    if (transfer == null) {
      return;
    }
    final applied = applyTransferToPumpTankForm(
      transferData: transfer,
      capacityController: _kwCtrl,
      systemHeightController: _heightCtrl,
    );
    if (applied) {
      setState(() {
        _result = null;
      });
    }
    _transferApplied = true;
  }

  void _clear() {
    setState(() {
      _kwCtrl.clear();
      _widthCtrl.clear();
      _lengthCtrl.clear();
      _heightCtrl.clear();
      _heatingType = PumpExpansionCalculator.heatingTypes.first;
      _result = null;
    });
    AppStateScope.of(context).clearTransfer();
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
    final width = _parseDouble(_widthCtrl.text);
    final length = _parseDouble(_lengthCtrl.text);
    final height = _parseDouble(_heightCtrl.text);
    final heatingType = _heatingType;

    if (kw.isNaN ||
        width.isNaN ||
        length.isNaN ||
        height.isNaN ||
        heatingType == null) {
      _showError(AppLocale.t('err_tank_invalid_input'));
      return;
    }

    try {
      final result = _calculator.calculate(
        capacityKw: kw,
        buildingWidthM: width,
        buildingLengthM: length,
        systemHeightM: height,
        heatingType: heatingType,
      );
      setState(() => _result = result);

      final createdAt = DateTime.now();
      await CalculationHistoryService.append(
        CalculationHistoryRecord(
          id: createdAt.microsecondsSinceEpoch.toString(),
          formulaId: 'tank',
          formulaName: AppLocale.t('tank'),
          createdAt: createdAt,
          inputs: {
            AppLocale.t('heat_cap'): _kwCtrl.text,
            AppLocale.t('building_width'): _widthCtrl.text,
            AppLocale.t('building_length'): _lengthCtrl.text,
            AppLocale.t('sys_h'): _heightCtrl.text,
            AppLocale.t('heat_type'): AppLocale.t(heatingType.labelKey),
          },
          outputs: {
            AppLocale.t('res_flow'):
                '${result.flowM3PerHour.toStringAsFixed(2)} ${AppLocale.t('flow_unit')}',
            AppLocale.t('res_press'):
                '${result.headMeter.toStringAsFixed(2)} ${AppLocale.t('press_unit')}',
            AppLocale.t('tank_vol'):
                '${result.tankVolumeLiter.toStringAsFixed(0)} L',
            AppLocale.t('res_opening'):
                '${result.openingPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
            AppLocale.t('res_safety'):
                '${result.safetyPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
            AppLocale.t('res_static'):
                '${result.staticPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
          },
        ),
      );
    } on PumpExpansionCalculationException catch (e) {
      setState(() => _result = null);
      switch (e.error) {
        case PumpExpansionCalculationError.invalidInput:
          _showError(AppLocale.t('err_tank_invalid_input'));
          break;
        case PumpExpansionCalculationError.heightTooHigh:
          _showError(AppLocale.t('err_tank_height'));
          break;
        case PumpExpansionCalculationError.invalidPressureRange:
          _showError(AppLocale.t('err_tank_invalid_pressure'));
          break;
        case PumpExpansionCalculationError.invalidResult:
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
        Card(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: FocusLabelTextField(
                        controller: _kwCtrl,
                        keyboardType: TextInputType.number,
                        labelText: AppLocale.t('heat_cap'),
                        prefixIcon: const Icon(Icons.bolt),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FocusLabelTextField(
                        controller: _heightCtrl,
                        keyboardType: TextInputType.number,
                        labelText: AppLocale.t('sys_h'),
                        prefixIcon: const Icon(Icons.height),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                      child: FocusLabelTextField(
                        controller: _widthCtrl,
                        keyboardType: TextInputType.number,
                        labelText: AppLocale.t('building_width'),
                        prefixIcon: const Icon(Icons.swap_horiz_outlined),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FocusLabelTextField(
                        controller: _lengthCtrl,
                        keyboardType: TextInputType.number,
                        labelText: AppLocale.t('building_length'),
                        prefixIcon: const Icon(Icons.swap_vert_outlined),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    initialValue: _heatingType?.volumeCoefficient,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('heat_type'),
                        prefixIcon: const Icon(Icons.whatshot)),
                    onChanged: (value) => setState(() {
                      _heatingType = PumpExpansionCalculator.heatingTypes
                          .firstWhere((type) => type.volumeCoefficient == value);
                    }),
                    items: PumpExpansionCalculator.heatingTypes
                        .map((type) => DropdownMenuItem(
                            value: type.volumeCoefficient,
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
                      child: ReadableText(
                        text: AppLocale.t('calculate'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: ReadableText(
                        text: AppLocale.t('clean'),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      )),
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
                    AppLocale.t('res_flow'),
                    '${_result!.flowM3PerHour.toStringAsFixed(2)} ${AppLocale.t('flow_unit')}',
                    isMain: true),
                _resRow(
                    AppLocale.t('res_press'),
                    '${_result!.headMeter.toStringAsFixed(2)} ${AppLocale.t('press_unit')}',
                    isMain: true),
                _resRow(
                    AppLocale.t('tank_vol'),
                    '${_result!.tankVolumeLiter.toStringAsFixed(0)} L',
                    isMain: true),
                const Divider(),
                ExpansionTile(
                  title: ReadableText(text: AppLocale.t('details')),
                  children: [
                    _resRow(
                        AppLocale.t('res_opening'),
                        '${_result!.openingPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}'),
                    _resRow(
                        AppLocale.t('res_safety'),
                        '${_result!.safetyPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}'),
                    _resRow(
                        AppLocale.t('res_static'),
                        '${_result!.staticPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}'),
                    const SizedBox(height: 8),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: ReadableText(text: AppLocale.t('share_pdf')),
                    onPressed: () => PdfReportService.generateSingleReport(
                          formulaName: AppLocale.t('tank'),
                          inputs: {
                            AppLocale.t('heat_cap'): _kwCtrl.text,
                            AppLocale.t('building_width'): _widthCtrl.text,
                            AppLocale.t('building_length'): _lengthCtrl.text,
                            AppLocale.t('sys_h'): _heightCtrl.text,
                            AppLocale.t('heat_type'):
                                _heatingType == null
                                    ? '-'
                                    : AppLocale.t(_heatingType!.labelKey),
                          },
                          outputs: {
                            AppLocale.t('res_flow'):
                                '${_result!.flowM3PerHour.toStringAsFixed(2)} ${AppLocale.t('flow_unit')}',
                            AppLocale.t('res_press'):
                                '${_result!.headMeter.toStringAsFixed(2)} ${AppLocale.t('press_unit')}',
                            AppLocale.t('tank_vol'):
                                '${_result!.tankVolumeLiter.toStringAsFixed(0)} L',
                            AppLocale.t('res_opening'):
                                '${_result!.openingPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
                            AppLocale.t('res_safety'):
                                '${_result!.safetyPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
                            AppLocale.t('res_static'):
                                '${_result!.staticPressureBar.toStringAsFixed(1)} ${AppLocale.t('bar_unit')}',
                          },
                        ))
              ]))
      ]),
    );
  }

  Widget _resRow(String label, String val, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: ReadableText(
              text: label,
              style: TextStyle(
                  color: isMain ? const Color(0xFF0052FF) : Colors.grey,
                  fontWeight: isMain ? FontWeight.w900 : FontWeight.normal,
                  fontSize: isMain ? 18 : 14),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: ReadableText(
              text: val,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: isMain ? 20 : 16),
            ),
          ),
        ],
      ),
    );
  }
}

class FanCoilTab extends StatefulWidget {
  const FanCoilTab({super.key});

  @override
  State<FanCoilTab> createState() => _FanCoilTabState();
}

class _FanCoilTabState extends State<FanCoilTab> {
  final TextEditingController _areaCtrl = TextEditingController();
  FanCoilPipeType _pipeType = FanCoilPipeType.twoPipe;
  FanCoilUsageType _usageType = FanCoilUsageType.office;
  FanCoilCalculationMode _calcMode = FanCoilCalculationMode.cooling;
  FanCoilResult? _result;

  @override
  void dispose() {
    _areaCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _areaCtrl.clear();
      _pipeType = FanCoilPipeType.twoPipe;
      _usageType = FanCoilUsageType.office;
      _calcMode = FanCoilCalculationMode.cooling;
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

  void _onPipeTypeChanged(FanCoilPipeType? value) {
    if (value == null) return;
    final wasBoth = _calcMode == FanCoilCalculationMode.both;
    setState(() {
      _pipeType = value;
      if (_pipeType == FanCoilPipeType.twoPipe &&
          _calcMode == FanCoilCalculationMode.both) {
        _calcMode = FanCoilCalculationMode.cooling;
      }
    });
    if (value == FanCoilPipeType.twoPipe && wasBoth) {
      _showError(AppLocale.t('fan_coil_two_pipe_warning'));
    }
  }

  Future<void> _calculate() async {
    final area = _parseDouble(_areaCtrl.text);
    if (area.isNaN) {
      _showError(AppLocale.t('err_invalid_number'));
      return;
    }
    if (area <= 0) {
      _showError(AppLocale.t('err_area_positive'));
      return;
    }

    final result = FanCoilCalculator.compute(
      areaM2: area,
      usageType: _usageType,
    );

    setState(() => _result = result);

    final createdAt = DateTime.now();
    final outputs = <String, dynamic>{};
    for (final row in _resultRows(result)) {
      outputs[row.label] = row.value;
    }
    outputs[AppLocale.t('fan_coil_unit_loads')] =
        'qc=${result.qc.toStringAsFixed(0)} W/m², qh=${result.qh.toStringAsFixed(0)} W/m²';
    await CalculationHistoryService.append(
      CalculationHistoryRecord(
        id: createdAt.microsecondsSinceEpoch.toString(),
        formulaId: 'fan_coil',
        formulaName: AppLocale.t('fan_coil'),
        createdAt: createdAt,
        inputs: {
          AppLocale.t('fan_coil_pipe_type'): _pipeTypeLabel(_pipeType),
          AppLocale.t('fan_coil_area'): '${area.toStringAsFixed(2)} m²',
          AppLocale.t('fan_coil_usage_type'): _usageTypeLabel(_usageType),
          AppLocale.t('fan_coil_calc_type'): _calcModeLabel(_calcMode),
        },
        outputs: outputs,
      ),
    );
  }

  String _formatResultSummary(FanCoilResult result) {
    switch (_calcMode) {
      case FanCoilCalculationMode.cooling:
        return '${AppLocale.t('fan_coil_cooling_capacity')}: ${result.qCoolKw.toStringAsFixed(2)} kW';
      case FanCoilCalculationMode.heating:
        return '${AppLocale.t('fan_coil_heating_capacity')}: ${result.qHeatKw.toStringAsFixed(2)} kW';
      case FanCoilCalculationMode.both:
        return '${AppLocale.t('fan_coil_cooling_capacity')}: ${result.qCoolKw.toStringAsFixed(2)} kW / ${AppLocale.t('fan_coil_heating_capacity')}: ${result.qHeatKw.toStringAsFixed(2)} kW';
    }
  }

  String _pipeTypeLabel(FanCoilPipeType type) {
    switch (type) {
      case FanCoilPipeType.twoPipe:
        return AppLocale.t('fan_coil_two_pipe');
      case FanCoilPipeType.fourPipe:
        return AppLocale.t('fan_coil_four_pipe');
    }
  }

  String _usageTypeLabel(FanCoilUsageType type) {
    switch (type) {
      case FanCoilUsageType.insulatedResidential:
        return AppLocale.t('fan_coil_usage_insulated');
      case FanCoilUsageType.midInsulatedResidential:
        return AppLocale.t('fan_coil_usage_mid_insulated');
      case FanCoilUsageType.office:
        return AppLocale.t('fan_coil_usage_office');
      case FanCoilUsageType.shopShowcase:
        return AppLocale.t('fan_coil_usage_shop_showcase');
    }
  }

  String _calcModeLabel(FanCoilCalculationMode mode) {
    switch (mode) {
      case FanCoilCalculationMode.cooling:
        return AppLocale.t('fan_coil_calc_cooling');
      case FanCoilCalculationMode.heating:
        return AppLocale.t('fan_coil_calc_heating');
      case FanCoilCalculationMode.both:
        return AppLocale.t('fan_coil_calc_both');
    }
  }

  List<FanCoilCalculationMode> _availableModes() {
    if (_pipeType == FanCoilPipeType.twoPipe) {
      return const [
        FanCoilCalculationMode.cooling,
        FanCoilCalculationMode.heating
      ];
    }
    return const [
      FanCoilCalculationMode.cooling,
      FanCoilCalculationMode.heating,
      FanCoilCalculationMode.both
    ];
  }

  List<_ResultRow> _resultRows(FanCoilResult result) {
    final rows = <_ResultRow>[];
    if (_calcMode == FanCoilCalculationMode.cooling ||
        _calcMode == FanCoilCalculationMode.both) {
      rows.add(_ResultRow(
        label: AppLocale.t('fan_coil_cooling_capacity'),
        value: '${result.qCoolKw.toStringAsFixed(2)} kW',
      ));
    }
    if (_calcMode == FanCoilCalculationMode.heating ||
        _calcMode == FanCoilCalculationMode.both) {
      rows.add(_ResultRow(
        label: AppLocale.t('fan_coil_heating_capacity'),
        value: '${result.qHeatKw.toStringAsFixed(2)} kW',
      ));
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    ReadableText(
                      text: AppLocale.t('fan_coil_desc'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FanCoilPipeType>(
                      value: _pipeType,
                      decoration: InputDecoration(
                        label: TappableLabel(
                            text: AppLocale.t('fan_coil_pipe_type')),
                        prefixIcon: const Icon(Icons.commit),
                      ),
                      onChanged: _onPipeTypeChanged,
                      items: FanCoilPipeType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_pipeTypeLabel(type)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    FocusLabelTextField(
                      controller: _areaCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      labelText: AppLocale.t('fan_coil_area'),
                      labelWidget:
                          TappableLabel(text: AppLocale.t('fan_coil_area')),
                      prefixIcon: const Icon(Icons.square_foot),
                      suffixText: 'm²',
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FanCoilUsageType>(
                      value: _usageType,
                      decoration: InputDecoration(
                        label: TappableLabel(
                            text: AppLocale.t('fan_coil_usage_type')),
                        prefixIcon: const Icon(Icons.home_work),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _usageType = value);
                      },
                      items: FanCoilUsageType.values
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(_usageTypeLabel(type)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<FanCoilCalculationMode>(
                      value: _calcMode,
                      decoration: InputDecoration(
                        label: TappableLabel(
                            text: AppLocale.t('fan_coil_calc_type')),
                        prefixIcon: const Icon(Icons.tune),
                      ),
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _calcMode = value);
                      },
                      items: _availableModes()
                          .map((mode) => DropdownMenuItem(
                                value: mode,
                                child: Text(_calcModeLabel(mode)),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clear,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 52),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: ReadableText(text: AppLocale.t('clean')),
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
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: ReadableText(text: AppLocale.t('calculate')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (result != null) ...[
              const SizedBox(height: 20),
              _ResultCard(rows: _resultRows(result)),
              const SizedBox(height: 12),
              ReadableText(
                text:
                    '${AppLocale.t('fan_coil_unit_loads')}: qc=${result.qc.toStringAsFixed(0)} W/m², qh=${result.qh.toStringAsFixed(0)} W/m²',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.picture_as_pdf),
                label: ReadableText(text: AppLocale.t('share_pdf')),
                onPressed: () {
                  final outputs = <String, dynamic>{};
                  for (final row in _resultRows(result)) {
                    outputs[row.label] = row.value;
                  }
                  outputs[AppLocale.t('fan_coil_unit_loads')] =
                      'qc=${result.qc.toStringAsFixed(0)} W/m², qh=${result.qh.toStringAsFixed(0)} W/m²';
                  PdfReportService.generateSingleReport(
                    formulaName: AppLocale.t('fan_coil'),
                    inputs: {
                      AppLocale.t('fan_coil_pipe_type'):
                          _pipeTypeLabel(_pipeType),
                      AppLocale.t('fan_coil_area'):
                          '${_areaCtrl.text} m²',
                      AppLocale.t('fan_coil_usage_type'):
                          _usageTypeLabel(_usageType),
                      AppLocale.t('fan_coil_calc_type'):
                          _calcModeLabel(_calcMode),
                    },
                    outputs: outputs,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum FanCoilPipeType {
  twoPipe,
  fourPipe,
}

enum FanCoilCalculationMode {
  cooling,
  heating,
  both,
}

class RecirculationPumpTab extends StatefulWidget {
  const RecirculationPumpTab({super.key});

  @override
  State<RecirculationPumpTab> createState() => _RecirculationPumpTabState();
}

class _RecirculationPumpTabState extends State<RecirculationPumpTab> {
  final TextEditingController _lbCtrl = TextEditingController();
  final TextEditingController _loCtrl = TextEditingController();
  double? _heatLossW;
  double? _flowLh;
  double? _flowM3h;

  @override
  void dispose() {
    _lbCtrl.dispose();
    _loCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _lbCtrl.clear();
      _loCtrl.clear();
      _heatLossW = null;
      _flowLh = null;
      _flowM3h = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double? _readInput(TextEditingController controller, String labelKey) {
    final label = AppLocale.t(labelKey);
    final text = controller.text.trim();
    if (text.isEmpty) {
      _showError('$label ${AppLocale.t('err_required')}');
      return null;
    }
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) {
      _showError('$label: ${AppLocale.t('err_invalid_number')}');
      return null;
    }
    if (value < 0) {
      _showError('$label: ${AppLocale.t('err_negative')}');
      return null;
    }
    return value;
  }

  Future<void> _calculate() async {
    // Test: Lb=120, Lo=80 => Qw=1880 W; Debi=783.33 L/h; Debi=0.78 m³/h
    final lb = _readInput(_lbCtrl, 'recirc_lb');
    if (lb == null) return;
    final lo = _readInput(_loCtrl, 'recirc_lo');
    if (lo == null) return;

    final heatLossW = (lb * 11) + (lo * 7);
    final flowLh = heatLossW / 2.4;
    final flowM3h = flowLh / 1000;

    setState(() {
      _heatLossW = heatLossW;
      _flowLh = flowLh;
      _flowM3h = flowM3h;
    });

    final createdAt = DateTime.now();
    await CalculationHistoryService.append(
      CalculationHistoryRecord(
        id: createdAt.microsecondsSinceEpoch.toString(),
        formulaId: 'recirculation_pump',
        formulaName: AppLocale.t('recirculation_pump'),
        createdAt: createdAt,
        inputs: {
          AppLocale.t('recirc_lb'): '${lb.toStringAsFixed(2)} m',
          AppLocale.t('recirc_lo'): '${lo.toStringAsFixed(2)} m',
        },
        outputs: {
          AppLocale.t('recirc_heat_loss'):
              '${heatLossW.toStringAsFixed(2)} W',
          AppLocale.t('recirc_required_flow_lh'):
              '${flowLh.toStringAsFixed(2)} L/h',
          AppLocale.t('recirc_required_flow_m3h'):
              '${flowM3h.toStringAsFixed(2)} m³/h',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultVisible =
        _heatLossW != null && _flowLh != null && _flowM3h != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  FocusLabelTextField(
                    controller: _lbCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    labelText: AppLocale.t('recirc_lb'),
                    labelWidget:
                        TappableLabel(text: AppLocale.t('recirc_lb')),
                    prefixIcon: const Icon(Icons.straighten),
                    suffixText: 'm',
                  ),
                  const SizedBox(height: 16),
                  FocusLabelTextField(
                    controller: _loCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    labelText: AppLocale.t('recirc_lo'),
                    labelWidget:
                        TappableLabel(text: AppLocale.t('recirc_lo')),
                    prefixIcon: const Icon(Icons.timeline),
                    suffixText: 'm',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ReadableText(text: AppLocale.t('clean')),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ReadableText(text: AppLocale.t('calculate')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (resultVisible) ...[
            const SizedBox(height: 20),
            _ResultCard(
              rows: [
                _ResultRow(
                  label: AppLocale.t('recirc_heat_loss'),
                  value: '${_heatLossW!.toStringAsFixed(2)} W',
                ),
                _ResultRow(
                  label: AppLocale.t('recirc_required_flow_lh'),
                  value: '${_flowLh!.toStringAsFixed(2)} L/h',
                ),
                _ResultRow(
                  label: AppLocale.t('recirc_required_flow_m3h'),
                  value: '${_flowM3h!.toStringAsFixed(2)} m³/h',
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: ReadableText(text: AppLocale.t('share_pdf')),
              onPressed: () => PdfReportService.generateSingleReport(
                formulaName: AppLocale.t('recirculation_pump'),
                inputs: {
                  AppLocale.t('recirc_lb'): '${_lbCtrl.text} m',
                  AppLocale.t('recirc_lo'): '${_loCtrl.text} m',
                },
                outputs: {
                  AppLocale.t('recirc_heat_loss'):
                      '${_heatLossW!.toStringAsFixed(2)} W',
                  AppLocale.t('recirc_required_flow_lh'):
                      '${_flowLh!.toStringAsFixed(2)} L/h',
                  AppLocale.t('recirc_required_flow_m3h'):
                      '${_flowM3h!.toStringAsFixed(2)} m³/h',
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CirculationPumpTab extends StatefulWidget {
  const CirculationPumpTab({super.key});

  @override
  State<CirculationPumpTab> createState() => _CirculationPumpTabState();
}

class _CirculationPumpTabState extends State<CirculationPumpTab> {
  static const double _kwToKcalH = 859.85;
  static const double _xRadiator = 20000;
  static const double _xFloor = 10000;
  static const double _safety = 1.10;
  static const double _headCoeff = 0.05;

  final TextEditingController _capacityCtrl = TextEditingController();
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();

  late _CapacityUnit _capacityUnit;
  late _CirculationSystemOption _systemOption;
  bool _applySafety = true;

  double? _flow;
  double? _flowSafe;
  double? _head;
  double? _headSafe;
  double? _selectedX;

  final List<_CapacityUnit> _capacityUnits = const [
    _CapacityUnit(labelKey: 'circulation_unit_kw', isKw: true),
    _CapacityUnit(labelKey: 'circulation_unit_kcalh', isKw: false),
  ];

  final List<_CirculationSystemOption> _systemOptions = const [
    _CirculationSystemOption(
      labelKey: 'circulation_system_radiator',
      xValue: _xRadiator,
    ),
    _CirculationSystemOption(
      labelKey: 'circulation_system_floor',
      xValue: _xFloor,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _capacityUnit = _capacityUnits.first;
    _systemOption = _systemOptions.first;
  }

  @override
  void dispose() {
    _capacityCtrl.dispose();
    _lengthCtrl.dispose();
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _capacityCtrl.clear();
      _lengthCtrl.clear();
      _widthCtrl.clear();
      _heightCtrl.clear();
      _capacityUnit = _capacityUnits.first;
      _systemOption = _systemOptions.first;
      _applySafety = true;
      _flow = null;
      _flowSafe = null;
      _head = null;
      _headSafe = null;
      _selectedX = null;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double? _readCapacity() {
    final label = AppLocale.t('circulation_capacity');
    final text = _capacityCtrl.text.trim();
    if (text.isEmpty) {
      _showMessage('$label ${AppLocale.t('err_required')}');
      return null;
    }
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) {
      _showMessage('$label: ${AppLocale.t('err_invalid_number')}');
      return null;
    }
    if (value <= 0) {
      _showMessage(AppLocale.t('err_capacity_positive'));
      return null;
    }
    return value;
  }

  double? _readDimension(TextEditingController controller, String labelKey) {
    final label = AppLocale.t(labelKey);
    final text = controller.text.trim();
    if (text.isEmpty) {
      _showMessage('$label ${AppLocale.t('err_required')}');
      return null;
    }
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) {
      _showMessage('$label: ${AppLocale.t('err_invalid_number')}');
      return null;
    }
    if (value < 0) {
      _showMessage('$label: ${AppLocale.t('err_negative')}');
      return null;
    }
    return value;
  }

  Future<void> _calculate() async {
    final capacity = _readCapacity();
    if (capacity == null) return;
    final length = _readDimension(_lengthCtrl, 'circulation_length');
    if (length == null) return;
    final width = _readDimension(_widthCtrl, 'circulation_width');
    if (width == null) return;
    final height = _readDimension(_heightCtrl, 'circulation_height');
    if (height == null) return;

    final capKcalH =
        _capacityUnit.isKw ? capacity * _kwToKcalH : capacity;
    final selectedX = _systemOption.xValue;
    final flow = capKcalH / selectedX;
    final head = (length + width + height) * _headCoeff;
    final flowSafe = _applySafety ? flow * _safety : null;
    final headSafe = _applySafety ? head * _safety : null;

    if (length == 0 && width == 0 && height == 0) {
      _showMessage(AppLocale.t('circulation_dimensions_required'));
    } else if (length > 1000 || width > 1000 || height > 1000) {
      _showMessage(AppLocale.t('circulation_dimensions_warning'));
    }

    setState(() {
      _flow = flow;
      _flowSafe = flowSafe;
      _head = head;
      _headSafe = headSafe;
      _selectedX = selectedX;
    });

    final createdAt = DateTime.now();
    final outputs = <String, dynamic>{
      AppLocale.t('circulation_flow'): '${flow.toStringAsFixed(3)} m³/h',
      AppLocale.t('circulation_head'): '${head.toStringAsFixed(3)} mSS',
      AppLocale.t('circulation_selected_x'):
          '${selectedX.toStringAsFixed(0)} (${AppLocale.t(_systemOption.labelKey)})',
    };
    if (_applySafety && flowSafe != null && headSafe != null) {
      outputs[AppLocale.t('circulation_flow_safe')] =
          '${flowSafe.toStringAsFixed(3)} m³/h';
      outputs[AppLocale.t('circulation_head_safe')] =
          '${headSafe.toStringAsFixed(3)} mSS';
    }
    await CalculationHistoryService.append(
      CalculationHistoryRecord(
        id: createdAt.microsecondsSinceEpoch.toString(),
        formulaId: 'circulation_pump',
        formulaName: AppLocale.t('circulation_pump'),
        createdAt: createdAt,
        inputs: {
          AppLocale.t('circulation_capacity'):
              '${capacity.toStringAsFixed(2)} ${AppLocale.t(_capacityUnit.labelKey)}',
          AppLocale.t('circulation_system_type'):
              AppLocale.t(_systemOption.labelKey),
          AppLocale.t('circulation_length'): '${length.toStringAsFixed(2)} m',
          AppLocale.t('circulation_width'): '${width.toStringAsFixed(2)} m',
          AppLocale.t('circulation_height'): '${height.toStringAsFixed(2)} m',
          AppLocale.t('circulation_safety'):
              _applySafety ? 'On' : 'Off',
        },
        outputs: outputs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultVisible = _flow != null && _head != null && _selectedX != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ReadableText(
                    text: AppLocale.t('circulation_pump_desc'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: FocusLabelTextField(
                          controller: _capacityCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          labelText: AppLocale.t('circulation_capacity'),
                          labelWidget: TappableLabel(
                            text: AppLocale.t('circulation_capacity'),
                          ),
                          prefixIcon: const Icon(Icons.bolt),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<_CapacityUnit>(
                          value: _capacityUnit,
                          decoration: InputDecoration(
                            label: TappableLabel(
                              text: AppLocale.t('circulation_capacity_unit'),
                            ),
                            prefixIcon: const Icon(Icons.straighten),
                          ),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _capacityUnit = value);
                          },
                          items: _capacityUnits
                              .map((unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(AppLocale.t(unit.labelKey)),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<_CirculationSystemOption>(
                    value: _systemOption,
                    decoration: InputDecoration(
                      label:
                          TappableLabel(text: AppLocale.t('circulation_system_type')),
                      prefixIcon: const Icon(Icons.thermostat),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _systemOption = value);
                    },
                    items: _systemOptions
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(AppLocale.t(option.labelKey)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _lengthCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          labelText: AppLocale.t('circulation_length'),
                          labelWidget: TappableLabel(
                            text: AppLocale.t('circulation_length'),
                          ),
                          prefixIcon: const Icon(Icons.straighten),
                          suffixText: 'm',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _widthCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          labelText: AppLocale.t('circulation_width'),
                          labelWidget: TappableLabel(
                            text: AppLocale.t('circulation_width'),
                          ),
                          prefixIcon: const Icon(Icons.swap_horiz),
                          suffixText: 'm',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FocusLabelTextField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    labelText: AppLocale.t('circulation_height'),
                    labelWidget:
                        TappableLabel(text: AppLocale.t('circulation_height')),
                    prefixIcon: const Icon(Icons.height),
                    suffixText: 'm',
                  ),
                  const SizedBox(height: 8),
                  ReadableText(
                    text: AppLocale.t('circulation_dimensions_note'),
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: ReadableText(text: AppLocale.t('circulation_safety')),
                    value: _applySafety,
                    onChanged: (value) =>
                        setState(() => _applySafety = value),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ReadableText(text: AppLocale.t('clean')),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ReadableText(text: AppLocale.t('calculate')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (resultVisible) ...[
            const SizedBox(height: 20),
            _ResultCard(
              rows: [
                _ResultRow(
                  label: AppLocale.t('circulation_flow'),
                  value: '${_flow!.toStringAsFixed(3)} m³/h',
                ),
                if (_applySafety && _flowSafe != null)
                  _ResultRow(
                    label: AppLocale.t('circulation_flow_safe'),
                    value: '${_flowSafe!.toStringAsFixed(3)} m³/h',
                  ),
                _ResultRow(
                  label: AppLocale.t('circulation_head'),
                  value: '${_head!.toStringAsFixed(3)} mSS',
                ),
                if (_applySafety && _headSafe != null)
                  _ResultRow(
                    label: AppLocale.t('circulation_head_safe'),
                    value: '${_headSafe!.toStringAsFixed(3)} mSS',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ReadableText(
              text:
                  '${AppLocale.t('circulation_selected_x')}: ${_selectedX!.toStringAsFixed(0)} (${AppLocale.t(_systemOption.labelKey)})',
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: ReadableText(text: AppLocale.t('share_pdf')),
              onPressed: () {
                final outputs = <String, dynamic>{
                  AppLocale.t('circulation_flow'):
                      '${_flow!.toStringAsFixed(3)} m³/h',
                  AppLocale.t('circulation_head'):
                      '${_head!.toStringAsFixed(3)} mSS',
                  AppLocale.t('circulation_selected_x'):
                      '${_selectedX!.toStringAsFixed(0)} (${AppLocale.t(_systemOption.labelKey)})',
                };
                if (_applySafety && _flowSafe != null && _headSafe != null) {
                  outputs[AppLocale.t('circulation_flow_safe')] =
                      '${_flowSafe!.toStringAsFixed(3)} m³/h';
                  outputs[AppLocale.t('circulation_head_safe')] =
                      '${_headSafe!.toStringAsFixed(3)} mSS';
                }
                PdfReportService.generateSingleReport(
                  formulaName: AppLocale.t('circulation_pump'),
                  inputs: {
                    AppLocale.t('circulation_capacity'):
                        '${_capacityCtrl.text} ${AppLocale.t(_capacityUnit.labelKey)}',
                    AppLocale.t('circulation_system_type'):
                        AppLocale.t(_systemOption.labelKey),
                    AppLocale.t('circulation_length'):
                        '${_lengthCtrl.text} m',
                    AppLocale.t('circulation_width'):
                        '${_widthCtrl.text} m',
                    AppLocale.t('circulation_height'):
                        '${_heightCtrl.text} m',
                    AppLocale.t('circulation_safety'):
                        _applySafety ? 'On' : 'Off',
                  },
                  outputs: outputs,
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _CapacityUnit {
  final String labelKey;
  final bool isKw;

  const _CapacityUnit({required this.labelKey, required this.isKw});
}

class _CirculationSystemOption {
  final String labelKey;
  final double xValue;

  const _CirculationSystemOption({
    required this.labelKey,
    required this.xValue,
  });
}

class ShuntPumpTab extends StatefulWidget {
  const ShuntPumpTab({super.key});

  @override
  State<ShuntPumpTab> createState() => _ShuntPumpTabState();
}

class _ShuntPumpTabState extends State<ShuntPumpTab> {
  final TextEditingController _powerCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  _ShuntHeatingOption? _selectedType;
  double? _flowM3h;
  double? _headMss;

  final List<_ShuntHeatingOption> _options = const [
    _ShuntHeatingOption('h_floor', true),
    _ShuntHeatingOption('h_panel', false),
    _ShuntHeatingOption('h_steel', false),
    _ShuntHeatingOption('h_cast', false),
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = _options.first;
  }

  @override
  void dispose() {
    _powerCtrl.dispose();
    _widthCtrl.dispose();
    _lengthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _powerCtrl.clear();
      _widthCtrl.clear();
      _lengthCtrl.clear();
      _heightCtrl.clear();
      _selectedType = _options.first;
      _flowM3h = null;
      _headMss = null;
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  double? _readInput(TextEditingController controller, String labelKey) {
    final label = AppLocale.t(labelKey);
    final text = controller.text.trim();
    if (text.isEmpty) {
      _showError('$label ${AppLocale.t('err_required')}');
      return null;
    }
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) {
      _showError('$label: ${AppLocale.t('err_invalid_number')}');
      return null;
    }
    if (value < 0) {
      _showError('$label: ${AppLocale.t('err_negative')}');
      return null;
    }
    return value;
  }

  Future<void> _calculate() async {
    // Test: P=4.80, Tip=Yerden Isıtma, En=30, Boy=45, H=30 => Debi=0.41 m³/h; Basma=9.45 mSS
    final power = _readInput(_powerCtrl, 'heat_cap');
    if (power == null) return;
    final width = _readInput(_widthCtrl, 'building_width');
    if (width == null) return;
    final length = _readInput(_lengthCtrl, 'building_length');
    if (length == null) return;
    final height = _readInput(_heightCtrl, 'sys_h');
    if (height == null) return;
    final heatingType = _selectedType;
    if (heatingType == null) {
      _showError(AppLocale.t('err_invalid_number'));
      return;
    }

    final qKcalPerHour = power * 860;
    final isFloor = heatingType.isFloorHeating;
    final flowM3h = isFloor ? (qKcalPerHour / 10000) : (qKcalPerHour / 20000);
    final totalLength = width + length + height;
    final headMss = totalLength * (isFloor ? 0.09 : 0.04);

    setState(() {
      _flowM3h = flowM3h;
      _headMss = headMss;
    });

    final createdAt = DateTime.now();
    await CalculationHistoryService.append(
      CalculationHistoryRecord(
        id: createdAt.microsecondsSinceEpoch.toString(),
        formulaId: 'shunt_pump',
        formulaName: AppLocale.t('shunt_pump'),
        createdAt: createdAt,
        inputs: {
          AppLocale.t('heat_cap'): '${power.toStringAsFixed(2)} kW',
          AppLocale.t('building_width'): '${width.toStringAsFixed(2)} m',
          AppLocale.t('building_length'): '${length.toStringAsFixed(2)} m',
          AppLocale.t('sys_h'): '${height.toStringAsFixed(2)} m',
          AppLocale.t('heat_type'): AppLocale.t(heatingType.labelKey),
        },
        outputs: {
          AppLocale.t('res_flow'): '${flowM3h.toStringAsFixed(2)} m³/h',
          AppLocale.t('res_press'): '${headMss.toStringAsFixed(2)} mSS',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final resultVisible = _flowM3h != null && _headMss != null;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _powerCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          labelText: AppLocale.t('heat_cap'),
                          labelWidget:
                              TappableLabel(text: AppLocale.t('heat_cap')),
                          prefixIcon: const Icon(Icons.bolt),
                          suffixText: 'kW',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _heightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          labelText: AppLocale.t('sys_h'),
                          labelWidget:
                              TappableLabel(text: AppLocale.t('sys_h')),
                          prefixIcon: const Icon(Icons.height),
                          suffixText: 'm',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _widthCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          labelText: AppLocale.t('building_width'),
                          labelWidget: TappableLabel(
                              text: AppLocale.t('building_width')),
                          prefixIcon: const Icon(Icons.swap_horiz),
                          suffixText: 'm',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _lengthCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(
                                  decimal: true),
                          labelText: AppLocale.t('building_length'),
                          labelWidget: TappableLabel(
                              text: AppLocale.t('building_length')),
                          prefixIcon: const Icon(Icons.straighten),
                          suffixText: 'm',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<_ShuntHeatingOption>(
                    value: _selectedType,
                    decoration: InputDecoration(
                      label: TappableLabel(text: AppLocale.t('heat_type')),
                      prefixIcon: const Icon(Icons.thermostat),
                    ),
                    onChanged: (value) =>
                        setState(() => _selectedType = value),
                    items: _options
                        .map((option) => DropdownMenuItem(
                              value: option,
                              child: Text(AppLocale.t(option.labelKey)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ReadableText(text: AppLocale.t('clean')),
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
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: ReadableText(text: AppLocale.t('calculate')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (resultVisible) ...[
            const SizedBox(height: 20),
            _ResultCard(
              rows: [
                _ResultRow(
                  label: AppLocale.t('shunt_flow'),
                  value: '${_flowM3h!.toStringAsFixed(2)} m³/h',
                ),
                _ResultRow(
                  label: AppLocale.t('shunt_head'),
                  value: '${_headMss!.toStringAsFixed(2)} mSS',
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.picture_as_pdf),
              label: ReadableText(text: AppLocale.t('share_pdf')),
              onPressed: () => PdfReportService.generateSingleReport(
                formulaName: AppLocale.t('shunt_pump'),
                inputs: {
                  AppLocale.t('heat_cap'): '${_powerCtrl.text} kW',
                  AppLocale.t('building_width'): '${_widthCtrl.text} m',
                  AppLocale.t('building_length'): '${_lengthCtrl.text} m',
                  AppLocale.t('sys_h'): '${_heightCtrl.text} m',
                  AppLocale.t('heat_type'):
                      AppLocale.t(_selectedType?.labelKey ?? ''),
                },
                outputs: {
                  AppLocale.t('shunt_flow'):
                      '${_flowM3h!.toStringAsFixed(2)} m³/h',
                  AppLocale.t('shunt_head'):
                      '${_headMss!.toStringAsFixed(2)} mSS',
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ShuntHeatingOption {
  final String labelKey;
  final bool isFloorHeating;

  const _ShuntHeatingOption(this.labelKey, this.isFloorHeating);
}

class _ResultCard extends StatelessWidget {
  final List<_ResultRow> rows;

  const _ResultCard({required this.rows});

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
        children: rows
            .expand((row) => [row, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      ),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;

  const _ResultRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final valueStyle = Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: const Color(0xFF0052FF),
        );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: TappableLabel(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        Text(value, style: valueStyle),
      ],
    );
  }
}

class BoilerExpansionTankTab extends StatefulWidget {
  const BoilerExpansionTankTab({super.key});

  @override
  State<BoilerExpansionTankTab> createState() => _BoilerExpansionTankTabState();
}

class _BoilerExpansionTankTabState extends State<BoilerExpansionTankTab> {
  late TextEditingController _volumeCtrl;
  late TextEditingController _minPressureCtrl;
  late TextEditingController _maxPressureCtrl;
  double? _result;
  double? _expansionWater;

  @override
  void initState() {
    super.initState();
    _volumeCtrl = TextEditingController();
    _minPressureCtrl = TextEditingController();
    _maxPressureCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _volumeCtrl.dispose();
    _minPressureCtrl.dispose();
    _maxPressureCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _volumeCtrl.clear();
      _minPressureCtrl.clear();
      _maxPressureCtrl.clear();
      _result = null;
      _expansionWater = null;
    });
  }

  double _parseDouble(String value) {
    if (value.trim().isEmpty) {
      return double.nan;
    }
    return double.tryParse(value.replaceAll(',', '.')) ?? double.nan;
  }

  String _formatNumber(double value) {
    final formatted = value.toStringAsFixed(1);
    return AppLocale.currentLang == 'TR'
        ? formatted.replaceAll('.', ',')
        : formatted;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _calc() async {
    final volume = _parseDouble(_volumeCtrl.text);
    final pMin = _parseDouble(_minPressureCtrl.text);
    final pMax = _parseDouble(_maxPressureCtrl.text);

    if (volume.isNaN || pMin.isNaN || pMax.isNaN) {
      _showError(AppLocale.t('err_boiler_expansion_invalid_input'));
      return;
    }
    if (volume <= 0) {
      _showError(AppLocale.t('err_boiler_expansion_invalid_volume'));
      return;
    }
    if (pMax <= pMin) {
      _showError(AppLocale.t('err_boiler_expansion_invalid_pressure'));
      return;
    }

    // TEST KONTROL: Vb=2000, Pmin=5, Pmax=8 -> Vexp=43.4, Vt=130.2
    final vExp = 0.0217 * volume;
    final vTank = vExp * (pMax + 1) / (pMax - pMin);

    setState(() {
      _expansionWater = vExp;
      _result = vTank;
    });

    final createdAt = DateTime.now();
    await CalculationHistoryService.append(
      CalculationHistoryRecord(
        id: createdAt.microsecondsSinceEpoch.toString(),
        formulaId: 'boiler_expansion_tank',
        formulaName: AppLocale.t('boiler_expansion_tank'),
        createdAt: createdAt,
        inputs: {
          AppLocale.t('boiler_expansion_volume'): '${_formatNumber(volume)} L',
          AppLocale.t('boiler_expansion_pmin'):
              '${_formatNumber(pMin)} ${AppLocale.t('bar_unit')}',
          AppLocale.t('boiler_expansion_pmax'):
              '${_formatNumber(pMax)} ${AppLocale.t('bar_unit')}',
        },
        outputs: {
          AppLocale.t('boiler_expansion_result'):
              '${_formatNumber(vTank)} L',
          AppLocale.t('boiler_expansion_water'):
              '${_formatNumber(vExp)} L',
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  TextField(
                    controller: _volumeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocale.t('boiler_expansion_volume'),
                      prefixIcon: const Icon(Icons.storage),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _minPressureCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocale.t('boiler_expansion_pmin'),
                      prefixIcon: const Icon(Icons.arrow_downward),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _maxPressureCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocale.t('boiler_expansion_pmax'),
                      prefixIcon: const Icon(Icons.arrow_upward),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _calc,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: ReadableText(
                      text: AppLocale.t('calculate'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: _clear,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: ReadableText(
                      text: AppLocale.t('clean'),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_result != null)
            Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0052FF), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _resultRow(
                    AppLocale.t('boiler_expansion_result'),
                    '${_formatNumber(_result!)} L',
                  ),
                  if (_expansionWater != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocale.t('boiler_expansion_water')}: ${_formatNumber(_expansionWater!)} L',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: ReadableText(text: AppLocale.t('share_pdf')),
                    onPressed: () => PdfReportService.generateSingleReport(
                      formulaName: AppLocale.t('boiler_expansion_tank'),
                      inputs: {
                        AppLocale.t('boiler_expansion_volume'):
                            '${_volumeCtrl.text} L',
                        AppLocale.t('boiler_expansion_pmin'):
                            '${_minPressureCtrl.text} ${AppLocale.t('bar_unit')}',
                        AppLocale.t('boiler_expansion_pmax'):
                            '${_maxPressureCtrl.text} ${AppLocale.t('bar_unit')}',
                      },
                      outputs: {
                        AppLocale.t('boiler_expansion_result'):
                            '${_formatNumber(_result!)} L',
                        if (_expansionWater != null)
                          AppLocale.t('boiler_expansion_water'):
                              '${_formatNumber(_expansionWater!)} L',
                      },
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: ReadableText(
            text: label,
            style: const TextStyle(
              color: Color(0xFF0052FF),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: ReadableText(
            text: value,
            textAlign: TextAlign.right,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CalculationHistoryRecord> _history = [];
  final Set<String> _selectedIds = {};
  bool _selectionMode = false;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final history = await CalculationHistoryService.loadRecords();
    if (!mounted) return;
    setState(() {
      _history = history;
    });
  }

  Future<void> _handleDelete() async {
    if (_selectedIds.isNotEmpty) {
      await CalculationHistoryService.removeByIds(_selectedIds);
      if (!mounted) return;
      setState(() {
        _history.removeWhere((record) => _selectedIds.contains(record.id));
        _selectedIds.clear();
        _selectionMode = false;
      });
    } else {
      _showDeleteAllDialog();
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: ReadableText(text: AppLocale.t('delete_confirm_title')),
        content: ReadableText(text: AppLocale.t('delete_confirm_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: ReadableText(text: AppLocale.t('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await CalculationHistoryService.clearAll();
              if (mounted) {
                setState(() {
                  _history = [];
                  _selectedIds.clear();
                  _selectionMode = false;
                });
              }
            },
            child: ReadableText(
              text: AppLocale.t('delete'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(CalculationHistoryRecord record) {
    setState(() {
      if (_selectedIds.contains(record.id)) {
        _selectedIds.remove(record.id);
      } else {
        _selectedIds.add(record.id);
      }
      if (_selectedIds.isEmpty) {
        _selectionMode = false;
      }
    });
  }

  void _setSelectionMode(bool enabled) {
    setState(() {
      _selectionMode = enabled;
      if (!enabled) {
        _selectedIds.clear();
      }
    });
  }

  void _selectAll() {
    setState(() {
      _selectionMode = true;
      _selectedIds
        ..clear()
        ..addAll(_history.map((record) => record.id));
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedIds.clear();
      _selectionMode = false;
    });
  }

  void _exportSelected() {
    if (_selectedIds.isEmpty) return;
    final selectedItems = _history
        .where((record) => _selectedIds.contains(record.id))
        .toList();
    PdfReportService.generateMultiReport(selectedItems);
  }

  String _formatDateTime(DateTime time) {
    final y = time.year.toString().padLeft(4, '0');
    final m = time.month.toString().padLeft(2, '0');
    final d = time.day.toString().padLeft(2, '0');
    final hh = time.hour.toString().padLeft(2, '0');
    final mm = time.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }

  String _formatKeyValues(Map<String, dynamic> values) {
    if (values.isEmpty) return '-';
    return values.entries
        .map((entry) => '${entry.key}: ${entry.value}')
        .join(', ');
  }

  String _formatSummary(Map<String, dynamic> outputs) {
    if (outputs.isEmpty) return '-';
    final entry = outputs.entries.first;
    return '${entry.key}: ${entry.value}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: ReadableText(
          text: AppLocale.t('history_title'),
          style: GoogleFonts.poppins(),
          maxLines: 2,
          textAlign: TextAlign.center,
        ),
        actions: [
          IconButton(
            icon: Icon(
              _selectedIds.isEmpty
                  ? Icons.delete_forever_outlined
                  : Icons.delete,
              color: _selectedIds.isEmpty ? Colors.grey : Colors.red,
            ),
            onPressed: _handleDelete,
            tooltip: _selectedIds.isNotEmpty
                ? 'Seçilenleri Sil'
                : 'Geçmişi Temizle',
          ),
        ],
      ),
      bottomNavigationBar: _selectedIds.isNotEmpty
          ? SafeArea(
              top: false,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: ElevatedButton.icon(
                  onPressed: _exportSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0052FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: ReadableText(
                    text:
                        '${AppLocale.t('bulk_pdf')} (${_selectedIds.length})',
                  ),
                ),
              ),
            )
          : null,
      body: _history.isEmpty
          ? Center(
              child: ReadableText(
                text: AppLocale.t('no_data'),
                style: GoogleFonts.poppins(color: Colors.grey),
              ))
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.start,
                    children: [
                      OutlinedButton(
                        onPressed: () => _setSelectionMode(!_selectionMode),
                        child: ReadableText(text: AppLocale.t('select')),
                      ),
                      OutlinedButton(
                        onPressed:
                            _history.isEmpty ? null : _selectAll,
                        child: ReadableText(text: AppLocale.t('select_all')),
                      ),
                      OutlinedButton(
                        onPressed:
                            _selectedIds.isEmpty ? null : _clearSelection,
                        child:
                            ReadableText(text: AppLocale.t('clear_selection')),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.only(
                        left: 16, right: 16, top: 8, bottom: 80),
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      final record = _history[index];
                      final dateStr = _formatDateTime(record.createdAt);
                      final inputs = _formatKeyValues(record.inputs);
                      final summary = _formatSummary(record.outputs);
                      final isSelected = _selectedIds.contains(record.id);

                      return GestureDetector(
                        onTap: () {
                          if (_selectionMode || _selectedIds.isNotEmpty) {
                            _toggleSelection(record);
                          }
                        },
                        onLongPress: () {
                          if (!_selectionMode) {
                            _setSelectionMode(true);
                          }
                          _toggleSelection(record);
                        },
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
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (_selectionMode || _selectedIds.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 12),
                                    child: Transform.scale(
                                      scale: 1.1,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor:
                                            const Color(0xFF0052FF),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        onChanged: (_) =>
                                            _toggleSelection(record),
                                      ),
                                    ),
                                  ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: ReadableText(
                                              text: record.formulaName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0052FF),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ReadableText(
                                            text: dateStr,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 24),
                                      ReadableText(
                                        text: '${AppLocale.t('inputs')}:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      ReadableText(
                                        text: inputs,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 12),
                                      ReadableText(
                                        text: '${AppLocale.t('results')}:',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600]),
                                      ),
                                      ReadableText(
                                        text: summary,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
