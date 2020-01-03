//library knob;

import 'dart:math';
import 'package:flutter/material.dart';
import 'tempo_ui.dart';

typedef OnPressedCallback = void Function();

class Knob extends StatefulWidget
{
  final double value;
  final double min;
  final double max;
  final double limit;
  final bool pressed;

  final double size;
  final Color color;
  final TextStyle textStyle;

  final ValueChanged<double> onChanged;
  final OnPressedCallback onPressed;

  Knob({@required this.value,
    this.min = 0, this.max = 1,
    this.limit = 0,
    this.pressed = false,
    this.size,
    this.color = Colors.blue,
    @required this.textStyle,
    @required this.onChanged, @required this.onPressed});

  @override
  State<StatefulWidget> createState() => KnobState();
}

class KnobState extends State<Knob>
{
  static const double minAngle = -160;
  static const double maxAngle = 160;
  static const double sweepAngle = maxAngle - minAngle;
  static const double innerRadius = 0.25;

  bool pressed = false;

  @override
  Widget build(BuildContext context)
  {
    print('Knob::build');
    double size = widget.size != null ? widget.size :
      MediaQuery.of(context).size.shortestSide; //TODO

    //double distanceToAngle = 0.007 * (widget.max - widget.min);
    double distanceToAngle = (widget.max - widget.min);

    double normalisedValue = (widget.value - widget.min)/(widget.max - widget.min);
    double angle = (minAngle + normalisedValue * sweepAngle) * 2 * pi / 360;
    return Center(
      child: Container(
        width: size,
        height: size,
        child: GestureDetector(
          onTap: () {
            setState(() {
              pressed = !pressed;
            });
            widget.onPressed();  //TODO Should place it inside setState?
          },
          onPanUpdate: (DragUpdateDetails details) {
            double radius = size / 2;
            Offset center = new Offset(radius, radius);
            Offset cur = details.localPosition - center;
            Offset prev = cur - details.delta;

            if (details.delta.distanceSquared < 2 || cur.dx.abs() < 1 || prev.dx.abs() < 1)
              return;

            radius *= innerRadius;
            if (cur.distanceSquared > radius * radius)  // TODO
            {
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
                double clippedValue = min(max(newValue, widget.min), min(widget.limit, widget.max));
                //print('Knob $cur - $prev - ${details.delta} - ${details.globalPosition} - $da - $clippedValue');
                //if (clippedValue != widget.value)
                  widget.onChanged(clippedValue);
                //if (pressed)
                  //setState(() {});
              }
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
            alignment: Alignment.center,
            children: <Widget>[
              Transform.rotate(
                angle: angle,
                child: ClipOval(
                  child: Container(
    //                color: widget.color,
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
  //                Icon(pressed ? Icons.pause : Icons.play_arrow,
   //                 size: 0.53 * size,
  //                  color: widget.color,
   //               ),
                  Text(widget.value.toInt().toString(),
                    style: TextStyle(color: Colors.white ,
                    fontSize:  26),
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