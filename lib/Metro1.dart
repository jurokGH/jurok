import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';  // for Colors
import 'package:flutter/widgets.dart';

import 'BipPauseCycle.dart';

class Metronome1 extends StatefulWidget
{
  _MetronomeState1 _metronomeState;

  Metronome1(BipPauseCycle cycle, int latency)
  {
    print("Metronome1::Metronome1: $_metronomeState");
    _metronomeState?.setCycle(cycle, latency);
  }

  void setCycle(BipPauseCycle cycle, int latency)
  {
    _metronomeState?.setCycle(cycle, latency);
  }

  void setTempo(double tempoBpM, int nativeSampleRate, int denominator, double duration)
  {
    _metronomeState?.setTempo(tempoBpM, nativeSampleRate, denominator, duration);
  }

  void setFrame(int frame)
  {
    _metronomeState?.setFrame(frame);
  }

  void play()
  {
    _metronomeState?.start();
  }

  void start0()
  {
    _metronomeState?.start0();
  }

  @override
  _MetronomeState1 createState()
  {
    print("Metronome1::createState");
    return _metronomeState = _MetronomeState1(bipPauseCycle: null, latencyInFrames: null);
  }
}

enum Direction
{
  Forward,
  Backward,
  Stopped
}

class _MetronomeState1 extends State<Metronome1> with SingleTickerProviderStateMixin
{
  BipPauseCycle bipPauseCycle;
  int latencyInFrames;
  _MetronomePainter _painter;

  double percentage = 0.0;
  double newPercentage = 100.0;
  AnimationController controller;
  Animation<double> _angleAnim;
  bool running = false;
  Direction direction = Direction.Forward;
  final double angle = pi / 6;

  double _period = 0;
  double _frame = 0;

  _MetronomeState1({this.bipPauseCycle, this.latencyInFrames})
  {
    print("_MetronomeState1::_MetronomeState1");
  }

  void setCycle(BipPauseCycle cycle, int latency)
  {
    bipPauseCycle = cycle;
    latencyInFrames = latency;
    _painter?.setCycle(bipPauseCycle, latencyInFrames);
  }

  void setTempo(double tempoBpM, int nativeSampleRate, int denominator, double duration)
  {
    if (tempoBpM > 0 && denominator > 0)
    {
      //int realBPM = bipPauseCycle?.setTempo(new Tempo(beatsPerMinute: tempoBpM.toInt(), denominator: denominator));
      _painter?.setCycle(bipPauseCycle, latencyInFrames = 0);

      int totalDurInt = 0;  //Игнорируем дробные части
      int length = bipPauseCycle.cycle.length;
      print('LengthLength: $length');
      for (int i = 0; i < length; i++) {
        totalDurInt += bipPauseCycle.cycle[i].len;
      }

      int dur = (totalDurInt * 1000) ~/ nativeSampleRate;
      int dur1 = (totalDurInt * 60000) ~/ (nativeSampleRate * tempoBpM / denominator);
      print('REALDUR_SETTEMPO: $totalDurInt,  $dur, $dur1, $duration,  $tempoBpM, $denominator');

      _period = duration;

      controller.duration = new Duration(milliseconds: 1000 * duration ~/ nativeSampleRate);
      if (controller.status == AnimationStatus.forward ||
        controller.status == AnimationStatus.reverse)
      {
        controller.stop();
        controller.forward();
      }

      print("Duration");
      print(controller.duration);
    }

    //if (tempoBpM > 0.0)
    //  controller.duration = new Duration(milliseconds: (60000.0 / tempoBpM).toInt());
  }

  void start()
  {
    print("bipPauseCycle.duration");
    print(bipPauseCycle.duration);
/*
    int bars = 1;
    int denominator = 1;
    int totalBeatsPerCycle = bars * denominator;
    int nativeSampleRate = 48000;
    int beatsPerMinute = latencyInFrames;
    double framesPerBeat = nativeSampleRate * 60.0 / beatsPerMinute;
    double dur = framesPerBeat * totalBeatsPerCycle;
    print(dur);
*/
    if (_painter != null)
    {
      //bipPauseCycle.duration / 48000;
      print("controller.isAnimating: ${controller.isAnimating}");
      if (running)
      {
        controller.stop();
      }
      else
      {
        controller.reset();
        if (direction == Direction.Forward)
          controller.forward().orCancel;
        else if (direction == Direction.Backward)
          controller.reverse().orCancel;
      }
      running = !running;
    }
    /*
    if (running)
      controller.stop();
    else
    {
      if (direction == Direction.Forward)
        controller.forward().orCancel;
      else if (direction == Direction.Backward)
        controller.reverse().orCancel;
      else
        ;
    }
    //controller.repeat(reverse: true).orCancel;
    running = !running;
     */
  }

