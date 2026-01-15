class HeaterTypeOption {
  final String labelKey;
  final double coefficient;

  const HeaterTypeOption({required this.labelKey, required this.coefficient});
}

enum ExpansionTankCalculationError {
  invalidInput,
  invalidPressureRange,
  invalidResult,
}

class ExpansionTankCalculationException implements Exception {
  final ExpansionTankCalculationError error;

  const ExpansionTankCalculationException(this.error);
}

class ExpansionTankResult {
  final double systemVolume;
  final double expansionVolume;
  final double reserveVolume;
  final double safetyValvePressure;
  final double maxOperatingPressure;
  final double staticPressure;
  final double requiredVolume;
  final double recommendedVolume;

  const ExpansionTankResult({
    required this.systemVolume,
    required this.expansionVolume,
    required this.reserveVolume,
    required this.safetyValvePressure,
    required this.maxOperatingPressure,
    required this.staticPressure,
    required this.requiredVolume,
    required this.recommendedVolume,
  });
}

class ExpansionTankCalculator {
  static const List<HeaterTypeOption> heaterTypes = [
    HeaterTypeOption(labelKey: 'h_floor', coefficient: 19.8),
    HeaterTypeOption(labelKey: 'h_panel', coefficient: 9.4),
    HeaterTypeOption(labelKey: 'h_steel', coefficient: 16.0),
    HeaterTypeOption(labelKey: 'h_cast', coefficient: 12.0),
  ];

  static const List<double> standardVolumes = [
    8,
    12,
    18,
    24,
    35,
    50,
    80,
    100,
    140,
    200,
    250,
    300,
    400,
    500,
    600,
    750,
    1000,
    1500,
    2000,
    2500,
    3000,
    5000,
    8000,
    10000,
  ];

  ExpansionTankResult calculate({
    required double capacityKw,
    required double systemHeightM,
    required HeaterTypeOption heaterType,
  }) {
    if (capacityKw <= 0 || systemHeightM <= 0) {
      throw const ExpansionTankCalculationException(
          ExpansionTankCalculationError.invalidInput);
    }

    final systemVolume = capacityKw * heaterType.coefficient;
    final expansionVolume = systemVolume * 3.55 / 100;
    final reserveVolume = systemVolume * 0.005;
    final safetyValvePressure = _resolveSafetyValvePressure(systemHeightM);
    final maxOperatingPressure = safetyValvePressure - 0.5;
    final staticPressure = systemHeightM / 10;
    final pressureDelta = maxOperatingPressure - staticPressure;

    if (pressureDelta <= 0) {
      throw const ExpansionTankCalculationException(
          ExpansionTankCalculationError.invalidPressureRange);
    }

    final requiredVolume =
        (expansionVolume + reserveVolume) * (maxOperatingPressure + 1) /
            pressureDelta;

    if (requiredVolume <= 0 || !requiredVolume.isFinite) {
      throw const ExpansionTankCalculationException(
          ExpansionTankCalculationError.invalidResult);
    }

    final recommendedVolume = standardVolumes.firstWhere(
      (volume) => volume >= requiredVolume,
      orElse: () => double.nan,
    );

    if (!recommendedVolume.isFinite) {
      throw const ExpansionTankCalculationException(
          ExpansionTankCalculationError.invalidResult);
    }

    return ExpansionTankResult(
      systemVolume: systemVolume,
      expansionVolume: expansionVolume,
      reserveVolume: reserveVolume,
      safetyValvePressure: safetyValvePressure,
      maxOperatingPressure: maxOperatingPressure,
      staticPressure: staticPressure,
      requiredVolume: requiredVolume,
      recommendedVolume: recommendedVolume,
    );
  }

  double _resolveSafetyValvePressure(double systemHeightM) {
    if (systemHeightM < 15) {
      return 2.5;
    }
    if (systemHeightM < 25) {
      return 3.5;
    }
    if (systemHeightM < 35) {
      return 4.0;
    }
    if (systemHeightM < 45) {
      return 4.5;
    }
    return 6.0;
  }
}
