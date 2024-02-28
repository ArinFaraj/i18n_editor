import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'menu_bar.dart';

final openedDirectory = ValueNotifier<Directory?>(null);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();

    openedDirectory.addListener(() {});
  }

  @override
  dispose() {
    sub.cancel();
    super.dispose();
  }

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
