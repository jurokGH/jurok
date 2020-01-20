import 'package:flutter/material.dart';
import 'note_ui.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

class AccentMetreWidget extends StatefulWidget
{
  final int beats;
  final int noteValue;
  final List<int> accents;
  final Size size;

  AccentMetreWidget({
    this.beats, this.noteValue, this.accents, this.size
  });
  /*
  final int minBeats;
  final int maxBeats;
  final int note;
  final int minNote;
  final int maxNote;
  final double width;
  final double height;
  final Color color;
  final TextStyle textStyle;

  //final ValueChanged<int> onChanged;
  final ValueChanged2<int, int> onChanged;
    @required this.onChanged,
    this.minBeats = 1, this.maxBeats = 8,
    this.minNote = 1, this.maxNote = 8,
    this.width = 0, this.height = 0,
    this.color = Colors.white,
    @required this.textStyle});
*/

  @override
  State<StatefulWidget> createState() {
    return AccentMetreState();
  }
}

class AccentMetreState extends State<AccentMetreWidget>
{
  AccentMetreState();

  @override
  Widget build(BuildContext context)
  {
    //TextStyle textStyleColor = widget.textStyle.copyWith(color: widget.color);
    final List<Widget> notes = new List<Widget>();
    for (int i = 0; i < widget.beats; i++)
    {
      final List<int> accent = widget.accents != null ? new List<int>.filled(1, widget.accents[i]) : null;

      Widget wix = new SizedBox(
        width: widget.size.width / widget.beats,
        height: widget.size.height,
        child:
      NoteWidget(
        subDiv: 1,
        denominator: widget.noteValue,
        active: -1,
        activeNoteType: ActiveNoteType.explosion,
        colorPast: Colors.white,
        colorNow: Colors.red,
        colorFuture: Colors.white,
        accents: accent,
      ),
      );
      notes.add(wix);
    };

    // TODO: implement build
    return Container(
      child: Wrap(
      children: notes,
    ));
  }
}
