///
/// Всё познается в движении. Нужно приматывать анимашку.
///

import 'dart:math';
import 'package:flutter/material.dart';

///Как анимируем активную поддолю
enum ActiveNoteType{
  ///Элиипс активной ноты рисуется с тем же центом
  headFixed,
  ///Штиль активной ноты неподвижен
  stemFixed,
  ///Всё неподвижно, вокруг активной ноты +разлетается херня
  explosion
}

class NoteWidget extends StatefulWidget {
  // TODO IS: Remove old comments

  ///number of subdivisions, numerator
  final int subDiv;

  final List<int> accents;

  /// Note duration, denominator
  /// 2 <= note <= 64
  final int denominator;

  /// Active subdivision
  /// Owl is playing: 0 <= active < subDiv
  /// Before: active < 0
  /// After: subDiv < active
  final int active;

  /// Note's colors:
  /// Цвет сыгранной ноты, цвет несыгранной
  final Color colorPast, colorNow, colorFuture, colorInner;

  final ActiveNoteType activeNoteType;

  NoteWidget({
    this.subDiv,
    this.accents,
    this.denominator,
    this.active,
    this.colorPast = Colors.blue,
    this.colorNow = Colors.pink,
    this.colorFuture = Colors.black,
    this.colorInner = Colors.yellow,
    this.activeNoteType
  });

  @override
  _NoteState createState() => _NoteState();
}

class _NoteState extends State<NoteWidget> {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: NotePainter(widget.denominator, widget.subDiv, widget.accents, widget.active,
        widget.colorPast, widget.colorNow, widget.colorFuture, widget.colorInner, widget.activeNoteType),
    );
    //TODO Шаблон для рисования красивого флажка
     /* 
    return Stack(
      children: [
      Image.asset('images/32nd_note.svg.png'),
      CustomPaint(
        painter: NotePainter(widget.denominator, widget.subDiv, widget.active,
          widget.colorPast, widget.colorNow,widget.colorFuture,widget.activeNoteType),
      )
    ]);
     */
  }
}



class NotePainter extends CustomPainter {
  /// denominator of the subdivision duration
  /// 0 < denominator
  final int denominator;

  /// Number of subdivisions, numerator
  /// DO NOT CONFUSE WITH NUMERATOR of musical signature
  /// 0 < subDiv
  final int subDiv;

  final List<int> accents;

  /// Active subdivision
  /// 0 < active <= subDiv
  ///   < 0 - еще не играли, все имеют цвет
  ///   0, .., subDiv-1 - есть активная
  ///   >= subDiv - нет активной
  final int active;

  ///[ОБЛАСТЬ ДЕЙСТВИЯ ЮРИКА --->]

  final ActiveNoteType activeNoteType;

  /// Note's colors
  /// Цвет сыгранной ноты, цвет играемой, цвет несыгранной.
  /// (сейчас определяется где-то в предке)
  final Color colorPast, colorNow, colorFuture;
  /// Note head gradient parameters
  //TODO
  /// Note head gradient parameters
  /// Gradient inner color
  final Color colorInner;// = Colors.yellow; //Colors.grey[700];
  /// Coefficient of gradient radius relating to note radius
  final double _coefGrad = 1.6;
  /// Gradient center shift along X-axis relating to note radius
  final double _coefGradSkewX = 0.15;

  /// Остальными значениями играть тут
  ///
  /// Следующие значения определяют раскладку на канвасе
  /// //ToDo: См. файл с разлиновкой

  /// ширина флага, logical pixels
  final double _widthStem = 1;

  ///толщина границы полый ноты и толщина её штиля.
  ///почему-то у ноты 1/2 принято рисовать штиль тоньше, чем у других, хз почему, но придется сделать.
  final double _widthHollowStem = 1;

  /// Не должен быть меньше, чем _widthHollowStem - иначе будет некрасиво
  final double _widthHollowHeadBoundary = 1;
  /// Угол наклона длинной оси головки ноты в радианах (CCW < 0)
  final double _headAngle = -0.4;
  /// Масштаб внутреннего эллипса головки половинной ноты по осям (X, Y)
  final double _innerScaleX = 0.9;
  final double _innerScaleY = 0.5;

  /// абсолютное значение в пикселях
  final double _tupletBracketLineWidth = 1;

  ///Ниже идут значения относительно высоты

  ///вертикальный радиус ноты (относительно высоты)
  final double _relRadius = 0.1;

  ///во сколько раз горизонтальный радиус ноты длинее
  final radiusRatio = 828.0 / 505;

