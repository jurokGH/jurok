import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:owlenome/util.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'NoteWidget.dart';
import 'prosody.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

typedef ImageIndexCallback2 = List<int> Function(
    int accent, int subbeat, int subbeatCount);

class HeadOwlWidget extends StatefulWidget {
  final int id;
  final bool accent;
  int nAccent; //TODO
  final int maxAccent;
  final bool active;
  final int activeSubbeat;
  int subbeatCount;
  final int denominator;
  final Animation<double> animation;
  final List<Image> images;
  final List<Image> headImages;
  final double anchorRatio = 0.01; //-0.08;//for 310
  final double imageHeightRatio;
  final double maxAngle;
  final Size size;

  //final double width;

  final ValueChanged2<int, int> onTap;
  final ValueChanged2<int, int> onNoteTap;
  final ImageIndexCallback2 getImageIndex;

  HeadOwlWidget({
    @required this.id,
    @required this.onTap,
    @required this.onNoteTap,
    @required this.getImageIndex,
    @required this.accent,
    @required this.nAccent,
    this.maxAccent = 3,
    @required this.active,
    @required this.denominator,
    @required this.activeSubbeat,
    @required this.subbeatCount,
    @required this.animation,
    @required this.images,
    @required this.headImages,
    @required this.imageHeightRatio,
    @required this.size,
    this.maxAngle = 1,
  });
  //:assert(subbeatCount > 0);

  @override
  HeadOwlState createState() => HeadOwlState(active, activeSubbeat, animation);
}

