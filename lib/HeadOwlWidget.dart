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
  double maxAngle = 1;

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

    bool newActive = state.isActiveBeat(widget.id);
    int newActiveSubbeat = state.getActiveSubbeat(widget.id);
    int t = state.getActiveTime(widget.id);
    //if (hash != activeHash)
    if (active != newActive || activeSubbeat != newActiveSubbeat || t != _time)
    //if (activeSubbeat != state.activeSubbeat || widget.subbeatCount == 1)
    {
      //debugPrint('REDRAW ${widget.id} - $newActive - ${state.activeSubbeat} - $activeSubbeat');
      setState((){
        activeHash = hash;
        //maxAngle = 2;
        _angle = maxAngle * sin(2 * pi * 0.000001 * t);
        active = newActive;
        activeSubbeat = newActiveSubbeat;
      });
    }
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
//    if (imageSize.height == null)
//      imageSize = new Size(imageSize.width, 1.2 * imageSize.width);
    final double aspect = imageSize.height / imageSize.width;
    print('OwlWidget $imageSize - $maxDragX - $aspect');

    Size noteSize = new Size(imageSize.width, 0.3 / 0.7 * imageSize.height);

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

    //_angle = 0;

    //TODO 1 vs 2 RepaintBoundary in Column
    return RepaintBoundary(
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              child: noteWidget,
//              ),
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
              Stack(
                //fit: StackFit.passthrough,
                alignment: AlignmentDirectional.topCenter,
                overflow: Overflow.visible,
                children: <Widget>[
                  Align(
                    alignment: Alignment.bottomCenter,
                    child:
//                AspectRatio( // This gives size to NoteWidget
//                    aspectRatio: aspect,   //1.2,//3.5 / 3,
//                    child:
                    widget.images[indexImage],
//                    Container(color: Colors.blue,
//                      width: widget.images[indexImage].width,
//                    height: widget.images[indexImage].height,
//                    child: widget.images[indexImage])//widget.images[indexImage],
                  ),
                  Positioned(
                    top: -30,
                    //alignment: Alignment(1, -1),
                    //alignment: Alignment.bottomCenter,
                    child:
                    Transform.rotate(
                      angle: _angle,
                      //origin: new Offset(0, 0),
                      //alignment: Alignment.topCenter,
                      child: widget.headImages[indexImageRot],
                    ),
                  ),
                ]
              ),
            ),
          ],
        ),
      ),
    );
  }
}