  ///Во сколько раз увеличивается активная нота
  ///Также используется для explosion mode, когда вместа увеличения
  ///ноты разлетается вокруг ноты всякая фигня (тогда этот параметр определяет
  ///радиус поражения)
  final double _bigRadiusMultiplier = 1.4;

  ///Низ зоны флагов
  final double _relFlagsZoneBottom = 0.45;//0.4 //VG

  ///!!! СЛОЖНОЕ МЕСТО... Непонятно: ширина штиля и пространство
  ///медлу ними должны ли масштабироваться? Пока принято решение, что да.
  ///
  ///Вторая сложность техническая - фдашлв может быть много.
  ///Зона для них фиксирована. Она заполняется
  ///снизу вверх, если не помещаемся - флаги и пространство
  ///между ними сжимаются. Из зоны не вылезаем. Играем 1/256 смело!!!

  /// несжатая толщина флага относительно высоты
  final double _relWidthFlag = 0.04;//0.06 //VG

  /// несжатое пространство между флагами относительно высоты
  final double _relSpaceBetweenFlag = 0.03;//0.04 //VG

  /// Относительная высота простого флага сравнительно с высотой штиля
  final double _relFlagHeight = 0.6;
  /// Относительный аспект простого флага = (высота / ширина) * 2
  /// 1 соответствует отношению сторон = 2
  final double _flagAspect = 1.2;

  ///от верхнего флага/скобки до числа
  final double _relSpaceBelowNumber = 0.00;

  ///высота текста-числа
  final double _relNumberHeight = 0.2;

  ///
  ///Значения для случая скобки (половинные и четвертные ноты):
  ///

  ///Отступ от половинной-четвертной ноты до скобки
  final double _spaceBelowTupletBracket = 0.1;

  ///Высота боковых загибов скобки
  final double _relTupletBracketHeight = 0.1;

  ///
  ///Параметры взрыва
  ///

  ///Толщина линий вокруг активной ноты
  final double _explosionLineWidth = 3;

  ///Число линий взрыва
  final int _numberOfExplosionLines = 16;

  final Color colorExplosion = Colors.redAccent;

  ///Зазор линии взрыва от ноты
  final double _startLineMultiplier = 1.4;

  ///[<---- ОБЛАСТЬ ДЕЙСТВИЯ ЮРИКА.   ]

  ///Отступы от краёв, где ничего не рисуется; логические пиксели(!)
  final double _safeX = 0;

  ///слева-справа
  //_safeTop = 0,_safeBottom = 0;


  // Auxiliary variables
  //
  Paint _paintFilledNote;
  Paint _paintHallowNote;
  Paint _paintStem;
  Paint _paintStemForHallow;
  Paint _paintFlag;
  Paint _paintSubdivFlag;
  Paint _paintExplosion;

  ///Степень двойки, определяющая написание одной ноты
  ///Наибольшее n такое, что 2^n <= denominator, то есть целая часть log_2(denominator)
  int _noteExponent; //Todo:final - move _setNoteBase to constructor?
  int _nmbOfFlags;

  bool _isPowerOf2;

  double _radius;
  double _radiusBig;
  double _noteCenterY;
  ///Верх ноты, верх зоны флагов
  double _flagsZoneTop;

  ///низ зоны флагов
  double _flagsZoneBottom;

  ///Во сколько приходится сжать флаги, чтобы попасть в область флагов при их большом количестве
  double _flagsRatio;

  double _flagWidth;
  double _deltaHforFlag;

  List<Offset> _explosionCoordinates1;
  List<Offset> _explosionCoordinates2;

  ///TODO:
  ///Часть констант должна вычисляться один раз
  ///И наоборот, я не понимаю, почему значение active должно быть final
  NotePainter([this.denominator, this.subDiv, this.accents, this.active,
    this.colorPast, this.colorNow, this.colorFuture, this.colorInner, this.activeNoteType]);

