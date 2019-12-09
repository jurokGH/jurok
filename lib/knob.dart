//library knob;

import 'dart:math';
import 'package:flutter/material.dart';

typedef OnPressedCallback = void Function();

class Knob extends StatefulWidget
{
  final double value;
  final double min;
  final double max;
  final bool pressed;

  final double size;
  final Color color;

  final ValueChanged<double> onChanged;
  final OnPressedCallback onPressed;

  Knob({this.value, this.min = 0, this.max = 1,
    this.pressed = false,
    this.color = Colors.blue, this.size = 50,
    this.onChanged, this.onPressed});

  @override
  State<StatefulWidget> createState() => KnobState();
}

class KnobState extends State<Knob>
{
  static const double minAngle = -160;
  static const double maxAngle = 160;
  static const double sweepAngle = maxAngle - minAngle;

  bool pressed = false;
  
  @override
  Widget build(BuildContext context)
  {
    TextStyle textStyle = Theme.of(context).textTheme.display1.apply(
      color: Colors.white,
      //backgroundColor: Colors.black45
    );
    //double distanceToAngle = 0.007 * (widget.max - widget.min);
    double distanceToAngle = (widget.max - widget.min);

    double normalisedValue = (widget.value - widget.min)/(widget.max - widget.min);
    double angle = (minAngle + normalisedValue * sweepAngle) * 2 * pi / 360;
    double size = widget.size;
    return Center(
      child: Container(
        width: size,
        height: size,
        child: GestureDetector(
          onTap: () {
            setState(() {
              pressed = !pressed;
            });
            widget.onPressed();
          },
          onPanUpdate: (DragUpdateDetails details) {
            Offset center = new Offset(size / 2, size / 2);
            Offset cur = details.localPosition - center;
            Offset prev = cur - details.delta;
            double da = atan2(cur.dy, cur.dx) - atan2(prev.dy, prev.dx);
            da *= 180 / pi;

            //TODO print('Knob ${atan2(cur.dy, cur.dx)} - ${atan2(prev.dy, prev.dx)}');
            if (-180 < da && da < 180)
            {
              //double changeInX = details.delta.dx;
              //double changeInValue = distanceToAngle * changeInX;
              // Change velocity over the radius
              double coef = 2 * cur.distance / size;
              if (coef < 0.3)
                coef = 0.3;

              double newValue = widget.value + (1 / coef) * da * (widget.max - widget.min) / sweepAngle;
              double clippedValue = min(max(newValue, widget.min), widget.max);
              //print('Knob $cur - $prev - ${details.delta} - ${details.globalPosition} - $da - $clippedValue');
              if (clippedValue != widget.value)
                widget.onChanged(clippedValue);
            }
          },
          /*
        onHorizontalDragUpdate: (DragUpdateDetails details) {
          double changeInX = details.delta.dx;
          double changeInValue = distanceToAngle * changeInX;
          double newValue = widget.value + changeInValue;
          double clippedValue = min(max(newValue, widget.min), widget.max);

          widget.onChanged(clippedValue);
        },
             */
          child: Stack(
            children: <Widget>[
              Transform.rotate(
                angle: angle,
                child: ClipOval(
                  child: Container(
                    color: widget.color,
                    child: Image.asset('images/TempoKnob.png',
                      height: size,
                      fit: BoxFit.cover
                    )
                  )
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Center(
                    child: Icon(pressed ? Icons.pause : Icons.play_arrow,
                    size: 0.4 * size,
                    color: textStyle.color.withOpacity(0.8),
                    )
                  ),

                  Center(
                    child: Text(widget.value.toInt().toString(),
                      style: textStyle)
                  ),
                ]
              )
            ]
          ),
        ),
      ),
    );
  }
}