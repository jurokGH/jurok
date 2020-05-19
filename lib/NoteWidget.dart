///
/// Всё познается в движении. Нужно приматывать анимашку.
///

import 'dart:math';
import 'package:flutter/material.dart';

import 'util.dart';

///Как анимируем активную поддолю
enum ActiveNoteType
{
  none,
  ///Элиипс активной ноты рисуется с тем же центром
  headFixed,
  ///Штиль активной ноты неподвижен
  stemFixed,
  ///Всё неподвижно, вокруг активной ноты +разлетается херня
  explosion
}

class NoteWidget extends StatefulWidget
{
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
  final Color colorPast, colorNow, colorFuture, colorInner, colorShadow;

  final ActiveNoteType activeNoteType;
  final Size size;
  final bool coverWidth;
  final bool showTuplet;
  final bool showAccent;
  final bool showShadow;
  final int maxAccentCount;

  NoteWidget({
    this.subDiv,
    this.accents,
    this.denominator,
    this.active,
    this.colorPast = Colors.blue,
    this.colorNow = Colors.pink,
    this.colorFuture = Colors.black,
    this.colorInner = Colors.yellow,
    this.colorShadow = Colors.black,
    this.activeNoteType,
    this.size = Size.zero,
    this.coverWidth = true,
    this.showTuplet = false,
    this.showAccent = false,
    this.showShadow = false,
    this.maxAccentCount = 3,
  });

  @override
  _NoteState createState() => _NoteState();
}

