import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';  // for Colors
import 'package:flutter/widgets.dart';

import 'BipPauseCycle.dart';

class BarrelOrgan extends StatefulWidget
{
  BarrelOrganState barrelOrganState;

  BarrelOrgan(BipPauseCycle cycle, int latency)
  {
    print("============444444444444444========================================");
    print(latency);
    print(cycle);
    barrelOrganState?.setCycle(cycle, latency);
  }

  void setCycle(BipPauseCycle cycle, int latency)
  {
    barrelOrganState?.setCycle(cycle, latency);
  }

  void setTempo(int tempoBpM, int denominator)
  {
    barrelOrganState?.setTempo(tempoBpM, denominator);
  }

  void play()
  {
    barrelOrganState?.play();
  }

  @override
  BarrelOrganState createState()
  {
    print("============33333333333333333========================================");
    return barrelOrganState = BarrelOrganState(bipPauseCycle: null, latencyInFrames: null);
  }
}

enum AnimationDirection
{
  Forward,
  Backward
}

class BarrelOrganState extends State<BarrelOrgan> with SingleTickerProviderStateMixin
{
  BipPauseCycle bipPauseCycle;
  int latencyInFrames;
  BarrelOrganPainter painter;
  bool isAnimating = false;
  AnimationDirection direction = AnimationDirection.Forward;

  BarrelOrganState({this.bipPauseCycle, this.latencyInFrames})
  {
    print("=======BarrelOrganStateBarrelOrganStateBarrelOrganState=========");
  }

  void setCycle(BipPauseCycle cycle, int latency)
  {
    bipPauseCycle = cycle;
    latencyInFrames = latency;
    painter?.setCycle(bipPauseCycle, latencyInFrames);
  }

  void setTempo(int tempoBpM, int denominator)
  {
    if (tempoBpM > 0 && denominator > 0)
    {
      //int realBPM = bipPauseCycle?.setTempo(new Tempo(beatsPerMinute: tempoBpM, denominator: denominator));
      painter?.setCycle(bipPauseCycle, latencyInFrames = 0);

      int totalDurInt = 0;  //Игнорируем дробные части
      int length = bipPauseCycle.cycle.length;
      for (int i = 0; i < length; i++) {
        totalDurInt += bipPauseCycle.cycle[i].l;
      }

      int dur = (totalDurInt * 1000) ~/ 48000;
      int dur1 = (totalDurInt * 60000) ~/ (48000 * tempoBpM / denominator);
      //print('REALDURSTIPN: $totalDurInt,  $dur, $tempoBpM, $denominator');
      print('REALDUR_SETTEMPO2: $totalDurInt,  $dur, $dur1, $tempoBpM, $denominator');

      controller.duration = new Duration(milliseconds: dur);
      if (controller.status == AnimationStatus.forward ||
        controller.status == AnimationStatus.reverse)
      {
        controller.stop();
        controller.forward();
      }

      print("Duration");
      print(controller.duration);
    }
  }

  void play()
  {
    if (painter != null)
    {
      //bipPauseCycle.duration / 48000;
      print("controller.isAnimating: ${controller.isAnimating}");
      if (isAnimating)
      {
        controller.stop();
      }
      else
      {
        controller.reset();
        if (direction == AnimationDirection.Forward)
          controller.forward();
        else if (direction == AnimationDirection.Backward)
          controller.reverse();
      }
      isAnimating = !isAnimating;
    }
  }

  double percentage = 0.0;
  double newPercentage = 100.0;
  AnimationController controller;
  Animation<double> _angleAnim;

