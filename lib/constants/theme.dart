import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/constants/colors.dart';

final lightTheme = Provider(
  (ref) {
    // uncomment the following lines to use different fonts for different locales
    // final locale = ref.watch(appLocaleProvider).value!;
    // final fontFamily = locale != AppLocale.en ? FontFamily.notoKufi : null;
    // const fontFamily = FontFamily.notoKufi;

    return ThemeData(
      // fontFamily: fontFamily,
      colorScheme: const ColorScheme.light(
        primary: cPrimaryColor,
        surfaceContainerHighest: Colors.white,
        outline: Color(0xFFC6C6CC),
        // surface: cSurfaceWhite,
        surface: cSurfaceWhite,
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: Color(0xFF7A7A7A),
        ),
      ),
    );
  },
);

// final darkTheme = ThemeData.from(
//   colorScheme: ColorScheme.fromSeed(
//     seedColor: cPrimaryColor,
//     brightness: Brightness.dark,
//   ),
// );
