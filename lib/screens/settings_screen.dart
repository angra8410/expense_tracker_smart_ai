import 'package:flutter/material.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function(Locale) onLanguageChanged;
  final Function(String) onCurrencyChanged;
  final Function(ThemeMode) onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _currentLanguage = 'es';
  String _currentCurrency = 'COP';
  String _currentTheme = 'light';

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
      _currentLanguage = language;
      _currentCurrency = currency;
      _currentTheme = theme;
    });
  }

  String _getLocalizedText(String key) {
    final isSpanish = _currentLanguage == 'es';
    switch (key) {
      case 'settings': return isSpanish ? 'Ajustes' : 'Settings';
      case 'language': return isSpanish ? 'Idioma' : 'Language';
      case 'currency': return isSpanish ? 'Moneda' : 'Currency';
      case 'theme': return isSpanish ? 'Tema' : 'Theme';
      case 'spanish': return isSpanish ? 'Español' : 'Spanish';
      case 'english': return isSpanish ? 'Inglés' : 'English';
      case 'colombianPeso': return isSpanish ? 'Peso Colombiano' : 'Colombian Peso';
      case 'usDollar': return isSpanish ? 'Dólar Estadounidense' : 'US Dollar';
      case 'light': return isSpanish ? 'Claro' : 'Light';
      case 'dark': return isSpanish ? 'Oscuro' : 'Dark';
      case 'chooseLanguage': return isSpanish ? 'Elige tu idioma' : 'Choose your language';
      case 'chooseCurrency': return isSpanish ? 'Elige tu moneda' : 'Choose your currency';
      case 'chooseTheme': return isSpanish ? 'Elige tu tema' : 'Choose your theme';
      case 'localization': return isSpanish ? 'Localización' : 'Localization';
      case 'appearance': return isSpanish ? 'Apariencia' : 'Appearance';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _currentTheme == 'dark';

    return Scaffold(
      appBar: AppBar(
        title: Text('⚙️ ${_getLocalizedText('settings')}'),
        backgroundColor: isDark ? Colors.grey[900]! : Colors.blue[700]!,
        foregroundColor: Colors.white,
      ),
      backgroundColor: isDark ? Colors.grey[850] : Colors.grey[50],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark 
                      ? [Colors.grey[800]!, Colors.grey[700]!]
                      : [Colors.blue[600]!, Colors.blue[400]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : Colors.blue).withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.settings, color: Colors.white, size: 28),
                      SizedBox(width: 12),
                      Text(
                        'Configuración / Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usuario: angra8410 🇨🇴 | Colombia',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Personaliza tu experiencia financiera',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Localization Section
            _buildSection(
              title: '🌐 ${_getLocalizedText('localization')}',
              children: [
                _buildLanguageSetting(),
                const SizedBox(height: 16),
                _buildCurrencySetting(),
              ],
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Appearance Section
            _buildSection(
              title: '🎨 ${_getLocalizedText('appearance')}',
              children: [
                _buildThemeSetting(),
              ],
              isDark: isDark,
            ),

            const SizedBox(height: 24),

            // Current Settings Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.grey[600]! : Colors.green[200]!,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: isDark ? Colors.green[300] : Colors.green[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Configuración Actual / Current Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green[300] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCurrentSetting('${_getLocalizedText('language')} / Language', 
                      _currentLanguage == 'es' ? '🇪🇸 Español' : '🇺🇸 English', isDark),
                  _buildCurrentSetting('${_getLocalizedText('currency')} / Currency', 
                      _currentCurrency == 'COP' ? '🇨🇴 Peso Colombiano' : '🇺🇸 US Dollar', isDark),
                  _buildCurrentSetting('${_getLocalizedText('theme')} / Theme', 
                      _currentTheme == 'dark' ? '🌙 ${_getLocalizedText('dark')}' : '☀️ ${_getLocalizedText('light')}', isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    required bool isDark,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[800] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : Colors.grey).withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLanguageSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedText('chooseLanguage'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _currentTheme == 'dark' ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildToggleOption(
                icon: '🇪🇸',
                title: 'Español',
                subtitle: 'Spanish',
                isSelected: _currentLanguage == 'es',
                onTap: () => _changeLanguage('es'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleOption(
                icon: '🇺🇸',
                title: 'English',
                subtitle: 'Inglés',
                isSelected: _currentLanguage == 'en',
                onTap: () => _changeLanguage('en'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCurrencySetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedText('chooseCurrency'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _currentTheme == 'dark' ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildToggleOption(
                icon: '🇨🇴',
                title: 'Peso COP',
                subtitle: '\$ 1.000 COP',
                isSelected: _currentCurrency == 'COP',
                onTap: () => _changeCurrency('COP'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleOption(
                icon: '🇺🇸',
                title: 'Dollar USD',
                subtitle: '\$ 1.00 USD',
                isSelected: _currentCurrency == 'USD',
                onTap: () => _changeCurrency('USD'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildThemeSetting() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLocalizedText('chooseTheme'),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _currentTheme == 'dark' ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildToggleOption(
                icon: '☀️',
                title: 'Claro / Light',
                subtitle: 'Tema claro',
                isSelected: _currentTheme == 'light',
                onTap: () => _changeTheme('light'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildToggleOption(
                icon: '🌙',
                title: 'Oscuro / Dark',
                subtitle: 'Tema oscuro',
                isSelected: _currentTheme == 'dark',
                onTap: () => _changeTheme('dark'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final isDark = _currentTheme == 'dark';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? Colors.blue[800] : Colors.blue[100])
              : (isDark ? Colors.grey[700] : Colors.grey[100]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? (isDark ? Colors.blue[600]! : Colors.blue[300]!)
                : (isDark ? Colors.grey[600]! : Colors.grey[300]!),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isSelected 
                    ? (isDark ? Colors.blue[200]! : Colors.blue[700]!)
                    : (isDark ? Colors.grey[300] : Colors.grey[700]),
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: isSelected 
                    ? (isDark ? Colors.blue[300]! : Colors.blue[600]!)
                    : (isDark ? Colors.grey[400] : Colors.grey[600]),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentSetting(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.green[300] : Colors.green[700],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changeLanguage(String languageCode) async {
    await SettingsService.setLanguage(languageCode);
    setState(() {
      _currentLanguage = languageCode;
    });
    widget.onLanguageChanged(Locale(languageCode));

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          languageCode == 'es' 
              ? '🇪🇸 Idioma cambiado a Español'
              : '🇺🇸 Language changed to English',
        ),
        backgroundColor: Colors.green[600],
      ),
    );
  }

  Future<void> _changeCurrency(String currencyCode) async {
    await SettingsService.setCurrency(currencyCode);
    setState(() {
      _currentCurrency = currencyCode;
    });
    widget.onCurrencyChanged(currencyCode);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          currencyCode == 'COP' 
              ? '🇨🇴 Moneda cambiada a Peso Colombiano'
              : '🇺🇸 Currency changed to US Dollar',
        ),
        backgroundColor: Colors.blue[600]!,
      ),
    );
  }

  Future<void> _changeTheme(String theme) async {
    await SettingsService.setTheme(theme);
    setState(() {
      _currentTheme = theme;
    });
    widget.onThemeChanged(theme == 'dark' ? ThemeMode.dark : ThemeMode.light);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          theme == 'dark' 
              ? '🌙 Tema cambiado a Oscuro'
              : '☀️ Tema cambiado a Claro',
        ),
        backgroundColor: Colors.purple[600],
      ),
    );
  }
}