class _NoteState extends State<NoteWidget>
{
  @override
  Widget build(BuildContext context)
  {
    return CustomPaint(
      size: widget.size,
      painter: NotePainter(
        widget.denominator, widget.subDiv, widget.accents, widget.active,
        widget.maxAccentCount,
        widget.colorPast, widget.colorNow, widget.colorFuture, widget.colorInner,
        widget.activeNoteType, widget.coverWidth, widget.showTuplet, widget.showAccent,
        widget.showShadow, widget.colorShadow,
      //TODO isComplex: true,
      )
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

class NotePainter extends CustomPainter
{
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

  final double _strideRatio = 4;
  final bool coverWidth;
  final bool showTuplet;
  final bool showAccent;
  final bool shadow;

  final int maxAccentCount;
  /// Respectively to _widthStem
  final double heightAccent2ratio = 1.25;
  final double gapAccent2ratio = 1.5;
  double _heightAccent2 = 0;
  double _gapAccent = 0;

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

  ///Ниже идут значения относительно высоты

  ///вертикальный радиус ноты (относительно высоты)
  final double _relRadius = 0.12;  // 0.1

  /// Во сколько раз горизонтальный радиус ноты длинее
  final double eccentricity = 828.0 / 505;

  ///Во сколько раз увеличивается активная нота
  ///Также используется для explosion mode, когда вместа увеличения
  ///ноты разлетается вокруг ноты всякая фигня (тогда этот параметр определяет
  ///радиус поражения)
  final double _bigRadiusMultiplier = 1.4;

  ///Низ зоны флагов
  double _relFlagsZoneBottom = 0;//0.45;//0.4 //VG

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
  final double _relFlagHeight = 0.55;  // 0.6 for _relFlagsZoneBottom = 0.45
  /// Относительный аспект простого флага = (высота / ширина) * 2
  /// 1 соответствует отношению сторон = 2
  final double _flagAspect = 1.2;

  ///от верхнего флага/скобки до числа
  final double _relSpaceBelowNumber = 0.00;

  ///высота текста-числа
  final double _relNumberHeight = 0.3;

  ///
  ///Значения для случая скобки (половинные и четвертные ноты):
  ///

  final bool fullTuplet = false;
  /// Высота боковых загибов скобки относительно высотвы цифры
  final double _relTupletHeight = 0.4;
  /// абсолютное значение в пикселях
  final double _tupletBracketLineWidth = 1;

  ///Отступ от половинной-четвертной ноты до скобки
  final double _spaceBelowTupletBracket = 0.1;

  ///
  ///Параметры взрыва
  ///

  ///Толщина линий вокруг активной ноты
  final double _explosionLineWidth = 3;

  ///Число линий взрыва
  final int _numberOfExplosionLines = 16;

  final Color colorExplosion = Colors.redAccent;
  /// Shadow color
  final Color colorShadow;
  /// Shadow blur radius
  final double shadowBlurRadius = 5;

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
  Paint _paintShadow;

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
  NotePainter([
    this.denominator, this.subDiv,
    this.accents,
    this.active,
    this.maxAccentCount,
    this.colorPast, this.colorNow, this.colorFuture, this.colorInner,
    this.activeNoteType,
    this.coverWidth, this.showTuplet, this.showAccent,
    this.shadow, this.colorShadow,
  ]);

  /// Рисуем одну четвертную/половинную нотку.
  /// isHallow - пустая внутри
  void _drawNakedNote(Canvas canvas, int sub,
      Offset centerHead, double radiusHead, double stemTop,
      Color color, bool isFilled)
  {
    //TODO Connect Stem and head without angles
    double noteWidth = 2 * radiusHead + (isFilled ? _widthStem : _widthHollowStem);
    ///Head of the note
    Rect rect = Rect.fromCenter(center: Offset.zero,
      width: noteWidth,
      height: 2 * radiusHead / eccentricity);

    final Rect rcGrad = Rect.fromCenter(
      center: Offset.zero.translate(_coefGradSkewX * radiusHead, 0),
      width: _coefGrad * noteWidth,
      height: _coefGrad * 2 * radiusHead / eccentricity);

    //TODO --Colors.white
    if (colorInner != color)
    {
      final Shader _headGradient = new RadialGradient(
        colors: <Color>[colorInner, color],
      ).createShader(rcGrad);
      _paintFilledNote.shader = _headGradient;
    }
    else
      _paintFilledNote.color = color;

    if (isFilled)
    {
      ///Filled
      //_paintFilledNote.color = color;
      //canvas.drawCircle(centerHead, radiusHead, _paintFilledNote);
      // Draw stem
      Offset off = centerHead.translate(radiusHead - 0.5 * _widthStem, 0);
      // Draw shadow
      if (shadow)
        canvas.drawLine(off, off.translate(0, stemTop - off.dy), _paintShadow);
      canvas.drawLine(off, off.translate(0, stemTop - off.dy), _paintStem);
      // Draw head
      canvas.save();
      canvas.translate(centerHead.dx, centerHead.dy);

      canvas.rotate(_headAngle);
      // Draw shadow
      if (shadow)
        canvas.drawOval(rect, _paintShadow);
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
            width: _innerScaleX * noteWidth,
            height: _innerScaleY * 2 * radiusHead / eccentricity
          )
        );
      Path pathOuter = new Path()
        ..addRect(
          Rect.fromCenter(center: Offset.zero,
            width: noteWidth,
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
      // Draw shadow
      if (shadow)
        canvas.drawOval(rect, _paintShadow);
      canvas.drawOval(rect, _paintFilledNote);
      canvas.restore();
    }
  }

  // Draw accents
  void _drawAccents(Canvas canvas, int sub, final Rect rc)
  {
    double delta = rc.width * (1.0 - cos(_headAngle));
    if (accents != null && sub < accents.length)
      for (int i = 0; i < accents[sub]; i++)
      {
        double y = i * (2 * _heightAccent2 + _gapAccent) + _gapAccent;
        final Offset offL = rc.bottomLeft.translate(0, y).translate(delta, 0);
        final Offset offR = rc.bottomRight.translate(0, y).translate(-delta, 0);
        final Offset offC = offR + Offset(0, _heightAccent2);
        canvas.drawLine(offL, offC, _paintStem);
        canvas.drawLine(offL + Offset(0, 2 * _heightAccent2), offC, _paintStem);
      }
  }

  Color _subnoteColor(int sub)
  {
    Color color;
    if (sub < active) color = colorPast;
    if (sub == active) color = colorNow;
    if (sub > active) color = colorFuture;
    return color;
  }

  ///Рисуем ноту номер sub обычной формы
  _drawRegularFormNote(Canvas canvas, int sub)
  {
    Color color = _subnoteColor(sub);
    _drawNakedNote(canvas, sub,
        new Offset(_noteCenterX(sub), _noteCenterY),
        _radius, _flagsZoneTop, color, (_noteExponent > 1));
  }

  ///Обсчитываем сразу всякие углы, чтобы каждый раз этого не делать.
  _initExplosionMathematics()
  {
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
  _drawExplosion1(Canvas canvas)
  {
    //ToDO:
    for (int i = 0; i < _numberOfExplosionLines; i++)
      canvas.drawLine(
          _explosionCoordinates1[i].translate(_noteCenterX(active), _noteCenterY),
        _explosionCoordinates2[i].translate(_noteCenterX(active), _noteCenterY),
        _paintExplosion
      );
  }

  _drawNotes(Canvas canvas)
  {
    bool isFilled = _noteExponent > 1;
    for (int i = 0; i < subDiv; i++)
      if (i != active)
      {
        Color color = _subnoteColor(i);
        _drawNakedNote(canvas, i,
          new Offset(_noteCenterX(i), _noteCenterY),
          _radius, _flagsZoneTop, color, isFilled);
        //_drawRegularFormNote(canvas, i);
      }

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
         activeRadius, _flagsZoneTop, colorNow, isFilled);
      if (activeNoteType == ActiveNoteType.explosion)
        _drawExplosion1(canvas);
    }

    if (showAccent)
      for (int i = 0; i < subDiv; i++)
      {
        double noteWidth = 2 * _radius + (isFilled ? _widthStem : _widthHollowStem);
        //double y = i == active ? _noteCenterY + _radius * (1 - _bigRadiusMultiplier) * tan(_headAngle) : _noteCenterY;
        double y = _noteCenterY;
        final Offset offHead = new Offset(_noteCenterX(i), y);

        ///Head of the note
        final Rect rect = Rect.fromCenter(center: offHead,
            width: noteWidth,
            height: 2 * _radius / eccentricity);

        // Draw accents
        _drawAccents(canvas, i, rect);
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
    double dy =  0.3 * flagHeight;  // Handpicked magic number <= yEnd

    Path path = _curvedFlag(flagHeight, _flagAspect);
    // Draw shadows
    if (shadow)
    {
      double y = _flagsZoneTop;
      for (int i = 0; i < _nmbOfFlags; i++, y += dy)
        canvas.drawPath(path.shift(new Offset(x, y)), _paintShadow);
    }
    // Draw flags
    double y = _flagsZoneTop;
    for (int i = 0; i < _nmbOfFlags; i++, y += dy)
      canvas.drawPath(path.shift(new Offset(x, y)), _paintFlag);
  }

  void _drawVerticalFlags(Canvas canvas)
  {
    if (_nmbOfFlags == 0)
      return;

    double rad;
    double left = _noteCenterX(0);
    ///Смешаем левую границу флагов
    if (0 == active && activeNoteType == ActiveNoteType.headFixed)
      rad = _radiusBig;
    else
      rad = _radius;
    left += rad;

    double right = _noteCenterX(subDiv - 1);
    ///Смещаем правую границу флагов
    if (subDiv - 1 == active && activeNoteType == ActiveNoteType.headFixed)
      rad = _radiusBig;
    else
      rad = _radius;
    right += rad;

    // Draw shadows
    if (shadow)
    {
      double y = _flagsZoneTop + _flagWidth * 0.5;
      for (int i = 0; i < _nmbOfFlags; i++)
      {
        Offset off = new Offset(left, y);
        //print("$off - $_flagWidth - $_nmbOfFlags");
        canvas.drawLine(off, off.translate(right - left, 0), _paintShadow);
        y += _flagWidth + _deltaHforFlag;
      }
    }
    // Draw flags
    double y = _flagsZoneTop + _flagWidth * 0.5;
    for (int i = 0; i < _nmbOfFlags; i++)
    {
      Offset off = new Offset(left, y);
      //print("$off - $_flagWidth - $_nmbOfFlags");
      canvas.drawLine(off, off.translate(right - left, 0), _paintSubdivFlag);
      y += _flagWidth + _deltaHforFlag;
    }
  }

  /// X-координата центра поддоли
  double _noteCenterX(int subDivN)
  {
    bool enoughWidth = _strideRatio * _radius * (subDiv - 1) + 2 * _radius + 2 * _safeX <= size.width;
    return coverWidth || !enoughWidth ?
      _safeX + (subDivN + 1) * (size.width - (_safeX + _safeX)) / (subDiv + 1) :
      0.5 * size.width + _strideRatio * _radius * (subDivN - 0.5 * (subDiv - 1));
    return _safeX + subDivN * (size.width - (_safeX + _safeX)) / (subDiv - 1);
  }

  _init()
  {
    ///Определяем тип базовой ноты
    int n = 1;
    int exp = 0;
    ///Может, есть и умнее код, но я боюсь
    ///слишком затейливой кроссплатформенной битовой арифметики, сорри.
    while (n < denominator)
    {
      n = n << 1;
      exp += 1;
    }
    _isPowerOf2 = n == denominator;
    _noteExponent = exp;
    if (!_isPowerOf2)
      _noteExponent--;
    _nmbOfFlags = max(_noteExponent - 2, 0);

    ///
    ///Геометрия
    ///

    _radius = size.height * _relRadius;
    _radiusBig = _radius * _bigRadiusMultiplier;
    _heightAccent2 = heightAccent2ratio * _widthStem;
    _gapAccent = gapAccent2ratio * _widthStem;

    // TODO Calculate empirical 1.1 coeff
    double coeff = showAccent ? 1 : _bigRadiusMultiplier;
    coeff = _bigRadiusMultiplier;
    coeff *= 1.1 / eccentricity;
    _noteCenterY = size.height - coeff * _radius;
    // Space under note head for accents
    if (showAccent)
      _noteCenterY -= (2 * _heightAccent2 + _gapAccent) * maxAccentCount;

    if (_nmbOfFlags < 2)
      _relFlagsZoneBottom = 2 * (_relWidthFlag + _relSpaceBetweenFlag);//0.15;

    double claimedSpaceForFlags = max(0, _nmbOfFlags - 1) * (_relSpaceBetweenFlag + _relWidthFlag);
    double presentSpaceForFlags = _relFlagsZoneBottom;
    double numberHeight = 0;
    if (showTuplet)
    {
      numberHeight = _relNumberHeight + _relSpaceBelowNumber;
      presentSpaceForFlags -= numberHeight;
    }
    _flagsRatio = 1;
    if (claimedSpaceForFlags > presentSpaceForFlags)
      _flagsRatio = presentSpaceForFlags / claimedSpaceForFlags;

    _flagsZoneBottom = _relFlagsZoneBottom * size.height;

    ///Определяем реальную высоту, где кончатся флаги (и ноты)
    double relFlagTop = max(numberHeight,
      _relFlagsZoneBottom - claimedSpaceForFlags);
    _flagsZoneTop = relFlagTop * size.height;
    //_flagsZoneTop = _relFlagsZoneBottom * size.height;

    _flagWidth = _relWidthFlag * _flagsRatio * size.height;
    _deltaHforFlag = _relSpaceBetweenFlag * _flagsRatio * size.height;
    _flagWidth = _relWidthFlag * size.height;
    _deltaHforFlag = _relSpaceBetweenFlag * size.height;

    ///Стили рисования нот, штилей, флагов и т.п.

    _paintFilledNote = new Paint()
      ..color = colorPast
      ..strokeWidth = _widthHollowHeadBoundary
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

    _paintShadow = new Paint()
      ..color = colorShadow
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, convertRadiusToSigma(shadowBlurRadius));

    ///Обсчитываем один раз всю математику
    _initExplosionMathematics();
  }

  Size size;

  @override
  void paint(Canvas canvas, Size size)
  {
    ///ToDo: move to constructor, make constants final?
    this.size = size;
    _init();

    //TODO Check
    double stemWidth = denominator == 2 || denominator == 3 ? _widthHollowStem : _widthStem;
    //TODO && !isPowerOf2
    bool useTupletLine = (denominator == subDiv && subDiv > 1 && !_isPowerOf2) ||
      (denominator == 2 * subDiv && subDiv == 3);

    ///Если нот несколько - вертикальные черты, или скоба для нот 1/2,1/4; число сверху
    _drawNotes(canvas);

    if (subDiv <= 1)
      _drawCurvedFlags(canvas);  // Single note
    else if (!useTupletLine)
      _drawVerticalFlags(canvas);

    if (showTuplet && !_isPowerOf2)
    {
      //TODO Draw text in the center
      double y = _flagsZoneTop - _relSpaceBelowNumber * size.height - size.height * _relNumberHeight * 0.5;
      Offset center = new Offset(size.width * 0.5, y);

      //canvas.drawCircle(center, size.height * _relNumberHeight * 0.5, _paintHallowNote);
      List<Shadow> shadows;
      if (shadow)
        shadows = new List<Shadow>.filled(1, new Shadow(color: colorShadow, blurRadius: shadowBlurRadius));

      TextSpan span = new TextSpan(
        text: subDiv.toString(),
        style: new TextStyle(color: colorPast,
          fontSize: size.height * _relNumberHeight,
          shadows: shadow ? shadows : null)
      );
      TextPainter tp = new TextPainter(text: span, textDirection: TextDirection.ltr);

      tp.layout();
      double xShift = fullTuplet ? 0 : tp.width * 0.25;
      tp.paint(canvas, center.translate(xShift, - tp.height * 0.5));

      //TODO
      if (useTupletLine)
      {
        final double xLeft = fullTuplet ?
          _noteCenterX(0) - _radius - 2 * stemWidth : _noteCenterX(0) + _radius - 3 * stemWidth;
        final Offset left = new Offset(xLeft, y);
        final Offset right = new Offset(_noteCenterX(subDiv - 1) + _radius + 2 * stemWidth, y);

        canvas.drawLine(left.translate(0, _relTupletHeight * tp.height), left, _paintStem);
        canvas.drawLine(left, center.translate(- 0.25 * tp.width + xShift, 0), _paintStem);
        canvas.drawLine(center.translate(1.25 * tp.width + xShift, 0), right, _paintStem);
        canvas.drawLine(right.translate(0, _relTupletHeight * tp.height), right, _paintStem);
      }
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
  bool shouldRepaint(NotePainter oldDelegate)
  {
    bool sameAccents = equalLists(accents, oldDelegate.accents);
    return this.denominator != oldDelegate.denominator ||
      this.subDiv != oldDelegate.subDiv ||
      this.active != oldDelegate.active ||
      !sameAccents ||
      this.maxAccentCount != oldDelegate.maxAccentCount ||
      this.colorPast != oldDelegate.colorPast ||
      this.colorNow != oldDelegate.colorNow ||
      this.colorFuture != oldDelegate.colorFuture ||
      this.colorInner != oldDelegate.colorInner ||
      this.colorShadow != oldDelegate.colorShadow ||
      this.coverWidth != oldDelegate.coverWidth ||
      this.showTuplet != oldDelegate.showTuplet ||
      this.showAccent != oldDelegate.showAccent ||
      this.shadow != oldDelegate.shadow ||
      this.activeNoteType != oldDelegate.activeNoteType;
  }

  static double convertRadiusToSigma(double radius)
  {
    return radius * 0.57735 + 0.5;
  }
}
