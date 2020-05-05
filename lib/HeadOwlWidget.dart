import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:owlenome/util.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'NoteWidget.dart';
import 'prosody.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

typedef ImageIndexCallback2 = List<int> Function(int accent, int subbeat, int subbeatCount);

class HeadOwlWidget extends StatefulWidget
{
  final int id;
  final bool accent;
  int nAccent;  //TODO
  final int maxAccent;
  final bool active;
  final int activeSubbeat;
  int subbeatCount;
  final int denominator;
  final Animation<double> animation;
  final List<Image> images;
  final List<Image> headImages;
  final double anchorRatio = 0.01;//-0.08;//for 310
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

class HeadOwlState extends State<HeadOwlWidget> with SingleTickerProviderStateMixin<HeadOwlWidget>
{
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

  HeadOwlState(/*this.subbeatCount, */this.active, this.activeSubbeat, this._controller);

  void onRedraw()
  {
    final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.update();
    int hash = state.getBeatState(widget.id);
    //debugPrint('AnimationController ${widget.id} $_counter $hash');
    _counter++;

    final bool newActive = state.isActiveBeat(widget.id);
    final int newActiveSubbeat = state.getActiveSubbeat(widget.id);
    final int t = state.getActiveTime(widget.id);
    //if (hash != activeHash)
    if (active != newActive || activeSubbeat != newActiveSubbeat || t != _time)
    //if (activeSubbeat != state.activeSubbeat || widget.subbeatCount == 1)
    {
      //debugPrint('REDRAW ${widget.id} - $newActive - ${state.activeSubbeat} - $activeSubbeat');
      setState((){
        activeHash = hash;
        //maxAngle = 2;
        _angle = widget.maxAngle * sin(2 * pi * 0.000001 * t);
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
  void initState()
  {
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
  void dispose()
  {
    _controller.removeListener(onRedraw);
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    final List<int> indices = widget.getImageIndex(widget.nAccent, activeSubbeat, widget.subbeatCount);
    final int indexImage = indices[0];
    final int indexImageRot = indices[1];

    maxDragX = widget.images[indexImage].width / 4;
    //maxDragY = widget.images[indexImage].height / 4;

    Size imageSize = new Size(widget.images[indexImage].width, widget.images[indexImage].height);
    //imageSize = new Size(widget.images[indexImage].width, widget.images[indexImage].width);
//    if (imageSize.height == null)
//      imageSize = new Size(imageSize.width, 1.2 * imageSize.width);
    final double aspect = imageSize.height / imageSize.width;

    Size noteSize = new Size(imageSize.width, (1.0 - widget.imageHeightRatio) * 330/250*imageSize.width);
    //noteSize = new Size(widget.size.width, (1.0 - widget.imageHeightRatio) * widget.size.height);
    //Size noteSize = new Size(imageSize.width, 0.3 / 0.7 * imageSize.height);
    print('OwlWidget $imageSize - $maxDragX - $aspect - ${1 / widget.size.aspectRatio}');
    Size sz2 = new Size(imageSize.width, 330 / 240 * imageSize.width);
    double ww = widget.headImages[0].width;
    double hh = widget.headImages[0].height;
    print('OwlWidget22 ${widget.size} - $imageSize - $noteSize - $sz2 - $ww - $hh');
    print('OwlWidget23 ${widget.images[0].width} - ${widget.images[0].height}');

    final NoteWidget noteWidget = new NoteWidget(
      subDiv: widget.subbeatCount,
      denominator: widget.denominator * widget.subbeatCount,
      active: active ? activeSubbeat : -1,
      activeNoteType: ActiveNoteType.stemFixed,
      coverWidth: true,
      showTuplet: true,
      showAccent: false,
      colorPast: Colors.white,
      colorNow: Colors.red,
      colorFuture: Colors.white,
      colorInner: Colors.white,
      showShadow: true,
      colorShadow: Colors.white.withOpacity(1),
      size: noteSize,
    );

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
          if (step != 0)
          {
            _dragStart = details.localPosition.dx;
            final int subbeatCount = clamp(widget.subbeatCount + step, 1, Subbeat.maxSubbeatCount);
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
          if (step != 0)
          {
            _dragStartY = details.localPosition.dy;
            final int accent = clamp(widget.nAccent + step, 0, widget.maxAccent);
            setState(() {
              widget.nAccent = accent;
            });
            widget.onTap(widget.id, accent);
          }
        },
        child: Column(
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
//              child: AspectRatio( // This gives size to NoteWidget
//                aspectRatio: 1.7,   //1.2,//3.5 / 3,
                //width: 0.9 * widget.width,
                //height: 0.9 * widget.width,
              child: Container(
//                width: noteSize.width,
//                height: noteSize.height,
                //color: Colors.green,
                child: noteWidget,
              ),
            ),

  //            RepaintBoundary(child:
            //TODO SizedBox(width: widget.width, height: widget.width * 310 / 250, child:
            GestureDetector(
              onTap: () {
                final int accent = clampLoop(widget.nAccent + 1, 0, widget.maxAccent);
                print('accent:OnTap $accent - ${widget.nAccent} - ${widget.maxAccent}');
                setState(() {
                  widget.nAccent = accent;
                });
                widget.onTap(widget.id, accent);
              },
              child:
              Container(
                //color: Colors.amber,
                width: imageSize.width,
                height: 330 / 250 * imageSize.width,
                alignment: Alignment.bottomCenter,

                child:
//                  Image.asset('images/owl6-1.png',
//                    width: imageSize.width,
//                    //height: imageSize.height,
//                    fit: BoxFit.contain,)
              Stack(
                //fit: StackFit.passthrough,
                //alignment: Alignment.bottomCenter,
                overflow: Overflow.visible,
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child:
//                AspectRatio( // This gives size to NoteWidget
//                    aspectRatio: 240 / 250,   //1.2,//3.5 / 3,
                Container(
                    //color: Colors.blue,
                    width: imageSize.width,
                    height: 240 / 250 * imageSize.width,
                    child:
                    widget.images[indexImage],
//                    Container(color: Colors.blue,
//                      width: widget.images[indexImage].width,
//                    height: widget.images[indexImage].height,
//                    child: widget.images[indexImage])//widget.images[indexImage],
                  ),
                  ),
                  Positioned(
                    top: widget.anchorRatio * 240 / 250 * imageSize.width,
                    //alignment: Alignment(1, -1),
                    //alignment: Alignment.bottomCenter,
                    child:
                    Transform.rotate(
                      angle: _angle,
                      //origin: new Offset(0, 0),
                      //alignment: Alignment.topCenter,
                      child:
//                      Container(
//                        color: Colors.pinkAccent,
                        //width: imageSize.width,
                        //height: 205 / 250 * imageSize.width,
                        //alignment: Alignment.bottomCenter,

//                        child:
//                  Image.asset('images/owl6h-0-0.png',
//                    width: widget.images[0].width,
//                    height: widget.images[0].height,
//                    fit: BoxFit.none,)
                    widget.headImages[indexImageRot],
//                      ),
                    ),
                  ),
                ]
              ),
              ),
            ),
          ],
        ),
      ),
      //),
    );
  }
}