  @override
  void initState() {
    super.initState();
    print("=======initStateinitStateinitStateinitStateinitState=========");
    isAnimating = false;

    controller = new AnimationController(
      lowerBound: 0.0,
      upperBound: 1.0,
      vsync: this,
      duration: new Duration(milliseconds: 1000),
    )
      ..addListener((){
        setState(() {
          percentage = lerpDouble(percentage,newPercentage,controller.value);
          //painter.time = lerpDouble(0, 2 * pi, controller.value / 60);
          percentage = controller.value;
          //painter.time = controller.value;
          //if (painter != null)
            //painter.time = _angleAnim.value;
          print('ANIM: ${controller.value}, ${_angleAnim.value}');
        });
      })
    ..addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed) {
        controller.reset();
        controller.forward();
        //controller.reverse();
        direction = AnimationDirection.Forward;
      }
      else if (status == AnimationStatus.dismissed)
      {
        controller.forward();
        direction = AnimationDirection.Forward;
      }
      else
        ;
    });
    _angleAnim = new Tween(begin: 0.0, end: 2 * pi).animate(controller);
  }

  @override
  Widget build(BuildContext context)
  {
    print("=======build=========");
    print(latencyInFrames);
    if (bipPauseCycle != null)
      print(bipPauseCycle.cycle.length);

    print("BarrelOrganPainter.BarrelOrganPainter.value");
    print(controller.value);
    painter = new BarrelOrganPainter(bipPauseCycle: bipPauseCycle, latencyInFrames: latencyInFrames, time: _angleAnim.value);

    return Center(
      child: Container(
        width: 300,
        height: 300,
        child: CustomPaint(
          painter: painter
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

class BarrelOrganPainter extends CustomPainter
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

  double time = 0.0;

  BarrelOrganPainter({this.bipPauseCycle, this.latencyInFrames, this.time,
    this.lineColor = Colors.blue, this.arcColor = Colors.black,
    this.lineWidth = 3, this.arcWidth = 3})
  {
    print('BarrelOrganPainter()');
    setAngles();
    print(latencyInFrames);
    print("BarrelOrganPainter.value");
    print(time);
  }

  void setCycle(BipPauseCycle cycle, int latency)
  {
    bipPauseCycle = cycle;
    latencyInFrames = latency;
    print('setCycle');
    setAngles();
  }

  @override
  void paint(Canvas canvas, Size size) {
    //canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
    //canvas.drawColor(Color.WHITE);
    print('WAIT ${this.time}');

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
    Paint circlePaint = new Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    Offset center = new Offset(size.width / 2, size.height / 2);
    double radius = 3 * min(center.dx, center.dy) / 4;
    Rect rect = new Rect.fromCircle(center: center, radius: radius);

    rotateAngleRad = deg2rad(90.0) - this.time;

    // Arrow
    Rect circle = new Rect.fromCircle(center: center, radius: radius);

    canvas.drawArc(circle, deg2rad(89.5), deg2rad(1.0), true, arcsPaint);
    //canvas.drawArc(circle, rotateAngleRad - deg2rad(5.0), deg2rad(10.0), false, arcsPaint);

    print("=============================-------------------=================================");
    print(latencyInFrames);
    print(this);

    if (bipPauseCycle == null || bipPauseCycle.cycle.length <= 0){
      canvas.drawCircle(center, radius, circlePaint);
      return;
    }

    print("controller.time");
    print(time);

    print("=============================*******************=================================");
    print(bipPauseCycle.duration);
    //latencyInFrames = this.time.toInt();

    totalPlayed = 0;
    for (int i = 0; i < bipPauseCycle.position.n; i++)
      totalPlayed += bipPauseCycle.cycle[i].l;
    totalPlayed += bipPauseCycle.position.offset;
    print('totalPlayed: $totalPlayed');
    double rotateAngleDeg = 90.0 + samplesToDegree * (latencyInFrames - totalPlayed);
    //rotateAngleRad = deg2rad(rotateAngleDeg);
    //rotateAngleRad = -this.time;
    print("rotateAngleRad $rotateAngleDeg, $latencyInFrames, $totalPlayed, $length");
    //rotateAngleRad = 0;

    for (int i = 0; i < length; i++)
    {
      print("$i / ${bipPauseCycle.cycle[i].a}");
      if (bipPauseCycle.cycle[i].a != bipPauseCycle.elasticSymbol)
      {
        // canvas.drawArc(oval, anglesDeg[i]+rotateAngleDeg, anglesDeg[i + 1] - anglesDeg[i], true, paint);
        //ToDo: лишний счет
        Offset p0 = new Offset(radius * cos(anglesRad[i] + rotateAngleRad),
            radius * sin(anglesRad[i] + rotateAngleRad));
        Offset p1 = new Offset(radius * cos(anglesRad[i + 1] + rotateAngleRad),
            radius * sin(anglesRad[i + 1] + rotateAngleRad));
        //canvas.drawLine(center + p0, center + p1, linesPaint);
        canvas.drawArc(rect, anglesRad[i] + rotateAngleRad, anglesRad[i + 1] - anglesRad[i], false, linesPaint);
/*
        Offset p00 = new Offset(center.dx + radius * cos(anglesRad[i] + rotateAngleRad),
          center.dy + radius * sin(anglesRad[i] + rotateAngleRad));
        Offset p10 =new Offset( center.dx + radius * cos(anglesRad[i + 1] + rotateAngleRad),
          center.dy + radius * sin(anglesRad[i + 1] + rotateAngleRad));
        canvas.drawLine(p0, p1, linesPaint);
*/
      }
    }

    print(time);

    double angle = this.time;
    Offset end = new Offset(sin(angle), cos(angle));
    //canvas.drawLine(center, center - end * radius, arcsPaint);
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
    print('resetAngles');
    setAngles();
  }

  void setAngles()
  {
    print("setAnglessetAnglessetAnglessetAnglessetAngles");
    if (bipPauseCycle == null || bipPauseCycle.cycle.length <= 0)
      return;

    length = bipPauseCycle.cycle.length;
    totalDurInt = 0;  //Игнорируем дробные части
    print('setAngles2');
    for (int i = 0; i < length; i++) {
      totalDurInt += bipPauseCycle.cycle[i].l;
      print(bipPauseCycle.cycle[i].l);
    }
    if (totalDurInt == 0) {
      print("totalDurInttotalDurInttotalDurInt");
      return;
    }

    // Получаем углы.
    samplesToDegree = 360.0 / totalDurInt;
    anglesDeg = new List<double>(length + 1);
    anglesRad = new List<double>(length + 1);
    anglesRad[0] = anglesDeg[0] = 0.0;
    anglesDeg[length] = 360.0;
    anglesRad[length] = 2 * pi;
    print("Angles");
    for (int i = 1; i < length; i++)
    {

      anglesDeg[i] = anglesDeg[i - 1] + (samplesToDegree * bipPauseCycle.cycle[i-1].l);
      // С ног на голову...
      anglesRad[i] = deg2rad(anglesDeg[i]);
      print("${anglesRad[i]}");
    }

    print("setAngles $length, $totalDurInt, $samplesToDegree");
  }

  double deg2rad(double angle) => angle * pi / 180.0;
}
