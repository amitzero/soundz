import 'package:flutter/material.dart';

class PlayingEffect extends StatefulWidget {
  final Size size;
  final Duration duration;
  final Color? color;
  final bool animate;
  const PlayingEffect({
    super.key,
    required this.size,
    this.duration = const Duration(seconds: 1),
    this.color,
    this.animate = true,
  });

  @override
  State<PlayingEffect> createState() => _PlayingEffectState();
}

class _PlayingEffectState extends State<PlayingEffect>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: widget.size,
          painter: MyPainter(
            animationValue: widget.animate ? _controller.value : 0.35,
            color: widget.color ?? Theme.of(context).colorScheme.background,
          ),
        );
      },
    );
  }
}

class MyPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  const MyPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.stroke;
    paint.color = color;
    var width = size.width / 5;
    var strokeWidth = size.width / 10;
    for (var i = 1; i < 5; i++) {
      var finalHeight = (size.height - strokeWidth) * getAnimationValue(i);
      var start = Offset(width * i, finalHeight);
      var end = Offset(width * i, size.height - strokeWidth);
      canvas
        ..drawCircle(start, 1, paint..strokeWidth = strokeWidth - 2)
        ..drawCircle(end, 1, paint)
        ..drawLine(
          start,
          end,
          paint..strokeWidth = strokeWidth,
        );
    }
  }

  double getAnimationValue(int index) {
    double value = animationValue;
    switch (index) {
      case 3:
        value += 0.75;
        value = value > 1 ? value - 1 : value;
        return _calculate(value);
      case 2:
        value += 0.5;
        value = value > 1 ? value - 1 : value;
        return _calculate(value);
      case 1:
        value += 0.25;
        value = value > 1 ? value - 1 : value;
        return _calculate(value);
      default:
        return _calculate(value);
    }
  }

  double _calculate(double value) {
    if (value < 0.5) {
      return value * 2;
    } else {
      return 1 - (value - 0.5) * 2;
    }
  }

  @override
  bool shouldRepaint(MyPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
