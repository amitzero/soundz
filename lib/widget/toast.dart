import 'package:flutter/material.dart';

class ToastView extends StatefulWidget {
  ToastView({super.key, this.text, this.content})
      : assert(
          (text != null || content != null) &&
              (text == null || content == null),
          'Only one of [text] and [content] must not be null.',
        );

  final String? text;
  final Widget? content;

  final List<Future Function()> _func = [];

  Future hide() {
    return _func.single();
  }

  @override
  State<ToastView> createState() => _ToastViewState();
}

class _ToastViewState extends State<ToastView>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    widget._func
      ..clear()
      ..add(_animationController.reverse);
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var bottom = MediaQuery.of(context).viewInsets.bottom + 10;
    return Positioned(
      bottom: bottom == 10 ? 100 : bottom,
      right: 0,
      left: 0,
      child: ScaleTransition(
        scale: _animationController,
        child: Center(
          child: Material(
            elevation: 10,
            color: Theme.of(context).colorScheme.onSecondary,
            child: widget.content ??
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(widget.text!),
                ),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
    );
  }
}

class Toast extends OverlayEntry {
  ToastView toastView;

  Toast._(this.toastView) : super(builder: (context) => toastView);

  factory Toast({String? text, Widget? content}) => Toast._(
        ToastView(text: text, content: content),
      );

  @override
  void remove() {
    toastView.hide().then((_) => super.remove());
  }

  static final List<ToastItem> _list = [];
  static bool _cycling = false;

  static void _cycle() async {
    if (_cycling || _list.isEmpty) return;
    _cycling = true;
    await _list.first.show();
    _list.removeAt(0);
    _cycling = false;
    _cycle();
  }

  static void show({
    required BuildContext context,
    String? text,
    Widget? content,
    Duration duration = const Duration(seconds: 3),
  }) {
    var toast = Toast(text: text, content: content);
    _list.add(ToastItem(toast, duration, context));
    _cycle();
  }
}

class ToastItem {
  ToastItem(this.toast, this.duration, this.context);

  Toast toast;
  Duration duration;
  BuildContext context;

  Future<void> show() async {
    Overlay.of(context)?.insert(toast);
    await Future.delayed(
      duration,
      () {
        toast.remove();
      },
    );
  }
}