  ///Рисуем одну четвертную/половинную нотку.
  /// isHallow - пустая внутри
  void _drawNakedNote(Canvas canvas, int sub,
      Offset centerHead, double radiusHead, double stemTop,
      Color color, bool isFilled) {

    ///Head of the note
    Rect rect = Rect.fromCenter(center: Offset.zero,
      width: 2 * radiusHead,
      height: 2 * radiusHead / radiusRatio);

    final Rect rcGrad = Rect.fromCenter(
      center: Offset.zero.translate(_coefGradSkewX * radiusHead, 0),
      width: _coefGrad * 2 * radiusHead,
      height: _coefGrad * 2 * radiusHead / radiusRatio);

    //TODO --Colors.white
    final Shader _headGradient = new RadialGradient(
      colors: <Color>[colorInner, color],
    ).createShader(rcGrad);
    _paintFilledNote.shader = _headGradient;

    if (isFilled)
    {
      ///Filled
      //_paintFilledNote.color = color;
      //canvas.drawCircle(centerHead, radiusHead, _paintFilledNote);
      // Draw stem
      Offset off = centerHead.translate(radiusHead - 0.5 * _widthStem, 0);
      canvas.drawLine(off, off.translate(0, stemTop - off.dy), _paintStem);
      // Draw head
      canvas.save();
      canvas.translate(centerHead.dx, centerHead.dy);

      final double heightAccent2 = 2.0 * _widthStem;
      if (accents != null && sub < accents.length)
        for (int i = 0; i < accents[sub]; i++)
        {
          final Rect rc = rcGrad;
          final Offset offL = rc.bottomLeft.translate(0, 2.5 * heightAccent2 * i).translate(2, 0);
          final Offset offR = rc.bottomRight.translate(0, 2.5 * heightAccent2 * i).translate(-2, 0);
          canvas.drawLine(offL, offR + Offset(0, heightAccent2), _paintStem);
          canvas.drawLine(offL + Offset(0, 2 * heightAccent2), offR + Offset(0, heightAccent2), _paintStem);
        }

      canvas.rotate(_headAngle);
      canvas.drawOval(rect, _paintFilledNote);
      canvas.restore();
    }
    else
    {
      ///Hollow
      _paintHallowNote.color = color;
      //canvas.drawCircle(centerHead, radiusHead-0.5 * _widthHollowHeadBoundary, _paintCircle);

      Path pathInner = new Path()
        ..addOval(
          Rect.fromCenter(center: Offset.zero,
            width: _innerScaleX * 2 * radiusHead,
            height: _innerScaleY * 2 * radiusHead / radiusRatio
          )
        );
      Path pathOuter = new Path()
        ..addRect(
          Rect.fromCenter(center: Offset.zero,
            width: 2 * rect.width,
            height: 2 * rect.height
          )
        );

      // Draw stem
      Offset off = centerHead.translate(radiusHead - 0.5 * _widthHollowStem, 0);
      canvas.drawLine(off, off.translate(0, stemTop - off.dy), _paintStemForHallow);
      // Draw hollow head
      canvas.save();
      canvas.translate(centerHead.dx, centerHead.dy);
      canvas.rotate(_headAngle);
      canvas.clipPath(Path.combine(PathOperation.difference, pathOuter, pathInner));
      canvas.drawOval(rect, _paintFilledNote);
      canvas.restore();
    }
  }


  ///Рисуем ноту номер sub обычной формы
  _drawRegularFormNote(Canvas canvas, int sub) {
    Color color;
    if (sub < active) color = colorPast;
    if (sub == active) color = colorNow;
    if (sub > active) color = colorFuture;
    _drawNakedNote(canvas, sub,
        new Offset(_noteCenterX(sub), _noteCenterY),
        _radius, _flagsZoneTop, color, (_noteExponent > 1));
  }

  ///Обсчитываем сразу всякие углы, чтобы каждый раз этого не делать.
  _initExplosionMathematics(){
    _explosionCoordinates1 = new List<Offset>(_numberOfExplosionLines);
    _explosionCoordinates2 = new List<Offset>(_numberOfExplosionLines);
    if (_numberOfExplosionLines<1) return;
    double rot = pi * 2/_numberOfExplosionLines;
    for(int i = 0; i<_numberOfExplosionLines; i++){
      double angle = rot * i;
      double s = sin(angle); double c = cos(angle);
      _explosionCoordinates1[i] = new Offset(
        c * _radius * _startLineMultiplier,s * _radius * _startLineMultiplier
      );
      _explosionCoordinates2[i] = new Offset(
          c * _radiusBig * _startLineMultiplier,s * _radiusBig * _startLineMultiplier
      );
    }
  }
  ///Рисуем вокруг активной ноты
  _drawExplosion1(Canvas canvas) {
    //ToDO:
    for(int i = 0; i<_numberOfExplosionLines; i++)
      {
        canvas.drawLine(_explosionCoordinates1[i].translate(_noteCenterX(active),_noteCenterY),
            _explosionCoordinates2[i].translate(_noteCenterX(active),_noteCenterY),
         _paintExplosion
        );
      }
  }

