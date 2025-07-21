import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/intelligence_screen.dart';
import 'screens/testing_screen.dart';
import 'services/web_storage_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await WebStorageService.init();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Locale _locale = const Locale('en');
  String _currency = 'USD';

  void _changeTheme(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void _changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _changeCurrency(String currency) {
    setState(() {
      _currency = currency;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Expense Tracker',
      themeMode: _themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      locale: _locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      home: MainScreen(
        onThemeChanged: _changeTheme,
        onLocaleChanged: _changeLocale,
        onCurrencyChanged: _changeCurrency,
        currency: _currency,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final Function(Locale) onLocaleChanged;
  final Function(String) onCurrencyChanged;
  final String currency;

  const MainScreen({
    super.key,
    required this.onThemeChanged,
    required this.onLocaleChanged,
    required this.onCurrencyChanged,
    required this.currency,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _navigateToTab(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _buildAppBarActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Language Toggle
        PopupMenuButton<Locale>(
          onSelected: (locale) {
            widget.onLocaleChanged(locale);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: Locale('en'),
              child: Row(
                children: [
                  Text('🇺🇸'),
                  SizedBox(width: 8),
                  Text('English'),
                ],
              ),
            ),
            PopupMenuItem(
              value: Locale('es'),
              child: Row(
                children: [
                  Text('🇪🇸'),
                  SizedBox(width: 8),
                  Text('Español'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.language, size: 16),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Currency Toggle
        PopupMenuButton<String>(
          onSelected: (currency) {
            widget.onCurrencyChanged(currency);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'COP',
              child: Row(
                children: [
                  Text('🇨🇴'),
                  SizedBox(width: 8),
                  Text('COP'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'USD',
              child: Row(
                children: [
                  Text('🇺🇸'),
                  SizedBox(width: 8),
                  Text('USD'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'EUR',
              child: Row(
                children: [
                  Text('🇪🇺'),
                  SizedBox(width: 8),
                  Text('EUR'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(widget.currency, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Theme Toggle
        PopupMenuButton<ThemeMode>(
          onSelected: (themeMode) {
            widget.onThemeChanged(themeMode);
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: ThemeMode.light,
              child: Row(
                children: [
                  Icon(Icons.light_mode),
                  SizedBox(width: 8),
                  Text('Light'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.dark,
              child: Row(
                children: [
                  Icon(Icons.dark_mode),
                  SizedBox(width: 8),
                  Text('Dark'),
                ],
              ),
            ),
            PopupMenuItem(
              value: ThemeMode.system,
              child: Row(
                children: [
                  Icon(Icons.auto_mode),
                  SizedBox(width: 8),
                  Text('System'),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.palette, size: 16),
                SizedBox(width: 4),
                Icon(Icons.arrow_drop_down, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> get _screens {
    return [
      HomeScreen(currency: widget.currency, onNavigateToTab: _navigateToTab),
      AddTransactionScreen(currency: widget.currency),
      const AnalyticsScreen(),
      BudgetScreen(currency: widget.currency),
      const IntelligenceScreen(),
      const TestingScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: _navigateToTab,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.psychology),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bug_report),
            label: 'Debug',
          ),
        ],
      ),
    );
  }
}