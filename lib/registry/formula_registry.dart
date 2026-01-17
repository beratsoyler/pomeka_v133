import 'package:flutter/material.dart';

import '../models/category_meta.dart';
import '../models/formula_meta.dart';
import '../localization/app_locale.dart';
import '../screens/calculators.dart';
import '../screens/formula_screen.dart';
import '../state/app_state.dart';

class FormulaRegistry {
  static const String categoryWater = 'water_systems';
  static const String categoryHeating = 'heating';
  static const String categoryPumps = 'pump_calculations';
  static const String categoryUtilities = 'utilities';

  static const List<CategoryMeta> categories = [
    CategoryMeta(
      id: categoryWater,
      titleKey: 'cat_water_systems',
      icon: Icons.water_drop,
      sortOrder: 1,
    ),
    CategoryMeta(
      id: categoryHeating,
      titleKey: 'cat_heating',
      icon: Icons.thermostat,
      sortOrder: 2,
    ),
    CategoryMeta(
      id: categoryPumps,
      titleKey: 'cat_pump_calculations',
      icon: Icons.water_drop_outlined,
      sortOrder: 3,
    ),
    CategoryMeta(
      id: categoryUtilities,
      titleKey: 'cat_utilities',
      icon: Icons.change_circle,
      sortOrder: 4,
    ),
  ];

  static final List<FormulaMeta> formulas = [
    FormulaMeta(
      id: 'hydrofor',
      titleKey: 'hydrofor',
      categoryId: categoryWater,
      icon: Icons.water_drop,
      tags: const ['pump', 'booster', 'flow', 'pressure'],
      builder: (context) => FormulaScreen(
        formulaId: 'hydrofor',
        titleKey: 'hydrofor',
        child: HydroforTab(
          toTank: (transfer) {
            final tank = FormulaRegistry.findById('tank');
            if (tank == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocale.t('transfer_target_missing'))),
              );
              return;
            }
            AppStateScope.of(context).setTransfer(transfer);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(AppLocale.t('transfer_success'))),
            );
            Navigator.push(context, MaterialPageRoute(builder: tank.builder));
          },
        ),
      ),
    ),
    FormulaMeta(
      id: 'recirculation_pump',
      titleKey: 'recirculation_pump',
      categoryId: categoryPumps,
      icon: Icons.loop,
      tags: const ['pump', 'recirculation', 'flow', 'heat'],
      builder: (context) => const FormulaScreen(
        formulaId: 'recirculation_pump',
        titleKey: 'recirculation_pump',
        child: RecirculationPumpTab(),
      ),
    ),
    FormulaMeta(
      id: 'shunt_pump',
      titleKey: 'shunt_pump',
      categoryId: categoryPumps,
      icon: Icons.rotate_left,
      tags: const ['pump', 'shunt', 'flow', 'head'],
      builder: (context) => const FormulaScreen(
        formulaId: 'shunt_pump',
        titleKey: 'shunt_pump',
        child: ShuntPumpTab(),
      ),
    ),
    FormulaMeta(
      id: 'boiler_installation',
      titleKey: 'boiler',
      categoryId: categoryHeating,
      icon: Icons.thermostat,
      tags: const ['boiler', 'heating', 'load'],
      builder: (context) => const FormulaScreen(
        formulaId: 'boiler_installation',
        titleKey: 'boiler',
        child: BoilerInstallationTab(),
      ),
    ),
    FormulaMeta(
      id: 'tank',
      titleKey: 'tank',
      categoryId: categoryHeating,
      icon: Icons.storage,
      tags: const ['expansion', 'pressure', 'tank'],
      builder: (context) => const FormulaScreen(
        formulaId: 'tank',
        titleKey: 'tank',
        child: TankTab(),
      ),
    ),
    FormulaMeta(
      id: 'boiler_expansion_tank',
      titleKey: 'boiler_expansion_tank',
      categoryId: categoryHeating,
      icon: Icons.storage,
      tags: const ['boiler', 'expansion', 'tank', 'pressure'],
      builder: (context) => const FormulaScreen(
        formulaId: 'boiler_expansion_tank',
        titleKey: 'boiler_expansion_tank',
        child: BoilerExpansionTankTab(),
      ),
    ),
    FormulaMeta(
      id: 'unit_converter',
      titleKey: 'converter',
      categoryId: categoryUtilities,
      icon: Icons.change_circle,
      tags: const ['units', 'converter'],
      builder: (context) => const FormulaScreen(
        formulaId: 'unit_converter',
        titleKey: 'converter',
        child: UnitConverterTab(),
      ),
    ),
  ];

  static List<FormulaMeta> enabledFormulas() {
    return formulas.where((f) => f.enabled).toList();
  }

  static FormulaMeta? findById(String id) {
    try {
      return formulas.firstWhere((f) => f.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<FormulaMeta> formulasForCategory(String categoryId) {
    return formulas
        .where((f) => f.categoryId == categoryId && f.enabled)
        .toList();
  }

  static int countForCategory(String categoryId) {
    return formulas
        .where((f) => f.categoryId == categoryId && f.enabled)
        .length;
  }
}
