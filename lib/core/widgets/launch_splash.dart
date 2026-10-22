import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Continúa la splash nativa (LaunchScreen.storyboard: mismo fondo e icono de 120 pt centrado)
/// y la anima al abrir la app: el icono se encoge un poco, crece y se desvanece mostrando la app.
class LaunchSplash extends StatefulWidget {
  const LaunchSplash({super.key, required this.child});

  static const icon = AssetImage('assets/images/app_icon.png');

  final Widget child;

  @override
  State<LaunchSplash> createState() => _LaunchSplashState();
}

class _LaunchSplashState extends State<LaunchSplash>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(vsync: this)
    ..addStatusListener((status) {
      if (status == AnimationStatus.completed) setState(() => _done = true);
    });
  var _done = false;

  late final _scale = TweenSequence([
    TweenSequenceItem(
      tween: Tween(
        begin: 1.0,
        end: 0.88,
      ).chain(CurveTween(curve: Curves.easeInOut)),
      weight: 35,
    ),
    TweenSequenceItem(
      tween: Tween(
        begin: 0.88,
        end: 1.8,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
      weight: 65,
    ),
  ]).animate(_controller);
  late final _iconOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.55, 1, curve: Curves.easeIn),
  );
  late final _backgroundOpacity = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 1, curve: Curves.easeOut),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller.isAnimating || _done) return;
    // Con «Reducir movimiento» solo se desvanece.
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = Duration(milliseconds: reduceMotion ? 250 : 1000);
    if (reduceMotion) _controller.value = 0.6;
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    final background = context.colors.background;
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) => ColoredBox(
              color: background.withValues(alpha: 1 - _backgroundOpacity.value),
              child: Center(
                child: Opacity(
                  opacity: 1 - _iconOpacity.value,
                  child: Transform.scale(
                    scale: _scale.value,
                    child: const Image(
                      image: LaunchSplash.icon,
                      width: 120,
                      height: 120,
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
