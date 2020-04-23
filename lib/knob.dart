//library knob;

import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';

typedef OnPressedCallback = void Function();

int inDialDivision(Offset pos, double radius2, double radiusDial2, int dialDivisions)
{
  int div = -1;
  double distance2 = pos.distanceSquared;//TODO Opt
  if (distance2 >= radiusDial2 && distance2 <= radius2)
  {
    final double angle = pos.direction;
    final double divAngle = 2 * pi / dialDivisions;
    div = angle ~/ divAngle;
  }
  return div;
}

int posInArrow(Offset pos, double radius2, double radiusDial2, int dialDivisions)
{
  int arrow = 0;
  double distance2 = pos.distanceSquared;//TODO Opt
  if (distance2 >= radiusDial2 && distance2 <= radius2)
  {
    final double angle = pos.direction.abs();
    final double divAngle = 2 * pi / dialDivisions;
    if (angle < divAngle)
      arrow = 1;
    else if (angle > pi - divAngle)
      arrow = -1;
  }
  return arrow;
}

class Knob extends StatefulWidget
{
  final double value;
  final double min;
  final double max;
  final double limit;
  final double minAngle;
  final double maxAngle;
  final int turnCount;
  final double sweepAngle;
  final bool pressed;
  final int dialDivisions;

  final double diameter;
  final double radiusButton;
  final double radiusDial;
  final Color color;
  final Color colorOutLimit;
  final TextStyle textStyle;
  final bool showIcon;
  final bool showText;
  final bool showDialText;
  final bool firmKnob;
  final bool debug;

  final ValueChanged<double> onChanged;
  final OnPressedCallback onPressed;

  Knob({@required this.value,
    this.min = 0, this.max = 1,
    this.limit = 0,
    this.dialDivisions = 10,
    this.pressed = false,
    this.minAngle = -160,
    this.maxAngle = 160,
    this.turnCount = 2,
    this.sweepAngle = 2 * 360.0 + 2 * 160.0,
    this.diameter,
    this.radiusButton = 0.4,
    this.radiusDial = 0.8,
    this.color = Colors.blue,
    this.colorOutLimit = Colors.red,
    this.showIcon = true,
    this.showText = true,
    this.showDialText = true,
    this.firmKnob = true,
    this.debug = false,
    @required this.textStyle,
    @required this.onChanged, @required this.onPressed});

  @override
  State<StatefulWidget> createState() => KnobState();
}

class KnobState extends State<Knob> with SingleTickerProviderStateMixin<Knob>
{
  //static const double minAngle = -170;
  //static const double maxAngle = 170;
  //static const double sweepAngle = maxAngle - minAngle;
  static const double centerRadius = 0.1;//0.25;

  double _value;
  double _startValue;
  Offset _startPos;
  Offset _prevPos;
  Offset _posSpot;
  Duration _prevTime;
  double _startAngle;
  double _prevAngle;
  int _prevDir;
  bool _outLimit;
  int turn;
  bool pressed = false;
  bool tap = false;

  final Color clrAnimRing1 = Colors.pink[400].withOpacity(0.5);
  final Color clrAnimRing2 = Colors.purple[800].withOpacity(0.5);

  AnimationController _controller;
  Animation<double> _animation;
  Animation<Color> _animColor;
  ColorTween _tweenColor;
  Color _colorRing;
  int _time = 5000;
  double _tangential;

  double flingVelocity = 1.5;
  double _friction = 0.1;//0.05;
  double _accel = 800;

  Image _image;  /// Knob image
  Size _imageSize = Size.zero;

