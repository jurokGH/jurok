//library knob;

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

typedef OnPressedCallback = void Function();

class Knob extends StatefulWidget
{
  final double value;
  final double min;
  final double max;
  final double limit;
  final bool pressed;
  final int scaleCount;

  final double size;
  final double buttonRadius;
  final double outerRadius;
  final Color color;
  final TextStyle textStyle;
  final bool showIcon;
  final bool showText;
  final bool debug;

  final ValueChanged<double> onChanged;
  final OnPressedCallback onPressed;

  Knob({@required this.value,
    this.min = 0, this.max = 1,
    this.limit = 0,
    this.scaleCount = 10,
    this.pressed = false,
    this.size,
    this.buttonRadius = 0.4,
    this.outerRadius = 0.8,
    this.color = Colors.blue,
    this.showIcon = true,
    this.showText = true,
    this.debug = false,
    @required this.textStyle,
    @required this.onChanged, @required this.onPressed});

  @override
  State<StatefulWidget> createState() => KnobState();
}

class KnobState extends State<Knob> with SingleTickerProviderStateMixin<Knob>
{
  static const double minAngle = -170;
  static const double maxAngle = 170;
  static const double sweepAngle = maxAngle - minAngle;
  static const double innerRadius = 0.1;//0.25;

  double _value;
  double _startValue;
  Offset _startPos;
  Offset _prevPos;
  Offset _posSpot;
  Duration _prevTime;
  double _startAngle;
  double _prevAngle;
  int turn;
  bool pressed = false;
  bool tap = false;

  AnimationController _controller;
  Animation<double> _animation;
  int _time = 5000;

  Image _image;  /// Knob image
  Size _imageSize = Size.zero;

  void onTimer()
  {
    _controller.value;
    /*
    _prevAngle + _animation.value;
    _value

    double clippedValue = min(max(widget.value, widget.min), min(widget.limit, widget.max));
    double normalizedValue = (clippedValue - widget.min)/(widget.max - widget.min);
    double angle = (minAngle + normalizedValue * sweepAngle) * pi / 180;
*/
    setState(() {});
  }

