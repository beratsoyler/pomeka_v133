import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'kazan_tesisat_calculator.dart';
import 'screens/formulas/formulas_home.dart';

// ---------------------------------------------------------------------------
// 1. MAIN ENTRY POINT & APP SETUP
// ---------------------------------------------------------------------------
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));
  runApp(const PomekaApp());
}

class PomekaApp extends StatefulWidget {
  const PomekaApp({super.key});
  @override
  State<PomekaApp> createState() => _PomekaAppState();
}

class _PomekaAppState extends State<PomekaApp> {
  ThemeMode _themeMode = ThemeMode.dark;
  bool _showSplash = true;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'POMEKA',
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      routes: {
        '/formulas': (_) => const FormulasHomeScreen(),
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 1200),
        switchInCurve: Curves.easeInOut,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (Widget child, Animation<double> animation) {
          return FadeTransition(opacity: animation, child: child);
        },
        child: _showSplash
            ? SplashScreen(
          key: const ValueKey('Splash'),
          onCompleted: () => setState(() => _showSplash = false),
        )
            : HomeScreen(
          key: const ValueKey('Home'),
          isDarkMode: _themeMode == ThemeMode.dark,
          onThemeChanged: _toggleTheme,
        ),
      ),
    );
  }

  ThemeData _buildTheme(Brightness b) {
    final isD = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor:
      isD ? const Color(0xFF131314) : const Color(0xFFF8F9FA),
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0052FF), brightness: b),
      textTheme: GoogleFonts.poppinsTextTheme(
          isD ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
      cardTheme: CardThemeData(
        elevation: isD ? 0 : 2,
        color: isD ? const Color(0xFF1E1F20) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: isD
              ? BorderSide(color: Colors.white.withValues(alpha: 0.08))
              : BorderSide.none,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isD ? const Color(0xFF252628) : const Color(0xFFF0F4F8),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. SPLASH SCREEN
// ---------------------------------------------------------------------------
class SplashScreen extends StatefulWidget {
  final VoidCallback onCompleted;
  const SplashScreen({super.key, required this.onCompleted});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2500));

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _controller,
          curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onCompleted();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0052FF).withValues(
                                alpha: 0.2 * _opacityAnimation.value),
                            blurRadius: 30,
                            spreadRadius: 10,
                          )
                        ],
                      ),
                      child: Image.asset('assets/pomeka-png-1757403926.png',
                          width: 180),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: 120,
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        backgroundColor: Colors.grey[100],
                        color: const Color(0xFF0052FF),
                        minHeight: 2,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "MÜHENDİSLİK ÇÖZÜMLERİ",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. LOCALIZATION MANAGER
// ---------------------------------------------------------------------------
class AppLocale {
  static String currentLang = 'TR';

