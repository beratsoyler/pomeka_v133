import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/app_locale.dart';
import '../models/modular_water_tank_result.dart';
import '../services/modular_water_tank_calculator.dart';
import '../widgets/focus_label_text_field.dart';
import '../widgets/readable_text.dart';

class ModularWaterTankTab extends StatefulWidget {
  const ModularWaterTankTab({super.key});

  @override
  State<ModularWaterTankTab> createState() => _ModularWaterTankTabState();
}

class _ModularWaterTankTabState extends State<ModularWaterTankTab> {
  late TextEditingController _xCtrl;
  late TextEditingController _yCtrl;
  late TextEditingController _zCtrl;
  final ModularWaterTankCalculator _calculator = ModularWaterTankCalculator();
  ModularWaterTankMode _mode = ModularWaterTankMode.fullCapacity;
  ModularWaterTankResult? _result;

  @override
  void initState() {
    super.initState();
    _xCtrl = TextEditingController();
    _yCtrl = TextEditingController();
    _zCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _xCtrl.dispose();
    _yCtrl.dispose();
    _zCtrl.dispose();
    super.dispose();
  }

  void _clear() {
    setState(() {
      _xCtrl.clear();
      _yCtrl.clear();
      _zCtrl.clear();
      _mode = ModularWaterTankMode.fullCapacity;
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

  Future<void> _calculate() async {
    final x = _parseDouble(_xCtrl.text);
    final y = _parseDouble(_yCtrl.text);
    final z = _parseDouble(_zCtrl.text);

    if (x.isNaN || y.isNaN || z.isNaN) {
      _showError(AppLocale.t('err_invalid_number'));
      return;
    }

    try {
      final result = _calculator.calculate(
        xMm: x,
        yMm: y,
        zMm: z,
        mode: _mode,
      );
      setState(() => _result = result);

      final prefs = await SharedPreferences.getInstance();
      final hist = prefs.getStringList('calculation_history') ?? [];
      hist.add(jsonEncode({
        'type': AppLocale.t('modular_tank'),
        'res': '${_formatVolume(result.volumeLiters)} L',
        'time': DateTime.now().toString(),
        'inputs':
            'X: ${_xCtrl.text} mm, Y: ${_yCtrl.text} mm, Z: ${_zCtrl.text} mm, ${AppLocale.t('modular_tank_mode')}: ${_modeLabel(_mode)}'
      }));
      await prefs.setStringList('calculation_history', hist);
    } on ModularWaterTankValidationException catch (e) {
      setState(() => _result = null);
      if (e.error == ModularWaterTankValidationError.dimensionsTooSmall) {
        _showError(AppLocale.t('err_modular_tank_dimensions'));
      }
    }
  }

  String _formatPanelValue(double value) {
    if ((value - value.roundToDouble()).abs() < 1e-9) {
      return value.round().toString();
    }
    if ((value * 2 - (value * 2).roundToDouble()).abs() < 1e-9) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(2);
  }

  String _formatMaybeInt(double value) {
    if ((value - value.roundToDouble()).abs() < 1e-9) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatVolume(double liters) {
    return liters.toStringAsFixed(3);
  }

  String _modeLabel(ModularWaterTankMode mode) {
    switch (mode) {
      case ModularWaterTankMode.fullCapacity:
        return AppLocale.t('modular_tank_mode_capacity');
      case ModularWaterTankMode.budget:
        return AppLocale.t('modular_tank_mode_budget');
    }
  }

  Widget _resRow(String label, String value, {bool isMain = false}) {
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
              text: value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: isMain ? 20 : 16),
            ),
          ),
        ],
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
                  ReadableText(
                    text: AppLocale.t('modular_tank_desc'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _xCtrl,
                          keyboardType: TextInputType.number,
                          labelText: AppLocale.t('modular_tank_width'),
                          prefixIcon: const Icon(Icons.swap_horiz),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: FocusLabelTextField(
                          controller: _yCtrl,
                          keyboardType: TextInputType.number,
                          labelText: AppLocale.t('modular_tank_length'),
                          prefixIcon: const Icon(Icons.swap_vert),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  FocusLabelTextField(
                    controller: _zCtrl,
                    keyboardType: TextInputType.number,
                    labelText: AppLocale.t('modular_tank_height'),
                    prefixIcon: const Icon(Icons.height),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<ModularWaterTankMode>(
                    value: _mode,
                    decoration: InputDecoration(
                      labelText: AppLocale.t('modular_tank_mode'),
                      prefixIcon: const Icon(Icons.tune),
                    ),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => _mode = value);
                    },
                    items: ModularWaterTankMode.values
                        .map((mode) => DropdownMenuItem(
                              value: mode,
                              child: Text(_modeLabel(mode)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _calculate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0052FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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
                          borderRadius: BorderRadius.circular(12)),
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
                children: [
                  _resRow(
                    AppLocale.t('modular_tank_panel_a'),
                    '${_formatPanelValue(_result!.panelCountA)} ${AppLocale.t('panel_unit')}',
                    isMain: true,
                  ),
                  _resRow(
                    AppLocale.t('modular_tank_panel_b'),
                    '${_formatPanelValue(_result!.panelCountB)} ${AppLocale.t('panel_unit')}',
                    isMain: true,
                  ),
                  _resRow(
                    AppLocale.t('modular_tank_panel_c'),
                    '${_formatPanelValue(_result!.panelCountC)} ${AppLocale.t('panel_unit')}',
                    isMain: true,
                  ),
                  _resRow(
                    AppLocale.t('modular_tank_side_panels'),
                    '${_formatMaybeInt(_result!.sidePanelCount)} ${AppLocale.t('panel_unit')}',
                  ),
                  _resRow(
                    AppLocale.t('modular_tank_volume'),
                    '${_formatVolume(_result!.volumeLiters)} L',
                    isMain: true,
                  ),
                  const Divider(),
                  ExpansionTile(
                    title:
                        ReadableText(text: AppLocale.t('modular_tank_effective_dimensions')),
                    children: [
                      _resRow(
                        AppLocale.t('modular_tank_effective_width'),
                        '${_formatMaybeInt(_result!.effectiveWidthMm)} ${AppLocale.t('mm_unit')}',
                      ),
                      _resRow(
                        AppLocale.t('modular_tank_effective_length'),
                        '${_formatMaybeInt(_result!.effectiveLengthMm)} ${AppLocale.t('mm_unit')}',
                      ),
                      _resRow(
                        AppLocale.t('modular_tank_effective_height'),
                        '${_formatMaybeInt(_result!.effectiveHeightMm)} ${AppLocale.t('mm_unit')}',
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
