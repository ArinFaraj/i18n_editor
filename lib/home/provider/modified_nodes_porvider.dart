import 'package:riverpod/riverpod.dart';

final modifiedNodesProvider =
    NotifierProvider<ModifiedNodesNotifier, Map<int, List<String>>>(
  ModifiedNodesNotifier.new,
  name: 'modifiedNodes',
);

class ModifiedNodesNotifier extends Notifier<Map<int, List<String>>> {
  @override
  Map<int, List<String>> build() {
    return {};
  }

  void add({required int address, required List<String> changedFiles}) {
    final currentlyModifierFilesOfAddress = state[address] ?? [];

    state = {
      ...state,
      address: {...currentlyModifierFilesOfAddress, ...changedFiles}.toList()
    };
  }

  void remove({required int address, required List<String> changedFiles}) {
    final currentlyModifierFilesOfAddress = state[address] ?? [];
    state = {
      ...state,
      address: [...currentlyModifierFilesOfAddress]
        ..removeWhere((element) => changedFiles.contains(element))
    };
  }
}
