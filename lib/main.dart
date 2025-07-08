import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/intelligence_screen.dart';
import 'screens/testing_screen.dart';
import 'screens/settings_screen.dart';
import 'services/app_initialization_service.dart';
import 'services/settings_service.dart';
import 'services/web_storage_service.dart'; // <-- Add this import
import 'l10n/app_localizations.dart'; // Generated localization

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppInitializationService.initialize();
    await WebStorageService.initialize(); // <-- Initialize your storage here
  } catch (e) {
    print('Initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale _locale = const Locale('es'); // Default to Spanish for Colombia
  String _currency = 'COP'; // Default to Colombian Peso
  ThemeMode _themeMode = ThemeMode.light;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final language = await SettingsService.getLanguage();
    final currency = await SettingsService.getCurrency();
    final theme = await SettingsService.getTheme();

    setState(() {
      _locale = Locale(language);
      _currency = currency;
      _themeMode = theme == 'dark' ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart AI Expense Tracker',
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate, // Generated delegate
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales, // Generated supported locales
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainScreen(
        currency: _currency,
        onLanguageChanged: (locale) {
          setState(() {
            _locale = locale;
          });
        },
        onCurrencyChanged: (currency) {
          setState(() {
            _currency = currency;
          });
        },
        onThemeChanged: (themeMode) {
          setState(() {
            _themeMode = themeMode;
          });
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainScreen extends StatefulWidget {
  final String currency;
  final Function(Locale) onLanguageChanged;
  final Function(String) onCurrencyChanged;
  final Function(ThemeMode) onThemeChanged;

  const MainScreen({
    super.key,
    required this.currency,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
    required this.onThemeChanged,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final GlobalKey<HomeScreenState> _homeScreenKey = GlobalKey<HomeScreenState>();

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
    
    // Refresh home screen when switching to it
    if (index == 0) {
      _homeScreenKey.currentState?.loadDashboardData();
    }
  }

  List<Widget> get _screens => [
    HomeScreen(
      key: _homeScreenKey,
      onNavigateToTab: _navigateToTab,
      currency: widget.currency,
    ),
    AddTransactionScreen(currency: widget.currency),
    const AnalyticsScreen(),
    const IntelligenceScreen(),
    const TestingScreen(),
    SettingsScreen(
      onLanguageChanged: widget.onLanguageChanged,
      onCurrencyChanged: widget.onCurrencyChanged,
      onThemeChanged: widget.onThemeChanged,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Generated localization
    
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          
          // Refresh home screen when switching to it
          if (index == 0) {
            _homeScreenKey.currentState?.loadDashboardData();
          }
        },
        selectedItemColor: Colors.purple[700],
        unselectedItemColor: Colors.grey[600],
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.add_circle),
            label: l10n.add,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.analytics),
            label: l10n.analytics,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.psychology),
            label: l10n.aiInsights,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.science),
            label: l10n.testing,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: l10n.settings,
          ),
        ],
      ),
    );
  }
}