  static const Map<String, Map<String, String>> languages = {
    'TR': {
      'hydrofor': 'HİDROFOR TESİSATI',
      'boiler': 'KAZAN TESİSATI HESABI',
      'tank': 'GENLEŞME TANKI',
      'converter': 'BİRİM DÖNÜŞTÜRÜCÜ',
      'calculate': 'HESAPLA',
      'clean': 'TEMİZLE',
      'search_hint': 'Menüde Ara...',
      'units': 'Daire/Birim Sayısı',
      'floors': 'Bina Kat Sayısı',
      'b_type': 'Bina Tipi',
      'people': 'Hane Başı Kişi',
      'coil': 'Serpantin Tipi',
      'res_flow': 'Debi (Q)',
      'res_press': 'Basınç (Hm)',
      'res_vol': 'Boyler Hacmi (V)',
      'tank_vol': 'Tank Hacmi (Vtank)',
      'heat_cap': 'Isıtıcı Kapasitesi (kW)',
      'sys_h': 'Sistem Yüksekliği (m)',
      'temp_f': 'Gidiş Sıcaklığı (°C)',
      'temp_r': 'Dönüş Sıcaklığı (°C)',
      'heat_type': 'Isıtıcı Tipi',
      'glycol': 'Glikol Oranı (%)',
      'res_static': 'Statik Basınç',
      'res_pregas': 'Ön Gaz Basıncı',
      'res_safety': 'Emniyet Ventili',
      'res_exp_vol': 'Genleşen Hacim',
      'res_water_vol': 'Su Hacmi (Vs)',
      'h_panel': 'Panel Radyatör',
      'h_cast': 'Döküm Radyatör',
      'h_floor': 'Yerden Isıtma',
      'h_fancoil': 'Fan Coil',
      'err_boiler_500':
      'Çift Serpantin 500L altı olamaz. Lütfen Tek Serpantin seçiniz.',
      't_konut': 'Toplu Konutlar',
      'l_konut': 'Lüks Konutlar',
      'l_villa': 'Lüks Villalar',
      'misafir': 'Misafirhaneler',
      'otel': 'Oteller',
      'hasta': 'Hastaneler',
      'buro': 'Bürolar',
      'okul': 'Okullar',
      'y_okul': 'Yatılı Okullar',
      'avm': 'AVM',
      'single': 'Tek Serpantin',
      'double': 'Çift Serpantin',
      'go_tank': 'Tank Hesabına Aktar',
      'share_pdf': 'PDF Raporu Oluştur',
      'report_title': 'POMEKA MÜHENDİSLİK RAPORU',
      'multi_report_title': 'POMEKA TOPLU HESAP DÖKÜMÜ',
      'min_unit': 'dk',
      'press_unit': 'mSS',
      'flow_unit': 'm³/h',
      'bar_unit': 'Bar',
      'pdf_footer':
      'Bu belge POMEKA Mobil Uygulaması tarafından otomatik olarak oluşturulmuştur.',
      'date': 'Tarih',
      'history_title': 'Hesaplama Geçmişi',
      'inputs': 'Girişler',
      'results': 'Sonuçlar',
      'no_data': 'Henüz hesaplama yok.',
      'clear_history': 'Geçmişi Temizle',
      'export_selected': 'Seçilenleri PDF Yap',
      'selected_count': 'Seçildi',
      'delete_confirm_title': 'Tüm Geçmişi Sil',
      'delete_confirm_msg':
      'Bütün hesaplama geçmişiniz silinecek. Emin misiniz?',
      'cancel': 'İptal',
      'delete': 'Sil',
      'chart_boiler_x': 'Isıtıcı Gücü (kW)',
      'chart_boiler_y': 'Süre (dk)',
      'chart_tank_x': 'Ort. Sıcaklık (°C)',
      'chart_tank_y': 'Genleşme (L)',
      'cat_press': 'Basınç',
      'cat_flow': 'Debi',
      'cat_power': 'Güç',
      'cat_len': 'Uzunluk',
      'cat_vol': 'Hacim',
      'val_input': 'Değer Girin',
      'val_result': 'Sonuç',
      'Litre': 'Litre',
      'Galon': 'Galon',
      'zone_pool': 'Havuz Isıtma Yükü',
      'zone_floor': 'Yerden Isıtma Yükü',
      'zone_boiler': 'Boyler Yükü',
      'zone_radiator': 'Radyatör Yükü',
      'zone_hamam': 'Hamam Isıtma Yükü',
      'zone_air_handler': 'Klima Santrali Yükü',
      'zone_heat_recovery': 'Isı Geri Kazanım Yükü',
      'heat_load_kcal': 'Isı Yükü',
      'velocity': 'Hız',
      'delta_t': 'ΔT',
      'total_heat_load': 'Toplam Isı Yükü',
      'boiler_capacity_kw': 'Kazan Kapasitesi (kW)',
      'boiler_capacity_kcal': 'Kazan Kapasitesi (kcal/h)',
      'total_flow': 'Toplam Debi',
      'err_negative': 'Negatif değer girilemez.',
      'err_delta_t': 'ΔT değeri 0 veya negatif olamaz.',
      'err_velocity': 'Hız değeri 0 veya negatif olamaz.',
      'boiler_capacity': 'Kazan Kapasitesi',
      'zone_title': 'Zonlar',
      'building_dims': 'Bina Ölçüleri',
      'building_width': 'En',
      'building_length': 'Boy',
      'building_height': 'Yükseklik',
      'system_type': 'Sistem Tipi',
      'system_floor': 'YERDEN ISITMA',
      'system_panel': 'PANEL RADYATÖR',
      'system_steel': 'ÇELİK RADYATÖR',
      'system_other': 'DİĞER',
      'collector_velocity': 'Kollektör Hızı',
      'zone_results': 'Zon Sonuçları',
      'flow': 'Debi',
      'pipe_diameter': 'Boru İç Çapı',
      'collector_diameter': 'Kollektör Boru İç Çapı',
      'expansion_tanks': 'Genleşme Tankları',
      'open_tank': 'Açık Genleşme Tankı',
      'closed_tank': 'Kapalı Genleşme Tankı',
      'opening_pressure': 'Açma Basıncı',
      'safety_pressure': 'Emniyet Basıncı',
      'height_warning': 'Yükseklik değeri için kontrol gerekli.',
      'check_height': 'KONTROL ET',
      'expansion_details': 'Detaylar',
      'system_volume': 'Sistem Su Hacmi',
      'expansion_volume': 'Genleşme Hacmi',
      'reserve_volume': 'Rezerv Hacim',
      'static_pressure': 'Statik Basınç',
      'formulas': 'Formüller',
      'search_formulas': 'Formül ara (örn: Genleşme, Debi, Basınç…)',
      'favorites': 'Favoriler',
      'recent_formulas': 'Son Kullanılanlar',
      'categories': 'Kategoriler',
      'no_results': 'Sonuç bulunamadı',
      'no_results_hint': 'Lütfen başka bir anahtar kelime deneyin.',
      'detail_placeholder': 'Bu ekran yakında gerçek hesaplama modülüne dönüşecek.'
    },
    'EN': {
      'hydrofor': 'BOOSTER SYSTEM',
      'boiler': 'BOILER INSTALLATION',
      'tank': 'EXPANSION TANK',
      'converter': 'UNIT CONVERTER',
      'calculate': 'CALCULATE',
      'clean': 'CLEAR',
      'search_hint': 'Search Menu...',
      'units': 'Number of Units',
      'floors': 'Number of Floors',
      'b_type': 'Building Type',
      'people': 'People per House',
      'coil': 'Coil Type',
      'heat_cap': 'Heating Capacity (kW)',
      'sys_h': 'System Height (m)',
      'temp_f': 'Flow Temp (°C)',
      'temp_r': 'Return Temp (°C)',
      'heat_type': 'Heater Type',
      'glycol': 'Glycol Ratio (%)',
      'res_static': 'Static Pressure',
      'res_pregas': 'Pre-Gas Pressure',
      'res_safety': 'Safety Valve',
      'res_exp_vol': 'Expansion Vol',
      'res_water_vol': 'Water Vol (Vs)',
      'h_panel': 'Panel Radiator',
      'h_cast': 'Cast Radiator',
      'h_floor': 'Floor Heating',
      'h_fancoil': 'Fan Coil',
      'err_boiler_500':
      'Double Coil cannot be under 500L. Please select Single Coil.',
      'res_flow': 'Flow (Q)',
      'res_press': 'Pressure (Hm)',
      'res_vol': 'Boiler Volume (V)',
      'tank_vol': 'Tank Volume (Vtank)',
      't_konut': 'Social Housing',
      'l_konut': 'Luxury Housing',
      'l_villa': 'Luxury Villas',
      'misafir': 'Guesthouses',
      'otel': 'Hotels',
      'hasta': 'Hospitals',
      'buro': 'Offices',
      'okul': 'Schools',
      'y_okul': 'Boarding Schools',
      'avm': 'Mall',
      'single': 'Single Coil',
      'double': 'Double Coil',
      'go_tank': 'Sync to Tank Calculation',
      'share_pdf': 'Create PDF Report',
      'report_title': 'POMEKA ENGINEERING REPORT',
      'multi_report_title': 'POMEKA BATCH REPORT',
      'min_unit': 'min',
      'press_unit': 'mWC',
      'flow_unit': 'm³/h',
      'bar_unit': 'Bar',
      'pdf_footer':
      'This document was automatically generated by POMEKA Mobile Application.',
      'date': 'Date',
      'history_title': 'Calculation History',
      'inputs': 'Inputs',
      'results': 'Results',
      'no_data': 'No calculations yet.',
      'clear_history': 'Clear History',
      'export_selected': 'Export Selected to PDF',
      'selected_count': 'Selected',
      'delete_confirm_title': 'Delete All History',
      'delete_confirm_msg':
      'All calculation history will be deleted. Are you sure?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'chart_boiler_x': 'Heating Power (kW)',
      'chart_boiler_y': 'Time (min)',
      'chart_tank_x': 'Avg Temp (°C)',
      'chart_tank_y': 'Expansion (L)',
      'cat_press': 'Pressure',
      'cat_flow': 'Flow',
      'cat_power': 'Power',
      'cat_len': 'Length',
      'cat_vol': 'Volume',
      'val_input': 'Enter Value',
      'val_result': 'Result',
      'Litre': 'Liter',
      'Galon': 'Gallon',
      'zone_pool': 'Pool Heating Load',
      'zone_floor': 'Floor Heating Load',
      'zone_boiler': 'Boiler Load',
      'zone_radiator': 'Radiator Load',
      'zone_hamam': 'Hamam Heating Load',
      'zone_air_handler': 'Air Handling Unit Load',
      'zone_heat_recovery': 'Heat Recovery Load',
      'heat_load_kcal': 'Heat Load',
      'velocity': 'Velocity',
      'delta_t': 'ΔT',
      'total_heat_load': 'Total Heat Load',
      'boiler_capacity_kw': 'Boiler Capacity (kW)',
      'boiler_capacity_kcal': 'Boiler Capacity (kcal/h)',
      'total_flow': 'Total Flow',
      'err_negative': 'Negative values are not allowed.',
      'err_delta_t': 'ΔT must be greater than 0.',
      'err_velocity': 'Velocity must be greater than 0.',
      'boiler_capacity': 'Boiler Capacity',
      'zone_title': 'Zones',
      'building_dims': 'Building Dimensions',
      'building_width': 'Width',
      'building_length': 'Length',
      'building_height': 'Height',
      'system_type': 'System Type',
      'system_floor': 'FLOOR HEATING',
      'system_panel': 'PANEL RADIATOR',
      'system_steel': 'STEEL RADIATOR',
      'system_other': 'OTHER',
      'collector_velocity': 'Collector Velocity',
      'zone_results': 'Zone Results',
      'flow': 'Flow',
      'pipe_diameter': 'Pipe Inner Diameter',
      'collector_diameter': 'Collector Pipe Inner Diameter',
      'expansion_tanks': 'Expansion Tanks',
      'open_tank': 'Open Expansion Tank',
      'closed_tank': 'Closed Expansion Tank',
      'opening_pressure': 'Opening Pressure',
      'safety_pressure': 'Safety Pressure',
      'height_warning': 'Height value requires verification.',
      'check_height': 'CHECK',
      'expansion_details': 'Details',
      'system_volume': 'System Water Volume',
      'expansion_volume': 'Expansion Volume',
      'reserve_volume': 'Reserve Volume',
      'static_pressure': 'Static Pressure',
      'formulas': 'Formulas',
      'search_formulas': 'Search formulas (e.g., Expansion, Flow, Pressure…)',
      'favorites': 'Favorites',
      'recent_formulas': 'Recently Used',
      'categories': 'Categories',
      'no_results': 'No results found',
      'no_results_hint': 'Try a different keyword.',
      'detail_placeholder': 'This screen will become a full calculator soon.'
    },
    'DE': {
      'hydrofor': 'DRUCKERHÖHUNG',
      'boiler': 'KESSELINSTALLATION',
      'tank': 'EXPANSIONSGEFÄSS',
      'converter': 'EINHEITENWANDLER',
      'calculate': 'BERECHNEN',
      'clean': 'LÖSCHEN',
      'search_hint': 'Suchen...',
      'units': 'Anzahl Einheiten',
      'floors': 'Anzahl Etagen',
      'b_type': 'Gebäudetyp',
      'people': 'Personen pro Haushalt',
      'coil': 'Spulentyp',
      'res_flow': 'Durchfluss (Q)',
      'res_press': 'Druck (Hm)',
      'res_vol': 'Boilervolumen (V)',
      'tank_vol': 'Tankvolumen (Vtank)',
      'heat_cap': 'Heizleistung (kW)',
      'sys_h': 'Systemhöhe (m)',
      'temp_f': 'Vorlauf (°C)',
      'temp_r': 'Rücklauf (°C)',
      'heat_type': 'Heizungstyp',
      'glycol': 'Glykolanteil (%)',
      'res_static': 'Statischer Druck',
      'res_pregas': 'Vordruck',
      'res_safety': 'Sicherheitsventil',
      'res_exp_vol': 'Expansionsvolumen',
      'res_water_vol': 'Wasservolumen (Vs)',
      'h_panel': 'Plattenheizkörper',
      'h_cast': 'Gussheizkörper',
      'h_floor': 'Fußbodenheizung',
      'h_fancoil': 'Fan Coil',
      'err_boiler_500': 'Doppelspule darf nicht unter 500L sein.',
      't_konut': 'Sozialwohnungen',
      'l_konut': 'Luxuswohnungen',
      'l_villa': 'Luxusvillen',
      'misafir': 'Gästehäuser',
      'otel': 'Hotels',
      'hasta': 'Krankenhäuser',
      'buro': 'Büros',
      'okul': 'Schulen',
      'y_okul': 'Internate',
      'avm': 'Einkaufszentren',
      'single': 'Einzelspule',
      'double': 'Doppelspule',
      'go_tank': 'Zum Tankrechner',
      'share_pdf': 'PDF-Bericht erstellen',
      'report_title': 'POMEKA INGENIEURBERICHT',
      'multi_report_title': 'POMEKA SAMMELBERICHT',
      'min_unit': 'Min',
      'press_unit': 'mWS',
      'flow_unit': 'm³/h',
      'bar_unit': 'Bar',
      'pdf_footer':
      'Dieses Dokument wurde automatisch von der POMEKA Mobile App erstellt.',
      'date': 'Datum',
      'history_title': 'Berechnungsverlauf',
      'inputs': 'Eingaben',
      'results': 'Ergebnisse',
      'no_data': 'Noch keine Berechnungen.',
      'clear_history': 'Verlauf löschen',
      'export_selected': 'Ausgewählte als PDF',
      'selected_count': 'Ausgewählt',
      'delete_confirm_title': 'Verlauf löschen',
      'delete_confirm_msg':
      'Der gesamte Verlauf wird gelöscht. Sind Sie sicher?',
      'cancel': 'Abbrechen',
      'delete': 'Löschen',
      'chart_boiler_x': 'Heizleistung (kW)',
      'chart_boiler_y': 'Zeit (Min)',
      'chart_tank_x': 'Durchschn. Temp (°C)',
      'chart_tank_y': 'Ausdehnung (L)',
      'cat_press': 'Druck',
      'cat_flow': 'Durchfluss',
      'cat_power': 'Leistung',
      'cat_len': 'Länge',
      'cat_vol': 'Volumen',
      'val_input': 'Wert eingeben',
      'val_result': 'Ergebnis',
      'Litre': 'Liter',
      'Galon': 'Gallone',
      'zone_pool': 'Beckenheizlast',
      'zone_floor': 'Fußbodenheizlast',
      'zone_boiler': 'Boilerlast',
      'zone_radiator': 'Heizkörperlast',
      'zone_hamam': 'Hammam-Heizlast',
      'zone_air_handler': 'RLT-Anlagenlast',
      'zone_heat_recovery': 'Wärmerückgewinnung',
      'heat_load_kcal': 'Heizlast',
      'velocity': 'Geschwindigkeit',
      'delta_t': 'ΔT',
      'total_heat_load': 'Gesamt-Heizlast',
      'boiler_capacity_kw': 'Kesselleistung (kW)',
      'boiler_capacity_kcal': 'Kesselleistung (kcal/h)',
      'total_flow': 'Gesamtdurchfluss',
      'err_negative': 'Negative Werte sind nicht erlaubt.',
      'err_delta_t': 'ΔT muss größer als 0 sein.',
      'err_velocity': 'Geschwindigkeit muss größer als 0 sein.',
      'boiler_capacity': 'Kesselleistung',
      'zone_title': 'Zonen',
      'building_dims': 'Gebäudemaße',
      'building_width': 'Breite',
      'building_length': 'Länge',
      'building_height': 'Höhe',
      'system_type': 'Systemtyp',
      'system_floor': 'FUSSBODENHEIZUNG',
      'system_panel': 'PLATTENHEIZKÖRPER',
      'system_steel': 'STAHLHEIZKÖRPER',
      'system_other': 'SONSTIGE',
      'collector_velocity': 'Kollektorgeschwindigkeit',
      'zone_results': 'Zonenergebnisse',
      'flow': 'Durchfluss',
      'pipe_diameter': 'Rohr-Innendurchmesser',
      'collector_diameter': 'Kollektor-Rohr-Innendurchmesser',
      'expansion_tanks': 'Ausdehnungsgefäße',
      'open_tank': 'Offenes Ausdehnungsgefäß',
      'closed_tank': 'Geschlossenes Ausdehnungsgefäß',
      'opening_pressure': 'Öffnungsdruck',
      'safety_pressure': 'Sicherheitsdruck',
      'height_warning': 'Höhenwert muss geprüft werden.',
      'check_height': 'PRÜFEN',
      'expansion_details': 'Details',
      'system_volume': 'Systemwasservolumen',
      'expansion_volume': 'Ausdehnungsvolumen',
      'reserve_volume': 'Reservevolumen',
      'static_pressure': 'Statischer Druck',
      'formulas': 'Formeln',
      'search_formulas': 'Formel suchen (z.B. Ausdehnung, Durchfluss, Druck…)',
      'favorites': 'Favoriten',
      'recent_formulas': 'Zuletzt verwendet',
      'categories': 'Kategorien',
      'no_results': 'Keine Ergebnisse gefunden',
      'no_results_hint': 'Bitte ein anderes Stichwort eingeben.',
      'detail_placeholder': 'Dieser Bildschirm wird bald zu einem Rechner.'
    },
    'FR': {
      'hydrofor': 'SURPRESSION',
      'boiler': 'INSTALLATION DE CHAUDIÈRE',
      'tank': 'VASE D\'EXPANSION',
      'converter': 'CONVERTISSEUR',
      'calculate': 'CALCULER',
      'clean': 'EFFACER',
      'search_hint': 'Rechercher...',
      'units': 'Nombre d\'Unités',
      'floors': 'Nombre d\'Étages',
      'b_type': 'Type de Bâtiment',
      'people': 'Pers. par Foyer',
      'coil': 'Type de Serpentin',
      'res_flow': 'Débit (Q)',
      'res_press': 'Pression (Hm)',
      'res_vol': 'Volume Ballon (V)',
      'tank_vol': 'Volume Vase (Vtank)',
      'heat_cap': 'Puissance (kW)',
      'sys_h': 'Hauteur Système (m)',
      'temp_f': 'Temp. Départ (°C)',
      'temp_r': 'Temp. Retour (°C)',
      'heat_type': 'Type Chauffage',
      'glycol': 'Taux Glycol (%)',
      'res_static': 'Pression Statique',
      'res_pregas': 'Pression Pré-gonflage',
      'res_safety': 'Soupape de Sécurité',
      'res_exp_vol': 'Volume Expansion',
      'res_water_vol': 'Volume Eau (Vs)',
      'h_panel': 'Radiateur Panneau',
      'h_cast': 'Radiateur Fonte',
      'h_floor': 'Chauffage Sol',
      'h_fancoil': 'Ventilo-convecteur',
      'err_boiler_500':
      'Le double serpentin ne peut pas être inférieur à 500L.',
      't_konut': 'Logements Sociaux',
      'l_konut': 'Logements de Luxe',
      'l_villa': 'Villas de Luxe',
      'misafir': 'Maisons d\'Hôtes',
      'otel': 'Hôtels',
      'hasta': 'Hôpitaux',
      'buro': 'Bureaux',
      'okul': 'Écoles',
      'y_okul': 'Internats',
      'avm': 'Centres Commerciaux',
      'single': 'Simple Serpentin',
      'double': 'Double Serpentin',
      'go_tank': 'Vers Calcul Vase',
      'share_pdf': 'Créer Rapport PDF',
      'report_title': 'RAPPORT D\'INGÉNIERIE POMEKA',
      'multi_report_title': 'RAPPORT COLLECTIF POMEKA',
      'min_unit': 'min',
      'press_unit': 'mCE',
      'flow_unit': 'm³/h',
      'bar_unit': 'Bar',
      'pdf_footer':
      'Ce document a été généré automatiquement par l\'application mobile POMEKA.',
      'date': 'Date',
      'history_title': 'Historique',
      'inputs': 'Entrées',
      'results': 'Résultats',
      'no_data': 'Aucun calcul.',
      'clear_history': 'Effacer l\'historique',
      'export_selected': 'Exporter la sélection',
      'selected_count': 'Sélectionné',
      'delete_confirm_title': 'Tout effacer',
      'delete_confirm_msg': 'Tout l\'historique sera effacé. Êtes-vous sûr ?',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'chart_boiler_x': 'Puissance (kW)',
      'chart_boiler_y': 'Temps (min)',
      'chart_tank_x': 'Temp. Moyenne (°C)',
      'chart_tank_y': 'Expansion (L)',
      'cat_press': 'Pression',
      'cat_flow': 'Débit',
      'cat_power': 'Puissance',
      'cat_len': 'Longueur',
      'cat_vol': 'Volume',
      'val_input': 'Entrer la valeur',
      'val_result': 'Résultat',
      'Litre': 'Litre',
      'Galon': 'Gallon',
      'zone_pool': 'Charge chauffage piscine',
      'zone_floor': 'Charge chauffage au sol',
      'zone_boiler': 'Charge ballon',
      'zone_radiator': 'Charge radiateur',
      'zone_hamam': 'Charge hammam',
      'zone_air_handler': 'Charge CTA',
      'zone_heat_recovery': 'Charge récupération chaleur',
      'heat_load_kcal': 'Charge thermique',
      'velocity': 'Vitesse',
      'delta_t': 'ΔT',
      'total_heat_load': 'Charge totale',
      'boiler_capacity_kw': 'Puissance chaudière (kW)',
      'boiler_capacity_kcal': 'Puissance chaudière (kcal/h)',
      'total_flow': 'Débit total',
      'err_negative': 'Les valeurs négatives sont interdites.',
      'err_delta_t': 'ΔT doit être supérieur à 0.',
      'err_velocity': 'La vitesse doit être supérieure à 0.',
      'boiler_capacity': 'Puissance chaudière',
      'zone_title': 'Zones',
      'building_dims': 'Dimensions du bâtiment',
      'building_width': 'Largeur',
      'building_length': 'Longueur',
      'building_height': 'Hauteur',
      'system_type': 'Type de système',
      'system_floor': 'CHAUFFAGE AU SOL',
      'system_panel': 'RADIATEUR PANNEAU',
      'system_steel': 'RADIATEUR ACIER',
      'system_other': 'AUTRE',
      'collector_velocity': 'Vitesse du collecteur',
      'zone_results': 'Résultats par zone',
      'flow': 'Débit',
      'pipe_diameter': 'Diamètre intérieur de tuyau',
      'collector_diameter': 'Diamètre intérieur du collecteur',
      'expansion_tanks': 'Vases d\'expansion',
      'open_tank': 'Vase d\'expansion ouvert',
      'closed_tank': 'Vase d\'expansion fermé',
      'opening_pressure': 'Pression d\'ouverture',
      'safety_pressure': 'Pression de sécurité',
      'height_warning': 'La hauteur doit être vérifiée.',
      'check_height': 'VÉRIFIER',
      'expansion_details': 'Détails',
      'system_volume': 'Volume d\'eau du système',
      'expansion_volume': 'Volume d\'expansion',
      'reserve_volume': 'Volume de réserve',
      'static_pressure': 'Pression statique',
      'formulas': 'Formules',
      'search_formulas':
          'Rechercher une formule (ex: Expansion, Débit, Pression…)',
      'favorites': 'Favoris',
      'recent_formulas': 'Récemment utilisés',
      'categories': 'Catégories',
      'no_results': 'Aucun résultat',
      'no_results_hint': 'Essayez un autre mot-clé.',
      'detail_placeholder':
          'Cet écran deviendra bientôt un calculateur complet.'
    }
  };