  @override
  void initState()
  {
    super.initState();

    _outLimit = false;

    _controller = new AnimationController(vsync: this, duration: new Duration(milliseconds: _time))
      ..addListener(onTimer);
      //..addStatusListener(onTimerStatus);
    _animation = new Tween<double>(begin: 0, end: 1)
      .chain(CurveTween(curve: Curves.linear)).animate(_controller);
      //.chain(CurveTween(curve: Curves.decelerate)).animate(_controller);
    _animColor = new ColorTween(begin: Colors.deepPurple[700], end: Colors.purple.withOpacity(0.25))
      //.chain(CurveTween(curve: Curves.easeInOutSine))
      .animate(_controller);
    _tweenColor = new ColorTween(begin: clrAnimRing1, end: clrAnimRing2);

    _image = new Image.asset('images/TempoKnob.png',
      //height: radius,
      fit: BoxFit.cover,  //contain
      filterQuality: FilterQuality.medium, //TODO Choose right one
    );
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  void onTimer()
  {
    //_controller.value;

    // a0 + v * t - k * t * t * 0.5
    double t = 0.001 * _animation.value;  // in sec
    _friction = 0.25;
    double angle = _prevAngle + _friction * (_tangential * t - _tangential.sign * 0.5 * _accel * t * t);

    double value = widget.min + (widget.max - widget.min) * (angle - widget.minAngle) / widget.sweepAngle;

    double clipped = min(max(value, widget.min), min(widget.limit, widget.max));
    //    double normalized = (clipped - widget.min)/(widget.max - widget.min);
    //    double angle = (widget.minAngle + normalized * widget.sweepAngle) * pi / 180;
    //debugPrint('onTimer ${_animation.value.toInt()} - $_prevAngle - $angle - $value');

    _colorRing = _tweenColor.lerp(sin(0.004 * 2 * pi * _animation.value));

    setState(() {});
    if (clipped != widget.value)
      widget.onChanged(clipped);
    else
    {
      //debugPrint('onTimer:stop');
      _controller.stop();
    }
  }

  void onTimerStatus(AnimationStatus status)
  {
    if (status == AnimationStatus.completed)
    {
    }
    setState(() {});
  }

  void onPanStart(DragStartDetails details, double radius)
  {
    if (_controller.isAnimating)
      _controller.stop();

    _value = _startValue = widget.value;
    _startPos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
    _prevPos = _startPos;
    double radius0 = _startPos.distance;
    if (_startPos.dx.abs() < 0.1)
      _startAngle = _startPos.dy < 0 ? -180 : 180;
    else
      _startAngle = _startPos.direction * 180 / pi;
    _prevAngle = _startAngle;
    _prevDir = 0;
    turn = 0;
    _prevTime = details.sourceTimeStamp;

    //debugPrint('onStart (pos,loc,glob,angle,rad0,val,time) ${_startPos.toString()} - ${details.localPosition.toString()} - ${details.globalPosition.toString()} - $_startAngle - $radius0 - $_startValue - $_prevTime');
  }

  void onPanUpdate(DragUpdateDetails details, double radius)
  {
    Offset pos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
    //Offset prev = cur - details.delta;

    //debugPrint('onPan (pos,glob,dx,dy,time) ${pos.toString()} - ${details.globalPosition.toString()} - ${details.delta.dx} - ${details.delta.dy} - ${details.sourceTimeStamp}');

    Duration t = details.sourceTimeStamp - _prevTime;
    if (_startPos == null || details.sourceTimeStamp - _prevTime < Duration(milliseconds: 0))
      return;
    _prevTime = details.sourceTimeStamp;

    //            if (details.delta.distanceSquared < 2 || cur.dx.abs() < 1 || prev.dx.abs() < 1)
    //              return;
    double radius2 = pos.distanceSquared;

    double radius00 = radius * centerRadius;
    if (radius2 > radius00 * radius00)  // TODO
    {
      //double da = atan2(cur.dy, cur.dx) - atan2(prev.dy, prev.dx);
      double alpha = pos.direction;
      alpha *= 180 / pi;

      // CW/CCW rotation direction
      int dir = 0;
      // Detect turnaround
      if (alpha * _prevAngle < 0 && (alpha - _prevAngle).abs() > 180)
      {
        dir = _prevAngle > 0 ? -1  : 1;
        turn -= dir;
        debugPrint('Turnaround - $dir - $turn - $alpha - $_prevAngle');
      }

      double alphaFull = alpha + 360 * turn;
      double da = alphaFull - _startAngle;

      if (dir == 0)
      {
        if (alpha != _prevAngle)
          dir = alpha < _prevAngle ? 1 : -1;
      }
      bool dirChanged = _prevDir != 0 && dir != _prevDir;
      print('Knob:Dir $dir - $_prevDir - $dirChanged - $alpha - $_prevAngle');
      if (dir != 0)
        _prevDir = dir;

      //debugPrint('Knob Angles: $alpha - $_startAngle - $da');
      //dda *= 180 / pi;
      //double changeInX = details.delta.dx;
      //double changeInValue = distanceToAngle * changeInX;

      //if (radius2)
      double radiusIn = 0.6 * radius;
      double radiusOut = widget.radiusDial * radius;

      // Change velocity over the radius
      double kOut = 2 * pi * radiusOut;
      kOut = 20 / (widget.max - widget.min);
      kOut = widget.dialDivisions / ((widget.max - widget.min) * 360 / widget.sweepAngle);

      double kIn = 2 * pi * radiusIn;
      kIn = 1;
      double radius0 = _startPos.distance;
      double k = lerpDouble(kIn, kOut, (radius0 - radiusIn) / (radiusOut - radiusIn));
      if (radius0 <= radiusIn)
        k = kIn;
      if (radius0 >= radiusOut)
        k = kOut;
      else
        k = (widget.max - widget.min) / widget.sweepAngle;
      //if (radius2 > radius * radius)  // TODO

      //double newValue = widget.value - (1 / coef) * da * (widget.max - widget.min) / sweepAngle;
      double newValue = _startValue - da * k;
      //double clipped = clamp(newValue, widget.min, min(widget.limit, widget.max));
      final double maxValue = min(widget.limit, widget.max);
      //TODO
      assert(widget.min <= maxValue);
      bool updateStart = false;
      print('Knob:newValue $newValue - $maxValue');
      if (newValue < widget.min)
      {
        _outLimit = true;
        //newValue = widget.min;
        if (!widget.firmKnob && dirChanged && dir == 1)
        {
          newValue = widget.min - (alpha - _prevAngle) * k;
          print('Knob:correctMin $newValue');
          updateStart = true;
        }
      }
      else if (newValue > maxValue)
      {
        _outLimit = true;
        //newValue = maxValue;
        if (!widget.firmKnob && dirChanged && dir == -1)
        {
          newValue = maxValue + (alpha - _prevAngle) * k;
          print('Knob:correctMax $newValue');
          updateStart = true;
        }
      }
      else
        _outLimit = false;

      final double clipped = min(max(newValue, widget.min), min(widget.limit, widget.max));
      if (updateStart)
      {
        print('Knob:updateStart - $newValue - $alpha - $_startValue - $_startAngle');
        _startValue = newValue;
        _startAngle = alphaFull;
      }

      // Save previous values
      _prevAngle = alpha;
      _prevPos = pos;
      _posSpot = _prevPos;

      //debugPrint('Knob $pos - ${details.delta} - ${details.globalPosition} - $da - $clipped');
      if (clipped != widget.value)
      {
        _value = clipped;

        //debugPrint('onPanUpdate ${details.localPosition.toString()} - ${details.globalPosition.toString()} - ${details.sourceTimeStamp} - $_value - $da -- $k');

        widget.onChanged(clipped);
        //if (pressed)
        //setState(() {});
      }
    }
  }

  void onPanEnd(DragEndDetails details, double radius)
  {
    final Offset velocity = details.velocity.pixelsPerSecond;
    double v = velocity.distance;
    //debugPrint('onPanEnd ${velocity.toString()} - $v');

    if (_prevPos == null || _prevAngle == null)
    {
      //debugPrint('onPanEnd Error ${velocity.toString()} - $v - $_prevPos - $_prevAngle');
      _startPos = null;
      return;
    }

    _prevAngle = widget.minAngle + widget.sweepAngle * (_value - widget.min) / (widget.max - widget.min);

    double alpha = _prevPos.direction;
    // velocity.dy has opposite direction to y-axis
    double tangential = - velocity.dx * sin(alpha) - velocity.dy * cos(alpha);
    // Tangential velocity
    final Offset velocityTang = new Offset(- tangential * sin(alpha), tangential * cos(alpha));

    double tangentialAbs = tangential.abs();
    _time = 1000;  // in msec
    _time = tangentialAbs ~/ flingVelocity;  // in msec
    _accel = 1000 * tangentialAbs / _time;
    //_time = (tangentialAbs * 1000) ~/ _accel;  // in msec
    // Knob turns CW to higher values
    _tangential = - tangential;
    //debugPrint('Velocity $_tangential - $_accel - $_time - $_prevAngle');

    _startPos = _prevPos = null;
    _outLimit = false;

    if (_controller.isAnimating)
      _controller.stop();
    if (tangentialAbs > 0)
    {
      _controller.reset();
      _controller.duration = new Duration(milliseconds: _time);
      _animation = new Tween<double>(begin: 0, end: _time.toDouble())
          .chain(CurveTween(curve: Curves.linear)).animate(_controller);

      _controller.forward(); //TODO .orCancel ??
    }
    else
      setState(() {});

    //widget.onChanged(_value);
  }

  @override
  Widget build(BuildContext context)
  {
    double size = widget.diameter != null ? widget.diameter :
      MediaQuery.of(context).size.shortestSide; //TODO

    //double distanceToAngle = 0.007 * (widget.max - widget.min);
    //double distanceToAngle = (widget.max - widget.min);

    double clipped = min(max(widget.value, widget.min), min(widget.limit, widget.max));
    double normalized = (clipped - widget.min)/(widget.max - widget.min);
    double angle = (widget.minAngle + normalized * widget.sweepAngle) * pi / 180;

    //debugPrint('Knob::build $clipped - $angle - $size - ${MediaQuery.of(context).size}');

    final Size imageSize = new Size.square(size);
    if (imageSize != _imageSize)
    {
      precacheImage(_image.image, context, size: imageSize);
      _imageSize = imageSize;
    }

    return LayoutBuilder(
    builder: (BuildContext context, BoxConstraints constraints) {
      //double size = widget.radius != null ? widget.diameter :
      Size sz = MediaQuery.of(context).size; //TODO
      //debugPrint('Builder ${MediaQuery.of(context).size} - $constraints');
      TextStyle textStyle = widget.textStyle;
      if (_outLimit)
        textStyle = widget.textStyle.copyWith(color: widget.colorOutLimit);

      return Center(child:
      Container(
        width: size,
        height: size,
        child: GestureDetector(
          onTapDown: (TapDownDetails details) {
            //debugPrint('onTapDown');
            
            if (_controller.isAnimating)
              _controller.stop();

            double radius = size / 2;
            Offset pos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
            tap = pos.distance <= (widget.radiusButton * radius);
            // For arrow buttons
            setState(() {
              _prevPos = pos;
            });
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
            //debugPrint('onTapUp');
            double radius = size / 2;
            double radius2 = radius * radius;
            double radiusDial2 = widget.radiusDial * widget.radiusDial * radius2;
            Offset pos = new Offset(details.localPosition.dx - radius, radius - details.localPosition.dy);
            double distance2 = pos.distanceSquared;//TODO Opt

            if (tap && distance2 <= radiusDial2)
            {
              setState(() {
                pressed = !pressed;
                pressed = false;
              });
              widget.onPressed();  //TODO Should place it inside setState?
              tap = false;
            }
            int arrow = posInArrow(pos, radius2, radiusDial2, widget.dialDivisions);
            if (arrow != 0)
            {
              //debugPrint('TapRing $arrow');
              double clipped = min(max(widget.value + arrow, widget.min), min(widget.limit, widget.max));
              if (clipped != widget.value)
              {
                _value = clipped;
                widget.onChanged(clipped);
              }
            }
            _prevPos = null;
          },
          onTapCancel: () {
            setState(() {
              tap = false;
              _prevPos = null;
            });
          },
          //onPanDown: (DragDownDetails details)
          onPanStart: (DragStartDetails details) {
            onPanStart(details, size / 2);
          },
          onPanUpdate: (DragUpdateDetails details) {
            onPanUpdate(details, size / 2);
          },
          onPanEnd: (DragEndDetails details) {
            onPanEnd(details, size / 2);
          },
          onPanCancel: () {
            //debugPrint('onPanCancel');
            setState(() {
              _startPos = _prevPos = null;
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
                    color: Colors.deepPurple.withOpacity(0.5), //widget.color,
                    child: _image,
                  )
                ),
              ),

              CustomPaint(
                painter: KnobPainter(widget.radiusDial, widget.radiusButton,
                  _prevPos, widget.dialDivisions,
                  pressed,
                  widget.showText,
                  widget.showDialText,
                  Colors.purpleAccent,
                  //_controller.isAnimating ? _animColor.value : Colors.purple.withOpacity(0.25),
                  _controller.isAnimating ? _colorRing : Colors.purple.withOpacity(0.25),
                  /// Arrows color
                  Colors.purpleAccent[400],//Colors.white,
                  /// Arrows pressed color
                  Colors.purpleAccent.withOpacity(0.5),
                  /// Press spot on outer ring color
                  Colors.redAccent[400],
                  widget.debug),
                size: Size(size, size),
//                child: Text(widget.value.toInt().toString(),
//                  style: widget.textStyle
//                ),
              ),

              widget.showDialText ?
              Positioned(
                top: 0,
                child: Text(widget.value.toInt().toString(),
                  style: widget.textStyle.copyWith(
                    color: Colors.purple[100],
                    fontSize: 0.6 * (1 - widget.radiusDial) * widget.diameter,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              :
              Container(),

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
                style: textStyle//.copyWith(fontSize: 40)
              )
              :
              Container(),
            ]
          ),
        ),
      ),
      );
      }
    );
  }
}

class KnobPainter extends CustomPainter
{
  final double radiusDial;
  final double radiusButton;
  final double radiusDot = 5;
  final Offset pos;
  /// Outer ring dot color
  final Color colorDot;
  /// Outer ring color
  final Color colorRing;
  /// Arrows-buttons +-1: main color
  final Color colorArrow;
  /// Arrows-buttons +-1: pressed color
  final Color colorArrowHi;
  /// Press spot on outer ring color
  final Color colorHit;
  final bool debug;
  final bool drawCenter;
  final bool showText;
  final bool showDialText;
  final int dialDivisions;

