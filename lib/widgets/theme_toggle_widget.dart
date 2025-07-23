import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart';

class ThemeToggleButton extends StatelessWidget {
  final bool showLabel;
  final IconData? lightIcon;
  final IconData? darkIcon;
  
  const ThemeToggleButton({
    super.key,
    this.showLabel = false,
    this.lightIcon,
    this.darkIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        
        if (showLabel) {
          return TextButton.icon(
            onPressed: () => themeService.toggleTheme(),
            icon: Icon(
              isDark 
                ? (lightIcon ?? Icons.light_mode) 
                : (darkIcon ?? Icons.dark_mode),
            ),
            label: Text(isDark ? 'Light Mode' : 'Dark Mode'),
          );
        }
        
        return IconButton(
          onPressed: () => themeService.toggleTheme(),
          icon: Icon(
            isDark 
              ? (lightIcon ?? Icons.light_mode) 
              : (darkIcon ?? Icons.dark_mode),
          ),
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
        );
      },
    );
  }
}

class ThemeToggleSwitch extends StatelessWidget {
  final String? label;
  
  const ThemeToggleSwitch({
    super.key,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (label != null) ...[
              Text(label!),
              const SizedBox(width: 8),
            ],
            Icon(
              Icons.light_mode,
              size: 20,
              color: !isDark ? Theme.of(context).primaryColor : Colors.grey,
            ),
            Switch(
              value: isDark,
              onChanged: (_) => themeService.toggleTheme(),
            ),
            Icon(
              Icons.dark_mode,
              size: 20,
              color: isDark ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ],
        );
      },
    );
  }
}

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
                ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.settings),
                ),
              ],
              selected: {themeService.themeMode},
              onSelectionChanged: (Set<ThemeMode> selection) {
                themeService.setThemeMode(selection.first);
              },
            ),
          ],
        );
      },
    );
  }
}