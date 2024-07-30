import 'package:flutter/material.dart';

class ExtendedFab extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget label;
  final Object? heroTag;

  const ExtendedFab({
    super.key,
    required this.onPressed,
    required this.label,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
        onPressed: onPressed,
        label: label,
        heroTag: heroTag,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)));
  }
}
