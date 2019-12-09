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

  int subBeatCount;
  final int subBeat;
  final int denominator;

  //final double width;

  final ValueChanged2<int, int> onTap;

  OwlWidget({this.id, this.onTap,
    this.accent, this.active,
    this.denominator,
    this.subBeat, this.subBeatCount});

  @override
  OwlState createState() => OwlState(subBeatCount, active, subBeat);
}

class OwlState extends State<OwlWidget>
{
  static final bool drawSubOwls = false;
  static final int maxSubCount = 8;
  int subCount;
  int subBeat;
  bool active;

  int _counter;

  OwlState(this.subCount, this.active, this.subBeat);

  bool isActive() => subCount > 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    //subCount = 1;
    _counter = 0;
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.subBeatCount > 0);
    print('OwlState: ${widget.id} - $_counter - ${widget.active} - ${widget.subBeatCount} - ${widget.subBeat}');
    _counter++;

    final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
      //.setActive(widget.id, widget.subBeatCount);

    int activeBeat = state.activeBeat;
    int activeSubbeat = state.activeSubbeat;

    bool accent = widget.id == activeBeat;

    int nFile1 = widget.accent ? 1 : 2;
    int nFile2 = widget.active ? 3 : 0;
    if (widget.active && widget.subBeatCount > 1)
    {
      nFile2 = widget.subBeat % widget.subBeatCount + 1;
      nFile2 = nFile2 % 5;
    }
/*
    final List<Widget> owls = List<Widget>();
    for (int i = 0; i < widget.subBeatCount % 5; i++)
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
    for (int i = 0; i < widget.subBeatCount; i++)
    {
      Widget w = new Image.asset('images/owl$nFile3-0.png',
        //width: widget.width / 7,
        fit: BoxFit.contain
      );
      subOwls.add(w);
    }

    //return Image.asset('images/owl2-$division.png',
    return GestureDetector(
      onTap: () {
        //widget.subCount++;
        setState(() {
          widget.subBeatCount++;
          if (widget.subBeatCount > maxSubCount)
            widget.subBeatCount = 1;
        });
        Provider.of<MetronomeState>(context, listen: false)
          .setActive(widget.id, widget.subBeatCount);
        widget.onTap(widget.id, widget.subBeatCount);
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
                child: Consumer<MetronomeState>(
                  builder: (BuildContext context, MetronomeState metronome, Widget child) {
                    return NoteWidget(
                      subDiv: widget.subBeatCount,
                      denominator: widget.denominator * widget.subBeatCount,
                      active: widget.id == metronome.activeBeat ? metronome.activeSubbeat : -1,
                      //active: widget.active ? widget.subBeat : -1,
                      activeNoteType: ActiveNoteType.explosion,
                      colorPast: Colors.white,
                      colorNow: Colors.red,
                      colorFuture: Colors.white,
                    );
                  }
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
