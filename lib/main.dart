import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// ---------------------------------------------------------------------------
// 1. AYARLAR, SABİTLER VE BORU STANDARTLARI (EXCEL UYUMLU)
// ---------------------------------------------------------------------------
class AppConstants {
  static const String appName = 'POMEKA';
  static const String logoPath = 'assets/pomeka-png-1757403926.png';

  static const Color primaryColor = Color(0xFF0D47A1);
  static const Color accentColor = Color(0xFF1976D2);
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkCardColor = Color(0xFF1E1E1E);
}

// Excel mantığına göre Ticari Boru Standartları
class PipeStandard {
  final String name;      // Örn: "1" (DN25)"
  final double innerDia;  // mm cinsinden iç çap
  final String label;     // Ekranda görünecek kısa ad

  PipeStandard(this.name, this.innerDia, this.label);
}

class AppPipeStandards {
  // EXCEL "Boru Çapı Hesabı-2.csv" DOSYASINDAKİ DEĞERLERLE BİREBİR AYNI LİSTE
  static final List<PipeStandard> pipes = [
    PipeStandard('1/2" (DN15)', 15.75, 'DN15'),
    PipeStandard('3/4" (DN20)', 21.25, 'DN20'),
    PipeStandard('1" (DN25)', 27.0, 'DN25'),
    PipeStandard('1 1/4" (DN32)', 35.0, 'DN32'),
    PipeStandard('1 1/2" (DN40)', 41.25, 'DN40'),
    PipeStandard('2" (DN50)', 52.0, 'DN50'),
    PipeStandard('2 1/2" (DN65)', 65.0, 'DN65'),
    PipeStandard('3" (DN80)', 80.0, 'DN80'),
    PipeStandard('4" (DN100)', 105.0, 'DN100'),
    PipeStandard('5" (DN125)', 130.0, 'DN125'),
    PipeStandard('6" (DN150)', 155.0, 'DN150'),
    PipeStandard('8" (DN200)', 207.0, 'DN200'),
    PipeStandard('10" (DN250)', 260.0, 'DN250'),
    PipeStandard('12" (DN300)', 310.0, 'DN300'),
  ];

  static PipeStandard selectPipe(double calculatedMm) {
    return pipes.firstWhere(
          (p) => p.innerDia >= calculatedMm,
      orElse: () => pipes.last,
    );
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const PomekaApp());
}

// ---------------------------------------------------------------------------
// 2. ANA UYGULAMA YAPISI
// ---------------------------------------------------------------------------
class PomekaApp extends StatefulWidget {
  const PomekaApp({super.key});

  @override
  State<PomekaApp> createState() => _PomekaAppState();
}

