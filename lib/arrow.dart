import 'package:flutter/material.dart';

enum ArrowDirection
{
  left, right,
}

class ArrowWidget extends StatelessWidget
{
  final ArrowDirection direction;
  final Color color;

  ArrowWidget({this.direction = ArrowDirection.left, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return CustomPaint(
      painter: ArrowPainter(direction, color)
    );
  }
}

class ArrowPainter extends CustomPainter
{
  final ArrowDirection direction;
  final Color color;

  ArrowPainter(this.direction, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint()
      ..style = PaintingStyle.fill
      ..color = color;
    final Path path = new Path();
    double x = direction == ArrowDirection.left ? size.width : 0;
    double y = 0;
    path.moveTo(x, y);
    x = direction == ArrowDirection.left ? 0 : size.width;
    y = size.height / 2;
    path.lineTo(x, y);
    x = direction == ArrowDirection.left ? size.width : 0;
    y = size.height;
    path.lineTo(x, y);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(ArrowPainter oldDelegate) {
    return direction != oldDelegate.direction ||
      color != oldDelegate.color;
  }
}
