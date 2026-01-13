import 'package:flutter/material.dart';

import 'kazan_tesisat_calculator.dart';
import 'main.dart';

class BoilerInstallationTab extends StatefulWidget {
  const BoilerInstallationTab({super.key});

  @override
  State<BoilerInstallationTab> createState() => _BoilerInstallationTabState();
}

class _BoilerInstallationTabState extends State<BoilerInstallationTab> {
  final List<_ZoneController> _zones = [];
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _lengthCtrl = TextEditingController();
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _collectorVelocityCtrl =
      TextEditingController(text: '0.7');
  String _systemTypeKey = 'system_type_floor';
  BoilerInstallationResult? _result;

  final List<_ZoneDefinition> _definitions = const [
    _ZoneDefinition('zone_pool', 0.7, 15),
    _ZoneDefinition('zone_floor', 0.7, 10),
    _ZoneDefinition('zone_boiler', 0.7, 20),
    _ZoneDefinition('zone_radiator', 0.7, 20),
    _ZoneDefinition('zone_hamam', 0.5, 10),
    _ZoneDefinition('zone_air_handler', 0.7, 15),
    _ZoneDefinition('zone_heat_recovery', 0.5, 15),
  ];

  final Map<String, double> _expansionCoefficients = const {
    'system_type_floor': 19.8,
    'system_type_panel': 9.4,
    'system_type_steel': 16.0,
    'system_type_other': 12.0,
  };

  @override
  void initState() {
    super.initState();
    for (final def in _definitions) {
      _zones.add(_ZoneController(
        labelKey: def.labelKey,
        velocityController: TextEditingController(text: def.defaultVelocity),
        deltaController: TextEditingController(text: def.defaultDeltaT),
        loadController: TextEditingController(),
        defaultVelocity: def.defaultVelocity,
        defaultDeltaT: def.defaultDeltaT,
      ));
    }
  }

  @override
  void dispose() {
    for (final zone in _zones) {
      zone.velocityController.dispose();
      zone.deltaController.dispose();
      zone.loadController.dispose();
    }
    _widthCtrl.dispose();
    _lengthCtrl.dispose();
    _heightCtrl.dispose();
    _collectorVelocityCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final inputs = <BoilerZoneInput>[];
    for (final zone in _zones) {
      final velocity =
          _parseDouble(zone.velocityController.text, fallback: zone.defaultVelocity);
      final deltaT =
          _parseDouble(zone.deltaController.text, fallback: zone.defaultDeltaT);
      final load = _parseDouble(zone.loadController.text);

      if (velocity <= 0) {
        _showError(AppLocale.t('err_velocity'));
        return;
      }
      if (deltaT <= 0) {
        _showError(AppLocale.t('err_delta_t'));
        return;
      }
      if (load < 0) {
        _showError(AppLocale.t('err_negative'));
        return;
      }

      inputs.add(BoilerZoneInput(
        labelKey: zone.labelKey,
        velocity: velocity,
        deltaT: deltaT,
        loadKcalPerHour: load,
      ));
    }

    final width = _parseDouble(_widthCtrl.text);
    final length = _parseDouble(_lengthCtrl.text);
    final height = _parseDouble(_heightCtrl.text);
    if (width < 0 || length < 0 || height < 0) {
      _showError(AppLocale.t('err_negative'));
      return;
    }
    final collectorVelocity =
        _parseDouble(_collectorVelocityCtrl.text, fallback: 0.7);
    if (collectorVelocity <= 0) {
      _showError(AppLocale.t('err_velocity'));
      return;
    }

    final coefficient = _expansionCoefficients[_systemTypeKey] ?? 12.0;
    setState(() {
      _result = BoilerInstallationCalculator.calculate(
        zones: inputs,
        collectorVelocity: collectorVelocity,
        building: BuildingDimensions(
          width: width,
          length: length,
          height: height,
        ),
        expansionCoefPerKw: coefficient,
      );
    });
  }