class HeadOwlState extends State<HeadOwlWidget>
    with SingleTickerProviderStateMixin<HeadOwlWidget> {
  static final bool drawSubOwls = false;
  //static final int maxSubCount = 8;

  int _counter;

  //int subbeatCount;
  bool active;
  int activeSubbeat;
  int _time;
  double _angle = 0;

  int activeHash;
  Animation<double> _controller;

  double _dragStart = 0;
  double maxDragX = 50;
  double _dragStartY = 0;
  double maxDragY = 25;

  HeadOwlState(/*this.subbeatCount, */ this.active, this.activeSubbeat,
      this._controller);

  void onRedraw() {
    final MetronomeState state =
        Provider.of<MetronomeState>(context, listen: false);
    state.update();
    int hash = state.getBeatState(widget.id);
    //debugPrint('AnimationController ${widget.id} $_counter $hash');
    _counter++;

    final bool newActive = state.isActiveBeat(widget.id);
    final int newActiveSubbeat = state.getActiveSubbeat(widget.id);
    //final int t = state.getActiveTime(widget.id);
    final int t = state.getReActiveTime();

    //if (hash != activeHash)

    // Active vs all owls swing their heads
    if (active != newActive || activeSubbeat != newActiveSubbeat || t != _time)
//    if (t != _time)
    //if (activeSubbeat != state.activeSubbeat || widget.subbeatCount == 1)
    {
      //debugPrint('REDRAW ${widget.id} - $newActive - ${state.activeSubbeat} - $activeSubbeat');
      setState(() {
        activeHash = hash;
        //maxAngle = 2;
        //_angle = 2 * pi * sin(2 * pi * 0.000001 * t);
        _angle = -widget.maxAngle * sin(2 * pi * 0.000001 * t);
        //минус- чтобы начинал в сторону движения всех нот
        active = newActive;
        activeSubbeat = newActiveSubbeat;
      });
    }
    _time = t;
    //    final int beat0 = activeHash >> 16;
    //    final int activeSubbeat0 = activeHash & 0xFFFF;
    //final bool active = widget.id == activeBeat;
  }

  @override
  void initState() {
    super.initState();

/*TODO Someone can check if several running AnimationController are better than 1
    AnimationController _controller0;
    int _period = 60000;
    _controller0 = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    )
    ..addListener(onRedraw);
    //_controller0.forward();
*/

    activeHash = 100;
    //subCount = 1;
    _counter = 0;
    _controller.addListener(onRedraw);
  }

  @override
  void dispose() {
    _controller.removeListener(onRedraw);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<int> indices = widget.getImageIndex(
        widget.nAccent, activeSubbeat, widget.subbeatCount);
    final int indexImage = indices[0];
    final int indexImageHead = indices[1];

    final Size imageSize = new Size(
        widget.images[indexImage].width, widget.images[indexImage].height);
    final double yOffset = widget.anchorRatio * imageSize.height;

    final Size owlSize = new Size(
        widget.size.width, widget.imageHeightRatio * widget.size.height);
    final Size noteSize = new Size(widget.size.width,
        (1.0 - widget.imageHeightRatio) * widget.size.height / 2.2 //!!!
        );

    maxDragX = imageSize.width / 4;
    //maxDragY = widget.images[indexImage].height / 4;

    final double aspect = imageSize.height / imageSize.width;
    print(
        'OwlWidget $imageSize - $maxDragX - $aspect - ${1 / widget.size.aspectRatio}');

    List<int> tupletsInts = [3, 5, 6, 7, 9, 10, 11];

    ///пока так

    final NoteWidget noteWidget = new NoteWidget(
      subDiv: widget.subbeatCount,
      denominator: widget.denominator * widget.subbeatCount,
      active: active ? activeSubbeat : -1,
      activeNoteType: ActiveNoteType.stemFixed,
      coverWidth: true,
      showTuplet: tupletsInts.contains(widget.subbeatCount),
      showAccent: false,
      colorPast: Colors.black,
      colorNow: Colors.red,
      colorFuture: Colors.black,
      colorInner: Colors.white.withOpacity(1),
      showShadow: true,
      colorShadow: Colors.white.withOpacity(1),
      size: noteSize,
    );

    ///Плашка с тенями  и акцентами.
    ///Растет снизу вверх, нужно следить, чтобы поместились все
    ///картинки акцента
    Widget accentedPlashka(double wOfBar, double hOfBar, int nOfAccents) {
      if (!(nOfAccents > 0)) return Container();

      ///ISH: Параметры из figma. Там ширина плашки была 31 когда я мерял отнощения, поэтому
      ///тут это мистическое число.
      ///ToDo: Юра

      ///paddings
      final double betweenPad = 1.5 * wOfBar / 31;
      final double topbutPad = 3 * betweenPad;
      final double leftrightPad = topbutPad - betweenPad;

      ///Прозрачность плашки
      final double opac = 0.76;

      ///shadow
      final Color shadCol = Color.fromRGBO(0, 0, 0, 0.25);
      final double shadX = 0; //-4*wOfBar/31;//0?
      final double shadY = 4 * wOfBar / 31;
      final double shadRad = 4 * wOfBar / 31;

      ///галка акцента в вертикальных паддингах
      final Widget iconAcc = Image.asset(
        'images/ac.png',
        fit: BoxFit.fitWidth,
      );

      final List<Widget> accentsWid = List<Widget>.filled(
          nOfAccents,
          Padding(
            padding: EdgeInsets.symmetric(
              vertical: betweenPad,
            ),
            child: iconAcc,
          ));

      return Opacity(
        opacity: opac,
        child: Container(
          width: wOfBar,
          height: hOfBar,
          //decoration: decorTmp(Colors.black),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Wrap(children: [
              Container(
                //decoration: decorTmp(Colors.yellowAccent),
                decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: shadCol,
                        offset: Offset(shadX, shadY),
                        //spreadRadius: 1,
                        blurRadius: shadRad,
                      ),
                    ],
                    image: DecorationImage(
                      image: AssetImage('images/but-note-2.png'),
                      fit: BoxFit.fill,
                    )),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: topbutPad,
                    horizontal: leftrightPad,
                  ), //
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: accentsWid,
                  ),
                ),
              ),
            ]),
          ),
        ),
      );
    }

    ///Нота на плашке
    Widget notePlashka(double hOfBar) {

      ///ISH: Витя, active из виджета почему-то всегда неактивен...
      final bool bActive=(Provider.of<MetronomeState>(context, listen: false)
          .activeBeat ==
          widget.id);

      ///ISH:
      ///ToDo: Юра
      ///Прозрачность плашки
      final double opac = 0.5;

      ///shadow
      final Color shadCol = Color.fromRGBO(42, 0, 49,
          bActive?0.9:0.5); //0.9 и 0.5 тут - это прозрачности тени в
      //зависимости от активности доли
      final double shadX = 4* hOfBar /57; //-4*wOfBar/31;//0?
      final double shadY = 4 * hOfBar / 57;
      final double shadRad = 6 * hOfBar / 57;

      return Stack(
        alignment: Alignment.center,
        children:        [
          Opacity(
            opacity: bActive?1:opac,
            child: Container(
            height: hOfBar,
            //Image.asset('images/but-note-1.png', fit: BoxFit.fitHeight,),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: shadCol,
                  offset: Offset(shadX, shadY),
                  blurRadius: shadRad,
                ),
              ],
              image: DecorationImage(
                /* //какая-то хрень некрасивая получилась, надо разбираться...
                colorFilter: (Provider.of<MetronomeState>(context, listen: false)
                            .activeBeat ==
                        widget.id)
                    ? ColorFilter.mode(
                        Colors.white.withOpacity(1), BlendMode.color)
                    : ColorFilter.mode(
                        Colors.black.withOpacity(0.5), BlendMode.color),
                 */
                image: // AssetImage('images/but-note-2.png'),
                    AssetImage('images/but-note-1.png'),
                fit: BoxFit.fill,
              ),
            ),
        ),
          ),
          noteWidget,
      ],
        );
    }

    //TODO 1 vs 2 RepaintBoundary in Column
    return RepaintBoundary(
//      child: Container(
//        width: widget.size.width,
//        height: widget.size.height,
      child: GestureDetector(
        onHorizontalDragStart: (DragStartDetails details) {
          _dragStart = details.localPosition.dx;
        },
        onHorizontalDragUpdate: (DragUpdateDetails details) {
          final double delta = details.localPosition.dx - _dragStart;
          //TODO
          int step = (Subbeat.maxSubbeatCount * delta) ~/ maxDragX;
          step = delta ~/ maxDragX;
          if (step != 0) {
            _dragStart = details.localPosition.dx;
            final int subbeatCount =
                clamp(widget.subbeatCount + step, 1, Subbeat.maxSubbeatCount);
            setState(() {
              widget.subbeatCount = subbeatCount;
            });
            widget.onNoteTap(widget.id, widget.subbeatCount);
          }
        },
        onVerticalDragStart: (DragStartDetails details) {
          //TODO Offset
          _dragStartY = details.localPosition.dy;
        },
        onVerticalDragUpdate: (DragUpdateDetails details) {
          final double delta = details.localPosition.dy - _dragStartY;
          //TODO
          int step = (widget.maxAccent * delta) ~/ maxDragY;
          step = delta ~/ maxDragY;
          //print('onVerticalDragUpdate - $delta - $step');
          if (step != 0) {
            _dragStartY = details.localPosition.dy;
            final int accent =
                clamp(widget.nAccent + step, 0, widget.maxAccent);
            setState(() {
              widget.nAccent = accent;
            });
            widget.onTap(widget.id, accent);
          }
        },
        child: Column(
          ///Нота над совой; стэк с головой и знаками акцентов
          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
//              RepaintBoundary(child:
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.subbeatCount = Subbeat.next(widget.subbeatCount);
                });
                //Provider.of<MetronomeState>(context, listen: false).setActiveState(widget.id, widget.subbeatCount);
                widget.onNoteTap(widget.id, widget.subbeatCount);
              },
              child: Padding(
                //ToDo: поднимаем над совой
                padding: EdgeInsets.only(bottom: owlSize.height / 10),
                child: notePlashka(noteSize.height*1.1),//ToDo: от балды...
              ),
            ),

            //            RepaintBoundary(child:
            //TODO SizedBox(width: widget.width, height: widget.width * 310 / 250, child:
            GestureDetector(
              onTap: () {
                final int accent =
                    clampLoop(widget.nAccent + 1, 0, widget.maxAccent);
                print(
                    'accent:OnTap $accent - ${widget.nAccent} - ${widget.maxAccent}');
                setState(() {
                  widget.nAccent = accent;
                });
                widget.onTap(widget.id, accent);
              },
              child: Container(
                width: owlSize.width,
                height: owlSize.height,
                alignment: Alignment.bottomCenter,
                child: Stack(
                  //fit: StackFit.passthrough,
                  //alignment: Alignment.bottomCenter,
                  overflow: Overflow.visible,
                  children: <Widget>[
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: widget.images[indexImage],
                    ),
                    Transform(
                      transform: Matrix4.rotationZ(_angle)
                        ..setTranslationRaw(0, yOffset, 0),
                      alignment: Alignment.center,
                      child: widget.headImages[indexImageHead],
                    ),
                    Positioned.fromRect(
                      rect: Rect.fromPoints(
                        Offset(0, owlSize.height),
                        Offset(owlSize.width / 3, owlSize.height / 2),
                      ),
                      child: accentedPlashka(owlSize.width / 3,
                          owlSize.height / 2, widget.nAccent),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
