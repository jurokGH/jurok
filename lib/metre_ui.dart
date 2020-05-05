import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'metre.dart';
import 'metronome_state.dart';
import 'util.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

class WheelScrollController extends FixedExtentScrollController
{
@override
  ScrollPosition createScrollPosition(ScrollPhysics physics, ScrollContext context, ScrollPosition oldPosition) {
    // TODO: implement createScrollPosition
    return super.createScrollPosition(physics, context, oldPosition);
  }
}

class LimitSizeText extends StatelessWidget
{
  final String text;
  final TextAlign textAlign;
  final TextStyle style;
  final String template;
  final TextStyle templateStyle;

  LimitSizeText({
    @required this.text,
    this.textAlign,
    @required this.style,
    this.template,
    this.templateStyle
  });

  Size _textSize(String str, TextStyle style)
  {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: str, style: style), maxLines: 1,
      textDirection: TextDirection.ltr,
      textAlign: textAlign == null ? TextAlign.center : textAlign)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  double maxFontSize(String text, TextStyle style, Size size)
  {
    for (double fontSize = style.fontSize; fontSize > 0; fontSize--)
    {
      Size textSize = _textSize(text, style.copyWith(fontSize: fontSize));
      bool fit = textSize.width <= size.width && textSize.height <= size.height;
      //print('textSize1 - $fontSize - $textSize - $size');
      if (fit)
        return fontSize;
    }
    // TODO
    return 1;
  }

  Widget _builder(BuildContext context, BoxConstraints constraints)
  {
    final double fontSize = maxFontSize(template == null ? text : template,
        templateStyle == null ? style : templateStyle,
        constraints.biggest);

    if (fontSize != style.fontSize)
      print('LimitSizeText limit to $fontSize');

    return Text(text,
      textAlign: textAlign,
      textDirection: TextDirection.ltr,
      maxLines: 1,
      //style: widget.textStyle
      style: style.copyWith(fontSize: fontSize)
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: _builder
    );
  }
}

class MetreWidget extends StatefulWidget
{
  bool update;
  final int beats;
  final int minBeats;
  final int maxBeats;
  final int noteIndex;
  final int minNoteIndex;
  final int maxNoteIndex;

  final double width;
  final double height;
  final double itemExtent;
  final Color color;
  final TextStyle textStyle;
  final TextStyle textStyleSelected;

  final ValueChanged<int> onBeatChanged;
  final ValueChanged<int> onNoteChanged;

  MetreWidget({
    this.update = false,
    @required this.beats,
    @required note,
    @required this.onBeatChanged,
    @required this.onNoteChanged,
    this.minBeats = 1, this.maxBeats = 32,
    minNote = 1, maxNote = 32,
    this.width = double.infinity,
    this.height = double.infinity,
    this.itemExtent = 40,
    this.color = Colors.white,
    @required this.textStyle,
    @required this.textStyleSelected
  }): noteIndex = noteValue2index(note),
      minNoteIndex = noteValue2index(minNote),
      maxNoteIndex = noteValue2index(maxNote);

