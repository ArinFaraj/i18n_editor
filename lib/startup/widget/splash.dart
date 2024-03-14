import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData.dark(),
      home: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          body: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'i18n Editor',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'Edit internationalization json files easily',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fade().slide(
                      begin: const Offset(0, 0.2),
                      curve: Curves.elasticOut,
                      duration: const Duration(milliseconds: 600),
                    ),
              ],
            )
                .animate()
                .fade(
                  duration: const Duration(milliseconds: 700),
                )
                .scale(
                  begin: const Offset(0.95, 0.95),
                  curve: Curves.elasticOut,
                  duration: const Duration(seconds: 4),
                ),
          ),
        ),
      ),
    );
  }
}
