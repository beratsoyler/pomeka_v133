import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/catalog_home_screen.dart';
import 'state/app_state.dart';

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
  final AppState _appState = AppState();

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: _appState,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'POMEKA',
        themeMode: _themeMode,
        theme: _buildTheme(Brightness.light),
        darkTheme: _buildTheme(Brightness.dark),
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
              : CatalogHomeScreen(
                  key: const ValueKey('CatalogHome'),
                  isDarkMode: _themeMode == ThemeMode.dark,
                  onThemeChanged: _toggleTheme,
                ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _appState.dispose();
    super.dispose();
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