  KnobPainter(this.radiusDial, this.radiusButton,
    this.pos, this.dialDivisions,
    this.drawCenter,
    this.showText,
    this.showDialText,
    this.colorDot,
    this.colorRing,
    this.colorArrow,
    this.colorArrowHi,
    this.colorHit,
    this.debug);

  Path arrowPath(int direction, Offset center, double radius, double deltaAngle, double xCenter)
  {
    final double x = radiusDial * radius * cos(deltaAngle);
    final double y = radiusDial * radius * sin(deltaAngle);
    Path path = new Path();
    path.moveTo(center.dx + direction * radius, center.dy);
    path.lineTo(center.dx + direction * x, center.dy + y);
    path.lineTo(center.dx + direction * xCenter, center.dy);
    path.lineTo(center.dx + direction * x, center.dy - y);
    path.close();
    return path;
  }

  Path divisionPath(int div, Offset center, double radius, double deltaAngle)
  {
    final double angle = div * deltaAngle;
//    final double x = radiusDial * radius * cos(angle);
//    final double y = radiusDial * radius * sin(angle);
//    final Rect rect = new Rect.fromCircle(center: center, radius: radius);
    Path path = new Path();
    //path.moveTo(center.dx + x, center.dy + y);
    path.arcTo(new Rect.fromCircle(center: center, radius: radius), angle, deltaAngle, true);
    path.arcTo(new Rect.fromCircle(center: center, radius: radiusDial * radius), angle + deltaAngle, -deltaAngle, false);
    path.close();
    return path;
  }