class _PomekaAppState extends State<PomekaApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _showSplash = true;

  void _toggleTheme() {
    setState(() => _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      home: _showSplash
          ? SplashScreen(onCompleted: () => setState(() => _showSplash = false))
          : DashboardScreen(
        isDarkMode: _themeMode == ThemeMode.dark,
        onThemeToggle: _toggleTheme,
      ),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: isDark ? AppConstants.darkBackground : AppConstants.lightBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: brightness,
        surface: isDark ? AppConstants.darkCardColor : Colors.white,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(
          isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        color: isDark ? AppConstants.darkCardColor : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isDark ? BorderSide(color: Colors.white.withValues(alpha: 0.1)) : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF2C2C2C) : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.3))),
        focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
            borderSide: BorderSide(color: AppConstants.primaryColor, width: 2)
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppConstants.darkBackground : AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. SPLASH SCREEN
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const SplashScreen({super.key, required this.onCompleted});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)));
    _controller.forward();
    Future.delayed(const Duration(seconds: 2, milliseconds: 500), () {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(AppConstants.logoPath, width: 250, errorBuilder: (context, error, stackTrace) => const Icon(Icons.engineering, size: 100, color: AppConstants.primaryColor)),
                  const SizedBox(height: 30),
                  Text("MÜHENDİSLİK ÇÖZÜMLERİ",
                      style: GoogleFonts.poppins(
                          fontSize: 14, letterSpacing: 3, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. DİL VE ÇEVİRİ SİSTEMİ
// ---------------------------------------------------------------------------
class AppLocale {
  static String currentLang = 'TR';
  static void toggle() {
    currentLang = currentLang == 'TR' ? 'EN' : 'TR';
  }

  static const Map<String, Map<String, String>> _localizedValues = {
    'TR': {
      'dashboard': 'Kontrol Paneli', 'search_hint': 'Hesaplama Ara...',
      'cat_water': 'SU TEMİNİ', 'cat_heat': 'ISITMA SİSTEMLERİ', 'cat_tools': 'ARAÇLAR',
      'hydrofor': 'Hidrofor Hesabı', 'boiler': 'Kazan Tesisat Hesabı', 'tank': 'Genleşme Tankı', 'converter': 'Birim Dönüştürücü',
      'chimney': 'Baca Kesit Hesabı', // Eklendi
      'calculate': 'HESAPLA', 'clean': 'TEMİZLE', 'add_zone': '+ ZON EKLE', 'remove': 'SİL',
      'units': 'Daire/Birim Sayısı', 'floors': 'Bina Kat Sayısı', 'b_type': 'Bina Tipi', 'people': 'Hane Başı Kişi',
      'coil': 'Serpantin Tipi', 'res_flow': 'Debi (Q)', 'res_press': 'Basınç (Hm)', 'res_vol': 'Boyler Hacmi (V)',
      'tank_vol': 'Tank Hacmi (Vtank)', 'heat_cap': 'Isıtıcı Kapasitesi (kW)', 'sys_h': 'Sistem Yüksekliği (m)',
      'temp_f': 'Gidiş Sıcaklığı (°C)', 'temp_r': 'Dönüş Sıcaklığı (°C)', 'heat_type': 'Isıtıcı Tipi', 'glycol': 'Glikol Oranı (%)',
      'res_static': 'Statik Basınç', 'res_pregas': 'Ön Gaz Basıncı', 'res_safety': 'Emniyet Ventili', 'res_exp_vol': 'Genleşen Hacim', 'res_water_vol': 'Su Hacmi (Vs)',
      'h_panel': 'Panel Radyatör', 'h_cast': 'Döküm Radyatör', 'h_floor': 'Yerden Isıtma', 'h_fancoil': 'Fan Coil',
      't_konut': 'Toplu Konutlar', 'l_konut': 'Lüks Konutlar', 'l_villa': 'Lüks Villalar', 'misafir': 'Misafirhaneler',
      'otel': 'Oteller', 'hasta': 'Hastaneler', 'buro': 'Bürolar', 'okul': 'Okullar', 'y_okul': 'Yatılı Okullar', 'avm': 'AVM',
      'single': 'Tek Serpantin', 'double': 'Çift Serpantin',
      'go_tank': 'Tank Hesabına Aktar', 'share_pdf': 'PDF Raporu Oluştur',
      'report_title': 'POMEKA MÜHENDİSLİK RAPORU', 'min_unit': 'dk', 'press_unit': 'mSS', 'flow_unit': 'm³/h', 'bar_unit': 'Bar',
      'pdf_footer': 'Bu belge POMEKA Mobil Uygulaması tarafından oluşturulmuştur.', 'date': 'Tarih', 'history_title': 'Hesaplama Geçmişi',
      'inputs': 'Girişler', 'results': 'Sonuçlar', 'no_data': 'Henüz hesaplama yok.', 'export_selected': 'Seçilenleri PDF Yap',
      'val_input': 'Değer Girin', 'cat_press': 'Basınç', 'cat_flow': 'Debi', 'cat_power': 'Güç', 'cat_len': 'Uzunluk', 'cat_vol': 'Hacim',

      'zone_title': 'Zon', 'heat_load': 'Isı Yükü (kcal/h)', 'delta_t': 'ΔT (°C)', 'velocity': 'Hız (m/s)',
      'pipe_dia': 'Boru Çapı', 'total_kw': 'TOPLAM KAZAN GÜCÜ', 'mm_unit': 'mm', 'collector_dia': 'Ana Kollektör Çapı',
      'type_rad': 'Radyatör', 'type_floor': 'Yerden Isıtma', 'type_pool': 'Havuz', 'type_boiler': 'Boyler', 'type_other': 'Diğer',
      'est_tank': 'Tahmini Genleşme Tankı', 'b_height': 'Bina Yüksekliği (m)',
      'total_water': 'Toplam Su Hacmi (Vs)', 'calc_dia': 'Hesaplanan', 'sel_pipe': 'Seçilen',
      // Baca Hesabı Çevirileri
      'fuel_type': 'Yakıt Türü', 'gas': 'Doğalgaz', 'liquid': 'Sıvı Yakıt', 'solid': 'Katı Yakıt',
      'chimney_area': 'Baca Kesit Alanı', 'chimney_dia': 'Baca Çapı (Ø)', 'rec_dia': 'Önerilen Çap', 'res_area_cm2': 'Alan (cm²)',
    },
    'EN': {
      'dashboard': 'Dashboard', 'search_hint': 'Search Calculations...',
      'cat_water': 'WATER SUPPLY', 'cat_heat': 'HEATING SYSTEMS', 'cat_tools': 'TOOLS',
      'hydrofor': 'Booster Calculation', 'boiler': 'Boiler Calculation', 'tank': 'Expansion Tank', 'converter': 'Unit Converter',
      'chimney': 'Chimney Calculation',
      'calculate': 'CALCULATE', 'clean': 'CLEAR', 'add_zone': '+ ADD ZONE', 'remove': 'REMOVE',
      'units': 'Units/Flats', 'floors': 'Floors', 'b_type': 'Building Type', 'people': 'People/Flat',
      'coil': 'Coil Type', 'res_flow': 'Flow (Q)', 'res_press': 'Pressure (Hm)', 'res_vol': 'Boiler Volume (V)',
      'tank_vol': 'Tank Volume (Vtank)', 'heat_cap': 'Heater Capacity (kW)', 'sys_h': 'System Height (m)',
      'zone_title': 'Zone', 'heat_load': 'Heat Load (kcal/h)', 'delta_t': 'ΔT (°C)', 'velocity': 'Velocity (m/s)',
      'pipe_dia': 'Pipe Dia', 'total_kw': 'TOTAL BOILER POWER', 'mm_unit': 'mm', 'collector_dia': 'Main Collector Dia',
      'type_rad': 'Radiator', 'type_floor': 'Floor Heating', 'type_pool': 'Pool', 'type_boiler': 'Boiler', 'type_other': 'Other',
      'est_tank': 'Est. Expansion Tank', 'b_height': 'Building Height (m)',
      'total_water': 'Total Water Volume (Vs)', 'calc_dia': 'Calculated', 'sel_pipe': 'Selected',
      // Chimney Translations
      'fuel_type': 'Fuel Type', 'gas': 'Natural Gas', 'liquid': 'Liquid Fuel', 'solid': 'Solid Fuel',
      'chimney_area': 'Chimney Section Area', 'chimney_dia': 'Chimney Diameter (Ø)', 'rec_dia': 'Recommended Dia', 'res_area_cm2': 'Area (cm²)',
    }
  };
  static String t(String key) => _localizedValues[currentLang]?[key] ?? key;
}

// ---------------------------------------------------------------------------
// 5. DASHBOARD SCREEN
// ---------------------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  final bool isDarkMode;
  final VoidCallback onThemeToggle;
  const DashboardScreen({super.key, required this.isDarkMode, required this.onThemeToggle});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> _menuItems = [
    {'id': 'hydrofor', 'icon': Icons.water_drop, 'cat': 'cat_water', 'page': const HydroforTab(), 'tags': ['su', 'basınç', 'pompa', 'hidrofor', 'konut']},
    {'id': 'tank', 'icon': Icons.storage, 'cat': 'cat_heat', 'page': const TankTab(), 'tags': ['tank', 'genleşme', 'ısıtma', 'kazan']},
    {'id': 'boiler', 'icon': Icons.thermostat, 'cat': 'cat_heat', 'page': const BoilerTab(), 'tags': ['boyler', 'kazan', 'boru', 'ısıtma']},
    // YENİ EKLENEN BACA HESABI MODÜLÜ
    {'id': 'chimney', 'icon': Icons.cloud_upload, 'cat': 'cat_heat', 'page': const ChimneyTab(), 'tags': ['baca', 'duman', 'kazan', 'gaz', 'boru']},
    {'id': 'converter', 'icon': Icons.change_circle, 'cat': 'cat_tools', 'page': const UnitConverterTab(), 'tags': ['birim', 'çevirici', 'bar', 'kw', 'uzunluk']},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredItems = _menuItems.where((item) {
      final title = AppLocale.t(item['id']).toLowerCase();
      final tags = (item['tags'] as List<String>).join(' ').toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query) || tags.contains(query);
    }).toList();

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        mini: true,
        backgroundColor: AppConstants.primaryColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onPressed: () => setState(() => AppLocale.toggle()),
        child: Text(
          AppLocale.currentLang,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Image.asset(
          AppConstants.logoPath,
          height: 32,
          color: Colors.white,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => const Text(AppConstants.appName),
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()))
          ),
          IconButton(
              icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: widget.onThemeToggle
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                  hintText: AppLocale.t('search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(icon: const Icon(Icons.clear), onPressed: (){ _searchCtrl.clear(); setState(() => _searchQuery=""); })
                      : null
              ),
            ),
          ),
          Expanded(
            child: filteredItems.isEmpty
                ? Center(child: Text(AppLocale.t('no_data'), style: const TextStyle(color: Colors.grey)))
                : GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: filteredItems.length,
              itemBuilder: (context, index) => _buildMenuCard(filteredItems[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CalculatorDetailScreen(titleKey: item['id'], child: item['page']))),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.zero,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppConstants.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(item['icon'], size: 40, color: AppConstants.primaryColor),
            ),
            const SizedBox(height: 16),
            Text(AppLocale.t(item['id']), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 4),
            Text(AppLocale.t(item['cat']), style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600))
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. DETAY SAYFASI
// ---------------------------------------------------------------------------
class CalculatorDetailScreen extends StatelessWidget {
  final String titleKey;
  final Widget child;
  const CalculatorDetailScreen({super.key, required this.titleKey, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t(titleKey).toUpperCase()),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios), onPressed: () => Navigator.pop(context)),
      ),
      body: child,
    );
  }
}

