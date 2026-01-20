import '../models/modular_water_tank_result.dart';

enum ModularWaterTankMode {
  fullCapacity,
  budget,
}

class ModularWaterTankCalculator {
  static const double panelModuleMm = 1080;
  static const double mountPayX = 800;
  static const double mountPayY = 800;
  static const double mountPayZ = 500;
  static const double panelCubeMm3 = 1259712000;
  static const double literDivisor = 1000000;

  ModularWaterTankResult calculate({
    required double xMm,
    required double yMm,
    required double zMm,
    required ModularWaterTankMode mode,
  }) {
    if (xMm <= mountPayX || yMm <= mountPayY || zMm <= mountPayZ) {
      throw const ModularWaterTankValidationException(
        ModularWaterTankValidationError.dimensionsTooSmall,
      );
    }

    final aRaw = (xMm - mountPayX) / panelModuleMm;
    final bRaw = (yMm - mountPayY) / panelModuleMm;
    final cRaw = (zMm - mountPayZ) / panelModuleMm;

    final a = _applyRounding(aRaw, mode);
    final b = _applyRounding(bRaw, mode);
    final c = _applyRounding(cRaw, mode);

    final sidePanels = (a + b) * 2 * c;
    final volumeLiters = a * b * c * panelCubeMm3 / literDivisor;

    return ModularWaterTankResult(
      panelCountA: a,
      panelCountB: b,
      panelCountC: c,
      sidePanelCount: sidePanels,
      volumeLiters: volumeLiters,
      effectiveWidthMm: a * panelModuleMm,
      effectiveLengthMm: b * panelModuleMm,
      effectiveHeightMm: c * panelModuleMm,
    );
  }

  double _applyRounding(double value, ModularWaterTankMode mode) {
    switch (mode) {
      case ModularWaterTankMode.fullCapacity:
        return (value * 2).floorToDouble() / 2;
      case ModularWaterTankMode.budget:
        return value.floorToDouble();
    }
  }
}

enum ModularWaterTankValidationError {
  dimensionsTooSmall,
}

class ModularWaterTankValidationException implements Exception {
  final ModularWaterTankValidationError error;

  const ModularWaterTankValidationException(this.error);

  @override
  String toString() =>
      'ModularWaterTankValidationException: ${error.toString()}';
}