  @override
  void paint(Canvas canvas, Size size)
  {
    //debugPrint('paint');

    double radius = size.width / 2;
    double radius2 = radius * radius;
    double radiusDial2 = radiusDial * radiusDial * radius2;

    Offset center = new Offset(size.width / 2, size.height / 2);
    Paint paintRing = new Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2
      ..color = colorRing;
    Paint paintArrow = new Paint()
      ..style = PaintingStyle.fill
      //..blendMode = BlendMode.darken
      ..strokeWidth = 2
      ..color = colorArrow;
    Paint paintArrowHi = new Paint()
      ..style = PaintingStyle.fill
      //..blendMode = BlendMode.darken
      ..strokeWidth = 2
      ..color = colorArrowHi;
//    final Shader paintArrowHi = new RadialGradient(
//      colors: <Color>[colorDot, colorDot.withOpacity(0.3)],
//    ).createShader(rcDot);
//    final Paint paintDot = new Paint()
//      ..style = PaintingStyle.fill
//    //..shader = gradientDot;
//      ..color = colorDot;

    if (debug)
      ;//canvas.drawCircle(center, radiusDial * radius, paintRing);

    if (drawCenter)
    {
      Paint paintBtn = new Paint()
        ..style = PaintingStyle.fill
        ..color = Colors.purpleAccent;
      canvas.drawCircle(center, radiusButton * radius, paintBtn);
    }

    if (debug)
      ;//canvas.drawCircle(center, radiusButton * radius, paintRing);

    final Path ring = new Path();
    double a = 1.9999 * pi;
    ring.arcTo(new Rect.fromCircle(center: center, radius: radius), 0, a, true);
    ring.arcTo(new Rect.fromCircle(center: center, radius: radiusDial * radius), a, -a, false);
    //ring.fillType = PathFillType.evenOdd;
//    ring.addOval(new Rect.fromCircle(center: center, radius: radius));
//    final Path ringInner = new Path();
//    ringInner.addOval(new Rect.fromCircle(center: center, radius: radiusDial * radius));
    ring.close();
    //ringInner.fillType = PathFillType.evenOdd;
//    ring.addPath(new Path()..addOval(
//        new Rect.fromCircle(center: center, radius: radiusDial * radius)), Offset.zero);
    //canvas.clipPath(new Path()..addOval(new Rect.fromCircle(center: center, radius: radiusDial * radius)));
    //canvas.drawPath(Path.combine(PathOperation.difference, ring, ringInner), paintRing);
    canvas.drawPath(ring, paintRing);

    //double radiusDot = 5;
    double angleDiv = 2 * pi / dialDivisions;
    final double coef = 0.75;
    double xCenter = (1 - coef + coef * radiusDial) * radius;

    final Path right = arrowPath(1, center, radius, angleDiv, xCenter);
    final Path left = arrowPath(-1, center, radius, angleDiv, xCenter);
    canvas.drawPath(right, paintArrow);
    canvas.drawPath(left, paintArrow);

    if (pos != null)
    {
      //debugPrint('posInArrow');
      int arrow = posInArrow(pos, radius2, radiusDial2, dialDivisions);
      if (arrow == 1)
      {
        //int div = dialDivisions ~/ 4;
        canvas.drawPath(divisionPath(dialDivisions - 1, center, radius, angleDiv), paintArrowHi);
        canvas.drawPath(divisionPath(0, center, radius, angleDiv), paintArrowHi);
        //canvas.drawPath(right, paintArrowHi);
      }
      else if (arrow == -1)
      {
        int div = dialDivisions ~/ 2;
        canvas.drawPath(divisionPath(div - 1, center, radius, angleDiv), paintArrowHi);
        canvas.drawPath(divisionPath(div, center, radius, angleDiv), paintArrowHi);
        //canvas.drawPath(left, paintArrowHi);
      }
    }

    /// Dial divisions
    for (int i = showDialText ? 1 : 0; i < dialDivisions; i++)
    {
      double angle = i * angleDiv - 0.5 * pi;
      if (angle == 0 || angle == pi)
        continue;
      Offset off = Offset(cos(angle), sin(angle));
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
    double deltaAngle = 2 * pi * dialDivisions;
    bool next = angleSpot % deltaAngle >= 0.5;

    double a = deltaAngle * (angleSpot ~/ deltaAngle);
    if (next)
      a += deltaAngle;
    Offset off = Offset(cos(a), sin(a));
    off *= 0.9 * radius;
    Offset pos1 = center + off;
*/

      double radiusSpot = 20;
      double radiusHit = pos.distance;
      if (radiusDial * radius < radiusHit && radiusHit <= radius)
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
    return radiusDial != oldDelegate.radiusDial || pos != oldDelegate.pos ||
      colorDot != oldDelegate.colorDot || colorRing != oldDelegate.colorRing;
  }
}
