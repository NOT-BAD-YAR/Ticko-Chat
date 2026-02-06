import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store/theme_provider.dart';
import '../store/auth_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          // Split View for Settings
          return Scaffold(
            appBar: AppBar(title: const Text('Settings')),
            body: Row(
              children: [
                // Left: Options
                Expanded(
                  flex: 1,
                  child: _SettingsList(showPreviewParams: false),
                ),
                const VerticalDivider(width: 1),
                // Right: Preview
                Expanded(
                  flex: 1,
                  child: _ThemePreview(),
                ),
              ],
            ),
          );
        }
        
        // Mobile View
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const _SettingsList(showPreviewParams: true),
        );
      },
    );
  }
}

class _SettingsList extends StatelessWidget {
  final bool showPreviewParams;

  const _SettingsList({required this.showPreviewParams});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.themeMode == ThemeMode.dark;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionHeader(context, 'Appearance'),
        SwitchListTile(
          title: const Text('Dark Mode'),
          subtitle: const Text('Enable dark theme'),
          value: isDark,
          onChanged: (value) {
            themeProvider.toggleTheme(value);
          },
          secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
        ),
        const SizedBox(height: 16),
        const Text('Theme Color'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _ColorOption(color: Colors.deepPurple, selected: themeProvider.seedColor == Colors.deepPurple),
            _ColorOption(color: Colors.blue, selected: themeProvider.seedColor == Colors.blue),
            _ColorOption(color: Colors.teal, selected: themeProvider.seedColor == Colors.teal),
            _ColorOption(color: Colors.orange, selected: themeProvider.seedColor == Colors.orange),
            _ColorOption(color: Colors.pink, selected: themeProvider.seedColor == Colors.pink),
          ],
        ),
        if (showPreviewParams) ...[
             const SizedBox(height: 20),
             const Divider(),
             const Padding(
               padding: EdgeInsets.symmetric(vertical: 8),
               child: Text('Preview', style: TextStyle(fontWeight: FontWeight.bold)),
             ),
             SizedBox(
               height: 300,
               child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _ThemePreview(),
               ),
             ),
        ],
        const Divider(height: 32),
         _buildSectionHeader(context, 'Account'),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
            ),
            onTap: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final bool selected;

  const _ColorOption({required this.color, required this.selected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Provider.of<ThemeProvider>(context, listen: false).setSeedColor(color);
      },
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected 
            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3) 
            : null,
          boxShadow: [
             BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: selected 
          ? const Icon(Icons.check, color: Colors.white, size: 20) 
          : null,
      ),
    );
  }
}

class _ThemePreview extends StatelessWidget {
  const _ThemePreview();

  @override
  Widget build(BuildContext context) {
    // A mock chat UI for preview
    final theme = Theme.of(context);
    return Container(
      color: theme.scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
            // Mock App Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white),
                  const SizedBox(width: 8),
                  const CircleAvatar(radius: 12, child: Text('A')),
                  const SizedBox(width: 8),
                  const Text('Alice', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Mock Messages
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Hey! Check out this new theme.', style: TextStyle(color: Colors.black)),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text('Wow! It looks amazing in Dark Mode too!', style: TextStyle(color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }
}