  static String t(String key) => languages[currentLang]?[key] ?? key;
}

// ---------------------------------------------------------------------------
// 4. PDF SERVICE
// ---------------------------------------------------------------------------
class PdfService {
  static Future<void> generateAndShare(
      {required String title, required Map<String, String> data}) async {
    final logoData = await rootBundle.load('assets/pomeka-png-1757403926.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    const PdfColor pdfPrimary = PdfColor.fromInt(0xFF0052FF);
    const PdfColor pdfLightGrey = PdfColor.fromInt(0xFFF4F6F8);

    final pdf = pw.Document();
    pdf.addPage(pw.Page(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      build: (pw.Context context) {
        return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoImage, AppLocale.t('report_title'), pdfPrimary),
              pw.SizedBox(height: 30),
              pw.Center(
                  child: pw.Text(title.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          color: pdfPrimary,
                          letterSpacing: 1.2))),
              pw.SizedBox(height: 30),
              _buildTable(data, pdfPrimary, pdfLightGrey),
              pw.Spacer(),
              _buildFooter(pdfPrimary),
            ]);
      },
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'Pomeka_${title.replaceAll(' ', '_')}.pdf');
  }

  static Future<void> generateMultiReport(
      List<Map<String, dynamic>> items) async {
    final logoData = await rootBundle.load('assets/pomeka-png-1757403926.png');
    final logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    const PdfColor pdfPrimary = PdfColor.fromInt(0xFF0052FF);
    const PdfColor pdfLightGrey = PdfColor.fromInt(0xFFF4F6F8);

    final pdf = pw.Document();
    pdf.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      theme: pw.ThemeData.withFont(base: font, bold: fontBold),
      header: (context) => _buildHeader(
          logoImage, AppLocale.t('multi_report_title'), pdfPrimary),
      footer: (context) => _buildFooter(pdfPrimary),
      build: (context) => [
        pw.SizedBox(height: 20),
        ...items.map((item) {
          final type = item['type'] ?? '';
          final date = item['time'] != null
              ? item['time']
              .toString()
              .substring(0, 16)
              .replaceAll('T', ' ')
              : '-';
          final inputs = item['inputs'] ?? '';
          final result = item['res'] ?? '';
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300),
                borderRadius: pw.BorderRadius.circular(8),
                color: PdfColors.white),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                        color: pdfLightGrey,
                        borderRadius:
                        pw.BorderRadius.vertical(top: pw.Radius.circular(8))),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(type,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  color: pdfPrimary)),
                          pw.Text(date,
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey700)),
                        ]),
                  ),
                  pw.Divider(height: 1, color: PdfColors.grey300),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(12),
                    child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('${AppLocale.t('inputs')}:',
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(inputs,
                              style: const pw.TextStyle(fontSize: 11)),
                          pw.SizedBox(height: 8),
                          pw.Text('${AppLocale.t('results')}:',
                              style: const pw.TextStyle(
                                  fontSize: 10, color: PdfColors.grey600)),
                          pw.Text(result,
                              style: pw.TextStyle(
                                  fontSize: 14,
                                  fontWeight: pw.FontWeight.bold,
                                  color: pdfPrimary)),
                        ]),
                  ),
                ]),
          );
        }),
      ],
    ));
    await Printing.sharePdf(
        bytes: await pdf.save(), filename: 'Pomeka_Toplu_Rapor.pdf');
  }

  static pw.Widget _buildHeader(
      pw.MemoryImage logo, String title, PdfColor color) {
    return pw.Column(children: [
      pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Image(logo, height: 40),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 12,
                      color: color)),
              pw.SizedBox(height: 4),
              pw.Text(
                  '${AppLocale.t('date')}: ${DateTime.now().toString().substring(0, 10)}',
                  style: const pw.TextStyle(
                      fontSize: 10, color: PdfColors.grey700)),
            ])
          ]),
      pw.SizedBox(height: 10),
      pw.Container(height: 2, width: double.infinity, color: color),
    ]);
  }

  static pw.Widget _buildFooter(PdfColor color) {
    return pw.Column(children: [
      pw.Divider(color: PdfColors.grey300),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Text("POMEKA Mobile Tools",
            style: pw.TextStyle(
                fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
        pw.Text(AppLocale.t('pdf_footer'),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ])
    ]);
  }

  static pw.Widget _buildTable(
      Map<String, String> data, PdfColor primary, PdfColor bg) {
    return pw.Container(
      decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: pw.BorderRadius.circular(8),
          color: bg),
      child: pw.Column(children: data.entries.map((e) {
        final index = data.keys.toList().indexOf(e.key);
        final isLast = index == data.length - 1;
        return pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: pw.BoxDecoration(
              border: isLast
                  ? null
                  : const pw.Border(
                  bottom: pw.BorderSide(color: PdfColors.grey300)),
              color: index % 2 == 0 ? PdfColors.white : bg),
          child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(e.key,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.grey800)),
                pw.Text(e.value,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 12,
                        color: primary)),
              ]),
        );
      }).toList()),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. CHART WIDGETS