  void _clear() {
    for (final zone in _zones) {
      zone.velocityController.text = zone.defaultVelocity;
      zone.deltaController.text = zone.defaultDeltaT;
      zone.loadController.clear();
    }
    _widthCtrl.clear();
    _lengthCtrl.clear();
    _heightCtrl.clear();
    _collectorVelocityCtrl.text = '0.7';
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: AppLocale.t('zones_title'),
            child: Column(
              children: [
                for (final zone in _zones) ...[
                  _ZoneCard(zone: zone),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: AppLocale.t('building_dimensions'),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _widthCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocale.t('width'),
                      suffixText: 'm',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _lengthCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocale.t('length'),
                      suffixText: 'm',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocale.t('height'),
                      suffixText: 'm',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: AppLocale.t('expansion_tanks'),
            child: Column(
              children: [
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocale.t('system_type'),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _systemTypeKey,
                      isExpanded: true,
                      onChanged: (value) =>
                          setState(() => _systemTypeKey = value ?? _systemTypeKey),
                      items: _expansionCoefficients.keys
                          .map((key) => DropdownMenuItem(
                                value: key,
                                child: Text(AppLocale.t(key)),
                              ))
                          .toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: AppLocale.t('collector_title'),
            child: TextField(
              controller: _collectorVelocityCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: AppLocale.t('collector_velocity'),
                suffixText: 'm/s',
              ),
            ),
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
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _ResultsSection(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ZoneDefinition {
  final String labelKey;
  final String defaultVelocity;
  final String defaultDeltaT;

  const _ZoneDefinition(this.labelKey, double velocity, double deltaT)
      : defaultVelocity = '${velocity.toStringAsFixed(1)}',
        defaultDeltaT = '${deltaT.toStringAsFixed(0)}';
}

class _ZoneController {
  final String labelKey;
  final TextEditingController velocityController;
  final TextEditingController deltaController;
  final TextEditingController loadController;
  final String defaultVelocity;
  final String defaultDeltaT;

  _ZoneController({
    required this.labelKey,
    required this.velocityController,
    required this.deltaController,
    required this.loadController,
    required this.defaultVelocity,
    required this.defaultDeltaT,
  });
}

class _ZoneCard extends StatelessWidget {
  final _ZoneController zone;

  const _ZoneCard({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocale.t(zone.labelKey),
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: zone.velocityController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: AppLocale.t('zone_velocity'),
                    suffixText: 'm/s',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
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
          const SizedBox(height: 10),
          TextField(
            controller: zone.loadController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: AppLocale.t('heat_load_kcal'),
              suffixText: 'kcal/h',
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _ResultsSection extends StatelessWidget {
  final BoilerInstallationResult result;

  const _ResultsSection({required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SectionCard(
          title: AppLocale.t('boiler_capacity_title'),
          child: Column(
            children: [
              _ResultRow(
                label: AppLocale.t('total_heat_load'),
                value:
                    '${result.totalLoadKcalPerHour.toStringAsFixed(0)} kcal/h',
              ),
              _ResultRow(
                label: AppLocale.t('boiler_capacity_kw'),
                value: '${result.boilerCapacityKw} kW',
              ),
              _ResultRow(
                label: AppLocale.t('boiler_capacity_kcal'),
                value:
                    '${result.boilerCapacityKcalPerHour.toStringAsFixed(0)} kcal/h',
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppLocale.t('zones_results_title'),
          child: Column(
            children: [
              for (final zone in result.zones) ...[
                _ZoneResultTile(zone: zone),
                const Divider(height: 24),
              ],
              _ResultRow(
                label: AppLocale.t('total_flow'),
                value: '${result.totalFlowM3PerHour.toStringAsFixed(2)} m³/h',
                isMain: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppLocale.t('collector_title'),
          child: Column(
            children: [
              _ResultRow(
                label: AppLocale.t('collector_diameter'),
                value: '${result.collectorDiameterMm.toStringAsFixed(2)} mm',
                isMain: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _SectionCard(
          title: AppLocale.t('expansion_results_title'),
          child: Column(
            children: [
              _ResultRow(
                label: AppLocale.t('open_tank'),
                value: '${result.expansion.openTankLiters} L',
                isMain: true,
              ),
              _ResultRow(
                label: AppLocale.t('closed_tank'),
                value: result.expansion.closedTankLiters == null
                    ? AppLocale.t('check_height')
                    : '${result.expansion.closedTankLiters!.toStringAsFixed(0)} L',
                isMain: true,
              ),
              _ResultRow(
                label: AppLocale.t('opening_pressure'),
                value: result.expansion.openingPressureBar == null
                    ? AppLocale.t('check_height')
                    : '${result.expansion.openingPressureBar!.toStringAsFixed(1)} bar',
              ),
              _ResultRow(
                label: AppLocale.t('safety_pressure'),
                value: result.expansion.safetyPressureBar == null
                    ? AppLocale.t('check_height')
                    : '${result.expansion.safetyPressureBar!.toStringAsFixed(1)} bar',
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  AppLocale.t('expansion_details'),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              _ResultRow(
                label: AppLocale.t('system_volume'),
                value:
                    '${result.expansion.systemVolumeLiters?.toStringAsFixed(1) ?? '-'} L',
              ),
              _ResultRow(
                label: AppLocale.t('expansion_volume'),
                value:
                    '${result.expansion.expansionVolumeLiters?.toStringAsFixed(1) ?? '-'} L',
              ),
              _ResultRow(
                label: AppLocale.t('reserve_volume'),
                value:
                    '${result.expansion.reserveVolumeLiters?.toStringAsFixed(1) ?? '-'} L',
              ),
              _ResultRow(
                label: AppLocale.t('static_pressure'),
                value:
                    '${result.expansion.staticPressureBar?.toStringAsFixed(1) ?? '-'} bar',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ZoneResultTile extends StatelessWidget {
  final BoilerZoneResult zone;

  const _ZoneResultTile({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocale.t(zone.labelKey),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _ResultRow(
          label: AppLocale.t('zone_flow'),
          value: '${zone.flowM3PerHour.toStringAsFixed(2)} m³/h',
        ),
        _ResultRow(
          label: AppLocale.t('zone_diameter'),
          value: '${zone.diameterMm.toStringAsFixed(2)} mm',
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMain;

  const _ResultRow({
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
