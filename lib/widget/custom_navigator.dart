import 'dart:async';

import 'package:flutter/material.dart';

class _Holder {
  _Holder();
  final Map<Key, dynamic> _map = {};
  static final _Holder instance = _Holder();
  dynamic get(Key key) => _map[key];
  void set(Key key, dynamic value) {
    _map[key] = value;
  }
}

class CustomNavigator<T> extends StatefulWidget {
  const CustomNavigator({required super.key, required this.home});
  final Widget home;

  @override
  State<CustomNavigator> createState() => _CustomNavigatorState<T>();

  static CustomNavigatorCallbacks<T> of<T>(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<
                _CustomNavigationController<T>>()
            ?.navigationCallbacks ??
        CustomNavigatorCallbacks.empty<T>();
  }

  static Future<T> push<T>(
      BuildContext context, CustomNavigationPageRoute route) {
    return CustomNavigator.of<T>(context).push(route);
  }

  static void pop<T>(BuildContext context, T? data) {
    return CustomNavigator.of<T>(context).pop(data);
  }
}

class _CustomNavigatorState<T> extends State<CustomNavigator> {
  late List<_PageHolder<T>> _widgets;
  late CustomNavigatorCallbacks<T> _navigationCallbacks;
  bool _animate = true;

  @override
  void initState() {
    super.initState();
    _widgets = _Holder.instance.get(widget.key!) as List<_PageHolder<T>>? ?? [];
    _animate = _widgets.isEmpty;
    _navigationCallbacks = CustomNavigatorCallbacks<T>(
      push: (CustomNavigationPageRoute widget) async {
        setState(() {
          _widgets.add(_PageHolder<T>(widget, Completer<T>()));
        });
        return _widgets.last.completer.future;
      },
      pop: ([T? data]) async {
        if (_widgets.isEmpty) {
          return;
        }
        await _widgets.last.widget.dispose;
        setState(() {
          _widgets.removeLast().completer.complete(data);
        });
      },
    );
  }

  @override
  void dispose() {
    _Holder.instance.set(widget.key!, _widgets);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CustomNavigationController<T>(
      navigationCallbacks: _navigationCallbacks,
      child: Stack(children: [
        widget.home,
        ..._widgets.map((e) {
          e.widget.animate = _animate;
          return e.widget;
        })
      ]),
    );
  }
}

class _PageHolder<T> {
  CustomNavigationPageRoute widget;
  Completer<T> completer;
  _PageHolder(this.widget, this.completer);
}

class ValueHolder<T> {
  T? value;
  ValueHolder(this.value);
}

class CustomNavigationPageRoute extends StatefulWidget {
  CustomNavigationPageRoute({
    Key? key,
    required this.child,
    this.transitionBuilder,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  final Widget child;
  final Widget Function(BuildContext, Widget, Animation<double>)?
      transitionBuilder;
  final Duration duration;
  final ValueHolder<Future<void> Function()> _pop = ValueHolder(() async {});
  Future<void> get dispose => _pop.value!();
  final ValueHolder<bool> _animate = ValueHolder(true);
  set animate(bool animate) {
    _animate.value = animate;
  }

  @override
  State<CustomNavigationPageRoute> createState() =>
      _CustomNavigationPageRouteState();
}

class _CustomNavigationPageRouteState extends State<CustomNavigationPageRoute>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    widget._pop.value = _controller.reverse;
    if (widget._animate.value!) {
      _controller.forward();
    } else {
      _controller.value = 1;
      widget.animate = true;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget page;
    if (widget.transitionBuilder != null) {
      page = widget.transitionBuilder!(context, widget.child, _controller);
    } else {
      page = AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return FadeTransition(opacity: _controller, child: child);
        },
        child: widget.child,
      );
    }
    return WillPopScope(
      child: page,
      onWillPop: () async {
        CustomNavigator.of(context).pop();
        return false;
      },
    );
  }
}

class _CustomNavigationController<T> extends InheritedWidget {
  const _CustomNavigationController({
    required super.child,
    required this.navigationCallbacks,
  });

  final CustomNavigatorCallbacks<T> navigationCallbacks;

  @override
  bool updateShouldNotify(covariant _CustomNavigationController oldWidget) {
    return true;
  }
}

class CustomNavigatorCallbacks<T> {
  Future<T> Function(CustomNavigationPageRoute) push;
  void Function([T?]) pop;

  CustomNavigatorCallbacks({required this.push, required this.pop});

  static CustomNavigatorCallbacks<T> empty<T>() => CustomNavigatorCallbacks<T>(
        push: (_) async {
          return Future<T>.error('No push function provided');
        },
        pop: ([T? _]) {},
      );
}
