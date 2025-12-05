import 'package:flutter/material.dart';

/// Transition de page avec slide depuis le bas
class SlideUpPageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  SlideUpPageRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    var begin = const Offset(0.0, 1.0);
    var end = Offset.zero;
    var curve = Curves.easeOutCubic;

    var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    var tween = Tween(begin: begin, end: end);

    return SlideTransition(
      position: tween.animate(curvedAnimation),
      child: child,
    );
  }
}

/// Transition de page avec fade
class FadePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;
  final Duration duration;

  FadePageRoute({
    required this.builder,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }
}

/// Transition de page avec scale et fade
class ScalePageRoute<T> extends PageRoute<T> {
  final WidgetBuilder builder;

  ScalePageRoute({required this.builder});

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => const Duration(milliseconds: 350);

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    var curve = Curves.easeOutCubic;
    var curvedAnimation = CurvedAnimation(parent: animation, curve: curve);
    
    var scaleTween = Tween<double>(begin: 0.8, end: 1.0);
    var fadeTween = Tween<double>(begin: 0.0, end: 1.0);

    return FadeTransition(
      opacity: fadeTween.animate(curvedAnimation),
      child: ScaleTransition(
        scale: scaleTween.animate(curvedAnimation),
        child: child,
      ),
    );
  }
}