// ---------------------------------------------------------------------------
// 7. HESAPLAMA MODÜLLERİ
// ---------------------------------------------------------------------------

// --- A. HİDROFOR HESABI ---
class HydroforTab extends StatefulWidget {
  final Function(String, String)? onRes;
  final VoidCallback? toTank;
  const HydroforTab({super.key, this.onRes, this.toTank});

  @override
  State<HydroforTab> createState() => _HydroforTabState();
}

class _HydroforTabState extends State<HydroforTab> {
  final _unitCountCtrl = TextEditingController();
  final _floorCountCtrl = TextEditingController();
  String _buildingType = 't_konut';
  String? _flowResult, _pressureResult;
  bool _loading = false;

  void _clear() {
    setState(() {
      _unitCountCtrl.clear();
      _floorCountCtrl.clear();
      _buildingType = 't_konut';
      _flowResult = null;
      _pressureResult = null;
      _loading = false;
    });
  }

  void _calculate() async {
    if (_unitCountCtrl.text.isEmpty || _floorCountCtrl.text.isEmpty) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300));

    final units = int.parse(_unitCountCtrl.text);
    final floors = int.parse(_floorCountCtrl.text);
    double consumption = _getConsumption(_buildingType);
    double simultaneity = _getSimultaneity(units);

    double q = (units * 4.0 * consumption * simultaneity) / 1000.0;
    double hm = (floors * 3.0) + 30.0;

    if (mounted) {
      setState(() {
        _flowResult = '${q.toStringAsFixed(2)} ${AppLocale.t('flow_unit')}';
        _pressureResult = '${hm.toStringAsFixed(2)} ${AppLocale.t('press_unit')}';
        _loading = false;
      });
      _saveHistory(AppLocale.t('hydrofor'), '$_flowResult / $_pressureResult', '${AppLocale.t('units')}: $units');
    }
  }

  double _getConsumption(String type) {
    switch (type) {
      case 'l_konut': case 'hasta': return 200.0;
      case 'l_villa': return 225.0;
      case 'misafir': case 'y_okul': return 100.0;
      case 'buro': return 80.0;
      case 'okul': return 20.0;
      case 'avm': return 50.0;
      default: return 150.0;
    }
  }

  double _getSimultaneity(int units) {
    if (units <= 4) return 0.66;
    if (units <= 10) return 0.45;
    if (units <= 20) return 0.40;
    if (units <= 50) return 0.35;
    if (units <= 100) return 0.30;
    return 0.25;
  }

  void _goToTankPage() {
    if (_flowResult == null) return;
    String q = _flowResult!.split(' ')[0];
    String h = _pressureResult!.split(' ')[0];
    Navigator.push(context, MaterialPageRoute(builder: (context) => CalculatorDetailScreen(titleKey: 'tank', child: TankTab(q: q, h: h))));
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(children: [
                  TextField(controller: _unitCountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocale.t('units'), prefixIcon: const Icon(Icons.people))),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(labelText: AppLocale.t('b_type'), prefixIcon: const Icon(Icons.business)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _buildingType, isExpanded: true,
                        onChanged: (v) => setState(() => _buildingType = v!),
                        items: ['t_konut', 'l_konut', 'l_villa', 'misafir', 'otel', 'hasta', 'buro', 'okul', 'y_okul', 'avm']
                            .map((e) => DropdownMenuItem(value: e, child: Text(AppLocale.t(e)))).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(controller: _floorCountCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocale.t('floors'), prefixIcon: const Icon(Icons.apartment))),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(horizontal: 4)
                          ),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(AppLocale.t('clean'), maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: PrimaryButton(onPressed: _calculate, label: AppLocale.t('calculate'))),
                    ],
                  ),
                ])
            )
        ),
        if (_loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
        if (_flowResult != null && !_loading)
          ResultContainer(
              children: [
                _ResultRow(label: AppLocale.t('res_flow'), value: _flowResult!, icon: Icons.water_drop),
                const Divider(),
                _ResultRow(label: AppLocale.t('res_press'), value: _pressureResult!, icon: Icons.speed),
                const SizedBox(height: 20),
                ResultChart(q: double.tryParse(_flowResult!.split(' ')[0]) ?? 0, hm: double.tryParse(_pressureResult!.split(' ')[0]) ?? 0, isDark: Theme.of(context).brightness == Brightness.dark),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: _goToTankPage, icon: const Icon(Icons.arrow_forward), label: Text(AppLocale.t('go_tank')), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12)))),
                    const SizedBox(width: 10),
                    Expanded(child: ElevatedButton.icon(onPressed: () => PdfService.generateAndShare(title: AppLocale.t('hydrofor'), data: {AppLocale.t('res_flow'): _flowResult!, AppLocale.t('res_press'): _pressureResult!}), icon: const Icon(Icons.picture_as_pdf), label: const Text("PDF"), style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)))),
                  ],
                )
              ]
          )
      ]),
    );
  }
}

// --- B. KAZAN TESİSAT HESABI (YENİLENMİŞ VE EXCEL MANTIĞINA UYUMLU) ---
class BoilerTab extends StatefulWidget {
  const BoilerTab({super.key});
  @override
  State<BoilerTab> createState() => _BoilerTabState();
}

