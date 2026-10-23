import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Icono propio de TRAVIO (assets/icons/{name}.svg, de design/SVG ICONS).
/// Sin tamaño ni color toma los del IconTheme, como Icon.
class AppIcon extends StatelessWidget {
  const AppIcon(this.name, {super.key, this.size, this.color});

  final String name;
  final double? size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final size = this.size ?? theme.size ?? 24;
    return SvgPicture.asset(
      'assets/icons/$name.svg',
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color ?? theme.color!, BlendMode.srcIn),
    );
  }
}
