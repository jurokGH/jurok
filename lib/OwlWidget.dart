import 'package:flutter/material.dart';
import 'package:owlenome/util.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'NoteWidget.dart';
import 'prosody.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

typedef ImageIndexCallback = int Function(int accent, int subbeat, int subbeatCount);

class OwlWidget extends StatefulWidget
{
  final int id;
  final bool accent;
  int nAccent;  //TODO
  final int maxAccentCount;
  final bool active;
  final int activeSubbeat;
  int subbeatCount;
  final int denominator;
  final Animation<double> animation;
  final List<Image> images;

  //final double width;

  final ValueChanged2<int, int> onTap;
  final ValueChanged2<int, int> onNoteTap;
  final ImageIndexCallback getImageIndex;

  OwlWidget({
    @required this.id,
    @required this.onTap,
    @required this.onNoteTap,
    @required this.getImageIndex,
    @required this.accent,
    @required this.nAccent,
    this.maxAccentCount = 3,
    @required this.active,
    @required this.denominator,
    @required this.activeSubbeat,
    @required this.subbeatCount,
    @required this.animation,
    @required this.images,
  });
  //:assert(subbeatCount > 0);

  @override
  OwlState createState() => OwlState(active, activeSubbeat, animation);
}

class OwlState extends State<OwlWidget> with SingleTickerProviderStateMixin<OwlWidget>
{
  static final bool drawSubOwls = false;
  //static final int maxSubCount = 8;

  int _counter;

  //int subbeatCount;
  bool active;
  int activeSubbeat;

  int activeHash;
  Animation<double> _controller;

  double _dragStart = 0;
  double maxDragX = 50;
  double _dragStartY = 0;
  double maxDragY = 25;

  OwlState(/*this.subbeatCount, */this.active, this.activeSubbeat, this._controller);

  void onRedraw()
  {
    final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.update();
    int hash = state.getBeatState(widget.id);
    //debugPrint('AnimationController ${widget.id} $_counter $hash');
    _counter++;

    bool newActive = state.isActiveBeat(widget.id);
    int newActiveSubbeat = state.getActiveSubbeat(widget.id);
    //if (hash != activeHash)
    if (active != newActive || activeSubbeat != newActiveSubbeat)
    //if (activeSubbeat != state.activeSubbeat || widget.subbeatCount == 1)
    {
      //debugPrint('REDRAW ${widget.id} - $newActive - ${state.activeSubbeat} - $activeSubbeat');
      setState((){
        activeHash = hash;
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
    int indexImage = widget.getImageIndex(widget.nAccent, activeSubbeat, widget.subbeatCount);

    maxDragX = widget.images[indexImage].width / 4;
    //maxDragY = widget.images[indexImage].height / 4;

    Size imageSize = new Size(widget.images[indexImage].width, widget.images[indexImage].height);
    if (imageSize.height == null)
      imageSize = new Size(imageSize.width, 1.2 * imageSize.width);
    //print('OwlWidget $imageSize - $maxDragX');

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
          int step = (widget.maxAccentCount * delta) ~/ maxDragY;
          step = delta ~/ maxDragY;
          //print('onVerticalDragUpdate - $delta - $step');
          if (step != 0)
          {
            _dragStartY = details.localPosition.dy;
            final int accent = clamp(widget.nAccent + step, 0, widget.maxAccentCount);
            setState(() {
              widget.nAccent = accent;
            });
            widget.onTap(widget.id, step);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
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
              child:
/*
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.rectangle,
                  boxShadow: [BoxShadow(
                color: Colors.deepPurple.withOpacity(0.7),
                offset: Offset.zero,
                blurRadius: 5.0,
                spreadRadius: 0.0,
                  )],
                ),
                child:
*/
              AspectRatio( // This gives size to NoteWidget
                aspectRatio: 1.7,//1.2,//3.5 / 3,
                //width: 0.9 * widget.width,
                //height: 0.9 * widget.width,
                child: Container(
                  //width: imageSize.width,
                  //height: imageSize.height,
  //                  decoration: BoxDecoration(
  //                    shadow:
  //                  ),
                  padding: EdgeInsets.only(bottom: 0),
                  child:
                  NoteWidget(
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
                    //size: imageSize,
                  ),
                ),
              ),
            ),
              //),

  //            RepaintBoundary(child:
            //TODO SizedBox(width: widget.width, height: widget.width * 310 / 250, child:
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.onTap(widget.id, widget.nAccent);
                });
              },
              child: widget.images[indexImage],
            ),
          ],
        ),
      ),
    );
  }
}

// Boilerplate
// Maybe somewhen in future try to paint images for optimization
class OwlPainter extends CustomPainter
{
  int id;
  bool active;

  OwlPainter({this.id, this.active});

@override
  void paint(Canvas canvas, Size size) {
    debugPrint('paint $id - $size');

    Paint paint = new Paint()
      ..color = active ? Colors.red : Colors.blue;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(OwlPainter oldDelegate) {
    // TODO: implement shouldRepaint
    debugPrint('shouldRepaint $id - $active - ${oldDelegate.active}');
    return oldDelegate.active != active;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) {
    // TODO: implement shouldRebuildSemantics
    //return false;
    return super.shouldRebuildSemantics(oldDelegate);
  }
}