// ---------------------------------------------------------------------------

class ResultChart extends StatelessWidget {
  final double q;
  final double hm;
  final bool isDark;

  const ResultChart(
      {super.key, required this.q, required this.hm, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const Color lineColor = Color(0xFF0052FF);
    final Color gridColor = isDark ? Colors.white10 : Colors.black12;
    final Color textColor = isDark ? Colors.grey : Colors.black54;

    List<FlSpot> spots = [];
    double maxQ = q * 1.5;
    if (maxQ == 0) maxQ = 10;
    double kVal = (q > 0) ? hm / (q * q) : 0;

    for (double i = 0; i <= maxQ; i += maxQ / 20) {
      spots.add(FlSpot(i, kVal * i * i));
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: gridColor, strokeWidth: 1),
                  getDrawingVerticalLine: (_) =>
                      FlLine(color: gridColor, strokeWidth: 1)),
              titlesData: FlTitlesData(
                show: true,
                rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: maxQ / 5,
                        getTitlesWidget: (v, m) => Text(v.toStringAsFixed(1),
                            style: TextStyle(color: textColor, fontSize: 10)))),
                leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        interval: hm / 4,
                        getTitlesWidget: (v, m) => Text(v.toStringAsFixed(0),
                            style: TextStyle(color: textColor, fontSize: 10)))),
              ),
              borderData: FlBorderData(
                  show: true, border: Border.all(color: gridColor)),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: lineColor,
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                      show: true, color: lineColor.withValues(alpha: 0.1)),
                ),
                LineChartBarData(
                  spots: [FlSpot(q, hm)],
                  color: Colors.red,
                  barWidth: 0,
                  dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                              radius: 6,
                              color: Colors.red,
                              strokeWidth: 2,
                              strokeColor:
                              isDark ? Colors.white : Colors.black)),
                ),
              ],
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  tooltipBgColor: Colors.blueGrey,
                  getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                    return touchedBarSpots.map((barSpot) {
                      return LineTooltipItem(
                          'Q: ${barSpot.x.toStringAsFixed(1)}\nHm: ${barSpot.y.toStringAsFixed(1)}',
                          const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold));
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BoilerChart extends StatelessWidget {
  final double volume;
  final bool isDark;

  const BoilerChart({super.key, required this.volume, required this.isDark});

  @override
  Widget build(BuildContext context) {
    const Color lineColor = Colors.orange;
    final Color gridColor = isDark ? Colors.white10 : Colors.black12;
    final Color textColor = isDark ? Colors.grey : Colors.black54;

    double idealP = (3.48 * volume) / 45.0;
    if (idealP < 5) idealP = 5;

    double minP = idealP * 0.2;
    double maxP = idealP * 2.5;

    List<FlSpot> spots = [];
    for (double p = minP; p <= maxP; p += (maxP - minP) / 20) {
      double t = (3.48 * volume) / p;
      spots.add(FlSpot(p, t));
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                  '${AppLocale.t('chart_boiler_x')} / ${AppLocale.t('chart_boiler_y')}',
                  style: TextStyle(fontSize: 10, color: textColor)),
              const SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: (maxP - minP) / 5,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                    ),
                    borderData: FlBorderData(
                        show: true, border: Border.all(color: gridColor)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: 0.1)),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.orangeAccent,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            return LineTooltipItem(
                                '${barSpot.x.toStringAsFixed(1)} kW\n${barSpot.y.toStringAsFixed(0)} dk',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold));
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TANK CHART: Genleşme Hacmi vs Ortalama Sıcaklık
// ---------------------------------------------------------------------------
class TankChart extends StatelessWidget {
  final double waterVolume;
  final double maxTemp;
  final bool isDark;

  const TankChart(
      {super.key,
        required this.waterVolume,
        required this.maxTemp,
        required this.isDark});

  @override
  Widget build(BuildContext context) {
    const Color lineColor = Colors.purple;
    final Color gridColor = isDark ? Colors.white10 : Colors.black12;
    final Color textColor = isDark ? Colors.grey : Colors.black54;

    List<FlSpot> spots = [];
    for (double t = 20; t <= maxTemp + 10; t += 5) {
      double n = (0.00029 * t * t - 0.0037 * t + 0.06);
      if (n < 0) n = 0;
      double expVol = waterVolume * n / 100;
      spots.add(FlSpot(t, expVol));
    }

    return AspectRatio(
      aspectRatio: 1.70,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.all(Radius.circular(18)),
          color: isDark ? const Color(0xFF1E1F20) : Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                  '${AppLocale.t('chart_tank_x')} / ${AppLocale.t('chart_tank_y')}',
                  style: TextStyle(fontSize: 10, color: textColor)),
              const SizedBox(height: 10),
              Expanded(
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                        show: true,
                        getDrawingHorizontalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1),
                        getDrawingVerticalLine: (_) =>
                            FlLine(color: gridColor, strokeWidth: 1)),
                    titlesData: FlTitlesData(
                      show: true,
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 20,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                      leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (v, m) => Text(
                                  v.toStringAsFixed(0),
                                  style: TextStyle(
                                      color: textColor, fontSize: 10)))),
                    ),
                    borderData: FlBorderData(
                        show: true, border: Border.all(color: gridColor)),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: lineColor,
                        barWidth: 3,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                            show: true,
                            color: lineColor.withValues(alpha: 0.1)),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipBgColor: Colors.purple,
                        getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                          return touchedBarSpots.map((barSpot) {
                            return LineTooltipItem(
                                '${barSpot.x.toStringAsFixed(0)} °C\n${barSpot.y.toStringAsFixed(1)} L',
                                const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold));
                          }).toList();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 6. MAIN HOMESCREEN
