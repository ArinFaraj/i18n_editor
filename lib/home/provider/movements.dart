import 'dart:math';

/// Generates a new id that is not used by any node.
int getNewId([List<int>? existing]) {
  final random = Random();
  var id = random.nextInt(9999999);

  while (existing?.contains(id) ?? false) {
    id = random.nextInt(999999999999);
  }

  return id;
}
