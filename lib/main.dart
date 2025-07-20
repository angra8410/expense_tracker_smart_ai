import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/home_screen.dart';
import 'screens/add_transaction_screen.dart';
import 'screens/analytics_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/intelligence_screen.dart';
import 'screens/testing_screen.dart';
import 'services/app_initialization_service.dart';
import 'services/settings_service.dart';
import 'services/transactions_service.dart';
import 'services/web_storage_service.dart';
import 'services/recurring_transactions_service.dart';
import 'l10n/app_localizations.dart'; // Generated localization

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await AppInitializationService.initialize();
    await WebStorageService.initialize(); // <-- Initialize your storage here
    
    // Ensure TransactionsService is also initialized by loading transactions
    await TransactionsService.getTransactions();
    
    // Initialize recurring transactions service
    await RecurringTransactionsService.initialize();
    
    print('✅ All services initialized successfully');
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
        PopupMenuButton<String>(
          onSelected: (language) {
            final locale = Locale(language);
            widget.onLanguageChanged(locale);
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'en',
              child: Row(
                children: [
                  Text('🇺🇸'),
                  SizedBox(width: 8),
                  Text('English'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'es',
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
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Localizations.localeOf(context).languageCode == 'es' ? '🇪🇸' : '🇺🇸',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.language, size: 16),
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
                Text(
                  widget.currency,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.attach_money, size: 16),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        
        // Theme Toggle
        IconButton(
          onPressed: () {
            final currentTheme = Theme.of(context).brightness == Brightness.dark 
                ? ThemeMode.light 
                : ThemeMode.dark;
            widget.onThemeChanged(currentTheme);
          },
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark 
                ? Icons.light_mode 
                : Icons.dark_mode,
            color: Colors.white,
          ),
          tooltip: Theme.of(context).brightness == Brightness.dark 
              ? 'Switch to Light Mode' 
              : 'Switch to Dark Mode',
        ),
      ],
    );
  }

  String _getScreenTitle() {
    final isSpanish = Localizations.localeOf(context).languageCode == 'es';
    switch (_selectedIndex) {
      case 0:
        return isSpanish ? '💰 Rastreador Inteligente de Gastos' : '💰 Smart Expense Tracker';
      case 1:
        return isSpanish ? 'Nueva Transacción' : 'New Transaction';
      case 2:
        return '📊 Analytics';
      case 3:
        return isSpanish ? '💰 Presupuestos' : '💰 Budgets';
      case 4:
        return '🧠 AI Insights';
      case 5:
        return '🧪 Test Lab';
      default:
        return '💰 Smart Expense Tracker';
    }
  }

  Color _getScreenColor() {
    switch (_selectedIndex) {
      case 0:
        return Colors.purple[700]!;
      case 1:
        return Colors.blue[700]!;
      case 2:
        return Colors.orange[700]!;
      case 3:
        return Colors.green[700]!;
      case 4:
        return Colors.indigo[700]!;
      case 5:
        return Colors.purple[700]!;
      default:
        return Colors.purple[700]!;
    }
  }

  List<Widget> get _screens => [
    HomeScreen(
      onNavigateToTab: _navigateToTab,
      currency: widget.currency,
    ),
    AddTransactionScreen(currency: widget.currency),
    AnalyticsScreen(currency: widget.currency),
    BudgetScreen(currency: widget.currency),
    IntelligenceScreen(), // Remove 'const' here
    const TestingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // Generated localization
    
    // Set context for alerts in storage services
    WebStorageService.setContext(context);
    TransactionsService.setContext(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        backgroundColor: _getScreenColor(),
        foregroundColor: Colors.white,
        actions: [_buildAppBarActions()],
      ),
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
          
          // Refresh budget screen when navigating to it
          if (index == 3) { // Budget screen index
            // Trigger refresh after a short delay to ensure the screen is visible
            Future.delayed(const Duration(milliseconds: 100), () {
              final budgetScreen = _screens[3] as BudgetScreen;
              // We need to access the state to call refresh method
              // This requires exposing a refresh method in BudgetScreen
            });
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
            icon: const Icon(Icons.account_balance_wallet),
            label: l10n.budgets,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.psychology),
            label: l10n.aiInsights,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.science),
            label: l10n.testing,
          ),
        ],
      ),
    );
  }
}