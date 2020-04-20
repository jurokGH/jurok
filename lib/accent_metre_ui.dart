import 'dart:math';

import 'package:flutter/material.dart';
import 'package:owlenome/util.dart';
import 'NoteWidget.dart';
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
  final int duration = 1000;
  bool _notify = true;

  ScrollController _controller;
  ScrollPhysics _physics;

  AccentMetreState();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _controller = new ScrollController(initialScrollOffset: 0.0);
    _controller.addListener(() {
      if (_controller.position.haveDimensions && _physics == null) {
        setState(() {
          var dimension = _controller.position.maxScrollExtent / (_metreList.length - 1);
          _physics = CustomScrollPhysics(itemDimension: dimension);
        });
      }
    });
  }

  Widget metreBuilder(BuildContext context, int index)
  {
    final List<int> metres = Prosody.getSimpleMetres(widget.beats, widget.pivoVodochka);

    double width = widget.size.width / metres.length;
    if (widget.beats == 2)
      width /= 3;
    else if (widget.beats == 3)
      width /= 2;
    else if (widget.beats == 4)
      width /= 1.5;

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

    return
/*
        child:
      new Container(
        color: Colors.blue,
        width: widget.width,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 5),
*/
      FittedBox(
        fit: BoxFit.contain,
        child: Wrap(children: notes),
    );

    return Container(
        height: double.infinity,
        width: 300,
        color: Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0),
        margin: const EdgeInsets.all(20.0),
      );
  }

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
/*
    final List<Widget> wixMetres = new List<Widget>.generate(
      _metreList.length,
      (int i)
      {
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

        return new RotatedBox(
          quarterTurns: 1,
/*
        child:
      new Container(
        color: Colors.blue,
        width: widget.width,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 5),
*/
          child: FittedBox(
            fit: BoxFit.contain,
            child: Wrap(children: notes),
          ),
        );
      },
    );
*/
    // TODO: implement build
    return Container(
      width: widget.size.width,
      height: widget.size.height,
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
          index = clampLoop(index, 0, _metreList.length - 1);
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
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          controller: _controller,
          physics: _physics,
          itemExtent: widget.size.width,
          itemBuilder: metreBuilder,
/*
          onSelectedItemChanged: (int index) {
            print(index);
            if (_notify)  // To prevent reenter via widget.onBNotehanged::setState
            {
              _activeMetre = index;
              widget.onChanged(_metreList[index].beats, _metreList[index].note);
            }
            //setState(() {});
          },
          clipToSize: true,
          renderChildrenOutsideViewport: false,
          childDelegate: ListWheelChildListDelegate(children: wixMetres),
*/
        ),
      )
    );
  }
}

class CustomScrollPhysics extends ScrollPhysics {
  final double itemDimension;

  CustomScrollPhysics({this.itemDimension, ScrollPhysics parent})
      : super(parent: parent);

  @override
  CustomScrollPhysics applyTo(ScrollPhysics ancestor) {
    return CustomScrollPhysics(
        itemDimension: itemDimension, parent: buildParent(ancestor));
  }

  double _getPage(ScrollPosition position) {
    return position.pixels / itemDimension;
  }

  double _getPixels(double page) {
    return page * itemDimension;
  }

  double _getTargetPixels(
      ScrollPosition position, Tolerance tolerance, double velocity) {
    double page = _getPage(position);
    if (velocity < -tolerance.velocity) {
      page -= 0.5;
    } else if (velocity > tolerance.velocity) {
      page += 0.5;
    }
    return _getPixels(page.roundToDouble());
  }

  @override
  Simulation createBallisticSimulation(
      ScrollMetrics position, double velocity) {
    // If we're out of range and not headed back in range, defer to the parent
    // ballistics, which should put us back in range at a page boundary.
    if ((velocity <= 0.0 && position.pixels <= position.minScrollExtent) ||
        (velocity >= 0.0 && position.pixels >= position.maxScrollExtent))
      return super.createBallisticSimulation(position, velocity);
    final Tolerance tolerance = this.tolerance;
    final double target = _getTargetPixels(position, tolerance, velocity);
    if (target != position.pixels)
      return ScrollSpringSimulation(spring, position.pixels, target, velocity,
          tolerance: tolerance);
    return null;
  }

  @override
  bool get allowImplicitScrolling => false;
}
