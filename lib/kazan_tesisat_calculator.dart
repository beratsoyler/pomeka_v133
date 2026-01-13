<<<<<<< HEAD
import 'dart:math' as math;

const double _pi = 3.14;

enum BoilerSystemType {
  floorHeating,
  panelRadiator,
  steelRadiator,
  other,
}

double systemTypeCoefficient(BoilerSystemType type) {
  switch (type) {
    case BoilerSystemType.floorHeating:
      return 19.8;
    case BoilerSystemType.panelRadiator:
      return 9.4;
    case BoilerSystemType.steelRadiator:
      return 16;
    case BoilerSystemType.other:
      return 12;
  }
}

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
=======
class BoilerZoneInput {
  final String labelKey;
  final double loadKcalPerHour;
  final double deltaT;

  const BoilerZoneInput({
    required this.labelKey,
    required this.loadKcalPerHour,
    required this.deltaT,
>>>>>>> origin/master
  });
}

class BoilerZoneResult {
  final String labelKey;
<<<<<<< HEAD
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

class BoilerExpansionResult {
  final double openTankLiters;
  final double? closedTankLiters;
  final double? openingPressureBar;
  final double? safetyPressureBar;
  final double? staticPressureBar;
  final double? systemVolumeLiters;
  final double? expansionVolumeLiters;
  final double? reserveVolumeLiters;
  final bool heightWarning;

  const BoilerExpansionResult({
    required this.openTankLiters,
    required this.closedTankLiters,
    required this.openingPressureBar,
    required this.safetyPressureBar,
    required this.staticPressureBar,
    required this.systemVolumeLiters,
    required this.expansionVolumeLiters,
    required this.reserveVolumeLiters,
    required this.heightWarning,
=======
  final double loadKcalPerHour;
  final double deltaT;
  final double flowM3PerHour;

  const BoilerZoneResult({
    required this.labelKey,
    required this.loadKcalPerHour,
    required this.deltaT,
    required this.flowM3PerHour,
>>>>>>> origin/master
  });
}

class BoilerInstallationResult {
  final double totalLoadKcalPerHour;
  final int boilerCapacityKw;
  final double boilerCapacityKcalPerHour;
  final List<BoilerZoneResult> zones;
  final double totalFlowM3PerHour;
<<<<<<< HEAD
  final double collectorDiameterMm;
  final BoilerExpansionResult expansion;
=======
>>>>>>> origin/master

  const BoilerInstallationResult({
    required this.totalLoadKcalPerHour,
    required this.boilerCapacityKw,
    required this.boilerCapacityKcalPerHour,
    required this.zones,
    required this.totalFlowM3PerHour,
<<<<<<< HEAD
    required this.collectorDiameterMm,
    required this.expansion,
=======
>>>>>>> origin/master
  });
}

class BoilerInstallationCalculator {
<<<<<<< HEAD
  static BoilerInstallationResult calculate({
    required List<BoilerZoneInput> zones,
    required double collectorVelocity,
    required double buildingHeight,
    required BoilerSystemType systemType,
  }) {
=======
  static BoilerInstallationResult calculate(List<BoilerZoneInput> zones) {
>>>>>>> origin/master
    final zoneResults = zones.map((zone) {
      final flow = zone.deltaT > 0
          ? zone.loadKcalPerHour / (zone.deltaT * 1000)
          : 0.0;
<<<<<<< HEAD
      final diameter =
          zone.velocity > 0 ? _diameterFromFlow(flow, zone.velocity) : 0.0;
      return BoilerZoneResult(
        labelKey: zone.labelKey,
        velocity: zone.velocity,
        deltaT: zone.deltaT,
        loadKcalPerHour: zone.loadKcalPerHour,
        flowM3PerHour: flow,
        diameterMm: diameter,
      );
    }).toList();

    final totalLoad = zoneResults.fold<double>(
        0, (sum, zone) => sum + zone.loadKcalPerHour);
=======
      return BoilerZoneResult(
        labelKey: zone.labelKey,
        loadKcalPerHour: zone.loadKcalPerHour,
        deltaT: zone.deltaT,
        flowM3PerHour: flow,
      );
    }).toList();

    final totalLoad =
        zoneResults.fold<double>(0, (sum, zone) => sum + zone.loadKcalPerHour);
>>>>>>> origin/master
    final boilerKw = totalLoad > 0 ? (totalLoad / 860).ceil() : 0;
    final boilerKcal = boilerKw * 860.0;
    final totalFlow =
        zoneResults.fold<double>(0, (sum, zone) => sum + zone.flowM3PerHour);
<<<<<<< HEAD
    final collectorDiameter = collectorVelocity > 0
        ? _diameterFromFlow(totalFlow, collectorVelocity)
        : 0.0;
=======
>>>>>>> origin/master

    return BoilerInstallationResult(
      totalLoadKcalPerHour: totalLoad,
      boilerCapacityKw: boilerKw,
      boilerCapacityKcalPerHour: boilerKcal,
      zones: zoneResults,
      totalFlowM3PerHour: totalFlow,
<<<<<<< HEAD
      collectorDiameterMm: collectorDiameter,
      expansion: _calculateExpansion(
        boilerKw: boilerKw,
        buildingHeight: buildingHeight,
        systemType: systemType,
      ),
    );
  }

  static double _diameterFromFlow(double flowM3PerHour, double velocity) {
    return math.sqrt((4 * flowM3PerHour) / (_pi * 3600 * velocity)) * 1000;
  }

  static BoilerExpansionResult _calculateExpansion({
    required int boilerKw,
    required double buildingHeight,
    required BoilerSystemType systemType,
  }) {
    final openTank = _openTankLiters(boilerKw);

    if (boilerKw <= 0) {
      return BoilerExpansionResult(
        openTankLiters: openTank,
        closedTankLiters: 0,
        openingPressureBar: 0,
        safetyPressureBar: 0,
        staticPressureBar: 0,
        systemVolumeLiters: 0,
        expansionVolumeLiters: 0,
        reserveVolumeLiters: 0,
        heightWarning: false,
      );
    }

    final openingPressure = _openingPressure(buildingHeight);
    final heightWarning = openingPressure == null;
    final statikBar = buildingHeight / 10;
    final coefficient = systemTypeCoefficient(systemType);
    final systemVolume = boilerKw * coefficient;
    final expansionVolume = (systemVolume * 3.55) / 100;
    final reserveVolume = systemVolume * 0.005;

    if (openingPressure == null) {
      return BoilerExpansionResult(
        openTankLiters: openTank,
        closedTankLiters: null,
        openingPressureBar: null,
        safetyPressureBar: null,
        staticPressureBar: statikBar,
        systemVolumeLiters: systemVolume,
        expansionVolumeLiters: expansionVolume,
        reserveVolumeLiters: reserveVolume,
        heightWarning: heightWarning,
      );
    }

    final safetyBar = openingPressure - 0.5;
    final closedTank = (expansionVolume + reserveVolume) *
        (safetyBar + 1) /
        (safetyBar - statikBar);

    return BoilerExpansionResult(
      openTankLiters: openTank,
      closedTankLiters: closedTank,
      openingPressureBar: openingPressure,
      safetyPressureBar: safetyBar,
      staticPressureBar: statikBar,
      systemVolumeLiters: systemVolume,
      expansionVolumeLiters: expansionVolume,
      reserveVolumeLiters: reserveVolume,
      heightWarning: heightWarning,
    );
  }

  static double _openTankLiters(int boilerKw) {
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
=======
    );
  }
>>>>>>> origin/master
}
