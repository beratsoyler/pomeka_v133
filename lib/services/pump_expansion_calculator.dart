class PumpExpansionHeatingType {
  final String labelKey;
  final double deltaT;
  final double headFactor;
  final double volumeCoefficient;

  const PumpExpansionHeatingType({
    required this.labelKey,
    required this.deltaT,
    required this.headFactor,
    required this.volumeCoefficient,
  });
}

enum PumpExpansionCalculationError {
  invalidInput,
  heightTooHigh,
  invalidPressureRange,
  invalidResult,
}

class PumpExpansionCalculationException implements Exception {
  final PumpExpansionCalculationError error;

  const PumpExpansionCalculationException(this.error);
}

class PumpExpansionResult {
  final double flowM3PerHour;
  final double headMeter;
  final double tankVolumeLiter;
  final double openingPressureBar;
  final double safetyPressureBar;
  final double staticPressureBar;

  const PumpExpansionResult({
    required this.flowM3PerHour,
    required this.headMeter,
    required this.tankVolumeLiter,
    required this.openingPressureBar,
    required this.safetyPressureBar,
    required this.staticPressureBar,
  });
}

class PumpExpansionCalculator {
  static const List<PumpExpansionHeatingType> heatingTypes = [
    PumpExpansionHeatingType(
      labelKey: 'h_floor',
      deltaT: 10,
      headFactor: 0.09,
      volumeCoefficient: 19.8,
    ),
    PumpExpansionHeatingType(
      labelKey: 'h_panel',
      deltaT: 20,
      headFactor: 0.04,
      volumeCoefficient: 9.4,
    ),
    PumpExpansionHeatingType(
      labelKey: 'h_steel',
      deltaT: 20,
      headFactor: 0.04,
      volumeCoefficient: 16.0,
    ),
    PumpExpansionHeatingType(
      labelKey: 'h_cast',
      deltaT: 20,
      headFactor: 0.04,
      volumeCoefficient: 12.0,
    ),
  ];

  PumpExpansionResult calculate({
    required double capacityKw,
    required double buildingWidthM,
    required double buildingLengthM,
    required double systemHeightM,
    required PumpExpansionHeatingType heatingType,
  }) {
    if (capacityKw <= 0 ||
        buildingWidthM <= 0 ||
        buildingLengthM <= 0 ||
        systemHeightM <= 0) {
      throw const PumpExpansionCalculationException(
          PumpExpansionCalculationError.invalidInput);
    }

    if (systemHeightM >= 45) {
      throw const PumpExpansionCalculationException(
          PumpExpansionCalculationError.heightTooHigh);
    }

    final loadKcalPerHour = capacityKw * 860;
    final flowM3PerHour = loadKcalPerHour / (1000 * heatingType.deltaT);
    final headMeter =
        (buildingWidthM + buildingLengthM + systemHeightM) *
            heatingType.headFactor;

    final systemVolumeLiter = capacityKw * heatingType.volumeCoefficient;
    final expansionVolume = systemVolumeLiter * 0.0355;
    final reserveVolume = systemVolumeLiter * 0.005;

    final staticPressureBar = systemHeightM / 10;
    final openingPressureBar = _openingPressure(systemHeightM);
    final safetyPressureBar = openingPressureBar - 0.5;
    final pressureDelta = safetyPressureBar - staticPressureBar;

    if (pressureDelta <= 0) {
      throw const PumpExpansionCalculationException(
          PumpExpansionCalculationError.invalidPressureRange);
    }

    final tankVolumeLiter =
        (expansionVolume + reserveVolume) * (safetyPressureBar + 1) /
            pressureDelta;

    if (tankVolumeLiter <= 0 || !tankVolumeLiter.isFinite) {
      throw const PumpExpansionCalculationException(
          PumpExpansionCalculationError.invalidResult);
    }

    return PumpExpansionResult(
      flowM3PerHour: flowM3PerHour,
      headMeter: headMeter,
      tankVolumeLiter: tankVolumeLiter,
      openingPressureBar: openingPressureBar,
      safetyPressureBar: safetyPressureBar,
      staticPressureBar: staticPressureBar,
    );
  }

  double _openingPressure(double systemHeightM) {
    if (systemHeightM < 15) {
      return 2.5;
    }
    if (systemHeightM < 25) {
      return 3.5;
    }
    if (systemHeightM < 35) {
      return 4.5;
    }
    if (systemHeightM < 45) {
      return 5.5;
    }
    throw const PumpExpansionCalculationException(
        PumpExpansionCalculationError.heightTooHigh);
  }
}
