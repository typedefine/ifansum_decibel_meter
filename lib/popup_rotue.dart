import 'package:flutter/material.dart';

class PopupPageRoute extends PageRoute {
  PopupPageRoute({
    required this.name,
    required this.title,
    required this.builder,
  }) : super(
    settings: RouteSettings(name: name),
  );

  final String title;
  final String name;
  final WidgetBuilder builder;

  @override
  String? get barrierLabel => null;

  @override
  bool get opaque => false;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => Duration(milliseconds: 0);

  @override
  Widget buildPage(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      ) {
    return Title(
      title: title,
      color: Theme.of(context).primaryColor,
      child: builder(context),
    );
  }

  /// 页面切换动画
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

  @override
  Color? get barrierColor => null;

  static void push(BuildContext context, Widget widget) {
    Navigator.of(context).push(PopupPageRoute(
      name: widget.toString(),
      title: widget.toString() + "zxf",
      builder: (_) {
        return Scaffold(backgroundColor: Colors.transparent, body: widget);
      },
    ));
  }
}