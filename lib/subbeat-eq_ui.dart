import 'package:flutter/material.dart';

import 'NoteWidget.dart';
import 'prosody.dart';

class SubbeatEqWidget extends StatefulWidget {
  final int subbeatCount;
  final int subbeatCountMax;
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
      this.subbeatCountMax = 4,
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

    ///Нота на плашке
    Widget notePlashka(double hOfBar) {
      ///shadow
      final Color shadCol = Color.fromRGBO(
          42, 0, 49, 0.9);
      final double shadX = 0 * hOfBar / 57; //4
      final double shadY = 4 * hOfBar / 57;
      final double shadRad = 6 * hOfBar / 57;

      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: noteSize.width*1.6,
            height: hOfBar,
            //Image.asset('images/but-note-1.png', fit: BoxFit.fitHeight,),
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: shadCol,
                  offset: Offset(shadX, shadY),
                  blurRadius: shadRad,
                ),
              ],
              image: DecorationImage(
                image: // AssetImage('images/but-note-2.png'),
                    AssetImage('images/but-note-1.png'),
                fit: BoxFit.fill,
              ),
            ),
          ),
          noteWidget,
        ],
      );
    }

    TextStyle textStyle = widget.textStyle
        .copyWith(color: Colors.black, fontSize: widget.size.width / 5);

    return GestureDetector(
      onTap: () {
        int subbeatCount = widget.allEqual
            ? (widget.subbeatCount <= widget.subbeatCountMax)
                ? (widget.subbeatCount % widget.subbeatCountMax) + 1
                : 1
            : widget.subbeatCount;
        widget.onChanged(subbeatCount); //ToDo - up ????
        //setState(() {});//Why?
      },
      child: Row(children: <Widget>[
        Align(
          alignment: Alignment.centerRight,
          child: Container(
           /* padding: EdgeInsets.only(left: widget.size.width * 0.01, top: widget.size.width * 0.01,
                bottom: widget.size.width * 0.01),*/
            width: widget.size.width / 4,
            //color: Colors.black,
            child: Image.asset('images/owl-sub.png', fit: BoxFit.contain),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: widget.allEqual
              ? Text(
                  " ~ ",
                  style: textStyle,
                  textScaleFactor: 1,
                )
              : Opacity(
                  opacity: 0.3,
                  child: Text(
                    " ~ ",
                    style: textStyle,
                    textScaleFactor: 1,
                  )

                  ///ToDo: а что мне помешало поставить условие на opacity?
                  ///А, может, текст должен зависеть тоже от этого... кто знает.
                  ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: widget.allEqual
              ? notePlashka(noteH)
              : Opacity(opacity: 0.3, child: notePlashka(noteH)),
        ),
      ]),
    );
  }
}
