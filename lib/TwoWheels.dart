import 'package:flutter/material.dart';
import 'util.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

class WheelScrollController extends FixedExtentScrollController {
  @override
  ScrollPosition createScrollPosition(ScrollPhysics physics,
      ScrollContext context, ScrollPosition oldPosition) {
    // TODO: implement createScrollPosition
    return super.createScrollPosition(physics, context, oldPosition);
  }
}

class TwoWheels extends StatefulWidget {
  final bool update;
  final int beats;
  final int minBeats;
  final int maxBeats;
  final int noteIndex;
  final int minNoteIndex;
  final int maxNoteIndex;

  final double width;
  final double height;
  final double itemExtent;
  final Color color;
  final TextStyle textStyle;
  //final TextStyle textStyleSelected;

  final ValueChanged<int> onBeatChanged;
  final ValueChanged<int> onNoteChanged;

  TwoWheels(
      {this.update = false,
      @required this.beats,
      @required note,
      @required this.onBeatChanged,
      @required this.onNoteChanged,
      this.minBeats = 1,
      this.maxBeats = 32,
      minNote = 1,
      maxNote = 32,
      this.width = double.infinity,
      this.height = double.infinity,
      this.itemExtent = 40,
      this.color = Colors.white,
      @required this.textStyle,
      //@required this.textStyleSelected,
      })
      : noteIndex = noteValue2index(note),
        minNoteIndex = noteValue2index(minNote),
        maxNoteIndex = noteValue2index(maxNote);

  @override
  State<StatefulWidget> createState() {
    return TwoWheelsState();
  }
}

class TwoWheelsState extends State<TwoWheels> {
  FixedExtentScrollController beatController;
  FixedExtentScrollController noteController;
  final int duration = 1000;
  bool _notify = true;

  TwoWheelsState();

  void finishUpdate(_) {
    // widget.update = false;
    _notify = true;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    beatController = new FixedExtentScrollController(
        initialItem: widget.beats - widget.minBeats);
    noteController = new FixedExtentScrollController(
        initialItem: widget.noteIndex - widget.minNoteIndex);
  }

  @override
  Widget build(BuildContext context) {
    double spaceBetween = widget.height / 50;
    //TODO final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    double width = widget.width;
    double height = 0.5 * (widget.height - spaceBetween);

    print('Metre::build ${widget.beats}');

    // To prevent reenter via widget.onBeat/NoteChanged::setState
    // when position is changing via jumpToItem/animateToItem
    if (widget.update) {
      _notify = false;
      print('update1 ${widget.beats}');
      //TODO Need?
      int beats = clampLoop(widget.beats, widget.minBeats, widget.maxBeats);
      if (true) {
        beatController.jumpToItem(beats - widget.minBeats);
        noteController.jumpToItem(widget.noteIndex - widget.minNoteIndex);
        finishUpdate(0);
      } else {
        //TODO Both run => when finishUpdate?
        beatController
            .animateToItem(beats - widget.minBeats,
                duration: Duration(milliseconds: duration), curve: Curves.ease)
            .catchError(finishUpdate)
            .then<void>(finishUpdate);
        noteController
            .animateToItem(widget.noteIndex - widget.minNoteIndex,
                duration: Duration(milliseconds: duration), curve: Curves.ease)
            .catchError(finishUpdate)
            .then<void>(finishUpdate);
      }
      print('update2 ${widget.beats}');
      //widget.update = false;
    }

    final TextStyle textStyle =
        widget.textStyle;

    final List<Widget> wixBeats = new List<Widget>.generate(
        widget.maxBeats - widget.minBeats + 1,
        (int i) => new RotatedBox(
              quarterTurns: 1,
              child: Text(
                (i + widget.minBeats).toString(),
                textAlign: TextAlign.center,
                style: textStyle,
                textScaleFactor: 1,
              ),
            ));

    final List<Widget> wixNotes = new List<Widget>.generate(
        widget.maxNoteIndex - widget.minNoteIndex + 1, (int i) {
      int noteValue = index2noteValue(i + widget.minNoteIndex);
      return new RotatedBox(
        quarterTurns: 1,
        child: Text(
          noteValue.toString(),
          textAlign: TextAlign.center,
          style: textStyle,
          textScaleFactor: 1,
        ),
      );
    });
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                //image: AssetImage('images/Metre.png'),
                //image: AssetImage('images/meter.png'),
                image: AssetImage('images/wh23meter.png'),
                fit: BoxFit.fill,
              ),
/*
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [widget.color.withOpacity(0.2), widget.color])
*/
            ),
            width: width,
            height: height,
            child: RotatedBox(
                quarterTurns: 3,
                child: GestureDetector(
                    onTap: () {
                      print('onTap ${widget.beats}');
                      int beats = clampLoop(
                          widget.beats + 1, widget.minBeats, widget.maxBeats);
                      print('onTap $beats');
                      widget.onBeatChanged(beats);
                      beatController.jumpToItem(beats - widget.minBeats);
                      //setState(() {});
                    },
                    child: Container(
                        //color: widget.color,
                        width: height, //double.infinity,
                        height: width,
                        child: ListWheelScrollView.useDelegate(
                          controller: beatController,
                          physics: new FixedExtentScrollPhysics(),
                          diameterRatio: 1.0,
                          perspective: 0.004,
                          offAxisFraction: 0,
                          useMagnifier: false,
                          magnification: 1,
                          itemExtent: widget.itemExtent,
                          squeeze: 1.5,
                          onSelectedItemChanged: (int index) {
                            print(
                                'onSelectedItemChanged ${index + widget.minBeats} - $_notify');
                            if (_notify) // To prevent reenter via widget.onBeatChanged::setState
                              widget.onBeatChanged(index + widget.minBeats);
                            //setState(() {});
                          },
                          clipToSize: true,
                          renderChildrenOutsideViewport: false,
                          childDelegate: ListWheelChildLoopingListDelegate(
                              children: wixBeats),
                        )))),
          ),
          Container(
            height: spaceBetween,
          ),
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                //image: AssetImage('images/Metre.png'),
                image: AssetImage('images/wh23meter.png'),
                fit: BoxFit.fill,
              ),
            ),
            width: width,
            height: height,
            child: RotatedBox(
                quarterTurns: 3,
                child: GestureDetector(
                    onTap: () {
                      int index = clampLoop(widget.noteIndex + 1,
                          widget.minNoteIndex, widget.maxNoteIndex);
                      widget.onNoteChanged(index2noteValue(index));
                      noteController.jumpToItem(index - widget.minNoteIndex);
                      //setState(() {});
                    },
                    child: Container(
                        //color: widget.color,
                        width: height, //double.infinity,
                        height: width,
                        child: ListWheelScrollView.useDelegate(
                          controller: noteController,
                          physics: new FixedExtentScrollPhysics(),
                          diameterRatio: 1.0,
                          perspective: 0.004,
                          offAxisFraction: 0.0,
                          useMagnifier: false,
                          magnification: 1.0,
                          itemExtent: widget.itemExtent,
                          squeeze: 1.5,
                          onSelectedItemChanged: (int index) {
                            //print(index);
                            if (_notify) // To prevent reenter via widget.onBNotehanged::setState
                              widget.onNoteChanged(
                                  index2noteValue(index + widget.minNoteIndex));
                            //setState(() {});
                          },
                          clipToSize: true,
                          renderChildrenOutsideViewport: false,
                          childDelegate: ListWheelChildLoopingListDelegate(
                              children: wixNotes),
                        )))),
          ),
        ]);
  }
}