// ---------------------------------------------------------------------------
class HomeScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onThemeChanged;
  const HomeScreen(
      {super.key, required this.isDarkMode, required this.onThemeChanged});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedToolIndex = 0;
  String? _sharedQ, _sharedH;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = "";

  final List<Map<String, dynamic>> _allMenuItems = [
    {'key': 'hydrofor', 'icon': Icons.water_drop, 'idx': 0},
    {'key': 'boiler', 'icon': Icons.thermostat, 'idx': 1},
    {'key': 'tank', 'icon': Icons.storage, 'idx': 2},
    {'key': 'converter', 'icon': Icons.change_circle, 'idx': 3},
  ];

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<String> titles = [
      AppLocale.t('hydrofor'),
      AppLocale.t('boiler'),
      AppLocale.t('tank'),
      AppLocale.t('converter')
    ];
    Widget body;
    switch (_selectedToolIndex) {
      case 0:
        body = HydroforTab(
            onRes: (q, h) => setState(() {
              _sharedQ = q;
              _sharedH = h;
            }),
            toTank: () => setState(() => _selectedToolIndex = 2));
        break;
      case 1:
        body = const BoilerInstallationTab();
        break;
      case 2:
        body = TankTab(q: _sharedQ, h: _sharedH);
        break;
      case 3:
        body = const UnitConverterTab();
        break;
      default:
        body = const SizedBox.shrink();
    }

    final filteredItems = _allMenuItems.where((item) {
      final title = AppLocale.t(item['key']).toLowerCase();
      final query = _searchQuery.toLowerCase();
      return title.contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Image.asset('assets/pomeka-png-1757403926.png', height: 32),
        centerTitle: true,
        actions: [
          IconButton(
              icon: const Icon(Icons.history),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (c) => const HistoryScreen()))),
          Switch(value: widget.isDarkMode, onChanged: widget.onThemeChanged),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF0052FF)),
                child: Center(
                    child: Image.asset('assets/pomeka-png-1757403926.png',
                        height: 40))),
            ListTile(
              leading: const Icon(Icons.functions),
              title: Text(AppLocale.t('formulas')),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/formulas');
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: AppLocale.t('search_hint'),
                  prefixIcon: const Icon(Icons.search),
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none),
                  filled: true,
                  fillColor:
                  widget.isDarkMode ? Colors.white10 : Colors.grey[200],
                ),
              ),
            ),
            Expanded(
                child: ListView.builder(
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final title = AppLocale.t(item['key']);
                    final icon = item['icon'] as IconData;
                    final idx = item['idx'] as int;
                    final isSelected = _selectedToolIndex == idx;

                    return ListTile(
                      leading: Icon(icon,
                          color:
                          isSelected ? const Color(0xFF0052FF) : Colors.grey),
                      title: Text(title,
                          style: TextStyle(
                              color: isSelected ? const Color(0xFF0052FF) : null,
                              fontWeight: isSelected ? FontWeight.bold : null)),
                      onTap: () {
                        setState(() => _selectedToolIndex = idx);
                        Navigator.pop(context);
                      },
                    );
                  },
                )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0052FF),
        child: const Icon(Icons.language, color: Colors.white),
        onPressed: () => _showLangPicker(),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
            child: Text(titles[_selectedToolIndex].toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.8)),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 60),
              child: Divider(
                  color: const Color(0xFF0052FF).withValues(alpha: 0.2),
                  thickness: 2)),
          Expanded(child: body),
        ],
      ),
    );
  }

  void _showLangPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (c) => Container(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            _lItem('TR', 'Türkçe', '🇹🇷'),
            _lItem('EN', 'English', '🇺🇸'),
            _lItem('DE', 'Deutsch', '🇩🇪'),
            _lItem('FR', 'Français', '🇫🇷'),
          ])),
    );
  }

  Widget _lItem(String c, String n, String f) => ListTile(
      leading: Text(f, style: const TextStyle(fontSize: 24)),
      title: Text(n),
      onTap: () {
        setState(() => AppLocale.currentLang = c);
        Navigator.pop(context);
      });
}

// ---------------------------------------------------------------------------
// 7. CALCULATOR TABS
// ---------------------------------------------------------------------------

// --- UNIT CONVERTER TAB ---
class UnitConverterTab extends StatefulWidget {
  const UnitConverterTab({super.key});
  @override
  State<UnitConverterTab> createState() => _UnitConverterTabState();
}

class _UnitConverterTabState extends State<UnitConverterTab> {
  final TextEditingController _inputCtrl = TextEditingController();
  String _selectedCategory = 'cat_press';
  String _fromUnit = 'Bar';
  String _toUnit = 'mSS';
  double _result = 0.0;

  final Map<String, Map<String, double>> _units = {
    'cat_press': {
      'Bar': 1.0,
      'mSS': 0.0980665,
      'Psi': 0.0689476,
      'Pa': 0.00001,
      'Atm': 1.01325
    },
    'cat_flow': {'m³/h': 1.0, 'lt/s': 3.6, 'lt/dk': 0.06, 'gpm': 0.22712},
    'cat_power': {
      'kW': 1.0,
      'HP': 0.7457,
      'kcal/h': 0.001162,
      'btu/h': 0.000293
    },
    'cat_len': {
      'm': 1.0,
      'cm': 0.01,
      'mm': 0.001,
      'inch': 0.0254,
      'ft': 0.3048
    },
    'cat_vol': {'Litre': 1.0, 'm³': 1000.0, 'Galon': 3.78541},
  };

  @override
  void initState() {
    super.initState();
    _resetUnits();
  }

  void _resetUnits() {
    final catKey = _selectedCategory;
    final keys = _units[catKey]!.keys.toList();
    setState(() {
      _fromUnit = keys[0];
      _toUnit = keys.length > 1 ? keys[1] : keys[0];
      _calculate();
    });
  }

  void _calculate() {
    double val = double.tryParse(_inputCtrl.text) ?? 0.0;
    double baseVal = val * _units[_selectedCategory]![_fromUnit]!;
    double res = baseVal / _units[_selectedCategory]![_toUnit]!;
    setState(() => _result = res);
  }

  @override
  Widget build(BuildContext context) {
    final catKeys = [
      'cat_press',
      'cat_flow',
      'cat_power',
      'cat_len',
      'cat_vol'
    ];
    final currentUnitKeys = _units[_selectedCategory]!.keys.toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final resultColor =
    isDark ? Colors.cyanAccent : Theme.of(context).primaryColor;
    final iconColor = isDark ? Colors.white : Theme.of(context).primaryColor;
    final borderColor = isDark
        ? Colors.white24
        : Theme.of(context).primaryColor.withValues(alpha: 0.2);
    final textColor = isDark ? Colors.white : Colors.black87;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor)),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                dropdownColor: isDark ? const Color(0xFF252628) : Colors.white,
                icon: Icon(Icons.unfold_more, color: iconColor, size: 28),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedCategory = val);
                    _resetUnits();
                  }
                },
                items: catKeys
                    .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(AppLocale.t(e),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: textColor))))
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 30),
          Card(
            elevation: 4,
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Row(children: [
                  Expanded(
                      flex: 2,
                      child: TextField(
                          controller: _inputCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          onChanged: (_) => _calculate(),
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                              labelText: AppLocale.t('val_input'),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12))))),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                          initialValue: _fromUnit,
                          decoration:
                          const InputDecoration(border: InputBorder.none),
                          isExpanded: true,
                          onChanged: (val) {
                            setState(() => _fromUnit = val!);
                            _calculate();
                          },
                          items: currentUnitKeys
                              .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(AppLocale.t(e),
                                  style: const TextStyle(fontSize: 14))))
                              .toList())),
                ]),
                const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Icon(Icons.arrow_downward, color: Colors.grey)),
                Row(children: [
                  Expanded(
                      flex: 2,
                      child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .primaryColor
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12)),
                          child: Text(
                              _result == 0 ? "0" : _result.toStringAsFixed(4),
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: resultColor)))),
                  const SizedBox(width: 16),
                  Expanded(
                      flex: 1,
                      child: DropdownButtonFormField<String>(
                          initialValue: _toUnit,
                          decoration:
                          const InputDecoration(border: InputBorder.none),
                          isExpanded: true,
                          onChanged: (val) {
                            setState(() => _toUnit = val!);
                            _calculate();
                          },
                          items: currentUnitKeys
                              .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(AppLocale.t(e),
                                  style: const TextStyle(fontSize: 14))))
                              .toList())),
                ]),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// --- HYDROFOR TAB ---
class HydroforTab extends StatefulWidget {
  final Function(String, String) onRes;
  final VoidCallback toTank;
  const HydroforTab({super.key, required this.onRes, required this.toTank});
  @override
  State<HydroforTab> createState() => _HydroforTabState();
}

class _HydroforTabState extends State<HydroforTab> {
  final _dCtrl = TextEditingController();
  final _kCtrl = TextEditingController();
  String? _qR, _hR, _type;
  bool _load = false;

  @override
  void initState() {
    super.initState();
    _type = 't_konut';
  }

  void _clear() {
    setState(() {
      _dCtrl.clear();
      _kCtrl.clear();
      _type = 't_konut';
      _qR = null;
      _hR = null;
      _load = false;
    });
  }