  _drawNotes(Canvas canvas) {
    for (int i = 0; i < subDiv; i++)
      if (i != active)
        _drawRegularFormNote(canvas, i);

    if (active >= 0 && active < subDiv)
    {

      ///Рисуем активную ноту
      double activeCenterX = _noteCenterX(active);
      double activeRadius = _radiusBig;

      switch (activeNoteType) {
        case ActiveNoteType.headFixed:
          break;
        case ActiveNoteType.stemFixed:
          activeCenterX -= _radiusBig - _radius;
          break;
        case ActiveNoteType.explosion:
          activeRadius = _radius;
          break;
        default:
      }
      _drawNakedNote(canvas, active,
         new Offset(activeCenterX, _noteCenterY),
         activeRadius, _flagsZoneTop, colorNow, _noteExponent > 1);
      if (activeNoteType == ActiveNoteType.explosion)
        _drawExplosion1(canvas);
    }
  }

  Path _curvedFlag(double height, double aspect)
  {
    Path path = new Path();
    //path.fillType = PathFillType.nonZero;
    if (aspect < 0)
      return path;

    double width = height / aspect;

    // TODO Make round end
    path.moveTo(0, 0);
    // Handpicked magic numbers
    double yEnd = 0.35;
    path.cubicTo(0 * width, 0.3 * height, 0.75 * width, 0.6 * height, 0.5 * width, height);
    path.cubicTo(0.6 * width, 0.8 * height, 0.4 * width, 0.6 * height, 0 * width, yEnd * height);
    path.close();
    return path;
  }

  void _drawCurvedFlags(Canvas canvas)
  {
    if (_nmbOfFlags == 0)
      return;

    double flagHeight = _relFlagHeight * (_noteCenterY - _flagsZoneTop);
    double x = _noteCenterX(0) + _radius;
    double y = _flagsZoneTop;
    double dy =  0.3 * flagHeight;  // Handpicked magic number <= yEnd

    Path path = _curvedFlag(flagHeight, _flagAspect);

    for (int i = 0; i < _nmbOfFlags; i++, y += dy)
      canvas.drawPath(path.shift(new Offset(x, y)), _paintFlag);
  }

  void _drawVerticalFlags(Canvas canvas){
    if (_nmbOfFlags == 0)
      return;

    double rad;

    double left = _noteCenterX(0);
    if ((0 == active)&&(activeNoteType == ActiveNoteType.headFixed))
      ///Смешаем левую границу флагов
      {rad = _radiusBig;} else {rad = _radius;}

    left += rad;

    double right = _noteCenterX(subDiv-1);
    if ((subDiv-1 == active)&&(activeNoteType == ActiveNoteType.headFixed))
    ///Смещаем правую границу флагов
        {rad = _radiusBig;} else {rad = _radius;}
    right += rad;

    double y = _flagsZoneBottom+_flagWidth * 0.5;

    for(int i = 0;i<_nmbOfFlags;i++) {
      Offset off = new Offset(left, y);
      canvas.drawLine(off, off.translate(right - left, 0), _paintSubdivFlag);
      y  -=  (_flagWidth + _deltaHforFlag);
    }
  }

  /// X-координата центра поддоли
  double _noteCenterX(int subDivN){
    return _safeX+
        (subDivN+1) * ((size.width- (_safeX+_safeX))/(subDiv+1));
  }

  _init()
  {
    ///Определяем тип базовой ноты
    int n = 1;
    int exp = 0;
    ///Может, есть и умнее код, но я боюсь
    ///слишком затейливой кроссплатформенной битовой арифметики, сорри.
    while (n <denominator)
    {
      n = n << 1;
      exp += 1;
    }
    _isPowerOf2 = n == denominator;
    _noteExponent = exp;
    _nmbOfFlags = max(_noteExponent - 2, 0);

    ///
    ///Геометрия
    ///

    _radius = size.height * _relRadius;
    _radiusBig = _radius * _bigRadiusMultiplier;
    _noteCenterY = size.height-_radiusBig;

    double claimedSpaceForFlags = max(0, _nmbOfFlags - 1) * (_relSpaceBetweenFlag + _relWidthFlag);
    double presentSpaceForFlags = _relFlagsZoneBottom - (_relNumberHeight + _relSpaceBelowNumber);
    _flagsRatio = 1;
    if (claimedSpaceForFlags > presentSpaceForFlags)
      _flagsRatio = presentSpaceForFlags / claimedSpaceForFlags;

    _flagsZoneBottom = _relFlagsZoneBottom * size.height;

    ///Определяем реальную высоту, где кончатся флаги (и ноты)
    double relFlagTop = max(_relNumberHeight + _relSpaceBelowNumber,
      _relFlagsZoneBottom - claimedSpaceForFlags);
    _flagsZoneTop = relFlagTop * size.height;

    _flagWidth = _relWidthFlag * _flagsRatio * size.height;
    _deltaHforFlag = _relSpaceBetweenFlag * _flagsRatio * size.height;

    ///Стили рисования нот, штилей, флагов и т.п.

    _paintFilledNote = new Paint()
      ..style = PaintingStyle.fill;

    _paintStem = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _widthStem
      ..color = colorPast;

    _paintHallowNote = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _widthHollowHeadBoundary;

    _paintStemForHallow = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _widthHollowStem
      ..color = colorPast;

    _paintFlag = new Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = _flagWidth
      ..color = colorPast;

    _paintSubdivFlag = new Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _flagWidth
      ..color = colorPast;

    _paintExplosion = new Paint()
      ..color = colorExplosion
      ..style = PaintingStyle.stroke
      ..strokeWidth = _explosionLineWidth
      ..strokeCap = StrokeCap.round;

    ///Обсчитываем один раз всю математику
    _initExplosionMathematics();
  }

