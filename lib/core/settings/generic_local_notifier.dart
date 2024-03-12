import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:i18n_editor/core/local_storage/sembast_local_storage.dart';

class GenericLocalNotifier<T, K> extends AsyncNotifier<T> {
  final String _key;
  final T _fallback;
  final T Function(K) _converter;
  final K Function(T) _deconverter;

  GenericLocalNotifier(
      this._key, this._fallback, this._converter, this._deconverter);

  @override
  Future<T> build() async {
    final localStorageRepo = await ref.watch(localStorageRepoProvider.future);
    final value = await localStorageRepo.get<K>(_key);
    if (value == null) {
      return _fallback;
    }
    return _converter(value);
  }

  Future<void> set(T value) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final localStorageRepo = ref.watch(localStorageRepoProvider).requireValue;
      await localStorageRepo.set(_key, _deconverter(value));
      return value;
    });
  }
}