  void _calc() async {
    if (_dCtrl.text.isEmpty || _kCtrl.text.isEmpty || _type == null) return;
    setState(() => _load = true);
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;

    final d = int.parse(_dCtrl.text);
    final k = int.parse(_kCtrl.text);

    double tuketim = 150.0;
    switch (_type) {
      case 't_konut':
        tuketim = 150.0;
        break;
      case 'l_konut':
        tuketim = 200.0;
        break;
      case 'l_villa':
        tuketim = 225.0;
        break;
      case 'misafir':
        tuketim = 100.0;
        break;
      case 'otel':
        tuketim = 150.0;
        break;
      case 'hasta':
        tuketim = 200.0;
        break;
      case 'buro':
        tuketim = 80.0;
        break;
      case 'okul':
        tuketim = 20.0;
        break;
      case 'y_okul':
        tuketim = 100.0;
        break;
      case 'avm':
        tuketim = 50.0;
        break;
    }

    double esZaman = 0.25;
    if (d <= 4) {
      esZaman = 0.66;
    } else if (d <= 10) {
      esZaman = 0.45;
    } else if (d <= 20) {
      esZaman = 0.40;
    } else if (d <= 50) {
      esZaman = 0.35;
    } else if (d <= 100) {
      esZaman = 0.30;
    }

    double q = (d * 4.0 * tuketim * esZaman) / 1000.0;
    double hm = (k * 3.0) + 40.0;

    setState(() {
      _qR = '${q.toStringAsFixed(2)} ${AppLocale.t('flow_unit')}';
      _hR = '${hm.toStringAsFixed(2)} ${AppLocale.t('press_unit')}';
      _load = false;
    });

    widget.onRes(q.toStringAsFixed(2), hm.toStringAsFixed(2));

    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getStringList('calculation_history') ?? [];
    h.add(jsonEncode({
      'type': AppLocale.t('hydrofor'),
      'res': '$_qR / $_hR',
      'time': DateTime.now().toString(),
      'inputs': '${AppLocale.t('units')}: ${_dCtrl.text}, ...'
    }));
    await prefs.setStringList('calculation_history', h);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  TextField(
                      controller: _dCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('units'),
                          prefixIcon: const Icon(Icons.people))),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _type,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('b_type'),
                        prefixIcon: const Icon(Icons.business)),
                    onChanged: (v) => setState(() => _type = v),
                    items: [
                      't_konut',
                      'l_konut',
                      'l_villa',
                      'misafir',
                      'otel',
                      'hasta',
                      'buro',
                      'okul',
                      'y_okul',
                      'avm'
                    ]
                        .map((e) => DropdownMenuItem(
                        value: e, child: Text(AppLocale.t(e))))
                        .toList(),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _kCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('floors'),
                          prefixIcon: const Icon(Icons.apartment))),
                  const SizedBox(height: 32),
                  ElevatedButton(
                      onPressed: _calc,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('calculate'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('clean'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]))),
        if (_load)
          const Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
        if (_qR != null && !_load) _buildResCard(),
      ]),
    );
  }

  Widget _buildResCard() {
    double qVal = double.tryParse(_qR!.split(' ')[0]) ?? 0;
    double hVal = double.tryParse(_hR!.split(' ')[0]) ?? 0;
    return Container(
      margin: const EdgeInsets.only(top: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF0052FF), width: 2),
          borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _row(AppLocale.t('res_flow'), _qR!, Icons.water_drop_outlined),
        const Divider(height: 24),
        _row(AppLocale.t('res_press'), _hR!, Icons.speed_outlined),
        const SizedBox(height: 24),
        ResultChart(
            q: qVal,
            hm: hVal,
            isDark: Theme.of(context).brightness == Brightness.dark),
        const SizedBox(height: 20),
        ElevatedButton(
            onPressed: widget.toTank,
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0052FF),
                foregroundColor: Colors.white,
                padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.send_to_mobile),
                const SizedBox(width: 8),
                Text(AppLocale.t('go_tank'))
              ],
            )),
        const SizedBox(height: 10),
        OutlinedButton.icon(
            icon: const Icon(Icons.picture_as_pdf),
            label: Text(AppLocale.t('share_pdf')),
            onPressed: () => PdfService.generateAndShare(
                title: AppLocale.t('hydrofor'),
                data: {
                  AppLocale.t('res_flow'): _qR!,
                  AppLocale.t('res_press'): _hR!
                }))
      ]),
    );
  }

  Widget _row(String l, String v, IconData i) => Row(children: [
    Icon(i, color: const Color(0xFF0052FF), size: 28),
    const SizedBox(width: 15),
    Expanded(
        child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
                style: Theme.of(context).textTheme.titleLarge,
                children: [
                  TextSpan(
                      text: '$l: ',
                      style: const TextStyle(color: Colors.grey)),
                  TextSpan(
                      text: v,
                      style: const TextStyle(fontWeight: FontWeight.bold))
                ])))
  ]);
}

// --- BOILER TAB ---
class BoilerTab extends StatefulWidget {
  const BoilerTab({super.key});
  @override
  State<BoilerTab> createState() => _BoilerTabState();
}

class BoilerInstallationTab extends StatefulWidget {
  const BoilerInstallationTab({super.key});

  @override
  State<BoilerInstallationTab> createState() => _BoilerInstallationTabState();
}

class _BoilerInstallationTabState extends State<BoilerInstallationTab> {
  final List<_BoilerZoneController> _zones = [];
  final _widthCtrl = TextEditingController();
  final _lengthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _collectorVelocityCtrl = TextEditingController(text: '0.7');
  BoilerSystemType _systemType = BoilerSystemType.floorHeating;
  BoilerInstallationResult? _result;

  final List<_BoilerZoneDefinition> _definitions = const [
    _BoilerZoneDefinition('zone_pool', 15, 0.7),
    _BoilerZoneDefinition('zone_floor', 10, 0.7),
    _BoilerZoneDefinition('zone_boiler', 20, 0.7),
    _BoilerZoneDefinition('zone_radiator', 20, 0.7),
    _BoilerZoneDefinition('zone_hamam', 10, 0.7),
    _BoilerZoneDefinition('zone_air_handler', 15, 0.7),
    _BoilerZoneDefinition('zone_heat_recovery', 15, 0.5),
  ];

  @override
  void initState() {
    super.initState();
    for (final def in _definitions) {
      _zones.add(_BoilerZoneController(
        labelKey: def.labelKey,
        loadController: TextEditingController(),
        deltaController: TextEditingController(text: def.defaultDeltaT.toString()),
        velocityController:
            TextEditingController(text: def.defaultVelocity.toString()),
        defaultDeltaT: def.defaultDeltaT,
        defaultVelocity: def.defaultVelocity,
      ));
    }
  }

  @override
  void dispose() {
    for (final zone in _zones) {
      zone.loadController.dispose();
      zone.deltaController.dispose();
      zone.velocityController.dispose();
    }
    _widthCtrl.dispose();
    _lengthCtrl.dispose();
    _heightCtrl.dispose();
    _collectorVelocityCtrl.dispose();
    super.dispose();
  }

  void _calculate() {
    final inputs = <BoilerZoneInput>[];
    final width = _parseDouble(_widthCtrl.text);
    final length = _parseDouble(_lengthCtrl.text);
    final height = _parseDouble(_heightCtrl.text);
    final collectorVelocity = _parseDouble(_collectorVelocityCtrl.text);
    if (height < 0) {
      _showError(AppLocale.t('err_negative'));
      return;
    }
    if (width < 0 || length < 0) {
      _showError(AppLocale.t('err_negative'));
      return;
    }
    if (collectorVelocity <= 0) {
      _showError(AppLocale.t('err_velocity'));
      return;
    }
    for (final zone in _zones) {
      final load = _parseDouble(zone.loadController.text);
      final deltaT = _parseDouble(zone.deltaController.text,
          fallback: zone.defaultDeltaT);
      final velocity = _parseDouble(zone.velocityController.text,
          fallback: zone.defaultVelocity);
      if (load < 0) {
        _showError(AppLocale.t('err_negative'));
        return;
      }
      if (deltaT <= 0) {
        _showError(AppLocale.t('err_delta_t'));
        return;
      }
      if (velocity <= 0) {
        _showError(AppLocale.t('err_velocity'));
        return;
      }
      inputs.add(BoilerZoneInput(
        labelKey: zone.labelKey,
        velocity: velocity,
        loadKcalPerHour: load,
        deltaT: deltaT,
      ));
    }

    setState(() {
      _result = BoilerInstallationCalculator.calculate(
        zones: inputs,
        collectorVelocity: collectorVelocity,
        buildingHeight: height,
        systemType: _systemType,
      );
    });
  }

  void _clear() {
    for (final zone in _zones) {
      zone.loadController.clear();
      zone.deltaController.text = zone.defaultDeltaT.toString();
      zone.velocityController.text = zone.defaultVelocity.toString();
    }
    _widthCtrl.clear();
    _lengthCtrl.clear();
    _heightCtrl.clear();
    _collectorVelocityCtrl.text = '0.7';
    _systemType = BoilerSystemType.floorHeating;
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
        children: [
          _sectionTitle(AppLocale.t('boiler_capacity')),
          _BoilerCapacityCard(result: _result),
          const SizedBox(height: 16),
          _sectionTitle(AppLocale.t('zone_title')),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  for (final zone in _zones) ...[
                    _BoilerZoneInputRow(zone: zone),
                    const SizedBox(height: 14),
                  ],
                  const SizedBox(height: 10),
                  _sectionTitle(AppLocale.t('building_dims')),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _widthCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppLocale.t('building_width'),
                            suffixText: 'm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _lengthCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppLocale.t('building_length'),
                            suffixText: 'm',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _heightCtrl,
                          keyboardType:
                              const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: AppLocale.t('building_height'),
                            suffixText: 'm',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocale.t('system_type'),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<BoilerSystemType>(
                        value: _systemType,
                        isExpanded: true,
                        onChanged: (val) {
                          if (val == null) return;
                          setState(() => _systemType = val);
                        },
                        items: [
                          BoilerSystemType.floorHeating,
                          BoilerSystemType.panelRadiator,
                          BoilerSystemType.steelRadiator,
                          BoilerSystemType.other,
                        ]
                            .map(
                              (type) => DropdownMenuItem(
                                value: type,
                                child: Text(_systemTypeLabel(type)),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _collectorVelocityCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: AppLocale.t('collector_velocity'),
                      suffixText: 'm/s',
                    ),
                  ),
                  const SizedBox(height: 10),
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
                  )
                ],
              ),
            ),
          ),
          if (_result != null) ...[
            const SizedBox(height: 20),
            _BoilerResultCard(result: _result!),
          ]
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  String _systemTypeLabel(BoilerSystemType type) {
    switch (type) {
      case BoilerSystemType.floorHeating:
        return AppLocale.t('system_floor');
      case BoilerSystemType.panelRadiator:
        return AppLocale.t('system_panel');
      case BoilerSystemType.steelRadiator:
        return AppLocale.t('system_steel');
      case BoilerSystemType.other:
        return AppLocale.t('system_other');
    }
  }
}

class _BoilerZoneDefinition {
  final String labelKey;
  final double defaultDeltaT;
  final double defaultVelocity;

  const _BoilerZoneDefinition(
      this.labelKey, this.defaultDeltaT, this.defaultVelocity);
}

class _BoilerZoneController {
  final String labelKey;
  final TextEditingController loadController;
  final TextEditingController deltaController;
  final TextEditingController velocityController;
  final double defaultDeltaT;
  final double defaultVelocity;