  Size size;

  @override
  void paint(Canvas canvas, Size size) {

    ///ToDo: move to constructor, make constants final?
    this.size = size;
    _init();

    ///Если нот несколько - вертикальные черты, или скоба для нот 1/2,1/4; число сверху
    _drawNotes(canvas);

    if (subDiv > 1)
      _drawVerticalFlags(canvas);
    else  // Single note
      _drawCurvedFlags(canvas);

    if (!_isPowerOf2) {
        Offset off = new Offset(size.width * 0.5,
          _flagsZoneTop-
              _relSpaceBelowNumber * size.height
              -size.height * _relNumberHeight * 0.5);

        //canvas.drawCircle(off, size.height * _relNumberHeight * 0.5, _paintHallowNote);

        TextSpan span = new TextSpan(
            style: new TextStyle(color: colorPast,
            fontSize:  size.height * _relNumberHeight,),
            text: subDiv.toString());
        TextPainter tp = new TextPainter(text: span,
            textDirection: TextDirection.ltr);
        tp.layout();
        tp.paint(canvas,off.translate(tp.width * 0.25, -tp.height * 0.5));
      }

    //https://stackoverflow.com/questions/57224518/flutter-applying-shadows-to-custompainted-widget
    //canvas.drawShadow();
    /*
    final Color shadowColor = Colors.black.withOpacity(0.15);

    Path shadowPath = Path();
    Paint shadowPaint = Paint();

    /// Points to make a semicircle approximation using Bezier Curve

    var shadowfirstendPoint = new Offset(endCurve-topSpace, 0.0);
    var shadowcontrolPoint1  = new Offset(startCurve+xValueInset+topSpace,yValueOffset);
    var shadowcontrolPoint2  = new Offset((diameter-xValueInset)+startCurve-topSpace,yValueOffset);

    //! Start sketching Shadow
    shadowPath.lineTo(startCurve+topSpace, 0.0);
    shadowPath.cubicTo(shadowcontrolPoint1.dx, shadowcontrolPoint1.dy,
      shadowcontrolPoint2.dx, shadowcontrolPoint2.dy,
      shadowfirstendPoint.dx, shadowfirstendPoint.dy);
    shadowPath.lineTo(size.width, 0.0);
    shadowPath.lineTo(size.width, size.height);
    shadowPath.lineTo(0.0, size.height);
    shadowPath.close();

    //! End Sketching Shadow
    shadowPaint.color = shadowColor;
    canvas.drawPath(shadowPath, shadowPaint);
    */

    ///ToDo: отладка, убрать
    if (false)
    {
      TextSpan span = new TextSpan(style: new TextStyle(color: colorPast),
          text: "denominator: " + denominator.toString() +
              ";\n subDiv: " + subDiv.toString() +
              "; active: " + active.toString() +
              "; noteExponent: " + _noteExponent.toString()
      );
      TextPainter tp = new
      TextPainter(text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, new Offset(0, 1.1 * size.height));
    }
  }

  @override
  bool shouldRepaint(NotePainter oldDelegate) {
    return this.denominator != oldDelegate.denominator ||
      this.subDiv != oldDelegate.subDiv ||
      this.active != oldDelegate.active ||
      this.colorPast != oldDelegate.colorPast ||
      this.colorNow != oldDelegate.colorNow ||
      this.colorFuture != oldDelegate.colorFuture ||
      this.activeNoteType != oldDelegate.activeNoteType;
  }
}
