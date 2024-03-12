import 'package:flutter/foundation.dart';
import 'package:i18n_editor/core/local_storage/local_storage_repository.dart';
import 'package:i18n_editor/core/logger/talker.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod/riverpod.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:sembast_web/sembast_web.dart';

class SembastLocalStorageRepository implements LocalStorageRepository {
  SembastLocalStorageRepository({Database? database})
      : _initialized = database != null,
        _db = database;

  Database? _db;
  bool _initialized;
  final _store = StoreRef.main();

  static Future<Database> _createDatabase(String filename) async {
    if (kIsWeb) {
      return databaseFactoryWeb.openDatabase(filename);
    } else {
      final appDocDir = await getApplicationDocumentsDirectory();
      return databaseFactoryIo.openDatabase(join(appDocDir.path, filename));
    }
  }

  Future<void> _initialize() async {
    _db = await _createDatabase('i18n_editor.db');
    _initialized = true;
  }

  Future<void> _checkInitialized() async {
    if (!_initialized) {
      await _initialize();
    }
  }

  @override
  Future<T?> get<T>(String id) async {
    final data = await _store.record(id).get(_db!) as T?;

    logger.debug('get: $id $data');
    return data;
  }

  @override
  Future<void> set<T>(String id, T data) async {
    logger.debug('set: $id $data');
    await _store.record(id).put(_db!, data);
  }

  @override
  Future<Stream<T?>> watch<T>(String id) async {
    final record = _store.record(id);

    return Future.value(
      record.onSnapshot(_db!).map((snapshot) {
        if (snapshot != null) {
          return snapshot.value as T;
        } else {
          return null;
        }
      }),
    );
  }

  @override
  Future<void> delete(String id) {
    return _store.record(id).delete(_db!);
  }

  @override
  void clear() {
    _store.delete(_db!);
  }
}

final localStorageRepoProvider = FutureProvider((ref) async {
  final sembastRepo = SembastLocalStorageRepository();
  await sembastRepo._checkInitialized();
  return sembastRepo;
});
