import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'note_ui.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

typedef ImageIndexCallback = int Function(int accent, int subbeat, int subbeatCount);

class OwlWidget extends StatefulWidget
{
  final int id;
  final bool accent;
  final int nAccent;
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
    @required this.active,
    @required this.denominator,
    @required this.activeSubbeat,
    @required this.subbeatCount,
    @required this.animation,
    @required this.images}):
    assert(subbeatCount > 0);

  @override
  OwlState createState() => OwlState(active, activeSubbeat, animation);
}

class OwlState extends State<OwlWidget> with SingleTickerProviderStateMixin<OwlWidget>
{
  static final bool drawSubOwls = false;
  static final int maxSubCount = 8;

  int _counter;

  //int subbeatCount;
  bool active;
  int activeSubbeat;

  int activeHash;
  Animation<double> _controller;

  double _dragStart = 0;
  double maxDragX = 50;

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
    //_controller0.dispose();
    _controller.removeListener(onRedraw);
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    final int beat0 = activeHash >> 16;
    final int activeSubbeat0 = activeHash & 0xFFFF;
    //final bool active = widget.id == activeBeat;

/*
    int indexImage = active ? 3 : 0;
    if (active && widget.subbeatCount > 1)
    {
      indexImage = activeSubbeat % widget.subbeatCount + 1;
      if (indexImage > 4) //TODO
        indexImage = 1 + indexImage % 4;
    }
*/

    int indexImage = widget.getImageIndex(widget.nAccent, activeSubbeat, widget.subbeatCount);

    maxDragX = widget.images[indexImage].width / 4;
/*
    int indexImage = 2 * (widget.nAccent + 1);
    if (active)
    {
      //indexImage++;
      indexImage += activeSubbeat % 2;
    }
*/

    //debugPrint('OwlState: ${widget.id} - $beat0 - $_counter - $active - ${widget.active} - $activeSubbeat - ${widget.activeSubbeat}');
    //if (subbeatCount != widget.subbeatCount)
      //debugPrint('!Owl:subbeatCount ${widget.subbeatCount}');
    //if (active != widget.active)
      //debugPrint('!Owl:active $active ${widget.active}');

    return
          //TODO 1 vs 2 RepaintBoundary in Column
          RepaintBoundary(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
//              RepaintBoundary(child:
            GestureDetector(
            onTap: () {
              setState(() {
                widget.subbeatCount++;
                //subbeatCount++;
                if (widget.subbeatCount > maxSubCount)
                {
                  //TODO
                  widget.subbeatCount = 1;
                  //subbeatCount = 1;
                }
              });
              //Provider.of<MetronomeState>(context, listen: false)
              //.setActiveState(widget.id, widget.subbeatCount);
              widget.onNoteTap(widget.id, widget.subbeatCount);
            },
            onHorizontalDragStart: (DragStartDetails details) {
              _dragStart = details.localPosition.dx;
            },
            onHorizontalDragUpdate: (DragUpdateDetails details) {
              double delta = details.localPosition.dx - _dragStart;
              int step = (maxSubCount * delta) ~/ maxDragX;
              step = delta ~/ maxDragX;
              if (step != 0)
              {
                _dragStart = details.localPosition.dx;
                int subbeatCount = widget.subbeatCount + step;
                //debugPrint('onHorizontalDragStart - $_dragStart - $delta - $step - $subbeatCount');
                if (subbeatCount < 1)
                  subbeatCount = 1;
                if (subbeatCount > maxSubCount)
                  subbeatCount = maxSubCount;

                setState(() {
                  widget.subbeatCount = subbeatCount;
                });
                widget.onNoteTap(widget.id, widget.subbeatCount);
              }
            },
            child: AspectRatio( // This gives size to NoteWidget
                aspectRatio: 1.2,//3.5 / 3,
                //width: 0.9 * widget.width,
                //height: 0.9 * widget.width,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 0),
                  child: NoteWidget(
                    subDiv: widget.subbeatCount,
                    denominator: widget.denominator * widget.subbeatCount,
                    active: active ? activeSubbeat : -1,
                    activeNoteType: ActiveNoteType.explosion,
                    colorPast: Colors.white,
                    colorNow: Colors.red,
                    colorFuture: Colors.white,
                  )
                 )
              ),
              ),

//              RepaintBoundary(child:
              //TODO SizedBox(
                //width: widget.width,
                //height: widget.width * 668 / 546,
                //child:
            GestureDetector(
              onTap: () {
                setState(() {
                  widget.onTap(widget.id, widget.nAccent);
                });
              },
              child: widget.images[indexImage]
            ),
          ])
        );
  }
}


//VG Boilerplate
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
