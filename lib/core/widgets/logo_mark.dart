import 'dart:math';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Símbolo de TRAVIO (design/LOGO/LOGO.png): flechas de intercambio sobre un globo.
class LogoMark extends StatelessWidget {
  const LogoMark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return CustomPaint(
      size: Size.square(size),
      painter: _LogoPainter(
        light: colors.brand,
        ring: colors.accent,
        // En oscuro el acento y la marca coinciden; como en el App Icon, la flecha de vuelta va clara.
        strong: dark ? colors.text : colors.accent,
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  _LogoPainter({required this.light, required this.ring, required this.strong});

  final Color light;
  final Color ring;
  final Color strong;

  @override
  void paint(Canvas canvas, Size size) {
    // Dibujado sobre la cuadrícula de 512 del PNG.
    canvas.scale(size.width / 512);
    const c = Offset(256, 256);
    Paint stroke(Color color, double width) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dots = Paint()..color = light;
    for (var i = 0; i < 72; i++) {
      final a = i * 2 * pi / 72;
      canvas.drawCircle(c + Offset(cos(a), sin(a)) * 186, 3.5, dots);
    }

    final grid = stroke(strong.withValues(alpha: 0.3), 5);
    canvas.drawLine(const Offset(256, 96), const Offset(256, 416), grid);
    canvas.drawLine(const Offset(96, 256), const Offset(416, 256), grid);
    canvas.drawOval(Rect.fromCenter(center: c, width: 144, height: 320), grid);
    canvas.drawCircle(c, 160, stroke(ring, 9));

    final top = stroke(light, 46);
    canvas.drawLine(const Offset(130, 195), const Offset(365, 195), top);
    canvas.drawPath(
      Path()
        ..moveTo(302, 135)
        ..lineTo(365, 195)
        ..lineTo(302, 258),
      top,
    );

    final bottom = stroke(strong, 46);
    canvas.drawLine(const Offset(378, 315), const Offset(150, 315), bottom);
    canvas.drawPath(
      Path()
        ..moveTo(212, 255)
        ..lineTo(150, 315)
        ..lineTo(212, 376),
      bottom,
    );
  }

  @override
  bool shouldRepaint(_LogoPainter old) =>
      old.light != light || old.ring != ring || old.strong != strong;
}