class ZoneData {
  String type = 'type_rad'; // Varsayılan Radyatör
  TextEditingController kcalCtrl = TextEditingController();
  TextEditingController velCtrl = TextEditingController(text: '0.7');
  TextEditingController dtCtrl = TextEditingController(text: '20');
  double calculatedDiameter = 0;
  double calculatedFlow = 0;
  PipeStandard? selectedPipe; // Seçilen standart boru

  void dispose() {
    kcalCtrl.dispose();
    velCtrl.dispose();
    dtCtrl.dispose();
  }
}

class _BoilerTabState extends State<BoilerTab> {
  final List<ZoneData> _zones = [];
  final TextEditingController _heightCtrl = TextEditingController(text: '36');

  double _totalKw = 0;
  PipeStandard? _collectorPipe; // Ana kollektör borusu
  double _collectorDiaCalc = 0;
  double _expansionTankVol = 0;
  String _tankDetails = "";

  @override
  void initState() {
    super.initState();
    _addZone();
  }

  void _addZone() {
    setState(() {
      _zones.add(ZoneData());
    });
  }

  void _removeZone(int index) {
    if (_zones.length > 1) {
      setState(() {
        _zones[index].dispose();
        _zones.removeAt(index);
        _calculate();
      });
    }
  }

  void _updateZoneType(int index, String? newVal) {
    if (newVal == null) return;
    setState(() {
      _zones[index].type = newVal;
      // Excel mantığı: Radyatörde dT=20, Yerden ısıtmada dT=10
      switch (newVal) {
        case 'type_rad':
          _zones[index].dtCtrl.text = '20';
          _zones[index].velCtrl.text = '0.7';
          break;
        case 'type_floor':
          _zones[index].dtCtrl.text = '10';
          _zones[index].velCtrl.text = '0.7';
          break;
        case 'type_pool':
          _zones[index].dtCtrl.text = '15';
          _zones[index].velCtrl.text = '1.0';
          break;
        case 'type_boiler':
          _zones[index].dtCtrl.text = '20';
          _zones[index].velCtrl.text = '0.7';
          break;
        default:
          break;
      }
      _calculate();
    });
  }

  void _calculate() {
    double totalKcal = 0;
    double totalFlowCalc = 0;
    double totalSystemWaterVolume = 0; // Vs (Toplam Su Hacmi)

    // 1. ZON HESAPLARI
    for (var zone in _zones) {
      double kcal = double.tryParse(zone.kcalCtrl.text) ?? 0;
      double vel = double.tryParse(zone.velCtrl.text) ?? 0.7;
      double dt = double.tryParse(zone.dtCtrl.text) ?? 20;

      if (kcal > 0) {
        totalKcal += kcal;
        // Debi (m3/h) = Q / (dT * 1000)
        zone.calculatedFlow = kcal / (dt * 1000);
        totalFlowCalc += zone.calculatedFlow;

        // Boru Çapı (mm) = 18.8 * sqrt(Debi / Hız) Formülü
        if (vel > 0) {
          zone.calculatedDiameter = 18.8 * math.sqrt(zone.calculatedFlow / vel);
          // YUVARLAMA: Standart boruyu seç
          zone.selectedPipe = AppPipeStandards.selectPipe(zone.calculatedDiameter);
        }

        // --- EXCEL SU HACMİ KATSAYILARI ---
        double factor = 9.4; // Radyatör (Standart)
        if (zone.type == 'type_floor') factor = 19.8; // Yerden ısıtma
        if (zone.type == 'type_rad') factor = 9.4;
        if (zone.type == 'type_boiler') factor = 5.0; // Boyler (Daha az su)
        if (zone.type == 'type_pool') factor = 5.0;

        double kw = kcal / 860.0;
        totalSystemWaterVolume += kw * factor;
      } else {
        zone.calculatedFlow = 0;
        zone.calculatedDiameter = 0;
        zone.selectedPipe = null;
      }
    }

    // 2. KOLLEKTÖR HESABI
    double collectorVelocity = 0.7;
    if (totalFlowCalc > 0) {
      _collectorDiaCalc = 18.8 * math.sqrt(totalFlowCalc / collectorVelocity);
      _collectorPipe = AppPipeStandards.selectPipe(_collectorDiaCalc);
    } else {
      _collectorDiaCalc = 0;
      _collectorPipe = null;
    }

    // --- 3. GENLEŞME TANKI (EXCEL MANTIĞINA %100 ÇEVRİLDİ) ---
    double height = double.tryParse(_heightCtrl.text) ?? 10;
    double pStatic = height / 10.0; // Örn: 36m -> 3.6 bar

    double pSafety = pStatic.ceilToDouble() + 1.0;
    if (pSafety < 2.0) pSafety = 2.0;

    double expansionCoeff = 0.0355;

    double ve = totalSystemWaterVolume * expansionCoeff; // Genleşen Su
    double vv = totalSystemWaterVolume * 0.005; // Su Rezervi (%0.5)
    if (vv < 3.0) vv = 3.0; // Min 3 Litre

    double efficiency = (pSafety - pStatic) / (pSafety + 1);
    if(efficiency <= 0.1) efficiency = 0.1;

    double tankVolCalc = (ve + vv) / efficiency;

    setState(() {
      _totalKw = totalKcal / 860.0;
      _expansionTankVol = tankVolCalc;
      _tankDetails = "Su Hacmi (Vs): ${totalSystemWaterVolume.toStringAsFixed(1)} Lt\n"
          "Genleşme (Ve): ${ve.toStringAsFixed(1)} Lt (n=%${(expansionCoeff*100).toStringAsFixed(2)})\n"
          "P.Statik: ${pStatic.toStringAsFixed(1)} bar / P.Emn: ${pSafety.toStringAsFixed(1)} bar";
    });
  }

  void _clear() {
    setState(() {
      for (var z in _zones) {
        z.dispose();
      }
      _zones.clear();
      _totalKw = 0;
      _collectorDiaCalc = 0;
      _collectorPipe = null;
      _expansionTankVol = 0;
      _tankDetails = "";
      _addZone();
    });
  }

