import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/startup/provider/app_startup.dart';
import 'package:i18n_editor/startup/widget/app_startup_error_widget.dart';
import 'package:i18n_editor/startup/widget/splash.dart';

/// Widget class to manage asynchronous app initialization
class AppStartupWidget extends ConsumerWidget {
  const AppStartupWidget({required this.onLoaded, super.key});
  final WidgetBuilder onLoaded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appStartupState = ref.watch(appStartupProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 700),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.elasticOut,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: Tween<double>(begin: 1.05, end: 1).animate(animation),
        child: FadeTransition(
          opacity: animation,
          child: child,
        ),
      ),
      child: appStartupState.when(
        data: (_) => onLoaded(context),
        loading: () => const Splash(),
        error: (e, st) => AppStartupErrorWidget(
          message: e.toString(),
          stackTrace: st,
          onRetry: () => ref.invalidate(appStartupProvider),
        ),
      ),
    );
  }
}
