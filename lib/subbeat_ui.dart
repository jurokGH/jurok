import 'package:flutter/material.dart';

import 'NoteWidget.dart';
import 'prosody.dart';

class SubbeatWidget extends StatefulWidget
{
  final int subbeatCount;
  final int noteValue;
  final ValueChanged<int> onChanged;
  final Color color;
  final TextStyle textStyle;
  final Size size;

  SubbeatWidget({
    this.subbeatCount = 1,
    this.noteValue = 4,
    @required this.onChanged,
    this.color = Colors.white,
    this.size = Size.zero,
    @required this.textStyle});

  @override
  State<StatefulWidget> createState() {
    return SubbeatState();
  }
}

class SubbeatState extends State<SubbeatWidget>
{
  SubbeatState();

  @override
  Widget build(BuildContext context)
  {
    final Size noteSize = new Size(0.8 * widget.size.width, 0.5 * widget.size.height);
    //noteSize -= new Offset(10, 30);
    final NoteWidget noteWidget = new NoteWidget(
      subDiv: widget.subbeatCount,
      denominator: widget.noteValue * widget.subbeatCount,
      active: -1,
      coverWidth: true,
      showTuplet: false,
      showAccent: false,
      colorPast: widget.color,
      colorNow: widget.color,
      colorFuture: widget.color,
      colorInner: Colors.white,
      size: noteSize,
    );

    return GestureDetector(
      onTap: () {
        int subbeatCount = Subbeat.next(widget.subbeatCount);
        setState(() {});
        widget.onChanged(subbeatCount);
      },
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Opacity(
            opacity: 0.6,
            child:
              Image.asset('images/owl-sub.png',//owl-btn
              //Image.asset('images/owl-btn.png',
              height: widget.size.height,
              fit: BoxFit.contain
            ),
          ),
          //BoxDecoration
          Padding(
            padding: const EdgeInsets.only(right: 10, top: 10),
            child: noteWidget,
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
