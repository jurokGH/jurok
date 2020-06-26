import 'package:flutter/material.dart';

///Виджет-колесо по кругу
class GoAroundWheelW extends StatefulWidget {
  final TextStyle textStyle;
  final List<int> list;
  final int position;
  final double width;
  final FixedExtentScrollController controller;

  ///Переход по тапу
  final bReactOnTap;
  final ValueChanged<int> onChanged;

  GoAroundWheelW({
    @required this.textStyle,
    @required this.position,
    @required this.list,
    @required this.width,
    this.onChanged,
    this.bReactOnTap = true,
    @required this.controller,
  });

  @override
  State<StatefulWidget> createState() => GoAroundWheelState();
}



class GoAroundWheelState extends State<GoAroundWheelW> {


  @override
  Widget build(BuildContext context) {


    final List<Widget> wixTempo = new List<Widget>.generate(
      widget.list.length,
          (int i) => new RotatedBox(
        quarterTurns: 1,
        child: new Container(
          alignment: Alignment.center,
          child: Text(widget.list[i].toString(),
              textDirection: TextDirection.ltr,
              maxLines: 1,
              textScaleFactor: 1,
              style: widget.textStyle),
        ),
      ),
    );



    return RotatedBox(
      quarterTurns: 3,
      child: GestureDetector(
        onTap: () {
          if (!widget.bReactOnTap) return; //ISH: Is it a correct way? //ToDo
          int index = (widget.position + 1)%widget.list.length;
          widget.controller.jumpToItem(index);
          /*widget.controller.animateToItem(index,
              duration: Duration(milliseconds:  250),
            curve: Curves.linear,
          );*/
        },
        child: ListWheelScrollView.useDelegate(
          controller: widget.controller,
          physics: new FixedExtentScrollPhysics(),
          diameterRatio: 1000.0,
          perspective: 0.000001,
          offAxisFraction: 0.0,
          useMagnifier: false,
          magnification: 1.0,
          itemExtent: widget.width,
          squeeze: 0.88,
          onSelectedItemChanged: (int index) {
            widget.onChanged(index);
          },
          clipToSize: true,
          renderChildrenOutsideViewport: false,
          childDelegate: ListWheelChildLoopingListDelegate(children: wixTempo),
        ),
      ),
    );

  }
}
