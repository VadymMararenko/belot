import 'package:flutter/material.dart';

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 180);
  static const standard = Duration(milliseconds: 340);
  static const large = Duration(milliseconds: 700);
  static const celebration = Duration(milliseconds: 1050);
  static const boltFlight = Duration(milliseconds: 1050);
  static const boltPulse = Duration(milliseconds: 220);
  static const reducedMotionHold = Duration(milliseconds: 120);

  static const enter = Curves.easeOutCubic;
  static const exit = Curves.easeInCubic;
  static const emphasizedEnter = Curves.easeOutBack;

  static bool disabled(BuildContext context) =>
      MediaQuery.maybeOf(context)?.disableAnimations ?? false;

  static Duration duration(BuildContext context, Duration value) =>
      disabled(context) ? Duration.zero : value;

  static AnimationStyle animationStyle(
    BuildContext context,
    Duration value,
  ) =>
      disabled(context)
          ? AnimationStyle.noAnimation
          : AnimationStyle(
              duration: value,
              reverseDuration: value,
              curve: enter,
              reverseCurve: exit,
            );

  static ChipAnimationStyle chipStyle(BuildContext context) {
    final style = animationStyle(context, fast);
    return ChipAnimationStyle(
      enableAnimation: style,
      selectAnimation: style,
      avatarDrawerAnimation: style,
      deleteDrawerAnimation: style,
    );
  }
}

Route<T> appPageRoute<T>(BuildContext context, Widget child) {
  return PageRouteBuilder<T>(
    transitionDuration: AppMotion.duration(context, AppMotion.standard),
    reverseTransitionDuration: AppMotion.duration(context, AppMotion.standard),
    pageBuilder: (_, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.035, 0.045),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

Future<T?> showMotionDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppMotion.duration(context, AppMotion.standard),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final fade = CurvedAnimation(
        parent: animation,
        curve: AppMotion.enter,
        reverseCurve: AppMotion.exit,
      );
      final scale = CurvedAnimation(
        parent: animation,
        curve: AppMotion.emphasizedEnter,
        reverseCurve: AppMotion.exit,
      );
      return FadeTransition(
        opacity: fade,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(scale),
          child: child,
        ),
      );
    },
  );
}

class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled || pressed == value) return;
    setState(() => pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = pressed && !AppMotion.disabled(context) ? 0.975 : 1.0;
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: scale,
        duration: AppMotion.duration(context, AppMotion.fast),
        curve: pressed ? AppMotion.exit : AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}

class MotionReveal extends StatelessWidget {
  const MotionReveal({
    super.key,
    required this.animation,
    required this.child,
    this.offset = const Offset(0, 0.08),
  });

  final Animation<double> animation;
  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position:
            Tween<Offset>(begin: offset, end: Offset.zero).animate(animation),
        child: child,
      ),
    );
  }
}
