import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class ThemeSettingsWidget extends StatelessWidget {
  const ThemeSettingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return SwitchListTile(
      secondary: const Icon(Icons.dark_mode),
      title: const Text("Dark Mode"),
      value: themeProvider.themeMode == ThemeMode.dark,
      onChanged: (value) {
        themeProvider.toggleTheme();
      },
    );
  }
}
