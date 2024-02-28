import 'package:flutter/material.dart';
import 'package:i18n_editor/home_page.dart';

class I18nApp extends StatelessWidget {
  const I18nApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'I18n Editor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}