  void onTimerStatus(AnimationStatus status)
  {
    if (status == AnimationStatus.completed)
    {
/*
      _prevAngle = angle1;
      _prevPos = pos;
      angle1 += 360 * turn;
      double da = angle1 - _startAngle;

      debugPrint('Knob $angle1 - $_startAngle - $da');
      //dda *= 180 / pi;
      //double changeInX = details.delta.dx;
      //double changeInValue = distanceToAngle * changeInX;

      //if (radius2)
      double radiusIn = 0.6 * radius;
      double radiusOut = widget.outerRadius * radius;

      // Change velocity over the radius
      double kOut = 2 * pi * radiusOut;
      kOut = 20 / (widget.max - widget.min);
      kOut = 10 / ((widget.max - widget.min) * 360 / sweepAngle);

      double kIn = 2 * pi * radiusIn;
      kIn = 1;
      double radius0 = _startPos.distance;
      double k = lerpDouble(kIn, kOut, (radius0 - radiusIn) / (radiusOut - radiusIn));
      if (radius0 <= radiusIn)
        k = kIn;
      if (radius0 >= radiusOut)
        k = kOut;
      else
        k = (widget.max - widget.min) / sweepAngle;
      //if (radius2 > radius * radius)  // TODO
      //
      // double newValue = _startValue - da * k;
      double clippedValue = min(max(newValue, widget.min), min(widget.limit, widget.max));

      //debugPrint('Knob $cur - $prev - ${details.delta} - ${details.globalPosition} - $da - $clippedValue');
      if (clippedValue != widget.value)
      {
        _value = clippedValue;

        debugPrint('onPanUpdate ${details.localPosition.toString()} - ${details.globalPosition.toString()} - ${details.sourceTimeStamp} - $_value - $da -- $k');

        widget.onChanged(clippedValue);
      }
      */
    }
    _controller.value;
    _prevAngle + _animation.value;

    double clippedValue = min(max(widget.value, widget.min), min(widget.limit, widget.max));
    double normalizedValue = (clippedValue - widget.min)/(widget.max - widget.min);
    double angle = (minAngle + normalizedValue * sweepAngle) * pi / 180;

    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _controller = new AnimationController(vsync: this, duration: new Duration(milliseconds: _time))
      ..addListener(onTimer)
      ..addStatusListener(onTimerStatus);
    _animation = new Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: Curves.decelerate)).animate(_controller);

    _image = new Image.asset('images/TempoKnob.png',
      //height: size,
      fit: BoxFit.cover,  //contain
      filterQuality: FilterQuality.medium, //TODO Choose right one
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    //debugPrint('Knob::build');
    double size = widget.size != null ? widget.size :
      MediaQuery.of(context).size.shortestSide; //TODO

    //double distanceToAngle = 0.007 * (widget.max - widget.min);
    double distanceToAngle = (widget.max - widget.min);

    double clippedValue = min(max(widget.value, widget.min), min(widget.limit, widget.max));
    double normalizedValue = (clippedValue - widget.min)/(widget.max - widget.min);
    double angle = (minAngle + normalizedValue * sweepAngle) * pi / 180;

    final Size imageSize = new Size.square(size);
    if (imageSize != _imageSize)
    {
      precacheImage(_image.image, context, size: imageSize);
      _imageSize = imageSize;
    }

    return //Center(child:
      Container(
        width: size,
        height: size,
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            //debugdebugPrint('onTapDown');
            double radius = size / 2;
            Offset pos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
            tap = pos.distance <= (innerRadius * radius);
          },
/*
          onTap: () {
            if (tap)
            {
              setState(() {
                pressed = !pressed;
              });
              widget.onPressed();  //TODO Should place it inside setState?
              tap = false;
            }
          },
*/
          onTapUp: (TapUpDetails details) {
            double radius = size / 2;
            Offset pos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
            //if (tap && pos.distance <= (innerRadius * radius))
            {
              setState(() {
                pressed = !pressed;
              });
              widget.onPressed();  //TODO Should place it inside setState?
              tap = false;
            }
          },
          onTapCancel: () {
            setState(() {
              tap = false;
            });
          },
          onPanStart: (DragStartDetails details)
          //onPanDown: (DragDownDetails details)
          {
            double radius = size / 2;
            _startValue = widget.value;
            _startPos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
            double radius0 = _startPos.distance;
            if (_startPos.dx.abs() < 0.5)
              _startAngle = _startPos.dy < 0 ? -180 : 180;
            else
              _startAngle = atan2(_startPos.dy, _startPos.dx) * 180 / pi;
            _prevAngle = _startAngle;
            _prevTime = details.sourceTimeStamp;
            turn = 0;

            //debugPrint('onPanStart  ${_startPos.toString()} - ${details.globalPosition.toString()} - $_prevTime - $_startValue - $_startAngle - $radius0');
          },
          onPanUpdate: (DragUpdateDetails details)
          {
            double radius = size / 2;
            Offset pos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
            //Offset prev = cur - details.delta;

            //debugPrint('onPanUpdate ${pos.toString()} - ${details.globalPosition.toString()} - ${details.sourceTimeStamp} - ${details.delta.dx} - ${details.delta.dy}');

            Duration t = details.sourceTimeStamp - _prevTime;
            if (details.sourceTimeStamp - _prevTime < Duration(milliseconds: 10))
              return;
            _prevTime = details.sourceTimeStamp;

//            if (details.delta.distanceSquared < 2 || cur.dx.abs() < 1 || prev.dx.abs() < 1)
//              return;
            double radius2 = pos.distanceSquared;

            double radius00 = radius * innerRadius;
            if (radius2 > radius00 * radius00)  // TODO
            {
              //double da = atan2(cur.dy, cur.dx) - atan2(prev.dy, prev.dx);
              double angle1 = atan2(pos.dy, pos.dx);
              angle1 *= 180 / pi;
              if (angle1 * _prevAngle < 0 && (angle1 - _prevAngle).abs() > 180)
              {
                turn += _prevAngle > 0 ? 1  : -1;
                //debugPrint('Turnaround');
              }
              _prevAngle = angle1;
              _prevPos = pos;
              _posSpot = _prevPos;
              angle1 += 360 * turn;
              double da = angle1 - _startAngle;

              //debugPrint('Knob $angle1 - $_startAngle - $da');
              //dda *= 180 / pi;
              //double changeInX = details.delta.dx;
              //double changeInValue = distanceToAngle * changeInX;

              //if (radius2)
              double radiusIn = 0.6 * radius;
              double radiusOut = widget.outerRadius * radius;

              // Change velocity over the radius
              double kOut = 2 * pi * radiusOut;
              kOut = 20 / (widget.max - widget.min);
              kOut = widget.scaleCount / ((widget.max - widget.min) * 360 / sweepAngle);

              double kIn = 2 * pi * radiusIn;
              kIn = 1;
              double radius0 = _startPos.distance;
              double k = lerpDouble(kIn, kOut, (radius0 - radiusIn) / (radiusOut - radiusIn));
              if (radius0 <= radiusIn)
                k = kIn;
              if (radius0 >= radiusOut)
                k = kOut;
              else
                k = (widget.max - widget.min) / sweepAngle;
              //if (radius2 > radius * radius)  // TODO

              //double newValue = widget.value - (1 / coef) * da * (widget.max - widget.min) / sweepAngle;
              double newValue = _startValue - da * k;
              double clippedValue = min(max(newValue, widget.min), min(widget.limit, widget.max));

              //debugPrint('Knob $cur - $prev - ${details.delta} - ${details.globalPosition} - $da - $clippedValue');
              if (clippedValue != widget.value)
              {
                _value = clippedValue;

                //debugPrint('onPanUpdate ${details.localPosition.toString()} - ${details.globalPosition.toString()} - ${details.sourceTimeStamp} - $_value - $da -- $k');

                widget.onChanged(clippedValue);
              //if (pressed)
                //setState(() {});
              }
            }
          },
          onPanEnd: (DragEndDetails details) {
            Offset velocity = details.velocity.pixelsPerSecond;
            double v = velocity.distance;
            final double v0 = 1;
            //debugPrint('onPanEnd ${velocity.toString()} - $v');

            setState(() {
              _prevPos = null;
            });

            _time = (v * 1000) ~/ v0;
            if (_controller.isAnimating)
            {
              _controller.stop();
              _controller.reset();
            }
            _controller.duration = new Duration(milliseconds: _time);
            _controller.forward().orCancel;

            //widget.onChanged(_value);
          },
          onPanCancel: () {
            setState(() {
              _prevPos = null;
            });
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
                    color: Colors.deepPurple.withOpacity(0.7), //widget.color,
                    child: _image,
                  )
                ),
              ),

              CustomPaint(
                painter: KnobPainter(widget.outerRadius, widget.buttonRadius,
                  _prevPos, widget.scaleCount, pressed,
                  Colors.purpleAccent, Colors.purple.withOpacity(0.25), Colors.blueAccent, widget.debug),
                size: Size(size, size),
//                child: Text(widget.value.toInt().toString(),
//                  style: widget.textStyle
//                ),
              ),

              widget.showIcon ?
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
//                  Icon(pressed ? Icons.pause : Icons.play_arrow,
//                    size: 0.5 * size,
//                    color: widget.color,
//                  ),
                  Text(widget.value.toInt().toString(),
                    style: widget.textStyle,
                  ),
                ]
              )
              :
              Container(),
              widget.showText ?
              Text(widget.value.toInt().toString(),
                style: widget.textStyle
              )
              :
              Container(),
            ]
          ),
        ),
      //),
    );
  }
}

