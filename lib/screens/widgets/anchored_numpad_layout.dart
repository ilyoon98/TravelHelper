import 'package:flutter/material.dart';

/// Pins the numpad to the bottom of the screen and lets everything above it
/// (mode/direction toggle, results, big number display) scroll independently,
/// anchored to the top. Without this, centering the whole screen made the
/// numpad's position shift every time the content above it grew or shrank
/// (e.g. digit cards wrapping to a second line) — this keeps "where I tap
/// numbers" a fixed, stable target.
class AnchoredNumpadLayout extends StatelessWidget {
  final Widget top;
  final Widget numpad;

  const AnchoredNumpadLayout({super.key, required this.top, required this.numpad});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            // Force full width: under a loose cross-axis constraint (the
            // default, non-stretch Column above this doesn't tighten it),
            // short content like the empty-state hint or the mode toggle
            // would otherwise shrink-wrap and drift left instead of
            // centering in the full-width space.
            child: SizedBox(width: double.infinity, child: top),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: numpad,
        ),
      ],
    );
  }
}