  _BoilerZoneController({
    required this.labelKey,
    required this.loadController,
    required this.deltaController,
    required this.velocityController,
    required this.defaultDeltaT,
    required this.defaultVelocity,
  });
}

class _BoilerZoneInputRow extends StatelessWidget {
  final _BoilerZoneController zone;

  const _BoilerZoneInputRow({required this.zone});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocale.t(zone.labelKey),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: TextField(
                controller: zone.velocityController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocale.t('velocity'),
                  suffixText: 'm/s',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: TextField(
                controller: zone.loadController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocale.t('heat_load_kcal'),
                  suffixText: 'kcal/h',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
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
      ],
    );
  }
}

class _BoilerCapacityCard extends StatelessWidget {
  final BoilerInstallationResult? result;

  const _BoilerCapacityCard({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(AppLocale.t('no_data')),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BoilerResultRow(
              label: AppLocale.t('total_heat_load'),
              value: '${result!.totalLoadKcalPerHour.toStringAsFixed(0)} kcal/h',
              isMain: true,
            ),
            _BoilerResultRow(
              label: AppLocale.t('boiler_capacity_kw'),
              value: '${result!.boilerCapacityKw} kW',
            ),
            _BoilerResultRow(
              label: AppLocale.t('boiler_capacity_kcal'),
              value:
                  '${result!.boilerCapacityKcalPerHour.toStringAsFixed(0)} kcal/h',
            ),
          ],
        ),
      ),
    );
  }
}

class _BoilerResultCard extends StatelessWidget {
  final BoilerInstallationResult result;

  const _BoilerResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFF0052FF), width: 2),
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF0052FF).withValues(alpha: 0.05),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(AppLocale.t('zone_results')),
          for (final zone in result.zones)
            _BoilerZoneResultRow(
              label: AppLocale.t(zone.labelKey),
              flow: zone.flowM3PerHour,
              diameter: zone.diameterMm,
            ),
          const Divider(height: 24),
          _BoilerResultRow(
            label: AppLocale.t('total_flow'),
            value: '${result.totalFlowM3PerHour.toStringAsFixed(2)} m³/h',
            isMain: true,
          ),
          _BoilerResultRow(
            label: AppLocale.t('collector_diameter'),
            value: '${result.collectorDiameterMm.toStringAsFixed(2)} mm',
          ),
          const Divider(height: 24),
          _sectionHeader(AppLocale.t('expansion_tanks')),
          _BoilerResultRow(
            label: AppLocale.t('open_tank'),
            value: '${result.expansion.openTankLiters.toStringAsFixed(0)} L',
          ),
          _BoilerResultRow(
            label: AppLocale.t('closed_tank'),
            value: result.expansion.closedTankLiters == null
                ? AppLocale.t('check_height')
                : '${result.expansion.closedTankLiters!.toStringAsFixed(0)} L',
          ),
          _BoilerResultRow(
            label: AppLocale.t('opening_pressure'),
            value: result.expansion.openingPressureBar == null
                ? AppLocale.t('check_height')
                : '${result.expansion.openingPressureBar!.toStringAsFixed(1)} bar',
          ),
          _BoilerResultRow(
            label: AppLocale.t('safety_pressure'),
            value: result.expansion.safetyPressureBar == null
                ? AppLocale.t('check_height')
                : '${result.expansion.safetyPressureBar!.toStringAsFixed(1)} bar',
          ),
          if (result.expansion.heightWarning)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                AppLocale.t('height_warning'),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const Divider(height: 24),
          _sectionHeader(AppLocale.t('expansion_details')),
          _BoilerResultRow(
            label: AppLocale.t('system_volume'),
            value: result.expansion.systemVolumeLiters == null
                ? '-'
                : '${result.expansion.systemVolumeLiters!.toStringAsFixed(1)} L',
          ),
          _BoilerResultRow(
            label: AppLocale.t('expansion_volume'),
            value: result.expansion.expansionVolumeLiters == null
                ? '-'
                : '${result.expansion.expansionVolumeLiters!.toStringAsFixed(1)} L',
          ),
          _BoilerResultRow(
            label: AppLocale.t('reserve_volume'),
            value: result.expansion.reserveVolumeLiters == null
                ? '-'
                : '${result.expansion.reserveVolumeLiters!.toStringAsFixed(1)} L',
          ),
          _BoilerResultRow(
            label: AppLocale.t('static_pressure'),
            value: result.expansion.staticPressureBar == null
                ? '-'
                : '${result.expansion.staticPressureBar!.toStringAsFixed(1)} bar',
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}

class _BoilerZoneResultRow extends StatelessWidget {
  final String label;
  final double flow;
  final double diameter;

  const _BoilerZoneResultRow({
    required this.label,
    required this.flow,
    required this.diameter,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${AppLocale.t('flow')}: ${flow.toStringAsFixed(2)} m³/h',
                ),
              ),
              Expanded(
                child: Text(
                  '${AppLocale.t('pipe_diameter')}: ${diameter.toStringAsFixed(2)} mm',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BoilerResultRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMain;

  const _BoilerResultRow({
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

class _BoilerTabState extends State<BoilerTab> {
  final _hCtrl = TextEditingController();
  final _pCtrl = TextEditingController(text: '3');
  double? _c;
  String? _res;
  bool _load = false;
  double? _numericRes;
  bool _isError = false;

  void _clear() {
    setState(() {
      _hCtrl.clear();
      _pCtrl.clear();
      _c = null;
      _res = null;
      _numericRes = null;
      _load = false;
      _isError = false;
    });
  }

  void _calc() async {
    final n = int.tryParse(_hCtrl.text);
    final k = int.tryParse(_pCtrl.text);
    if (n == null || _c == null) return;
    setState(() {
      _load = true;
      _isError = false;
    });
    await Future.delayed(const Duration(milliseconds: 650));
    if (!mounted) return;
    double val = n * k! * 0.4 * 50 * 0.583 * _c!;

    if (_c == 1.0 && val < 500) {
      setState(() {
        _res = AppLocale.t('err_boiler_500');
        _numericRes = null;
        _isError = true;
        _load = false;
      });
      return;
    }

    setState(() {
      _numericRes = val;
      _res = '${val.toStringAsFixed(2)} L';
      _load = false;
    });
    final prefs = await SharedPreferences.getInstance();
    final h = prefs.getStringList('calculation_history') ?? [];
    h.add(jsonEncode({
      'type': AppLocale.t('boiler'),
      'res': _res,
      'time': DateTime.now().toString(),
      'inputs': '...'
    }));
    await prefs.setStringList('calculation_history', h);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  TextField(
                      controller: _hCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('units'),
                          prefixIcon: const Icon(Icons.house_outlined))),
                  const SizedBox(height: 16),
                  TextField(
                      controller: _pCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                          labelText: AppLocale.t('people'),
                          prefixIcon: const Icon(Icons.people_outline))),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    initialValue: _c,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('coil'),
                        prefixIcon: const Icon(Icons.sync_alt)),
                    onChanged: (v) => setState(() => _c = v),
                    items: [
                      DropdownMenuItem(
                          value: 1.15, child: Text(AppLocale.t('single'))),
                      DropdownMenuItem(
                          value: 1.0, child: Text(AppLocale.t('double')))
                    ],
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                      onPressed: _calc,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('calculate'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('clean'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]))),
        if (_load)
          const Padding(
              padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
        if (_res != null && !_load)
          Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  border: Border.all(
                      color: _isError ? Colors.red : const Color(0xFF0052FF),
                      width: 2),
                  borderRadius: BorderRadius.circular(20),
                  color: _isError ? Colors.red.withValues(alpha: 0.1) : null),
              child: Column(children: [
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(
                      _isError ? Icons.error_outline : Icons.thermostat_auto,
                      color: _isError ? Colors.red : const Color(0xFF0052FF),
                      size: 28),
                  const SizedBox(width: 15),
                  Expanded(
                      child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                              style: Theme.of(context).textTheme.titleLarge,
                              children: [
                                if (!_isError)
                                  TextSpan(
                                      text: '${AppLocale.t('res_vol')}: ',
                                      style:
                                      const TextStyle(color: Colors.grey)),
                                TextSpan(
                                    text: _res!,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _isError ? Colors.red : null))
                              ])))
                ]),
                const SizedBox(height: 24),
                if (_numericRes != null && !_isError) ...[
                  BoilerChart(
                      volume: _numericRes!,
                      isDark: Theme.of(context).brightness == Brightness.dark),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf),
                      label: Text(AppLocale.t('share_pdf')),
                      onPressed: () => PdfService.generateAndShare(
                          title: AppLocale.t('boiler'),
                          data: {AppLocale.t('res_vol'): _res!}))
                ]
              ]))
      ]),
    );
  }
}

