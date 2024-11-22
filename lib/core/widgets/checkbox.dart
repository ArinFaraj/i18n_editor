import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class DCheckbox extends HookWidget {
  const DCheckbox({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final bool? value;
  final ValueChanged<bool?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextButton(
      onPressed: () {
        onChanged?.call(value == true ? false : true);
      },
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        padding: const EdgeInsets.all(10),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: value == true ? theme.primaryColor : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: value == false
              ? Border.all(color: theme.colorScheme.outline, width: 1.5)
              : null,
        ),
        width: 18,
        height: 18,
        child: IgnorePointer(
          child: Transform.scale(
            scale: 0.7,
            child: Checkbox(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: value,
              onChanged: (_) {},
              side: BorderSide.none,
              fillColor: const WidgetStatePropertyAll(Colors.transparent),
            ),
          ),
        ),
      ),
    );
  }
}