  @override
  void dispose() {
    for (var z in _zones) {
      z.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // BİNA YÜKSEKLİĞİ GİRİŞİ
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context).cardColor,
            child: Row(
              children: [
                const Icon(Icons.apartment, color: Colors.grey),
                const SizedBox(width: 10),
                Text("${AppLocale.t('b_height')}: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.all(8)),
                    onChanged: (_) => _calculate(),
                  ),
                ),
              ],
            ),
          ),

          // ZON LİSTESİ
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              itemCount: _zones.length,
              itemBuilder: (context, index) {
                final zone = _zones[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: zone.type,
                                items: ['type_rad', 'type_floor', 'type_pool', 'type_boiler', 'type_other']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(AppLocale.t(e), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))))
                                    .toList(),
                                onChanged: (val) => _updateZoneType(index, val),
                              ),
                            ),
                            if (_zones.length > 1)
                              IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeZone(index))
                          ],
                        ),
                        const Divider(),
                        Row(
                          children: [
                            Expanded(child: _buildInput(zone.kcalCtrl, AppLocale.t('heat_load'))),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInput(zone.dtCtrl, AppLocale.t('delta_t'))),
                            const SizedBox(width: 10),
                            Expanded(child: _buildInput(zone.velCtrl, AppLocale.t('velocity'))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // SONUÇ KARTI
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${AppLocale.t('cat_flow')}: ${zone.calculatedFlow.toStringAsFixed(2)} m³/h', style: const TextStyle(fontSize: 12)),
                                  Text('${AppLocale.t('calc_dia')}: ${zone.calculatedDiameter.toStringAsFixed(1)} mm', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const Divider(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle, size: 16, color: AppConstants.primaryColor),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${AppLocale.t('sel_pipe')}: ${zone.selectedPipe?.name ?? '-'}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor, fontSize: 16),
                                  ),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ALT BİLGİ PANELİ
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, -5))],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      // Ana Kollektör
                      Expanded(
                        child: _buildSummaryBox(
                            AppLocale.t('collector_dia'),
                            _collectorPipe?.name ?? "-"
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Genleşme Tankı
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if(_tankDetails.isNotEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_tankDetails), duration: const Duration(seconds: 4)));
                            }
                          },
                          child: _buildSummaryBox(AppLocale.t('est_tank'), "${_expansionTankVol.toStringAsFixed(0)} Lt"),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppLocale.t('total_kw'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${_totalKw.toStringAsFixed(2)} kW', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: AppConstants.primaryColor)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _addZone,
                      icon: const Icon(Icons.add),
                      label: Text(AppLocale.t('add_zone')),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocale.t('clean')),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: PrimaryButton(
                          onPressed: () {
                            FocusScope.of(context).unfocus();
                            _calculate();
                          },
                          label: AppLocale.t('calculate'),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryBox(String title, String val) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppConstants.primaryColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppConstants.primaryColor.withValues(alpha: 0.2))
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1),
          const SizedBox(height: 4),
          FittedBox(fit: BoxFit.scaleDown, child: Text(val, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppConstants.primaryColor))),
        ],
      ),
    );
  }

  Widget _buildInput(TextEditingController ctrl, String label) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        labelStyle: const TextStyle(fontSize: 11),
      ),
      onChanged: (_) => _calculate(),
    );
  }
}

// --- C. GENLEŞME TANKI HESABI ---
class TankTab extends StatefulWidget {
  final String? q, h;
  const TankTab({super.key, this.q, this.h});
  @override
  State<TankTab> createState() => _TankTabState();
}

class _TankTabState extends State<TankTab> {
  late TextEditingController _kwCtrl;
  late TextEditingController _hCtrl;
  final _tfCtrl = TextEditingController(text: '80');
  final _trCtrl = TextEditingController(text: '60');
  double _heaterFactor = 12.0;
  double _glycol = 0.0;
  String? _resTank, _resStatic, _resPreGas, _resSafety, _resExpVol, _resWaterVol;
  double? _numericWaterVol, _numericMaxTemp;

  @override
  void initState() {
    super.initState();
    _kwCtrl = TextEditingController(text: widget.q);
    _hCtrl = TextEditingController(text: widget.h != null ? (double.tryParse(widget.h!)! * 3).toString() : '');
  }

  void _clear() {
    setState(() {
      _kwCtrl.clear();
      _hCtrl.clear();
      _tfCtrl.text = '80';
      _trCtrl.text = '60';
      _heaterFactor = 12.0;
      _glycol = 0.0;
      _resTank = null; _resStatic = null; _resPreGas = null; _resSafety = null; _resExpVol = null; _resWaterVol = null;
      _numericWaterVol = null; _numericMaxTemp = null;
    });
  }

