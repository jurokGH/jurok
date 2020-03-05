import 'package:flutter/material.dart';

enum BarBracketDirection
{
  left, right,
}

class BarBracketWidget extends StatelessWidget
{
  final BarBracketDirection direction;
  final Color color;
  final Size size;
  //final GestureTapCallback onTap;

  BarBracketWidget({
    this.direction,
    this.color = Colors.white,
    this.size = Size.zero,
    //this.onTap
  });

  @override
  Widget build(BuildContext context)
  {
    // TODO: implement build
    //return GestureDetector(onTap: onTap, child:
    return CustomPaint(
      size: size,
      painter: BarBracketPainter(direction, color)
    );
  }
}

class BarBracketPainter extends CustomPainter
{
  final BarBracketDirection direction;
  final Color color;

  BarBracketPainter(this.direction, this.color);

  @override
  void paint(Canvas canvas, Size size)
  {
    final Paint paint = new Paint()
      ..style = PaintingStyle.fill
      ..color = color;

    final double wrc = 0.3 * size.width;
    final double xrc = direction == BarBracketDirection.left ? 0 : size.width - wrc;
    final double wln = 0.1 * size.width;
    final double xln = (direction == BarBracketDirection.left ? 0.45 : 0.45) * size.width;
    final double radius = 0.16 * size.width;
    final double x = direction == BarBracketDirection.left ? size.width - radius : radius;

    canvas.drawRect(Rect.fromLTWH(xrc, 0, wrc, size.height), paint);
    canvas.drawRect(Rect.fromLTWH(xln, 0, wln, size.height), paint);
    canvas.drawCircle(new Offset(x, 0.375 * size.height), radius, paint);
    canvas.drawCircle(new Offset(x, 0.625 * size.height), radius, paint);
  }

  @override
  bool shouldRepaint(BarBracketPainter oldDelegate)
  {
    return direction != oldDelegate.direction ||
      color != oldDelegate.color;
  }
}
