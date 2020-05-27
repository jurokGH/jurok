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

  SubbeatEqWidget(
      {this.subbeatCount = 1,
      this.noteValue = 4,
      @required this.onChanged,
      this.noteColor = Colors.black,
      this.size = Size.zero,
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
    Size noteSize = Size(noteH * 0.3, noteH);

    //final Size noteSize =        new Size(0.8 * widget.size.width, 0.5 * widget.size.height);
    final NoteWidget noteWidget = new NoteWidget(
      subDiv: widget.subbeatCount,
      denominator: widget.noteValue * widget.subbeatCount,
      active: -1,
      coverWidth: true,
      showTuplet: false,
      showAccent: false,
      colorPast: widget.noteColor,
      colorNow: widget.noteColor,
      colorFuture: widget.noteColor,
      colorInner: Colors.white.withOpacity(0.1), //ToDo????
      size: noteSize,
    );

    return GestureDetector(
      onTap: () {
        int subbeatCount = Subbeat.next(widget.subbeatCount);
        widget.onChanged(subbeatCount);//ToDo - up ????
        setState(() {});
      },
      /*child: Stack(
            alignment: AlignmentDirectional.center,
            children: <Widget>[
              Opacity(
                opacity: 0.9,
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
        )*/

      child: Row(children: <Widget>[
       /* Image.asset('images/owl-sub.png',
            width: widget.size.width/3,
            fit: BoxFit.contain
        ),*/
        /*Container(
            width: noteSize.width *
                1.2), //Размер хвостика нотки не должен цеплять равенство*/
        Align(
            alignment: Alignment.centerRight,
            child: Container(
                width: widget.size.width/3,
                //color: Colors.black,
              child:Image.asset('images/owl-sub.png',
                  width: widget.size.width/3,
                  fit: BoxFit.contain
              ),
                //child: Text(" =", style: widget.textStyle.copyWith(fontSize: noteH/1.5))
            ),
        ),

        Align(
            alignment: Alignment.center,
            child: Text(" =", style: widget.textStyle.copyWith(fontSize: noteH/1.7))),
        Align(alignment: Alignment.centerLeft,
        child:Container(
            height: noteSize.height,
            width:  0.99*widget.size.width*2/4,
            child: NoteWidget(
              subDiv: widget.subbeatCount,
              denominator: widget.noteValue * widget.subbeatCount,
              active: -1,
              accents: [],
              showAccent: false,
              showTuplet: true,
              coverWidth: true,
              colorPast: Colors.black,
              colorNow: Colors.black,
              colorFuture: Colors.black,
              colorInner: Colors.black,
              size: noteSize,
            )),),

      ]),
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
