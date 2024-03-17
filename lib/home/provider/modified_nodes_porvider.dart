import 'package:riverpod/riverpod.dart';

final modifiedNodesProvider =
    NotifierProvider<ModifiedNodesNotifier, Map<List<dynamic>, List<String>>>(
  ModifiedNodesNotifier.new,
  name: 'modifiedNodes',
);

class ModifiedNodesNotifier extends Notifier<Map<List<dynamic>, List<String>>> {
  @override
  Map<List<dynamic>, List<String>> build() {
    return {};
  }

  void add(
      {required List<dynamic> address, required List<String> changedFiles}) {
    final currentlyModifierFilesOfAddress = state[address] ?? [];

    state = {
      ...state,
      address: {...currentlyModifierFilesOfAddress, ...changedFiles}.toList()
    };
  }

  void remove({required List address, required List<String> changedFiles}) {
    final currentlyModifierFilesOfAddress = state[address] ?? [];
    state = {
      ...state,
      address: [...currentlyModifierFilesOfAddress]
        ..removeWhere((element) => changedFiles.contains(element))
    };
  }
}
