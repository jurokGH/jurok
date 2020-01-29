import 'package:flutter/material.dart';
import 'note_ui.dart';
import 'metre.dart';
import 'prosody.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

class AccentMetreWidget extends StatefulWidget
{
  final int beats;
  final int noteValue;
  final bool pivoVodochka;
  final List<int> accents;
  final Size size;
  final ValueChanged2<int, int> onChanged;

  AccentMetreWidget({
    this.beats, this.noteValue, this.accents, this.size, this.pivoVodochka = true,
    @required this.onChanged,
  });

  @override
  State<StatefulWidget> createState() {
    return AccentMetreState();
  }
}

class AccentMetreState extends State<AccentMetreWidget>
{
  static List<Metre> _metreList =
  [
    Metre(2, 2),
    Metre(3, 4),
    Metre(4, 4),
    Metre(6, 8),
    Metre(9, 8),
    Metre(12, 16),
    Metre(5, 8),  // 3+2/8
  ];
  int _activeMetre = 0;

  AccentMetreState();

  @override
  Widget build(BuildContext context)
  {
    final List<int> metres = Prosody.getSimpleMetres(widget.beats, widget.pivoVodochka);
    double width = widget.size.width / metres.length;
    if (widget.beats <= 4)
      width /= 2;

    print(widget.accents);
    //TextStyle textStyleColor = widget.textStyle.copyWith(color: widget.color);
    final List<Widget> notes = new List<Widget>();
    int j = 0;  // Simple metre 1st note index
    for (int i = 0; i < metres.length; i++)
    {
      final List<int> accents = widget.accents?.sublist(j, j + metres[i]);
      print('widget.accents');
      print(accents);
      j += metres[i];

      Widget wix = new SizedBox(
        width: width,
        height: widget.size.height,
        child:
        NoteWidget(
          subDiv: metres[i],
          denominator: widget.noteValue,
          active: -1,
          colorPast: Colors.white,
          colorNow: Colors.red,
          colorFuture: Colors.white,
          accents: accents,
        ),
      );
      notes.add(wix);
    };

    // TODO: implement build
    return Container(
      child: GestureDetector(
        onTap: () {
          _activeMetre = (_activeMetre + 1) % _metreList.length;
          if (_activeMetre >= _metreList.length)
            _activeMetre = 0;
          widget.onChanged(_metreList[_activeMetre].beats, _metreList[_activeMetre].note);
        //setState(() {});
        //Provider.of<MetronomeState>(context, listen: false)
        //.setActiveState(widget.id, widget.subbeatCount);
        //widget.onTap(widget.id, widget.subbeatCount);
        },
        onHorizontalDragEnd: (DragEndDetails details) {
          int index = widget.beats + details.primaryVelocity.sign.toInt();
          if (index < 0)
            index = _metreList.length - 1;
          if (index >= _metreList.length)
            index = 0;
          _activeMetre = index;
          ;
          widget.onChanged(_metreList[_activeMetre].beats, _metreList[_activeMetre].note);
        },
        onVerticalDragEnd: (DragEndDetails details) {
          bool pivoVodochka = !widget.pivoVodochka;
          //widget.onChanged(_metreList[_activeMetre].beats, _metreList[_activeMetre].note);
        },
        child: Wrap(
        children: notes,
      )
    ));
  }
}
