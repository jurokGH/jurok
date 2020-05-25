import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'dart:ui' as ui;

///Рисуем радиусы.
const bool showRadii = false;



class KnobValue {
  ///угол между пальцем и отрисованным изображением в момент нажатия
  /// -pi, pi
  // double deltaAngle;
  ///угол нажатия
  double tapAngle;

  ///Общий угол в момент тапа
  ///-inf,inf
  double absoluteAngleAtTap;

  ///Общий угол
  ///-inf,inf
  double absoluteAngle;

  ///Начальные условия
  double value0;
  double angle0;

  double value; //ToDo:  value <-> angle

  bool pushed;

  int initTimeOfTap;
/*
  KnobValue(double val, double absAngle){
    this.value=val; this.absoluteAngle=absAngle;

    this.absoluteAngleAtTap=absoluteAngle;//ToDo: ???
    this.tapAngle=absoluteAngle;
    this.deltaAngle=0;
  }*/

  //KnobValue({this.value,this.deltaAngle,this.tapAngle,this.absoluteAngle,
  KnobValue(
      {@required this.pushed,
      this.value,
      this.tapAngle,
      this.absoluteAngle,
      this.absoluteAngleAtTap,
      this.value0,
      this.angle0,
      this.initTimeOfTap});
}

class KnobTuned extends StatefulWidget {
  final int timeToDilation;

  final double innerRadius;
  final double outerRadius;

  final double diameter;

  //final double value;
  //final double initValue;
  // /значение намотанного угла, где отображается картинка
  //final double angle;

  final double minValue;
  final double maxValue;

  final KnobValue knobValue;

  final ValueChanged<KnobValue> onChanged;
  final TextStyle textStyle;

  final double sensitivity; //size/2*pi;

  final double pushFactor;

  //final ui.Image image;

  KnobTuned({
    @required this.pushFactor,
    @required this.knobValue,
    @required this.minValue,
    @required this.maxValue,
    @required this.diameter,
    @required this.onChanged,
    @required this.sensitivity,
    @required this.innerRadius,
    @required this.outerRadius,
    @required this.timeToDilation,
    this.textStyle,
    //@required this.image
  });

  /*
  KnobTuned({@required this.value,
    @required this.initValue,
    @required this.angle,
    @required this.minValue,
    @required this.maxValue,
    @required this.diameter,
    @required this.onChanged,
  });*/

  @override
  State<StatefulWidget> createState() => KnobTunedState();
}

class KnobTunedState extends State<KnobTuned> {
  /*double angleRad(Offset X){
    double ang=pi/4;
    if (X.dx==0) {       if (X.dy>0) {ang*=-1; } }
    else {ang =
     }
    return ang;
  }*/

  Offset X;
  Offset Y;

  Image _image;

  /// Knob image
  Size _imageSize = Size.zero;

  double getValueUncut(double absAngle, double ang0, double val0) {
    double size = widget.diameter != null
        ? widget.diameter
        : MediaQuery.of(context).size.shortestSide; //ToDo:???

    return val0 + (absAngle - ang0) / (2 * pi) * size / widget.sensitivity;
  }

  double getValue(double absAngle, double ang0, double val0) {
    return max(min(getValueUncut(absAngle, ang0, val0), widget.maxValue),
        widget.minValue);
  }

