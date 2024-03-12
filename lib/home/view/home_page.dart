import 'package:flutter/material.dart';
import 'package:i18n_editor/menu_bar.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MyMenuBar(),
        ],
      ),
    );
  }
}