  @override
  State<StatefulWidget> createState() {
    return MetreState();
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
  Offset _tapPosition;

  FixedExtentScrollController beatController;
  FixedExtentScrollController noteController;
  final int duration = 1000;
  bool _notify = true;

  MetreState();

  void _beatScrollListener()
  {
    print('_beatScrollListener');
  }

  void finishUpdate(_)
  {
    widget.update = false;
    _notify = true;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    beatController = new FixedExtentScrollController(initialItem: widget.beats - widget.minBeats);
    //beatController.addListener(_beatScrollListener);
    noteController = new FixedExtentScrollController(initialItem: widget.noteIndex - widget.minNoteIndex);
  }

  @override
  Widget build(BuildContext context)
  {
    //TODO final MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    double width = widget.width;
    double height = 0.5 * widget.height - 2;

    print('Metre::build ${widget.beats}');

    // To prevent reenter via widget.onBeat/NoteChanged::setState
    // when position is changing via jumpToItem/animateToItem
    if (widget.update)
    {
      _notify = false;
      print('update1 ${widget.beats}');
      //TODO Need?
      int beats = clampLoop(widget.beats, widget.minBeats, widget.maxBeats);
      if (true)
      {
        beatController.jumpToItem(beats - widget.minBeats);
        noteController.jumpToItem(widget.noteIndex - widget.minNoteIndex);
        finishUpdate(0);
      }
      else
      {
        //TODO Both run => when finishUpdate?
        beatController.animateToItem(beats - widget.minBeats,
          duration: Duration(milliseconds: duration), curve: Curves.ease)
          .catchError(finishUpdate).then<void>(finishUpdate);
        noteController.animateToItem(widget.noteIndex - widget.minNoteIndex,
          duration: Duration(milliseconds: duration), curve: Curves.ease)
          .catchError(finishUpdate).then<void>(finishUpdate);
      }
      print('update2 ${widget.beats}');
      //widget.update = false;
    }

/*
        onDoubleTap: () {
          _iMetre++;
          if (_iMetre >= _metreList.length)
            _iMetre = 0;
          widget.onChanged(_metreList[_iMetre].beats, _metreList[_iMetre].note);
        },
        onTapDown:  _storePosition,
        //onLongPress: _showMenu,
        onVerticalDragEnd: (DragEndDetails details) {
          _iMetre -= details.primaryVelocity.sign.toInt();
          if (_iMetre >= _metreList.length)
            _iMetre = 0;
          if (_iMetre < 0)
            _iMetre = _metreList.length - 1;
          widget.onChanged(_metreList[_iMetre].beats, _metreList[_iMetre].note);
        },
 */
    final double fontSize = 0.7 * height;//6
    final double fontSizeHi = 0.7 * height;//65
    final TextStyle textStyle = widget.textStyle.copyWith(fontSize: fontSize);
    final TextStyle textStyleHi = widget.textStyleSelected.copyWith(fontSize: fontSizeHi);
    final TextStyle textStyleHiB = textStyle.copyWith(fontSize: fontSizeHi, fontWeight: FontWeight.bold);

    final List<Widget> wixBeats = new List<Widget>.generate(widget.maxBeats - widget.minBeats + 1,
      (int i) => new RotatedBox(
        quarterTurns: 1,
        child:
//        FittedBox(
//          fit: BoxFit.fitHeight,
//          child:
        LimitSizeText(
          text: (i + widget.minBeats).toString(),
          textAlign: TextAlign.center,
          //textScaleFactor: 1.5,
          style: i + widget.minBeats == widget.beats ? textStyleHi : textStyle,
          template: '12',
          templateStyle: textStyleHi,
        ),
//        ),
      )
    );

    final List<Widget> wixNotes = new List<Widget>.generate(widget.maxNoteIndex - widget.minNoteIndex + 1,
      (int i) {
        int noteValue = index2noteValue(i + widget.minNoteIndex);
        return new RotatedBox(
          quarterTurns: 1,
          child:
//          FittedBox(
//            fit: BoxFit.fitHeight,
//            child:
            LimitSizeText(
            text: noteValue.toString(),
            textAlign: TextAlign.center,
            style: i + widget.minNoteIndex == widget.noteIndex ? textStyleHiB : textStyle,
            // To Change color for irregular metre:
            // style: i + widget.minNoteIndex == widget.noteIndex ? widget.textStyleSelected : widget.textStyle,
            template: '16',
            templateStyle: textStyleHiB,
          ),
//          ),
        );
      }
    );

    return
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/Metre.png'),
                  fit: BoxFit.fill,
                ),
/*
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [widget.color.withOpacity(0.2), widget.color])
*/
            ),
            width: width,
            height: height,
            child: RotatedBox(
              quarterTurns: 3,
              child: GestureDetector(
                onTap: () {
                  print('onTap ${widget.beats}');
                  int beats = clampLoop(widget.beats + 1, widget.minBeats, widget.maxBeats);
                  print('onTap $beats');
                  widget.onBeatChanged(beats);
                  beatController.jumpToItem(beats - widget.minBeats);
                  //setState(() {});
                },
                child: Container(
                  //color: widget.color,
                  width: height,//double.infinity,
                  height: width,
                  child:
                  ListWheelScrollView.useDelegate(
                    controller: beatController,
                    physics: new FixedExtentScrollPhysics(),
                    diameterRatio: 1.0,
                    perspective: 0.004,
                    offAxisFraction: 0,
                    useMagnifier: false,
                    magnification: 1,
                    itemExtent: widget.itemExtent,
                    squeeze: 1.5,
                    onSelectedItemChanged: (int index) {
                      print('onSelectedItemChanged ${index + widget.minBeats} - $_notify');
                      if (_notify)  // To prevent reenter via widget.onBeatChanged::setState
                        widget.onBeatChanged(index + widget.minBeats);
                      //setState(() {});
                    },
                    clipToSize: true,
                    renderChildrenOutsideViewport: false,
                    childDelegate: ListWheelChildLoopingListDelegate(children: wixBeats),
                  )
                )
              )
            ),
          ),

          Container(
            //width: 0.3 * _sizeCtrls.height,
            height: 4,
          ),

          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/Metre.png'),
                fit: BoxFit.fill,
              ),