  void _calculate() {
    final kw = double.tryParse(_kwCtrl.text);
    final h = double.tryParse(_hCtrl.text);
    final tf = double.tryParse(_tfCtrl.text) ?? 80;
    final tr = double.tryParse(_trCtrl.text) ?? 60;
    if (kw == null || h == null) return;

    double vs = kw * _heaterFactor;
    double pst = h / 10.0;
    double p0 = pst + 0.2;
    double pmax = pst + 1.5;
    double tm = (tf + tr) / 2;
    double roCold = 999.0;
    double roHot = 1000.0 - ((tm - 4) * (tm - 4) / 180.0);
    double n = ((roCold / roHot) - 1) * 100;
    if (n <= 0) n = 0.5;
    if (_glycol > 0) n *= 1.1;

    double ve = vs * n / 100.0;
    double vwr = math.max(vs * 0.005, 3.0);
    double k = ((pmax + 1) - (p0 + 1)) / (pmax + 1);
    if (k <= 0) k = 0.1;

    setState(() {
      _numericWaterVol = vs;
      _numericMaxTemp = tf;
      _resWaterVol = '${vs.toStringAsFixed(0)} L';
      _resStatic = '${pst.toStringAsFixed(1)} Bar';
      _resPreGas = '${p0.toStringAsFixed(1)} Bar';
      _resSafety = '${pmax.toStringAsFixed(1)} Bar';
      _resExpVol = '${ve.toStringAsFixed(1)} L';
      _resTank = '${((ve + vwr) / k).toStringAsFixed(1)} L';
    });
    _saveHistory(AppLocale.t('tank'), _resTank!, 'kW: $kw, H: $h');
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(children: [
          Row(children: [
            Expanded(child: TextField(controller: _kwCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocale.t('heat_cap'), prefixIcon: const Icon(Icons.bolt)))),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _hCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocale.t('sys_h'), prefixIcon: const Icon(Icons.height)))),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: TextField(controller: _tfCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocale.t('temp_f'), prefixIcon: const Icon(Icons.thermostat, color: Colors.red)))),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _trCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: AppLocale.t('temp_r'), prefixIcon: const Icon(Icons.thermostat, color: Colors.blue)))),
          ]),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(labelText: AppLocale.t('heat_type'), prefixIcon: const Icon(Icons.whatshot)),
            child: DropdownButtonHideUnderline(child: DropdownButton<double>(value: _heaterFactor, isExpanded: true, onChanged: (v) => setState(() => _heaterFactor = v!), items: [12.0, 15.0, 20.0, 8.0].asMap().entries.map((e) => DropdownMenuItem(value: e.value, child: Text(AppLocale.t(['h_panel', 'h_cast', 'h_floor', 'h_fancoil'][e.key])))).toList())),
          ),
          const SizedBox(height: 16),
          InputDecorator(
            decoration: InputDecoration(labelText: AppLocale.t('glycol'), prefixIcon: const Icon(Icons.ac_unit)),
            child: DropdownButtonHideUnderline(child: DropdownButton<double>(value: _glycol, isExpanded: true, onChanged: (v) => setState(() => _glycol = v!), items: [0.0, 10.0, 20.0, 30.0, 40.0, 50.0].map((e) => DropdownMenuItem(value: e, child: Text('%${e.toInt()}'))).toList())),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _clear,
                  style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 56),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 4)
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(AppLocale.t('clean'), maxLines: 1, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: PrimaryButton(onPressed: _calculate, label: AppLocale.t('calculate'))),
            ],
          ),
        ]))),
        if (_resTank != null)
          ResultContainer(children: [
            _ResultRow(label: AppLocale.t('tank_vol'), value: _resTank!, isMain: true),
            const Divider(),
            _ResultRow(label: AppLocale.t('res_water_vol'), value: _resWaterVol!),
            _ResultRow(label: AppLocale.t('res_static'), value: _resStatic!),
            _ResultRow(label: AppLocale.t('res_pregas'), value: _resPreGas!),
            _ResultRow(label: AppLocale.t('res_safety'), value: _resSafety!),
            _ResultRow(label: AppLocale.t('res_exp_vol'), value: _resExpVol!),
            if (_numericWaterVol != null) ...[
              const SizedBox(height: 20),
              TankChart(waterVolume: _numericWaterVol!, maxTemp: _numericMaxTemp!, isDark: Theme.of(context).brightness == Brightness.dark)
            ],
            const SizedBox(height: 10),
            TextButton.icon(icon: const Icon(Icons.picture_as_pdf), label: Text(AppLocale.t('share_pdf')), onPressed: () => PdfService.generateAndShare(title: AppLocale.t('tank'), data: {AppLocale.t('tank_vol'): _resTank!}))
          ])
      ]),
    );
  }
}

// --- E. BACA KESİT HESABI (YENİ MODÜL) ---
class ChimneyTab extends StatefulWidget {
  const ChimneyTab({super.key});

  @override
  State<ChimneyTab> createState() => _ChimneyTabState();
}

class _ChimneyTabState extends State<ChimneyTab> {
  final _kwCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  // Excel Katsayıları: Doğalgaz=0.012, Sıvı=0.02, Katı=0.03
  String _fuelType = 'gas';
  final Map<String, double> _coefficients = {'gas': 0.012, 'liquid': 0.02, 'solid': 0.03};

  String? _resArea, _resDia, _resRecDia;
  bool _loading = false;

  void _calculate() async {
    if (_kwCtrl.text.isEmpty || _heightCtrl.text.isEmpty) return;

    setState(() => _loading = true);
    await Future.delayed(const Duration(milliseconds: 300)); // Hafif gecikme efekti

    double kw = double.tryParse(_kwCtrl.text.replaceAll(',', '.')) ?? 0;
    double h = double.tryParse(_heightCtrl.text.replaceAll(',', '.')) ?? 0;

    if (kw > 0 && h > 0) {
      double kcal = kw * 860; // kW -> kcal/h
      double k = _coefficients[_fuelType]!;

      // FORMÜL: Fb (cm2) = k * Q (kcal) / sqrt(h)
      double areaCm2 = (k * kcal) / math.sqrt(h);

      // Çap Hesabı: A = pi * r^2  => d = 2 * sqrt(A/pi)
      double diaCm = 2 * math.sqrt(areaCm2 / math.pi);

      // Standart Yuvarlama (Çift sayılara yuvarla: 20, 22, 24...)
      double recDia = (diaCm / 2).ceil() * 2.0;
      if (recDia < diaCm) recDia += 2;

      setState(() {
        _resArea = "${areaCm2.toStringAsFixed(1)} cm²";
        _resDia = "Ø${diaCm.toStringAsFixed(1)} cm";
        _resRecDia = "Ø${recDia.toStringAsFixed(0)} cm"; // Standart boru
        _loading = false;
      });

      // Geçmişe Kaydet (Mevcut fonksiyonu kullanıyoruz)
      _saveHistory(AppLocale.t('chimney'), _resRecDia!, "kW: $kw, H: $h m");
    } else {
      setState(() => _loading = false);
    }
  }

  void _clear() {
    setState(() {
      _kwCtrl.clear();
      _heightCtrl.clear();
      _resArea = null;
      _resDia = null;
      _resRecDia = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  TextField(
                      controller: _kwCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: AppLocale.t('heat_cap'), prefixIcon: const Icon(Icons.bolt))
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _heightCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: "${AppLocale.t('b_height')} (m)", prefixIcon: const Icon(Icons.height))
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(labelText: AppLocale.t('fuel_type'), prefixIcon: const Icon(Icons.local_fire_department)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _fuelType,
                        isExpanded: true,
                        onChanged: (v) => setState(() => _fuelType = v!),
                        items: _coefficients.keys.map((e) => DropdownMenuItem(value: e, child: Text(AppLocale.t(e)))).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _clear,
                          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 56), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                          child: Text(AppLocale.t('clean')),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                          flex: 2,
                          child: PrimaryButton(onPressed: _calculate, label: AppLocale.t('calculate'))
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_loading) const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),

          if (_resRecDia != null && !_loading)
            ResultContainer(
              children: [
                _ResultRow(label: AppLocale.t('rec_dia'), value: _resRecDia!, isMain: true, icon: Icons.check_circle),
                const Divider(),
                _ResultRow(label: AppLocale.t('res_area_cm2'), value: _resArea!),
                _ResultRow(label: AppLocale.t('chimney_dia'), value: _resDia!),
                const SizedBox(height: 10),
                TextButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(AppLocale.t('share_pdf')),
                    onPressed: () => PdfService.generateAndShare(title: AppLocale.t('chimney'), data: {
                      AppLocale.t('rec_dia'): _resRecDia!,
                      AppLocale.t('res_area_cm2'): _resArea!,
                      AppLocale.t('chimney_dia'): _resDia!
                    })
                )
              ],
            )
        ],
      ),
    );
  }
}

