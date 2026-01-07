import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SvgTabIcon extends StatelessWidget {
  const SvgTabIcon({
    super.key,
    required this.assetPath,
    required this.selected,
    this.size = 22,
  });

  final String assetPath;
  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final color = selected
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurface.withOpacity(0.55);

    return SizedBox(
      width: 48,
      height: 48,
      child: Center(
        child: SvgPicture.asset(
          assetPath,
          width: size,
          height: size,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
      ),
    );
  }
}
