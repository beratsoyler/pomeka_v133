import 'dart:math' as math;

const double _excelPi = 3.14;

class BoilerZoneInput {
  final String labelKey;
  final double velocity;
  final double deltaT;
  final double loadKcalPerHour;

  const BoilerZoneInput({
    required this.labelKey,
    required this.velocity,
    required this.deltaT,
    required this.loadKcalPerHour,
  });
}

class BoilerZoneResult {
  final String labelKey;
  final double velocity;
  final double deltaT;
  final double loadKcalPerHour;
  final double flowM3PerHour;
  final double diameterMm;

  const BoilerZoneResult({
    required this.labelKey,
    required this.velocity,
    required this.deltaT,
    required this.loadKcalPerHour,
    required this.flowM3PerHour,
    required this.diameterMm,
  });
}

class BuildingDimensions {
  final double width;
  final double length;
  final double height;

  const BuildingDimensions({
    required this.width,
    required this.length,
    required this.height,
  });
}

class ExpansionTankResult {
  final int openTankLiters;
  final double? closedTankLiters;
  final double? openingPressureBar;
  final double? safetyPressureBar;
  final double? staticPressureBar;
  final double? systemVolumeLiters;
  final double? expansionVolumeLiters;
  final double? reserveVolumeLiters;
  final bool needsHeightCheck;

  const ExpansionTankResult({
    required this.openTankLiters,
    required this.closedTankLiters,
    required this.openingPressureBar,
    required this.safetyPressureBar,
    required this.staticPressureBar,
    required this.systemVolumeLiters,
    required this.expansionVolumeLiters,
    required this.reserveVolumeLiters,
    required this.needsHeightCheck,
  });
}

class BoilerInstallationResult {
  final double totalLoadKcalPerHour;
  final int boilerCapacityKw;
  final double boilerCapacityKcalPerHour;
  final List<BoilerZoneResult> zones;
  final double totalFlowM3PerHour;
  final double collectorDiameterMm;
  final ExpansionTankResult expansion;
  final BuildingDimensions building;

  const BoilerInstallationResult({
    required this.totalLoadKcalPerHour,
    required this.boilerCapacityKw,
    required this.boilerCapacityKcalPerHour,
    required this.zones,
    required this.totalFlowM3PerHour,
    required this.collectorDiameterMm,
    required this.expansion,
    required this.building,
  });
}

class BoilerInstallationCalculator {
  static BoilerInstallationResult calculate({
    required List<BoilerZoneInput> zones,
    required double collectorVelocity,
    required BuildingDimensions building,
    required double expansionCoefPerKw,
  }) {
    final zoneResults = zones.map((zone) {
      final flow = zone.deltaT > 0
          ? zone.loadKcalPerHour / (zone.deltaT * 1000)
          : 0.0;
      final diameter = zone.velocity > 0 && flow > 0
          ? math.sqrt((4 * flow) / (_excelPi * 3600 * zone.velocity)) * 1000
          : 0.0;
      return BoilerZoneResult(
        labelKey: zone.labelKey,
        velocity: zone.velocity,
        deltaT: zone.deltaT,
        loadKcalPerHour: zone.loadKcalPerHour,
        flowM3PerHour: flow,
        diameterMm: diameter,
      );
    }).toList();

    final totalLoad =
        zoneResults.fold<double>(0, (sum, zone) => sum + zone.loadKcalPerHour);
    final boilerKw = totalLoad > 0 ? (totalLoad / 860).ceil() : 0;
    final boilerKcal = boilerKw * 860.0;
    final totalFlow =
        zoneResults.fold<double>(0, (sum, zone) => sum + zone.flowM3PerHour);
    final collectorDiameter = collectorVelocity > 0 && totalFlow > 0
        ? math.sqrt((4 * totalFlow) / (_excelPi * 3600 * collectorVelocity)) *
            1000
        : 0.0;

    final expansion = _calculateExpansion(
      boilerKw: boilerKw,
      expansionCoefPerKw: expansionCoefPerKw,
      height: building.height,
    );

    return BoilerInstallationResult(
      totalLoadKcalPerHour: totalLoad,
      boilerCapacityKw: boilerKw,
      boilerCapacityKcalPerHour: boilerKcal,
      zones: zoneResults,
      totalFlowM3PerHour: totalFlow,
      collectorDiameterMm: collectorDiameter,
      expansion: expansion,
      building: building,
    );
  }

  static ExpansionTankResult _calculateExpansion({
    required int boilerKw,
    required double expansionCoefPerKw,
    required double height,
  }) {
    final openTank = _openTankLiters(boilerKw);

    final systemVolume = boilerKw * expansionCoefPerKw;
    final expansionVolume = (systemVolume * 3.55) / 100;
    final reserveVolume = systemVolume * 0.005;
    final openingPressure = _openingPressure(height);
    final needsCheck = openingPressure == null;
    final safetyPressure = openingPressure != null ? openingPressure - 0.5 : null;
    final staticPressure = height / 10;
    final closedTank = (safetyPressure != null && safetyPressure > staticPressure)
        ? (expansionVolume + reserveVolume) *
            (safetyPressure + 1) /
            (safetyPressure - staticPressure)
        : null;

    return ExpansionTankResult(
      openTankLiters: openTank,
      closedTankLiters: closedTank,
      openingPressureBar: openingPressure,
      safetyPressureBar: safetyPressure,
      staticPressureBar: staticPressure,
      systemVolumeLiters: systemVolume,
      expansionVolumeLiters: expansionVolume,
      reserveVolumeLiters: reserveVolume,
      needsHeightCheck: needsCheck,
    );
  }

  static int _openTankLiters(int boilerKw) {
    if (boilerKw < 70) return 25;
    if (boilerKw < 90) return 35;
    if (boilerKw < 120) return 50;
    if (boilerKw < 151) return 80;
    if (boilerKw < 181) return 80;
    return 0;
  }

  static double? _openingPressure(double height) {
    if (height < 15) return 2.5;
    if (height < 25) return 3.5;
    if (height < 35) return 4.5;
    if (height < 45) return 5.5;
    return null;
  }
}