// --- D. BİRİM DÖNÜŞTÜRÜCÜ ---
class UnitConverterTab extends StatefulWidget {
  const UnitConverterTab({super.key});
  @override
  State<UnitConverterTab> createState() => _UnitConverterTabState();
}

class _UnitConverterTabState extends State<UnitConverterTab> {
  final _inputCtrl = TextEditingController();
  String _selectedCategory = 'cat_press';
  String _fromUnit = 'Bar';
  String _toUnit = 'mSS';
  double _result = 0.0;

  final Map<String, Map<String, double>> _conversionRates = {
    'cat_press': {'Bar': 1.0, 'mSS': 10.197, 'Psi': 14.5038, 'Pa': 100000.0, 'Atm': 0.98692},
    'cat_flow': {'m³/h': 1.0, 'lt/s': 0.2777, 'lt/dk': 16.6667, 'gpm': 4.4028},
    'cat_power': {'kW': 1.0, 'HP': 1.341, 'kcal/h': 860.0, 'btu/h': 3412.14},
    'cat_len': {'m': 1.0, 'cm': 100.0, 'mm': 1000.0, 'inch': 39.3701, 'ft': 3.2808},
    'cat_vol': {'Litre': 1.0, 'm³': 0.001, 'Galon': 0.26417},
  };

  void _clear() {
    setState(() {
      _inputCtrl.clear();
      _result = 0.0;
    });
  }

  void _calculate() {
    double val = double.tryParse(_inputCtrl.text) ?? 0.0;
    double baseVal = val / _conversionRates[_selectedCategory]![_fromUnit]!;
    setState(() => _result = baseVal * _conversionRates[_selectedCategory]![_toUnit]!);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.withValues(alpha: 0.2))),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedCategory, isExpanded: true,
              onChanged: (val) {
                setState(() {
                  _selectedCategory = val!;
                  _fromUnit = _conversionRates[val]!.keys.first;
                  _toUnit = _conversionRates[val]!.keys.skip(1).first;
                  _calculate();
                });
              },
              items: _conversionRates.keys.map((e) => DropdownMenuItem(value: e, child: Text(AppLocale.t(e)))).toList(),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Card(child: Padding(padding: const EdgeInsets.all(24), child: Column(children: [
          Row(children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: _inputCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _calculate(),
                decoration: InputDecoration(
                  labelText: AppLocale.t('val_input'),
                  suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: _clear),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(child: _buildUnitDropdown(_fromUnit, (val) { setState(() => _fromUnit = val!); _calculate(); })),
          ]),
          const Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Icon(Icons.arrow_downward, color: Colors.grey)),
          Row(children: [
            Expanded(flex: 2, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppConstants.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(_result == 0 ? "0" : _result.toStringAsFixed(4), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppConstants.primaryColor)))),
            const SizedBox(width: 16),
            Expanded(child: _buildUnitDropdown(_toUnit, (val) { setState(() => _toUnit = val!); _calculate(); })),
          ]),
        ]))),
      ]),
    );
  }

  Widget _buildUnitDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey.withValues(alpha: 0.3)), borderRadius: BorderRadius.circular(8)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, onChanged: onChanged, items: _conversionRates[_selectedCategory]!.keys.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList())),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. YARDIMCI WIDGET'LAR
// ---------------------------------------------------------------------------
class PrimaryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  const PrimaryButton({super.key, required this.onPressed, required this.label});
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
    );
  }
}

class ResultContainer extends StatelessWidget {
  final List<Widget> children;
  final bool isError;
  const ResultContainer({super.key, required this.children, this.isError = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          border: Border.all(color: isError ? Colors.red : AppConstants.primaryColor, width: 2),
          borderRadius: BorderRadius.circular(16),
          color: isError ? Colors.red.withValues(alpha: 0.05) : AppConstants.primaryColor.withValues(alpha: 0.05)
      ),
      child: Column(children: children),
    );
  }
}

class _ResultRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final bool isMain;
  const _ResultRow({required this.label, required this.value, this.icon, this.isMain = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        if (icon != null) ...[Icon(icon, color: AppConstants.primaryColor, size: 24), const SizedBox(width: 12)],
        Text(label, style: TextStyle(color: isMain ? AppConstants.primaryColor : Colors.grey[700], fontWeight: isMain ? FontWeight.w900 : FontWeight.w500, fontSize: isMain ? 18 : 14)),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMain ? 20 : 16))
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// 9. GEÇMİŞ VE PDF SERVİSİ
// ---------------------------------------------------------------------------
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  final Set<int> _selected = {};

  @override
  void initState() { super.initState(); _loadHistory(); }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => _history = (prefs.getStringList('calculation_history') ?? []).map((e) => jsonDecode(e) as Map<String, dynamic>).toList().reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocale.t('history_title')), actions: [if (_history.isNotEmpty) IconButton(icon: Icon(Icons.delete, color: _selected.isEmpty ? Colors.white70 : Colors.redAccent), onPressed: _deleteItems)]),
      floatingActionButton: _selected.isNotEmpty ? FloatingActionButton.extended(onPressed: () => PdfService.generateMultiReport(_selected.map((i) => _history[i]).toList()), backgroundColor: AppConstants.primaryColor, icon: const Icon(Icons.picture_as_pdf, color: Colors.white), label: Text('${AppLocale.t('export_selected')} (${_selected.length})', style: const TextStyle(color: Colors.white))) : null,
      body: _history.isEmpty ? Center(child: Text(AppLocale.t('no_data'), style: const TextStyle(color: Colors.grey))) : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final isSelected = _selected.contains(index);
          return GestureDetector(
            onTap: () => setState(() => isSelected ? _selected.remove(index) : _selected.add(index)),
            child: Card(
              color: isSelected ? AppConstants.primaryColor.withValues(alpha: 0.1) : null,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: isSelected ? const BorderSide(color: AppConstants.primaryColor, width: 2) : BorderSide.none),
              child: ListTile(
                title: Text(item['type'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor)),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 4), Text('${AppLocale.t('inputs')}: ${item['inputs']}'), Text(item['res'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))]),
                trailing: isSelected ? const Icon(Icons.check_circle, color: AppConstants.primaryColor) : null,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _deleteItems() async {
    final prefs = await SharedPreferences.getInstance();
    if (_selected.isNotEmpty) {
      final keep = _history.asMap().entries.where((e) => !_selected.contains(e.key)).map((e) => e.value).toList();
      await prefs.setStringList('calculation_history', keep.reversed.map((e) => jsonEncode(e)).toList());
      setState(() { _history = keep; _selected.clear(); });
    } else { await prefs.remove('calculation_history'); setState(() => _history.clear()); }
  }
}

