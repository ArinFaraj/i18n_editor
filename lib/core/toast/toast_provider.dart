import 'package:riverpod/riverpod.dart';

enum ToastType { info, success, warning, error }

typedef ToastContent = (String, ToastType);

class ToastNotifier extends Notifier<List<ToastContent>> {
  @override
  List<ToastContent> build() => [];

  void show(String message, {required ToastType type}) {
    state = [
      ...state,
      (message, type),
    ];
  }

  void remove(List<ToastContent> toasts) {
    state = [
      for (final toast in state)
        if (!toasts.contains(toast)) toast,
    ];
  }
}

final toastProvider = NotifierProvider<ToastNotifier, List<ToastContent>>(
  ToastNotifier.new,
  name: 'toast',
);