  /*double getAngle(Offset off) {
    /*double size = widget.diameter != null
        ? widget.diameter
        : MediaQuery.of(context).size.shortestSide;*/
    double radius =  widget.diameter / 2;
    Offset center = new Offset(radius, radius);
    return (off - center).direction;
  }*/

  @override
  void initState() {
    super.initState();

    _image = new Image.asset(
      'images/knob4.png',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  Widget build(BuildContext context) {
    //print('Knob::build');
    double size = widget.diameter != null
        ? widget.diameter
        : MediaQuery.of(context).size.shortestSide; //TODO

    double factor = 1;
    if (widget.knobValue.pushed) {
      double d = widget.pushFactor - 1;
      int dTime = DateTime.now().millisecondsSinceEpoch - widget.knobValue.initTimeOfTap;
      if (widget.timeToDilation > 0) {
        double d1 = d * min(1, dTime / widget.timeToDilation);
        factor = 1 + d1;
      }
      else factor=widget.pushFactor;
      //size*=(1+d1);
      //size*=(widget.pushFactor);
    }

    size = size * factor;

    final Size imageSize = new Size.square(size);
    if (imageSize != _imageSize) {
      precacheImage(_image.image, context, size: imageSize);
      _imageSize = imageSize;
    }

    return Center(
      child: Container(
        height: size,
        width: size,
        child: GestureDetector(
          onPanEnd: (DragEndDetails details) {
            //Это нужно, чтобы не было
            //дерганий на короткие тапы
            KnobValue newVal = KnobValue(
              pushed: false,
              value: widget.knobValue.value,
              tapAngle: null,
              absoluteAngle: widget.knobValue.absoluteAngle,
              initTimeOfTap:
                  widget.knobValue.initTimeOfTap, //Не обязательно, видимо
            );
            widget.onChanged(newVal);
            print('onPanEnd\n--------');
          },
          onPanStart: (DragStartDetails downDetails) {
            print('onPanStart');
          },
          onPanDown: (DragDownDetails downDetails) {
            print('onPanDown');

            double radius = widget.diameter / 2;
            Offset center = new Offset(radius, radius);
            Offset X = downDetails.localPosition - center;
            double angle = X.direction;
            //double angle=getAngle(cur);
            KnobValue newVal = new KnobValue(
              value: widget.knobValue.value,
              tapAngle: angle,
              /*deltaAngle: angle -
                    (widget.knobValue.absoluteAngle % (2 * pi)),*/
              absoluteAngle: widget.knobValue.absoluteAngle,
              absoluteAngleAtTap: widget.knobValue.absoluteAngle,
              value0: widget.knobValue.value,
              angle0: widget.knobValue.absoluteAngle,
              pushed: true,
              initTimeOfTap: DateTime.now().millisecondsSinceEpoch,
            );
            widget.onChanged(newVal);
            print(
                'AbsAngle at tap: ${newVal.absoluteAngle.toStringAsFixed(4)}');
            print('AbsAngle OF tap: ${newVal.tapAngle.toStringAsFixed(4)}');
          },
          onPanUpdate: (DragUpdateDetails details) {
            if (widget.knobValue.tapAngle == null) return;

            /*
             if (details.delta.distanceSquared < 1
             /*    ||
                cur.dx.abs() < 1 ||
                prev.dx.abs() < 1*///Непонятно. А если много точек на пиксель и тонкие пальцы?
             // А если сверху-вниз?
             )
              return;*/

            double radius = widget.diameter / 2;
            Offset center = new Offset(radius, radius);
            Offset X = details.localPosition - center;

            double radMin = radius * widget.innerRadius;
            double radMax = radius * widget.outerRadius;

            if ((X.distanceSquared >= radMin * radMin) &&
                (X.distanceSquared <= radMax * radMax)) {
              double angleNow = X.direction;
              double deltaNow = angleNow - widget.knobValue.tapAngle;
              if (deltaNow > pi) deltaNow -= 2 * pi;
              if (deltaNow < -pi) deltaNow += 2 * pi;
              double absoluteAngleNow =
                  widget.knobValue.absoluteAngleAtTap + deltaNow;

              //Ловим переход по кругу
              double orientationBound = pi / 2;
              double tapAngleCorrected = widget.knobValue.tapAngle;
              double absoluteAngleAtTapCorrected =
                  widget.knobValue.absoluteAngleAtTap;

              double deltaTap =
                  (angleNow % (2 * pi) - tapAngleCorrected % (2 * pi));

              if (deltaTap.abs() > orientationBound) {
                /*double compensate=orientationBound*deltaTap.sign;
                //deltaAngleCorrected-=compensate;
                tapAngleCorrected+=compensate;
                absoluteAngleAtTapCorrected+=compensate;*/

                tapAngleCorrected = angleNow;
                absoluteAngleAtTapCorrected = absoluteAngleNow;

                print('corrections');
                print(
                    'AbsAngle at tap: ${absoluteAngleAtTapCorrected.toStringAsFixed(4)}');
                print(
                    'AbsAngle OF tap: ${tapAngleCorrected.toStringAsFixed(4)}');
              }

              double valu0corr = widget.knobValue.value0;
              double angl0corr = widget.knobValue.angle0;
              double valCorr = getValue(absoluteAngleNow,
                  widget.knobValue.angle0, widget.knobValue.value0);
              if (getValueUncut(absoluteAngleNow, widget.knobValue.angle0,
                      widget.knobValue.value0) !=
                  valCorr) {
                valu0corr = valCorr;
                angl0corr = absoluteAngleNow;
              }

              KnobValue newVal = new KnobValue(
                //deltaAngle: deltaAngleCorrected,
                pushed: true,
                tapAngle: tapAngleCorrected,
                absoluteAngleAtTap: absoluteAngleAtTapCorrected,
                absoluteAngle: absoluteAngleNow,
                value: valCorr, //ToDo: это лишнее, не так

                value0: valu0corr,
                angle0: angl0corr,
                initTimeOfTap: widget.knobValue.initTimeOfTap,
              );
              widget.onChanged(newVal);
            }
          },

          child: Stack(alignment: Alignment.center, children: <Widget>[
            Transform.rotate(
                angle: widget.knobValue.absoluteAngle,
                //child: ClipOval(
                child: Container(
                    height: size,
                    width: size,
//                color: widget.color,
                    child: _image)
                //),
                ),

            Container(
              height: size,
              width: size,
              child: new CustomPaint(
                painter: KnobPainter(
                    widget.diameter,
                    widget.knobValue.absoluteAngle,
                    //widget.image,
                    widget.innerRadius,
                    widget.outerRadius //Отладочное
                    ),
              ),
            ),
            //tempoIndicator(widget.knobValue.value.toInt(),
            //   widget.minValue.toInt(),widget.maxValue.toInt(), 0.1* widget.diameter),
            Text(widget.knobValue.value.toInt().toString(),
                style: widget.textStyle.copyWith(
                  fontSize: widget.textStyle.fontSize * factor,
                )

                ///ISH: Думаю, это я по уродски сделал
                )
          ]),

          /* Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      //                Icon(pressed ? Icons.pause : Icons.play_arrow,
                      //                 size: 0.53 * size,
                      //                  color: widget.color,
                      //               ),
                      Text(widget.value.toInt().toString(),
                        style: TextStyle(color: Colors.white ,
                            fontSize:  26*size*FACTOR_OR_ZEBRA_WILL_COME_FOR_US,
                      ),
                    ]
                )*/
          //  ]
          //),
        ),
      ),
    );
  }
}

