import 'package:flutter/material.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

class MetreWidget extends StatefulWidget
{
  final int beats;
  final int minBeats;
  final int maxBeats;
  final int note;
  final int minNote;
  final int maxNote;
  final Color color;

  //final ValueChanged<int> onChanged;
  final ValueChanged2<int, int> onChanged;

  MetreWidget({this.beats, this.note, this.onChanged,
    this.minBeats = 1, this.maxBeats = 8, this.minNote = 1, this.maxNote = 8,
    this.color = Colors.white});

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    return MetreState();
  }
}

class Metre
{
  final int beats;
  final int note;

  Metre(this.beats, this.note);

  String toString()
  {
    return beats.toString() + '/' + note.toString();
  }
}

class MetreState extends State<MetreWidget>
{
  static List<Metre> _metreList =
  [
    Metre(2, 2),
    Metre(2, 4),
    Metre(4, 4),
    Metre(3, 4),
    Metre(3, 8),
    Metre(3, 2),
    Metre(6, 8),
  ];
  int _iMetre = 2;

  MetreState();

  @override
  Widget build(BuildContext context)
  {
    TextStyle textStyle = Theme.of(context).textTheme.display1.apply(
      color: widget.color,
      //backgroundColor: Colors.black45
    );
    TextStyle textStyleMenu = textStyle.apply(
      color: widget.color,
      backgroundColor: Colors.deepPurple
    );

    List<PopupMenuEntry<int>> menuItems = new List<PopupMenuEntry<int>>();
    for (int i = 0; i < _metreList.length; i++)
      menuItems.add(new PopupMenuItem<int>(
        value: i,
        child: Text(_metreList[i].toString()),
        textStyle: textStyleMenu,
        height: 12
      ));

    // TODO: implement build
    return
    /*
      PopupMenuButton<int>(
      onSelected: (int value) {

        },
      itemBuilder: (BuildContext context) => menuItems,
    child:
    */
    Container(
      width: 80,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('images/Metre.png'),
          fit: BoxFit.contain,
        )
      ),
      //Padding(
      //  padding: const EdgeInsets.all(8.0),
      child: GestureDetector(
        onDoubleTap: () {
          _iMetre++;
          if (_iMetre >= _metreList.length)
            _iMetre = 0;
          widget.onChanged(_metreList[_iMetre].beats, _metreList[_iMetre].note);
        },
        onLongPress: () {
          List<PopupMenuEntry> menuItems = new List<PopupMenuEntry>();
          for (int i = 0; i < _metreList.length; i++)
            menuItems.add(new PopupMenuItem(
              value: i,
              child: Text(_metreList[i].toString()),
              textStyle: textStyleMenu,
              height: 36
            ));

          showMenu(
            context: context,
            position: RelativeRect.fromLTRB(0, 0, 20, 100),
            items: menuItems,
          );
        },
        onVerticalDragEnd: (DragEndDetails details) {
          _iMetre -= details.primaryVelocity.sign.toInt();
          if (_iMetre >= _metreList.length)
            _iMetre = 0;
          if (_iMetre < 0)
            _iMetre = _metreList.length - 1;
          widget.onChanged(_metreList[_iMetre].beats, _metreList[_iMetre].note);
        },
        child: IntrinsicWidth(  //TODO Time-expensive!
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  /*
                  print('onHorizontalDragUpdate');
                  double changeInX = details.delta.dx;
                  double changeInValue = distanceToAngle * changeInX;
                  double newValue = widget.value + changeInValue;
                  double clippedValue = min(max(newValue, widget.min), widget.max);

                  widget.onChanged(clippedValue);
                   */
                },
                onHorizontalDragEnd: (DragEndDetails details) {
                  int beats = widget.beats + details.primaryVelocity.sign.toInt();
                  if (beats < widget.minBeats)
                    beats = widget.maxBeats;
                  if (beats > widget.maxBeats)
                    beats = widget.minBeats;
                  widget.onChanged(beats, widget.note);
                },
                onTap: () {
                  int beats = widget.beats >= widget.maxBeats ?
                    widget.minBeats : widget.beats + 1;
                  widget.onChanged(beats, widget.note);
                },
                child: Text(widget.beats.toString(),
                  style: textStyle,
                ),
              ),
              //child: Text(widget.beats.toString(),
              //  style: Theme.of(context).textTheme.display1,
              //SizedBox.expand(
                //fit: BoxFit.fill,
                //width: double.infinity,
                //child:
              /*
              Container(
                height: 2,
                width: 24,
                color: widget.color,
                //constraints: BoxConstraints.tightForFinite(),
                //margin: const EdgeInsets.all(2.0)
              ),
               */
              //),
              GestureDetector(
                onHorizontalDragUpdate: (DragUpdateDetails details) {
                  /*
                  print('onHorizontalDragUpdate');
                  double changeInX = details.delta.dx;
                  double changeInValue = distanceToAngle * changeInX;
                  double newValue = widget.value + changeInValue;
                  double clippedValue = min(max(newValue, widget.min), widget.max);

                  widget.onChanged(clippedValue);
                   */
                },
                onHorizontalDragEnd: (DragEndDetails details) {
                  int note = widget.note;
                  if (details.primaryVelocity.sign > 0)
                    note *= 2;
                  if (details.primaryVelocity.sign < 0)
                    note ~/= 2;
                  if (note < widget.minNote)
                    note = widget.maxNote;
                  if (note > widget.maxNote)
                    note = widget.minNote;
                  widget.onChanged(widget.beats, note);
                },
                onTap: () {
                  int note = widget.note >= widget.maxNote ?
                    widget.minNote : 2 * widget.note;
                  widget.onChanged(widget.beats, note);
                },
                child: Text(widget.note.toString(),
                  style: textStyle,
                ),
              ),
            ]
          )
        )
      )
    );
  }
}

class _DividerPainter extends CustomPainter
{
  @override
  void paint(Canvas canvas, Size size) {
    // TODO: implement paint
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    // TODO: implement shouldRepaint
    return false;
  }
}
