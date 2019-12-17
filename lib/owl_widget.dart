import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'note_ui.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

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
  bool redraw = false;
  //AnimationController _controller0;
  int _period = 60000;
  Animation<double> _controller;

  OwlState(/*this.subbeatCount, */this.active, this.activeSubbeat, this._controller);

  void onRedraw()
  {
    final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
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
          redraw = false;
          //_time = _controller.value;
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

/*
    _controller0 = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    )
    ..addListener(onRedraw);
*/

    _controller.addListener(onRedraw);

    //_controller.reset();
    //_controller.forward();
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
    //final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
      //.setActive(widget.id, widget.subbeatCount);
    //int activeBeat = state.activeBeat;
    //int activeSubbeat = state.activeSubbeat;
    //bool accent = widget.id == activeBeat;

    final int nFile3 = widget.accent ? 2 : 1;
    //Size childSize = new Size(minWidth, minWidth * 546 / 668);
    final List<Widget> subOwls = List<Widget>();
    for (int i = 0; i < widget.subbeatCount; i++)
    {
      Widget w = new Image.asset('images/owl$nFile3-0.png',
          //width: widget.width / 7,
        fit: BoxFit.contain
      );
      subOwls.add(w);
    }

    final int beat0 = activeHash >> 16;
    final int activeSubbeat0 = activeHash & 0xFFFF;
    //final bool active = widget.id == activeBeat;

    final int nFile1 = widget.accent ? 1 : 2;
    int indexImage = active ? 3 : 0;
    if (active && widget.subbeatCount > 1)
    {
      indexImage = activeSubbeat % widget.subbeatCount + 1;
      if (indexImage > 4)
        indexImage = 1 + indexImage % 4;
    }
    final String imageName = 'images/owl$nFile1-$indexImage.png';

    print('OwlState: ${widget.id} - $beat0 - $_counter - $active - ${widget.active} - $activeSubbeat - ${widget.activeSubbeat}');
    //if (subbeatCount != widget.subbeatCount)
      //print('!Owl:subbeatCount ${widget.subbeatCount}');
    if (active != widget.active)
      print('!Owl:active $active ${widget.active}');

    _counter++;

    /// Provider-Selector
    return GestureDetector(
          onTap: () {
            //widget.subCount++;
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
            widget.onTap(widget.id, widget.subbeatCount);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              RepaintBoundary(
                child: AspectRatio(
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
                  )
                ),

              RepaintBoundary(
                child: SizedBox(
                  //width: widget.width,
                  //height: widget.width * 668 / 546,
                  child: drawSubOwls ?

                  Stack(
                    children: <Widget>[
                      /*            IndexedStack(
                  index: indexImage,
                  children: owls,
                ),
                */
                      Image.asset(imageName,
                      //width: widget.width,
                      fit: BoxFit.contain
                      ),

                      Center(
                        child: SizedBox(
                        //width: 0.9 * widget.width,
                          child: Align(
                            alignment: Alignment(0, -0.3),
                            child: Wrap(
                              //alignment: WrapAlignment.center,
                              //crossAxisAlignment: WrapCrossAlignment.center,
                              //runAlignment: WrapAlignment.start,
                              spacing: 6,
                              runSpacing: 4,
                              children: subOwls,
                            )
                          )
                        )
                      )
                  ])

                  :
                  widget.images[indexImage]
                )
              )
          ])
        );
  }

  Widget __build1(BuildContext context) {
    assert(widget.subbeatCount > 0);
    print('OwlState: ${widget.id} - $_counter - ${widget.active} - ${widget.subbeatCount} - ${widget.activeSubbeat}');
    _counter++;

    //final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    //.setActive(widget.id, widget.subbeatCount);
    //int activeBeat = state.activeBeat;
    //int activeSubbeat = state.activeSubbeat;
    //bool accent = widget.id == activeBeat;

    /*
    final List<Widget> owls = List<Widget>();
    for (int i = 0; i < widget.subbeatCount % 5; i++)
    {
      Widget w = new Image.asset('images/owl$nFile1-${i+1}.png',
        width: widget.width,
        fit: BoxFit.contain
      );
      owls.add(w);
    }
*/
    int nFile3 = widget.accent ? 2 : 1;
    //Size childSize = new Size(minWidth, minWidth * 546 / 668);
    final List<Widget> subOwls = List<Widget>();
    for (int i = 0; i < widget.subbeatCount; i++)
    {
      Widget w = new Image.asset('images/owl$nFile3-0.png',
        //width: widget.width / 7,
        fit: BoxFit.contain
      );
      subOwls.add(w);
    }

    //return Image.asset('images/owl2-$division.png',
    /// Provider-Selector
    return Selector<MetronomeState, int>(
      selector: (BuildContext context, MetronomeState state) => state.getBeatState(widget.id),
      builder: (BuildContext context, int activeState, Widget child)
      {
        final int activeBeat = activeState >> 16;
        final int activeSubbeat = activeState & 0xFFFF;
        bool active = widget.id == activeBeat;

        final int nFile1 = widget.accent ? 1 : 2;
        int nFile2 = active ? 3 : 0;
        if (active && widget.subbeatCount > 1)
        {
          nFile2 = activeSubbeat % widget.subbeatCount + 1;
          if (nFile2 > 4)
            nFile2 = 1 + nFile2 % 5;
        }

        print('OwlState2: ${widget.id} - $activeBeat - $activeSubbeat - $active');

        return GestureDetector(
          onTap: () {
            //widget.subCount++;
            setState(() {
              //subbeatCount++;
              if (widget.subbeatCount > maxSubCount)
              //TODO
                widget.subbeatCount = 1;
              //widget.subbeatCount++;
              //if (widget.subbeatCount > maxSubCount)
                //TODO
                //widget.subbeatCount = 1;
            });
            //Provider.of<MetronomeState>(context, listen: false)
            //.setActiveState(widget.id, widget.subbeatCount);
            widget.onTap(widget.id, widget.subbeatCount);
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            //  width: 80,
            //  height: 100,
            children: <Widget>[
              RepaintBoundary(
                child: AspectRatio(
                  aspectRatio: 1,
                  //width: 0.9 * widget.width,
                  //height: 0.9 * widget.width,
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: NoteWidget(
                      subDiv: widget.subbeatCount,
                      denominator: widget.denominator * widget.subbeatCount,
                      active: active ? activeSubbeat : -1,
                      //active: widget.active ? widget.activeSubbeat : -1,
                      activeNoteType: ActiveNoteType.explosion,
                      colorPast: Colors.white,
                      colorNow: Colors.red,
                      colorFuture: Colors.white,
                    )
                  )
                )
              ),

              RepaintBoundary(
                child: SizedBox(
                  //width: widget.width,
                  //height: widget.width * 668 / 546,
                  child: drawSubOwls ?

                  Stack(
                    children: <Widget>[
                      /*            IndexedStack(
                  index: nFile2,
                  children: owls,
                ),
                */
                      Image.asset('images/owl$nFile1-$nFile2.png',
                        //width: widget.width,
                        fit: BoxFit.contain
                      ),

                      Center(
                        child: SizedBox(
                          //width: 0.9 * widget.width,
                          child: Align(
                            alignment: Alignment(0, -0.3),
                            child: Wrap(
                              //alignment: WrapAlignment.center,
                              //crossAxisAlignment: WrapCrossAlignment.center,
                              //runAlignment: WrapAlignment.start,
                              spacing: 6,
                              runSpacing: 4,
                              children: subOwls,
                            )
                          )
                        )
                      )
                    ])

                    :
                  Image.asset('images/owl$nFile1-$nFile2.png',
                    //width: widget.width,
                    fit: BoxFit.contain
                  ),

                  /*
              child: CustomPaint(
              size: Size(80, 100),
              painter: OwlPainter(id: widget.id, active: active),
              isComplex: false,
              willChange: true,
              )
              */
                )
              )
            ])
        );
      }
    );
  }
}

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