/*
Widget tempoIndicator(int tempo, int minTempo, int maxTempo, double size) {
  String s = 'Tempo: ${tempo.toString()}';
  if (tempo >= maxTempo) s += ' (MAX)';
  if (tempo<= maxTempo) s += ' (MIN)';
  return Text(s,
    style: TextStyle(fontSize: size,
      color: Colors.amberAccent,),);
}*/

//ToDo: отладочное; также можно использовать для рисования ui.Image на канве
class KnobPainter extends CustomPainter {
  KnobPainter(
      [this.diameter,
      this.angle,
      //this.image,
      this.innerRadius,
      this.outerRadius //Отладочное. Отрисовка области, где там не действует
      ]);

  final double radOfIndicator = 0.4;

  final double innerRadius;
  final double outerRadius;

  //final ui.Image image;

  double angle;
  double diameter;

  /* Offset X;
  Offset Y;*/

  Size size;
  Canvas canvas;
  @override
  void paint(Canvas canvas, Size size) {
    if (!showRadii) return;

    // if (Y==null) return;
    this.size = size;
    this.canvas = canvas;

    //Offset off = new Offset(size.width / 2, size.height / 2);

    Paint _paintHallowNote = new Paint();
    _paintHallowNote.style = PaintingStyle.stroke;
    _paintHallowNote.strokeWidth = 2;
    _paintHallowNote.color = Colors.blue;

    //Offset off1 =
    //  off.translate(diameter / 2 * cos(angle), diameter / 2 * sin(angle));
    //canvas.drawLine(off, off1, _paintHallowNote);

    Paint _paintNote = new Paint();
    //_paintNote.style = PaintingStyle.fill;
    _paintNote.style = PaintingStyle.stroke;
    _paintNote.color = Colors.redAccent;
    _paintNote.strokeWidth = 2;

    //double indicatorRad = diameter * (1 - radOfIndicator) / 2;
    // off1 = off.translate(indicatorRad * cos(angle), indicatorRad * sin(angle));
/*    Offset center =     new Offset(diameter/2, diameter/2);
*/
    // double angleToDraw=0;
    //if (Y!=center)  angleToDraw=(Y-center).direction;
    //off1 = off.translate(indicatorRad * cos(angle), indicatorRad * sin(angle));
    //canvas.drawCircle(off1, diameter / 2 * radOfIndicator, _paintNote);

    /*
     Paint paintForImage=new Paint();
     paintForImage.style = PaintingStyle.stroke;
     canvas.drawImage(image,off1.translate(-radOfIndicator,-radOfIndicator),
         paintForImage);*/

    canvas.drawCircle(Offset(size.width / 2, size.height / 2),
        diameter / 2 * innerRadius, _paintHallowNote);
    canvas.drawCircle(Offset(size.width / 2, size.height / 2),
        diameter / 2 * outerRadius, _paintHallowNote);
  }

  @override
  bool shouldRepaint(KnobPainter oldDelegate) {
    // TODO
    //return this != oldDelegate;
    return true;
  }
}
