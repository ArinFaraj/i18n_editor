abstract class LocalStorageRepository {
  Future<T?> get<T>(String id);

  Future<Stream<T?>> watch<T>(String id);

  Future<void> set<T>(String id, T data);

  Future<void> delete(String id);

  void clear();
}
