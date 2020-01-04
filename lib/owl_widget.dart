import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'note_ui.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

double grad2rad(double x) => x * pi / 180;

class OwlWidget extends StatefulWidget
{
  final int id;
  final bool accent;
  final bool active;
  final int activeSubbeat;
  int subbeatCount;
  final int denominator;
  final Animation<double> animation;
  final List<Image> images;

  //final double width;

  final ValueChanged2<int, int> onTap;

  OwlWidget({
    @required this.id,
    @required this.onTap,
    @required this.accent,
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

  AnimationController _animController;
  Animation<double> _animRot;
  Animation<double> _animRot1;
  Animation<double> _animRot2;
  Animation<double> _animScale;
  Animation<double> _animScale1;

  int _period = 200;
  double _angle = 0;
  double _scale = 1;
  static final double _angleMax = 10;
  static final double _scaleMax = 1.1;

  OwlState(/*this.subbeatCount, */this.active, this.activeSubbeat, this._controller);

  void onRedraw()
  {
    final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.update();
    int hash = state.getBeatState(widget.id);
    //print('AnimationController ${widget.id} $_counter $hash');
    _counter++;

    bool newActive = state.isActiveBeat(widget.id);
    int newActiveSubbeat = state.getActiveSubbeat(widget.id);
    //if (hash != activeHash)
    if (active != newActive || activeSubbeat != newActiveSubbeat)
      //if (activeSubbeat != state.activeSubbeat || widget.subbeatCount == 1)
      {
        print('REDRAW ${widget.id} - $newActive - ${state.activeSubbeat} - $activeSubbeat');

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

    activeHash = 100;
    //subCount = 1;
    _counter = 0;

/*TODO Someone can check if several running AnimationController are better than 1
    AnimationController _controller0;
    int _period = 60000;

    _controller0 = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    )
    ..addListener(onRedraw);
*/
    _animController = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    )
    ..addStatusListener((AnimationStatus status) {
      if (status == AnimationStatus.completed)
        _animController.reset();
    });

    _animRot = new Tween<double>(begin: 0, end: grad2rad(_angleMax))
      .animate(CurvedAnimation(curve: Interval(0, 0.25, curve: Curves.linear), parent: _animController))
    ..addListener((){
      if (_animController.value < 0.25)
      setState((){
        _angle = _animRot.value;
      });
    });
    _animRot1 = new Tween<double>(begin: grad2rad(_angleMax), end: -grad2rad(_angleMax))
      .animate(CurvedAnimation(curve: Interval(0.25, 0.75, curve: Curves.linear), parent: _animController))
      ..addListener((){
        if (_animController.value >= 0.25 && _animController.value < 0.75)
          setState((){
            _angle = _animRot1.value;
          });
      });
    _animRot2 = new Tween<double>(begin: -grad2rad(_angleMax), end: 0)
      .animate(CurvedAnimation(curve: Interval(0.75, 1.0, curve: Curves.linear), parent: _animController))
      ..addListener((){
        if (_animController.value >= 0.75)
          setState((){
            _angle = _animRot2.value;
          });
      });

    _animScale = new Tween<double>(begin: 1.0, end: _scaleMax)
      .animate(CurvedAnimation(curve: Interval(0, 0.5, curve: Curves.linear), parent: _animController))
      ..addListener((){
        if (_animController.value < 0.5)
          setState((){
            _scale = _animScale.value;
          });
      });
    _animScale1 = new Tween<double>(begin: _scaleMax, end: 1)
      .animate(CurvedAnimation(curve: Interval(0.5, 1.0, curve: Curves.linear), parent: _animController))
      ..addListener((){
        if (_animController.value >= 0.5)
          setState((){
            _scale = _animScale1.value;
          });
      });

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
    final int beat0 = activeHash >> 16;
    final int activeSubbeat0 = activeHash & 0xFFFF;
    //final bool active = widget.id == activeBeat;

    int indexImage = active ? 3 : 0;
    if (active && widget.subbeatCount > 1)
    {
      indexImage = activeSubbeat % widget.subbeatCount + 1;
      if (indexImage > 4) //TODO
        indexImage = 1 + indexImage % 4;
    }

    //print('OwlState: ${widget.id} - $beat0 - $_counter - $active - ${widget.active} - $activeSubbeat - ${widget.activeSubbeat}');
    //if (subbeatCount != widget.subbeatCount)
      //print('!Owl:subbeatCount ${widget.subbeatCount}');
    //if (active != widget.active)
      //print('!Owl:active $active ${widget.active}');
    return GestureDetector(
          onTap: () {
            setState(() {
              _animController.forward();//.orCancel;
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
            widget.onTap(widget.id, widget.subbeatCount);
          },
          //TODO 1 vs 2 RepaintBoundary in Column
          child: RepaintBoundary(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
//              RepaintBoundary(child:
              AspectRatio( // This gives size to NoteWidget
                aspectRatio: 1,
                //width: 0.9 * widget.width,
                //height: 0.9 * widget.width,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 8),
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

//              RepaintBoundary(child:
              //TODO SizedBox(
                //width: widget.width,
                //height: widget.width * 668 / 546,
                //child:
            Transform.rotate(
              alignment: Alignment.bottomCenter,
              angle: _angle,
              child:
                Transform.scale(
                  alignment: Alignment.bottomCenter,
                  scale: _scale,
                  child:
                    widget.images[indexImage]
              )
            )
          ])
        ));
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
    print('paint $id - $size');

    Paint paint = new Paint()
      ..color = active ? Colors.red : Colors.blue;

    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(OwlPainter oldDelegate) {
    // TODO: implement shouldRepaint
    print('shouldRepaint $id - $active - ${oldDelegate.active}');
    return oldDelegate.active != active;
  }

  @override
  bool shouldRebuildSemantics(CustomPainter oldDelegate) {
    // TODO: implement shouldRebuildSemantics
    //return false;
    return super.shouldRebuildSemantics(oldDelegate);
  }
}