  void start0()
  {
    if (running)
      controller.stop();
    else
      {
        if (direction == Direction.Forward)
          controller.forward().orCancel;
        else if (direction == Direction.Backward)
          controller.reverse().orCancel;
        else
          ;
      }
      //controller.repeat(reverse: true).orCancel;
    running = !running;
  }

  void setFrame(int frame)
  {
    setState(() {
      _frame = frame.toDouble();
    });
  }

  @override
  void initState() {
    super.initState();
    print("_MetronomeState1::initState");
    running = false;

    controller = new AnimationController
    (
      vsync: this,
      duration: new Duration(milliseconds: 1000),
      //upperBound: 60
    )
      ..addListener((){
        setState(() {
          print("Anim: ${_angleAnim.value}");
          percentage = lerpDouble(percentage,newPercentage,controller.value);
          _painter?.time = lerpDouble(0, 2 * pi, controller.value / 10);
          percentage = controller.value;
          _painter?.time = _angleAnim.value;
          print("8888888888888888");
          print(_angleAnim.value);
        });
      })
    ..addStatusListener((AnimationStatus status)
    {
      if (status == AnimationStatus.completed) {
        controller.reverse();
        direction = Direction.Backward;
      }
      else if (status == AnimationStatus.dismissed)
      {
        controller.forward();
        direction = Direction.Forward;
      }
      else
        ;
    });

    _angleAnim = new Tween(begin: -angle, end: angle).animate(
      new CurvedAnimation(parent: controller,
        curve: Curves.easeIn, reverseCurve: Curves.easeOut));
      //curve: Curves.easeInOut, reverseCurve: Curves.easeInOut));
/*
    _angleAnim = new TweenSequence(
      <TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: -angle, end: angle)
            .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50.0,
        ),
        //TweenSequenceItem<double>(
        //  tween: ConstantTween<double>(1.0),
        //  weight: 20.0,
        //),
        TweenSequenceItem<double>(
          tween: Tween<double>(begin: angle, end: -angle)
            .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 50.0,
        ),
      ],
    ).animate(controller);
    */
  }

  @override
  Widget build(BuildContext context)
  {
    print("_MetronomeState1:build");

    return Center(
      child: Container(
        width: 300,
        height: 300,
        child: CustomPaint(
          painter: _painter = new _MetronomePainter(bipPauseCycle: bipPauseCycle,
            latencyInFrames: latencyInFrames,
            period: _period, time: _frame,//_angleAnim.value,
            maxAngle: angle)
        )
      )
    );
  }

  @override
  void dispose()
  {
    controller.dispose();
    super.dispose();
  }
}

class _MetronomePainter extends CustomPainter
{
  BipPauseCycle bipPauseCycle;
  int latencyInFrames;

  //double rotateAngleDeg;
  double rotateAngleRad;

  double samplesToDegree;

  // private
  List<double> anglesDeg;
  List<double> anglesRad;
  int length, totalDurInt, totalPlayed;

  Color lineColor, arcColor;
  double lineWidth, arcWidth;
  double maxAngle;

  double period;
  double time;

  _MetronomePainter({this.bipPauseCycle, this.latencyInFrames,
    this.period, this.time,
    this.maxAngle = pi / 6,
    this.lineColor = Colors.blue, this.arcColor = Colors.black,
    this.lineWidth = 3, this.arcWidth = 3})
  {
    setAngles();
    print(latencyInFrames);
  }

  void setCycle(BipPauseCycle cycle, int latency)
  {
    bipPauseCycle = cycle;
    latencyInFrames = latency;
    setAngles();
  }