// --- TANK TAB ---
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

  double? _heaterFactor = 12.0;
  double? _glycol = 0.0;

  String? _resTank;
  String? _resStatic, _resPreGas, _resSafety, _resExpVol, _resWaterVol;
  double? _numericWaterVol, _numericMaxTemp;

  @override
  void initState() {
    super.initState();
    _kwCtrl = TextEditingController(text: widget.q);
    String initialH =
    widget.h != null ? (double.tryParse(widget.h!)! * 3).toString() : '';
    _hCtrl = TextEditingController(text: initialH);
  }

  void _clear() {
    setState(() {
      _kwCtrl.clear();
      _hCtrl.clear();
      _tfCtrl.text = '80';
      _trCtrl.text = '60';
      _heaterFactor = 12.0;
      _glycol = 0.0;
      _resTank = null;
      _resStatic = null;
      _resPreGas = null;
      _resSafety = null;
      _resExpVol = null;
      _resWaterVol = null;
      _numericWaterVol = null;
    });
  }

  double _getExpansionCoef(double temp) {
    double roCold = 999.0;
    double roHot = 1000.0 - ((temp - 4) * (temp - 4) / 180.0);
    double expansion = ((roCold / roHot) - 1) * 100;
    return expansion > 0 ? expansion : 0.5;
  }

  void _calc() async {
    final kw = double.tryParse(_kwCtrl.text);
    final h = double.tryParse(_hCtrl.text);
    final tf = double.tryParse(_tfCtrl.text) ?? 80;
    final tr = double.tryParse(_trCtrl.text) ?? 60;

    if (kw == null || h == null) return;

    // 1. Su Hacmi (Vs)
    double vs = kw * _heaterFactor!;

    // 2. Statik Basınç (Pst)
    double pst = h / 10.0;

    // 3. Ön Gaz Basıncı (P0)
    double p0 = pst + 0.2;

    // 4. Emniyet Ventili (Psv)
    double psv = pst + 1.5;
    double pmax = psv;

    // 5. Genleşme Hesabı
    double tm = (tf + tr) / 2;
    double n = _getExpansionCoef(tm);
    if (_glycol! > 0) n = n * 1.1;

    double ve = vs * n / 100.0;

    // 6. Tank Su Hacmi (Vwr)
    double vwr = vs * 0.005;
    if (vwr < 3) vwr = 3;

    // 7. Basınç Faktörü (K)
    double k = ((pmax + 1) - (p0 + 1)) / (pmax + 1);
    if (k <= 0) k = 0.1;

    // 8. Toplam Tank Hacmi (Vt)
    double vt = (ve + vwr) / k;

    setState(() {
      _numericWaterVol = vs;
      _numericMaxTemp = tf;

      _resWaterVol = '${vs.toStringAsFixed(0)} L';
      _resStatic = '${pst.toStringAsFixed(1)} Bar';
      _resPreGas = '${p0.toStringAsFixed(1)} Bar';
      _resSafety = '${psv.toStringAsFixed(1)} Bar';
      _resExpVol = '${ve.toStringAsFixed(1)} L';
      _resTank = '${vt.toStringAsFixed(1)} L';
    });

    final prefs = await SharedPreferences.getInstance();
    final hist = prefs.getStringList('calculation_history') ?? [];
    hist.add(jsonEncode({
      'type': AppLocale.t('tank'),
      'res': _resTank,
      'time': DateTime.now().toString(),
      'inputs': 'kW: $kw, H: $h m'
    }));
    await prefs.setStringList('calculation_history', hist);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        Card(
            child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _kwCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: AppLocale.t('heat_cap'),
                                prefixIcon: const Icon(Icons.bolt)))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextField(
                            controller: _hCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: AppLocale.t('sys_h'),
                                prefixIcon: const Icon(Icons.height)))),
                  ]),
                  const SizedBox(height: 16),
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: _tfCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: AppLocale.t('temp_f'),
                                prefixIcon: const Icon(
                                    Icons.thermostat_outlined,
                                    color: Colors.red)))),
                    const SizedBox(width: 16),
                    Expanded(
                        child: TextField(
                            controller: _trCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                                labelText: AppLocale.t('temp_r'),
                                prefixIcon: const Icon(
                                    Icons.thermostat_outlined,
                                    color: Colors.blue)))),
                  ]),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    initialValue: _heaterFactor,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('heat_type'),
                        prefixIcon: const Icon(Icons.whatshot)),
                    onChanged: (v) => setState(() => _heaterFactor = v),
                    items: [
                      DropdownMenuItem(
                          value: 12.0, child: Text(AppLocale.t('h_panel'))),
                      DropdownMenuItem(
                          value: 15.0, child: Text(AppLocale.t('h_cast'))),
                      DropdownMenuItem(
                          value: 20.0, child: Text(AppLocale.t('h_floor'))),
                      DropdownMenuItem(
                          value: 8.0, child: Text(AppLocale.t('h_fancoil'))),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<double>(
                    initialValue: _glycol,
                    decoration: InputDecoration(
                        labelText: AppLocale.t('glycol'),
                        prefixIcon: const Icon(Icons.ac_unit)),
                    onChanged: (v) => setState(() => _glycol = v),
                    items: [0.0, 10.0, 20.0, 30.0, 40.0, 50.0]
                        .map((e) =>
                        DropdownMenuItem(value: e, child: Text('%${e.toInt()}')))
                        .toList(),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                      onPressed: _calc,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0052FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('calculate'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                  const SizedBox(height: 16),
                  OutlinedButton(
                      onPressed: _clear,
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          foregroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 60),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                      child: Text(AppLocale.t('clean'),
                          style: const TextStyle(fontWeight: FontWeight.bold))),
                ]))),
        if (_resTank != null)
          Container(
              margin: const EdgeInsets.only(top: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF0052FF), width: 2),
                  borderRadius: BorderRadius.circular(20)),
              child: Column(children: [
                _resRow(AppLocale.t('tank_vol'), _resTank!, isMain: true),
                const Divider(),
                _resRow(AppLocale.t('res_water_vol'), _resWaterVol!),
                _resRow('${AppLocale.t('res_static')}:', _resStatic!),
                _resRow('${AppLocale.t('res_pregas')}:', _resPreGas!),
                _resRow('${AppLocale.t('res_safety')}:', _resSafety!),
                _resRow('${AppLocale.t('res_exp_vol')}:', _resExpVol!),

                const SizedBox(height: 24),
                if (_numericWaterVol != null)
                  TankChart(
                      waterVolume: _numericWaterVol!,
                      maxTemp: _numericMaxTemp!,
                      isDark: Theme.of(context).brightness == Brightness.dark),

                const SizedBox(height: 20),
                OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: Text(AppLocale.t('share_pdf')),
                    onPressed: () => PdfService.generateAndShare(
                        title: AppLocale.t('tank'),
                        data: {
                          AppLocale.t('heat_cap'): _kwCtrl.text,
                          AppLocale.t('res_static'): _resStatic!,
                          AppLocale.t('res_pregas'): _resPreGas!,
                          AppLocale.t('tank_vol'): _resTank!
                        }))
              ]))
      ]),
    );
  }

  Widget _resRow(String label, String val, {bool isMain = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isMain ? const Color(0xFF0052FF) : Colors.grey,
                  fontWeight: isMain ? FontWeight.w900 : FontWeight.normal,
                  fontSize: isMain ? 20 : 14)),
          Text(val,
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: isMain ? 24 : 16)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 8. HISTORY SCREEN
// ---------------------------------------------------------------------------
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> h = prefs.getStringList('calculation_history') ?? [];
    if (!mounted) return;
    setState(() {
      _history = h
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .toList()
          .reversed
          .toList();
    });
  }

  Future<void> _handleDelete() async {
    if (_selectedIndices.isNotEmpty) {
      final prefs = await SharedPreferences.getInstance();
      List<Map<String, dynamic>> keptHistory = [];

      for (int i = 0; i < _history.length; i++) {
        if (!_selectedIndices.contains(i)) {
          keptHistory.add(_history[i]);
        }
      }

      final saveList = keptHistory.reversed.map((e) => jsonEncode(e)).toList();
      await prefs.setStringList('calculation_history', saveList);

      setState(() {
        _history = keptHistory;
        _selectedIndices.clear();
      });
    } else {
      _showDeleteAllDialog();
    }
  }

  void _showDeleteAllDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocale.t('delete_confirm_title')),
        content: Text(AppLocale.t('delete_confirm_msg')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocale.t('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('calculation_history');
              if (mounted) {
                setState(() {
                  _history = [];
                  _selectedIndices.clear();
                });
              }
            },
            child: Text(AppLocale.t('delete'),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _exportSelected() {
    if (_selectedIndices.isEmpty) return;
    List<Map<String, dynamic>> selectedItems = [];
    for (int index in _selectedIndices) {
      selectedItems.add(_history[index]);
    }
    PdfService.generateMultiReport(selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.t('history_title'), style: GoogleFonts.poppins()),
        actions: [
          IconButton(
            icon: Icon(
              _selectedIndices.isEmpty
                  ? Icons.delete_forever_outlined
                  : Icons.delete,
              color: _selectedIndices.isEmpty ? Colors.grey : Colors.red,
            ),
            onPressed: _handleDelete,
            tooltip: _selectedIndices.isNotEmpty
                ? 'Seçilenleri Sil'
                : 'Geçmişi Temizle',
          ),
        ],
      ),
      floatingActionButton: _selectedIndices.isNotEmpty
          ? FloatingActionButton.extended(
        onPressed: _exportSelected,
        backgroundColor: const Color(0xFF0052FF),
        icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
        label: Text(
          '${AppLocale.t('export_selected')} (${_selectedIndices.length})',
          style: const TextStyle(color: Colors.white),
        ),
      )
          : null,
      body: _history.isEmpty
          ? Center(
          child: Text(AppLocale.t('no_data'),
              style: GoogleFonts.poppins(color: Colors.grey)))
          : ListView.builder(
        padding: const EdgeInsets.only(
            left: 16, right: 16, top: 16, bottom: 80),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          final item = _history[index];
          final dateStr = item['time'] != null
              ? item['time']
              .toString()
              .substring(0, 16)
              .replaceAll('T', ' ')
              : '---';
          final inputs = item['inputs'] ?? '---';
          final isSelected = _selectedIndices.contains(index);

          return GestureDetector(
            onTap: () => _toggleSelection(index),
            child: Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: isSelected
                  ? const Color(0xFF0052FF).withValues(alpha: 0.08)
                  : null,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected
                      ? const Color(0xFF0052FF)
                      : Colors.grey.withValues(alpha: 0.2),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(item['type'] ?? 'Hesap',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0052FF))),
                        ),
                        Row(
                          children: [
                            Text(dateStr,
                                style: const TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            const SizedBox(width: 8),
                            Transform.scale(
                              scale: 1.2,
                              child: Checkbox(
                                value: isSelected,
                                activeColor: const Color(0xFF0052FF),
                                shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(4)),
                                onChanged: (v) => _toggleSelection(index),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Text('${AppLocale.t('inputs')}:',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    Text(inputs,
                        style:
                        const TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    Text('${AppLocale.t('results')}:',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey[600])),
                    Text(item['res'] ?? '---',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