Future<void> _saveHistory(String type, String res, String inputs) async {
  final prefs = await SharedPreferences.getInstance();
  final h = prefs.getStringList('calculation_history') ?? [];
  h.add(jsonEncode({'type': type, 'res': res, 'time': DateTime.now().toString(), 'inputs': inputs}));
  await prefs.setStringList('calculation_history', h);
}

class PdfService {
  static Future<void> generateAndShare({required String title, required Map<String, String> data}) async {
    final logoData = await rootBundle.load(AppConstants.logoPath);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final pdfPrimary = PdfColor.fromInt(AppConstants.primaryColor.toARGB32());
    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (context) => pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [_buildHeader(logoImage, AppLocale.t('report_title'), pdfPrimary), pw.SizedBox(height: 30), pw.Center(child: pw.Text(title.toUpperCase(), style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: pdfPrimary))), pw.SizedBox(height: 30), _buildTable(data, pdfPrimary), pw.Spacer(), _buildFooter(pdfPrimary)]),
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Pomeka_${title.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateMultiReport(List<Map<String, dynamic>> items) async {
    final logoData = await rootBundle.load(AppConstants.logoPath);
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final pdfPrimary = PdfColor.fromInt(AppConstants.primaryColor.toARGB32());
    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      header: (context) => _buildHeader(logoImage, 'TOPLU RAPOR', pdfPrimary),
      footer: (context) => _buildFooter(pdfPrimary),
      build: (context) => items.map((item) => _buildHistoryItem(item, pdfPrimary)).toList(),
    ));
    await Printing.sharePdf(bytes: await pdf.save(), filename: 'Pomeka_Batch.pdf');
  }

  static pw.Widget _buildHeader(pw.MemoryImage logo, String title, PdfColor color) {
    return pw.Column(children: [pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Image(logo, height: 40), pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [pw.Text(title, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: color)), pw.Text('${AppLocale.t('date')}: ${DateTime.now().toString().substring(0, 10)}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))])]), pw.SizedBox(height: 10), pw.Container(height: 2, width: double.infinity, color: color)]);
  }
  static pw.Widget _buildFooter(PdfColor color) {
    return pw.Column(children: [pw.Divider(color: PdfColors.grey300), pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text("POMEKA Mobile", style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)), pw.Text(AppLocale.t('pdf_footer'), style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600))])]);
  }
  static pw.Widget _buildTable(Map<String, String> data, PdfColor primary) {
    return pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)), child: pw.Column(children: data.entries.map((e) { final index = data.keys.toList().indexOf(e.key); return pw.Container(padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12), decoration: pw.BoxDecoration(border: index != data.length - 1 ? const pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300)) : null, color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100), child: pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text(e.key, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)), pw.Text(e.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12, color: primary))])); }).toList()));
  }
  static pw.Widget _buildHistoryItem(Map<String, dynamic> item, PdfColor color) {
    return pw.Container(margin: const pw.EdgeInsets.only(bottom: 20), decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey300), borderRadius: pw.BorderRadius.circular(8)), child: pw.Padding(padding: const pw.EdgeInsets.all(12), child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [pw.Text(item['type'] ?? '', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: color)), pw.Divider(height: 10, color: PdfColors.grey300), pw.Text('${AppLocale.t('inputs')}: ${item['inputs']}', style: const pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 5), pw.Text('${AppLocale.t('results')}: ${item['res']}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold))])));
  }
}

// ---------------------------------------------------------------------------
// 10. GRAFİKLER (Charts)
// ---------------------------------------------------------------------------
class ResultChart extends StatelessWidget {
  final double q, hm;
  final bool isDark;
  const ResultChart({super.key, required this.q, required this.hm, required this.isDark});
  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    double kVal = (q > 0) ? hm / (q * q) : 0;
    for (double i = 0; i <= q * 1.5; i += q * 1.5 / 20) {
      spots.add(FlSpot(i, kVal * i * i));
    }
    return AspectRatio(aspectRatio: 1.7, child: LineChart(LineChartData(
        gridData: FlGridData(show: true, getDrawingHorizontalLine: (_) => FlLine(color: isDark ? Colors.white10 : Colors.black12, strokeWidth: 1)),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: true, border: Border.all(color: isDark ? Colors.white10 : Colors.black12)),
        lineBarsData: [
          LineChartBarData(spots: spots, isCurved: true, color: AppConstants.primaryColor, barWidth: 3, dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(show: true, color: AppConstants.primaryColor.withValues(alpha: 0.1))),
          LineChartBarData(spots: [FlSpot(q, hm)], color: Colors.red, barWidth: 0, dotData: const FlDotData(show: true))
        ]
    )));
  }
}

class BoilerChart extends StatelessWidget {
  final double volume;
  final bool isDark;
  const BoilerChart({super.key, required this.volume, required this.isDark});
  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    double idealP = (3.48 * volume) / 45.0;
    for (double p = idealP * 0.2; p <= idealP * 2.5; p += (idealP * 2.3) / 20) {
      spots.add(FlSpot(p, (3.48 * volume) / p));
    }
    return AspectRatio(aspectRatio: 1.7, child: LineChart(LineChartData(
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.orange, barWidth: 3,
            belowBarData: BarAreaData(show: true, color: Colors.orange.withValues(alpha: 0.1)))]
    )));
  }
}

class TankChart extends StatelessWidget {
  final double waterVolume, maxTemp;
  final bool isDark;
  const TankChart({super.key, required this.waterVolume, required this.maxTemp, required this.isDark});
  @override
  Widget build(BuildContext context) {
    List<FlSpot> spots = [];
    for (double t = 20; t <= maxTemp + 10; t += 5) {
      double n = (0.00029 * t * t - 0.0037 * t + 0.06);
      if (n < 0) n = 0;
      spots.add(FlSpot(t, waterVolume * n / 100));
    }
    return AspectRatio(aspectRatio: 1.7, child: LineChart(LineChartData(
        titlesData: const FlTitlesData(show: false),
        lineBarsData: [LineChartBarData(spots: spots, isCurved: true, color: Colors.purple, barWidth: 3,
            belowBarData: BarAreaData(show: true, color: Colors.purple.withValues(alpha: 0.1)))]
    )));
  }
}