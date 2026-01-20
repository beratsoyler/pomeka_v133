class FanCoilCalculator {
  static const Map<FanCoilUsageType, FanCoilLoad> _loads = {
    FanCoilUsageType.insulatedResidential: FanCoilLoad(qc: 130, qh: 70),
    FanCoilUsageType.midInsulatedResidential: FanCoilLoad(qc: 150, qh: 100),
    FanCoilUsageType.office: FanCoilLoad(qc: 170, qh: 90),
    FanCoilUsageType.shopShowcase: FanCoilLoad(qc: 210, qh: 120),
  };

  static FanCoilLoad loadsFor(FanCoilUsageType usageType) {
    return _loads[usageType]!;
  }

  static FanCoilResult compute({
    required double areaM2,
    required FanCoilUsageType usageType,
  }) {
    final loads = loadsFor(usageType);
    final qCoolKw = areaM2 * loads.qc / 1000;
    final qHeatKw = areaM2 * loads.qh / 1000;
    return FanCoilResult(
      qc: loads.qc,
      qh: loads.qh,
      qCoolKw: qCoolKw,
      qHeatKw: qHeatKw,
    );
  }
}

class FanCoilLoad {
  final double qc;
  final double qh;

  const FanCoilLoad({required this.qc, required this.qh});
}

class FanCoilResult {
  final double qc;
  final double qh;
  final double qCoolKw;
  final double qHeatKw;

  const FanCoilResult({
    required this.qc,
    required this.qh,
    required this.qCoolKw,
    required this.qHeatKw,
  });
}

enum FanCoilUsageType {
  insulatedResidential,
  midInsulatedResidential,
  office,
  shopShowcase,
}
