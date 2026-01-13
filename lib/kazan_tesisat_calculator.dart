class BoilerZoneInput {
  final String labelKey;
  final double loadKcalPerHour;
  final double deltaT;

  const BoilerZoneInput({
    required this.labelKey,
    required this.loadKcalPerHour,
    required this.deltaT,
  });
}

class BoilerZoneResult {
  final String labelKey;
  final double loadKcalPerHour;
  final double deltaT;
  final double flowM3PerHour;

  const BoilerZoneResult({
    required this.labelKey,
    required this.loadKcalPerHour,
    required this.deltaT,
    required this.flowM3PerHour,
  });
}

class BoilerInstallationResult {
  final double totalLoadKcalPerHour;
  final int boilerCapacityKw;
  final double boilerCapacityKcalPerHour;
  final List<BoilerZoneResult> zones;
  final double totalFlowM3PerHour;

  const BoilerInstallationResult({
    required this.totalLoadKcalPerHour,
    required this.boilerCapacityKw,
    required this.boilerCapacityKcalPerHour,
    required this.zones,
    required this.totalFlowM3PerHour,
  });
}

class BoilerInstallationCalculator {
  static BoilerInstallationResult calculate(List<BoilerZoneInput> zones) {
    final zoneResults = zones.map((zone) {
      final flow = zone.deltaT > 0
          ? zone.loadKcalPerHour / (zone.deltaT * 1000)
          : 0.0;
      return BoilerZoneResult(
        labelKey: zone.labelKey,
        loadKcalPerHour: zone.loadKcalPerHour,
        deltaT: zone.deltaT,
        flowM3PerHour: flow,
      );
    }).toList();

    final totalLoad =
        zoneResults.fold<double>(0, (sum, zone) => sum + zone.loadKcalPerHour);
    final boilerKw = totalLoad > 0 ? (totalLoad / 860).ceil() : 0;
    final boilerKcal = boilerKw * 860.0;
    final totalFlow =
        zoneResults.fold<double>(0, (sum, zone) => sum + zone.flowM3PerHour);

    return BoilerInstallationResult(
      totalLoadKcalPerHour: totalLoad,
      boilerCapacityKw: boilerKw,
      boilerCapacityKcalPerHour: boilerKcal,
      zones: zoneResults,
      totalFlowM3PerHour: totalFlow,
    );
  }
}