/*
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white70, Colors.white70])
*/
            ),
            width: width,
            height: height,
            child: RotatedBox(
              quarterTurns: 3,
              child: GestureDetector(
                onTap: () {
                  int index = clampLoop(widget.noteIndex + 1, widget.minNoteIndex, widget.maxNoteIndex);
                  widget.onNoteChanged(index2noteValue(index));
                  noteController.jumpToItem(index - widget.minNoteIndex);
                  //setState(() {});
                },
                child: Container(
                  //color: widget.color,
                  width: height,//double.infinity,
                  height: width,
                  child:
                  ListWheelScrollView.useDelegate(
                    controller: noteController,
                    physics: new FixedExtentScrollPhysics(),
                    diameterRatio: 1.0,
                    perspective: 0.004,
                    offAxisFraction: 0.0,
                    useMagnifier: false,
                    magnification: 1.0,
                    itemExtent: widget.itemExtent,
                    squeeze: 1.5,
                    onSelectedItemChanged: (int index) {
                      //print(index);
                      if (_notify)  // To prevent reenter via widget.onBNotehanged::setState
                        widget.onNoteChanged(index2noteValue(index + widget.minNoteIndex));
                      //setState(() {});
                    },
                    clipToSize: true,
                    renderChildrenOutsideViewport: false,
                    childDelegate: ListWheelChildLoopingListDelegate(children: wixNotes),
                  )
                )
              )
            ),
          ),
        ]
      );
  }

  void _storePosition(TapDownDetails details)
  {
    _tapPosition = details.globalPosition;
  }

  void _showMenu()
  {
    TextStyle textStyleMenu = widget.textStyle;
    //.copyWith(color: widget.color);

    List<PopupMenuEntry<int>> menuItems = new List<PopupMenuEntry<int>>();
    for (int i = 0; i < _metreList.length; i++)
      menuItems.add(new PopupMenuItem(
        value: i,
        child: Text(_metreList[i].toString()),
        textStyle: textStyleMenu,
        height: 28
      ));

    final RenderBox overlay = Overlay.of(context).context.findRenderObject();

    showMenu<int>(
      context: context,
      position: //RelativeRect.fromLTRB(0, 0, 0, 0),
      RelativeRect.fromRect(
        _tapPosition & Size(100, 100), // smaller rect, the touch area
        Offset.zero & overlay.size   // Bigger rect, the entire screen
      ),
      items: menuItems,
      initialValue: _iMetre,
      elevation: 4,
      //shape: ,
      color: widget.color,
      //captureInheritedThemes: false,
    )
      .then<void>((int choice) {
      if (choice != null)
      {
        setState(() {
          _iMetre = choice;
        });
        //widget.onChanged(_metreList[_iMetre].beats, _metreList[_iMetre].note);
      }
    });
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
