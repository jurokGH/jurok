import 'package:flutter/material.dart';

import 'NoteWidget.dart';
import 'prosody.dart';

class SubbeatEqWidget extends StatefulWidget {
  final int subbeatCount;
  final int noteValue;
  final ValueChanged<int> onChanged;
  final Color noteColor;
  final TextStyle textStyle;
  final Size size;
  final bool allEqual;

  SubbeatEqWidget(
      {this.subbeatCount = 1,
      this.noteValue = 4,
      @required this.onChanged,
      this.noteColor = Colors.black,
      this.size = Size.zero,
      this.allEqual = false,
      @required this.textStyle});

  @override
  State<StatefulWidget> createState() {
    return SubbeatEqState();
  }
}

class SubbeatEqState extends State<SubbeatEqWidget> {
  SubbeatEqState();

  @override
  Widget build(BuildContext context) {
    double noteH = widget.size.height;
    //Size noteSize = Size(noteH * 0.3, noteH);
    Size noteSize = Size(0.28 * widget.size.width, noteH * 0.85);

    //final Size noteSize =        new Size(0.8 * widget.size.width, 0.5 * widget.size.height);
    final Widget noteWidget = Container(
        height: noteSize.height,
        width: widget.size.width * 2 / 4,
        child: NoteWidget(
          subDiv: widget.subbeatCount,
          denominator: widget.noteValue * widget.subbeatCount,
          active: -1,
          accents: [],
          showAccent: false,
          showTuplet: (widget.subbeatCount == 3),

          ///ToDo!!!
          coverWidth: true,
          colorPast: widget.noteColor,
          colorNow: widget.noteColor,
          colorFuture: widget.noteColor,
          colorInner: Colors.white.withOpacity(0.1), //ToDo????
          size: noteSize,
        ));

    TextStyle textStyle= widget.textStyle.copyWith(
        color: Colors.black, fontSize: widget.size.width / 5);

    return GestureDetector(
      onTap: () {
        int subbeatCount = Subbeat.next(widget.subbeatCount);
        widget.onChanged(subbeatCount); //ToDo - up ????
        setState(() {});
      },
      child: Row(children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            width: widget.size.width / 3.4,
            //color: Colors.black,
            child: Image.asset('images/owl-sub.png', fit: BoxFit.contain),
          ),
        ),
        Align(
            alignment: Alignment.center,
            child: widget.allEqual? Text(" =", style: textStyle)
            : Opacity(opacity: 0.3, child: Text(" =", style: textStyle)
            ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: widget.allEqual
              ? noteWidget
              : Opacity(opacity: 0.3, child: noteWidget),
        ),
      ]),
    );
  }
}
