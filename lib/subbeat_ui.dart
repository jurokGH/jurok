import 'package:flutter/material.dart';

import 'note_ui.dart';

class SubbeatWidget extends StatefulWidget
{
  final int subbeatCount;
  final int noteValue;
  final ValueChanged<int> onChanged;
  final Color color;
  final TextStyle textStyle;

  SubbeatWidget({
    this.subbeatCount = 1,
    this.noteValue = 4,
    @required this.onChanged,
    this.color = Colors.white,
    @required this.textStyle});

  @override
  State<StatefulWidget> createState() {
    return SubbeatState();
  }
}

class SubbeatState extends State<SubbeatWidget>
{
  SubbeatState();

  /// Loop through subdivision list: 1, 2, 4, 3
  int nextSubbeat(int subBeat)
  {
    subBeat++;
    if (subBeat == 3)
      subBeat = 4;
    else if (subBeat == 4)
      subBeat = 1;
    else if (subBeat >= 5)
      subBeat = 3;
    return subBeat;
  }

  @override
  Widget build(BuildContext context)
  {
    return GestureDetector(
      onTap: () {
        int subbeatCount = nextSubbeat(widget.subbeatCount);
        setState(() {});
        widget.onChanged(subbeatCount);
      },
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Opacity(
            opacity: 0.55,
            child:
            Image.asset('images/owl2-3.png',
              height: 70,
              fit: BoxFit.contain
            ),
          ),
          //BoxDecoration
          SizedBox(
            //aspectRatio: 0.5,
            height: 70,
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(right: 10, bottom: 10),
              child:
              NoteWidget(
                subDiv: widget.subbeatCount,
                denominator: widget.noteValue * widget.subbeatCount,
                active: -1,
                colorPast: widget.color,
                colorNow: widget.color,
                colorFuture: widget.color,
              )
            ),
          ),
        ]
      )
/*      child: Row(
        children: <Widget>[
          Opacity(
            opacity: 0.5,
          child:
          Image.asset('images/owl2-3.png',
            height: 60,
            fit: BoxFit.contain
          ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
            child: Text('=', style: widget.textStyle.copyWith(color: widget.color))
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
            child: SizedBox(
              //aspectRatio: 0.5,
              height: 60,
              width: 60,
              child: NoteWidget(
                subDiv: widget.subbeatCount,
                denominator: widget.noteValue * widget.subbeatCount,
                active: -1,
                colorPast: widget.color,
                colorNow: widget.color,
                colorFuture: widget.color,
              )
            )
          ),
        ]
      )*/
    );
  }
}
