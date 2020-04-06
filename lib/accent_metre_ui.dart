import 'package:flutter/material.dart';
import 'package:owlenome/util.dart';
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
  final Color color;
  final ValueChanged2<int, int> onChanged;
  final ValueChanged<bool> onOptionChanged;

  AccentMetreWidget({
    this.beats, this.noteValue, this.accents, this.pivoVodochka = true,
    this.size,
    this.color,
    @required this.onChanged,
    @required this.onOptionChanged,
  });

  @override
  State<StatefulWidget> createState() => AccentMetreState();
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
    if (widget.beats == 2)
      width /= 3;
    else if (widget.beats == 3)
      width /= 2;
    else if (widget.beats == 4)
      width /= 1.5;

    print("Aaccent::build");
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

      final Widget wix = new NoteWidget(
        subDiv: metres[i],
        denominator: widget.noteValue,
        active: -1,
        colorPast: Colors.black,
        colorNow: Colors.black,
        colorFuture: Colors.black,
        colorInner: Colors.black,
        accents: accents,
        coverWidth: true,
        showTuplet: true,
        showAccent: true,
        size: new Size(width, widget.size.height),
      );
      notes.add(wix);
    };

    // TODO: implement build
    return Container(
      child: GestureDetector(
        onTap: () {
          _activeMetre = _activeMetre + 1;
          if (_activeMetre >= _metreList.length)
            _activeMetre = 0;
          print("Accent::onChanged ${_metreList[_activeMetre].beats} - ${_metreList[_activeMetre].note}");

          widget.onChanged(_metreList[_activeMetre].beats, _metreList[_activeMetre].note);
        //setState(() {});
        //Provider.of<MetronomeState>(context, listen: false)
        //.setActiveState(widget.id, widget.subbeatCount);
        //widget.onTap(widget.id, widget.subbeatCount);
        },
        onHorizontalDragEnd: (DragEndDetails details) {
          int index = _activeMetre - details.primaryVelocity.sign.toInt();
          index = loopClamp(index, 0, _metreList.length - 1);
          _activeMetre = index;
          widget.onChanged(_metreList[_activeMetre].beats, _metreList[_activeMetre].note);
        },
        onVerticalDragEnd: (DragEndDetails details) {
          widget.onOptionChanged(!widget.pivoVodochka);
          //setState(() {});
        },
        onDoubleTap: () {
          widget.onOptionChanged(!widget.pivoVodochka);
        },
        child: Wrap(
          children: notes,
        )
      )
    );
  }
}
