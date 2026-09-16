import 'package:flutter/material.dart';

/// Shared numeric keypad: 0-9, backspace (지우기), clear (초기화).
class Numpad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final VoidCallback onClear;

  const Numpad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '지우기', '0', '초기화'];
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.6,
        children: keys.map((k) {
          return _NumpadButton(
            label: k,
            onTap: () {
              if (k == '지우기') {
                onBackspace();
              } else if (k == '초기화') {
                onClear();
              } else {
                onDigit(k);
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class _NumpadButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _NumpadButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isAction = label == '지우기' || label == '초기화';
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isAction ? 16 : 26,
              color: scheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