class KnobPainter extends CustomPainter
{
  final double outer;
  final double inner;
  final double radiusDot = 5;
  final Offset pos;
  final Color colorDot;
  final Color colorRing;
  final Color colorHit;
  final bool debug;
  final bool drawCenter;
  final int scaleCount;

  KnobPainter(this.outer, this.inner, this.pos, this.scaleCount, this.drawCenter, this.colorDot, this.colorRing, this.colorHit, this.debug);

  @override
  void paint(Canvas canvas, Size size)
  {
    double radius = size.width / 2;
    Offset center = new Offset(size.width / 2, size.height / 2);
    Paint paintRing = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = colorRing;
    if (debug)
      canvas.drawCircle(center, outer * radius, paintRing);

    if (drawCenter)
    {
      Paint paintBtn = new Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.purpleAccent;
      canvas.drawCircle(center, inner * radius, paintBtn);
    }

    if (debug)
      canvas.drawCircle(center, inner * radius, paintRing);

    //double radiusDot = 5;
    for (int i = 0; i < scaleCount; i++)
    {
      double angle = i * 2 * pi / scaleCount;
      Offset off = Offset(sin(angle), cos(angle));
      off *= 0.9 * radius;

      final Rect rcDot = new Rect.fromCircle(center: center + off, radius: radiusDot);
      final Shader gradientDot = new RadialGradient(
        colors: <Color>[colorDot, colorDot.withOpacity(0.3)],
      ).createShader(rcDot);
      final Paint paintDot = new Paint()
        ..style = PaintingStyle.fill
        //..shader = gradientDot;
        ..color = colorDot;

      canvas.drawCircle(center + off, radiusDot, paintDot);
    }

    if (pos != null)
    {
/*
    double angleSpot = atan2(-pos.dy, pos.dx);
    double deltaAngle = 2 * pi * scaleCount;
    bool next = angleSpot % deltaAngle >= 0.5;

    double a = deltaAngle * (angleSpot ~/ deltaAngle);
    if (next)
      a += deltaAngle;
    Offset off = Offset(sin(a), cos(a));
    off *= 0.9 * radius;
    Offset pos1 = center + off;
*/

      double radiusSpot = 20;
      double radiusHit = pos.distance;
      if (outer * radius < radiusHit && radiusHit <= radius)
      {
        Offset off = new Offset(pos.dx, -pos.dy);
        Rect rc = new Rect.fromCircle(center: center + off, radius: radiusSpot);
        final Shader gradient = new RadialGradient(
          colors: <Color>[colorHit, colorHit.withOpacity(0.0)],
        ).createShader(rc);
        final Paint paintHit = new Paint()
          ..style = PaintingStyle.fill
          ..shader = gradient;
        canvas.drawCircle(center + off, radiusSpot, paintHit);
      }
    }
  }

  @override
  bool shouldRepaint(KnobPainter oldDelegate) {
    return outer != oldDelegate.outer || pos != oldDelegate.pos ||
      colorDot != oldDelegate.colorDot || colorRing != oldDelegate.colorRing;
  }
}
