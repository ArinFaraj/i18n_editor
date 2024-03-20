import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/toast/toast_provider.dart';

void handleToasts(
  List<ToastContent> toasts,
  BuildContext context,
  WidgetRef ref,
) {
  showSequencialToasts(
    toasts: toasts
        .map(
          (e) => Toast(
            animationBuilder: (context, controller, child) => SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(controller),
              child: FadeTransition(
                opacity: controller,
                child: child,
              ),
            ),
            alignment: Alignment.topRight,
            duration: const Duration(seconds: 4),
            child: Padding(
              padding: const EdgeInsets.only(
                top: 60,
                right: 30,
              ),
              child: Card(
                color: switch (e.$2) {
                  ToastType.info => null,
                  ToastType.success => Colors.green,
                  ToastType.warning => Colors.orange,
                  ToastType.error => Colors.red,
                }
                    ?.withOpacity(0.3),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        switch (e.$2) {
                          ToastType.info => Icons.info,
                          ToastType.success => Icons.check,
                          ToastType.warning => Icons.warning,
                          ToastType.error => Icons.error,
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        e.$1,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .toList(),
    context: context,
  );
  ref.read(toastProvider.notifier).remove(toasts);
}