  @override
  void paint(Canvas canvas, Size size)
  {
    // Lines
    //paint.setColor(Color.BLUE);
    //paint.setStrokeWidth(7);
    Paint linesPaint = new Paint()
      ..color = lineColor
    //..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke
      ..strokeWidth = lineWidth;
    //paint.setColor(Color.BLACK);
    //paint.setStrokeWidth(3);
    Paint arcsPaint = new Paint()
      ..color = arcColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = arcWidth;
    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = 3 * min(center.dx, center.dy) / 4;

    //print("=============================-------------------=================================");
    //print(latencyInFrames);
    //if (bipPauseCycle == null || bipPauseCycle.cycle.length <= 0)
    if (true)
    {
      //print("Paint timer ${60 * this.time}");
      double angle = 0;//this.time - 0.5 * pi;
      //angle = 0.5 * pi;

      if (period > 0)
      {
        int cycle = time ~/ period;
        double t = (time - cycle * period) / period;
        if (cycle % 2 == 1)
        {
          angle += lerpDouble(-maxAngle, maxAngle, 1.0 - t);
        }
        else
        {
          angle += lerpDouble(-maxAngle, maxAngle, t);
        }
        print('Painter::Paint: $t - $time - $period / $angle - $maxAngle');
      }
      else
        print('Painter::Paint: $time - $period / $angle - $maxAngle');

      angle -= 0.5 * pi;
      Offset end = new Offset(cos(angle), sin(angle));
      canvas.drawLine(center, center + end * radius, arcsPaint);

      Offset dash0 = new Offset.fromDirection(-maxAngle - 0.5 * pi, radius);
      canvas.drawLine(center + dash0, center + dash0 * 1.1, arcsPaint);
      canvas.drawLine(center - new Offset(0, radius), center - new Offset(0, 1.1 * radius), arcsPaint);
      dash0 = new Offset.fromDirection(maxAngle - 0.5 * pi, radius);
      canvas.drawLine(center + dash0, center + dash0 * 1.1, arcsPaint);
    }
    else
    {
      print("=============================*******************=================================");
      print(bipPauseCycle.duration);
      latencyInFrames = time.toInt();

      totalPlayed = 0;
      for (int i = 0; i < bipPauseCycle.position.n; i++)
        totalPlayed += bipPauseCycle.cycle[i].len;
      totalPlayed += bipPauseCycle.position.offset;

      double rotateAngleDeg = 90.0 + samplesToDegree * (latencyInFrames - totalPlayed);
      rotateAngleRad = deg2rad(rotateAngleDeg);
      rotateAngleRad = time;

      //canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
      //canvas.drawColor(Color.WHITE);

 /*
    for (int i = 0; i < length; i++)
    {
      if (bipPauseCycle.cycle[i].char != bipPauseCycle.elasticSymbol)
      {
        // canvas.drawArc(oval, anglesDeg[i]+rotateAngleDeg, anglesDeg[i + 1] - anglesDeg[i], true, paint);
        //ToDo: лишний счет
        Offset p0 = new Offset(radius * cos(anglesRad[i] + rotateAngleRad),
          radius * sin(anglesRad[i] + rotateAngleRad));
        Offset p1 = new Offset(radius * cos(anglesRad[i + 1] + rotateAngleRad),
          radius * sin(anglesRad[i + 1] + rotateAngleRad));
        canvas.drawLine(center + p0, center + p1, linesPaint);
      }
    }
    // Arrow
    Rect circle = new Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(circle, deg2rad(89.5), deg2rad(1.0), true, arcsPaint);
*/
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return true;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) {
    // TODO: implement shouldRebuildSemantics
    //return super.shouldRebuildSemantics(oldDelegate);
    return true;
  }

  // Вызывается при изменении цикла (в частности, при изменении tempo)
  // @param cycle Новый цикл.
  // В теории может никак не быть свзязан со старым, но
  // это пока не тестировалось.
  // Работает корректно при изменении длин эластиков (изменении темпа)

  void resetAngles(BipPauseCycle cycle)
  {
    this.bipPauseCycle = cycle;
    setAngles();
  }

  void setAngles()
  {
    if (bipPauseCycle == null || bipPauseCycle.cycle.length <= 0)
      return;

    length = bipPauseCycle.cycle.length;
    totalDurInt = 0;  //Игнорируем дробные части
    for (int i = 0; i < length; i++)
      totalDurInt += bipPauseCycle.cycle[i].len;
    if (totalDurInt == 0)
    {
      return;
    }
    // Получаем углы.
    samplesToDegree = 360.0 / totalDurInt;
    anglesDeg = new List<double>(length + 1);
    anglesRad = new List<double>(length + 1);
    anglesRad[0] = anglesDeg[0] = 0.0;
    anglesDeg[length] = 360.0;
    anglesRad[length] = 2 * pi;
    for (int i = 1; i < length; i++)
    {

      anglesDeg[i] = anglesDeg[i - 1] + (samplesToDegree * bipPauseCycle.cycle[i-1].len);
      // С ног на голову...
      anglesRad[i] = deg2rad(anglesDeg[i]);
    }
    print('setAngles: $length : $anglesRad');
  }

  double deg2rad(double angle) => angle * pi / 180.0;
}
