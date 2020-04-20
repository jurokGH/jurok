import 'package:flutter/material.dart';
import 'NoteWidget.dart';
import 'metre.dart';
import 'prosody.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

class NoteTempoWidget extends StatefulWidget
{
  final int tempo;
  final int noteValue;
  final Size size;
  final Color color;
  final TextStyle textStyle;
  final ValueChanged<void> onChanged;

  NoteTempoWidget({
    @required this.tempo,
    this.noteValue = 4,
    this.size,
    this.color,
    this.textStyle,
    this.onChanged,
  });

  @override
  State<StatefulWidget> createState() => NoteTempoState();
}

class NoteTempoState extends State<NoteTempoWidget>
{
  NoteTempoState();

  @override
  Widget build(BuildContext context)
  {
    Widget wix = new SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child:
      NoteWidget(
        subDiv: 1,
        denominator: widget.noteValue,
        active: -1,
        colorPast: widget.color,
        colorNow: widget.color,
        colorFuture: widget.color,
        colorInner: widget.color,
        accents: [],
        showAccent: false,
        showTuplet: false,
        coverWidth: true,
      ),
    );

    // TODO: implement build
    return GestureDetector(
      onTap: () {
        //widget.onChanged();
      //setState(() {});
      },
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: <Widget>[
          wix,
          Container(width: 2),
          Text('=' + widget.tempo.toString(),
            style: widget.textStyle),
        ],
      ),
    );
  }
}
