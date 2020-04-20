import 'dart:math';

import 'package:flutter/material.dart';
import 'util.dart';
import 'NoteWidget.dart';
import 'metre.dart';
import 'prosody.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

int _getItemFromOffset({
  double offset,
  double itemExtent,
  double minScrollExtent,
  double maxScrollExtent,
})
{
  return (min(max(offset, minScrollExtent), maxScrollExtent) / itemExtent).round();
}


class MetreBarWidget extends StatefulWidget
{
  bool update;
  final int beats;
  final int noteValue;
  final bool pivoVodochka;
  final List<int> accents;
  final int activeMetre;
  final List<MetreBar> metres;
  final Size size;
  final Color color;
  final Color colorIrregular;
  final ValueChanged<int> onSelectedChanged;
  //final ValueChanged2<int, int> onMetreChanged;
  final ValueChanged<bool> onOptionChanged;

  MetreBarWidget({
    this.update = false,
    this.beats,
    this.noteValue,
    this.activeMetre,
    this.metres,
    this.accents,
    this.pivoVodochka = true,
    this.size,
    this.color,
    this.colorIrregular,
    @required this.onSelectedChanged,
    //@required this.onMetreChanged,
    @required this.onOptionChanged,
  });

  @override
  State<StatefulWidget> createState() => MetreBarState();
}

class MetreBarState extends State<MetreBarWidget>
{
/*
  static List<MetreBar> _metreList =
  [
    MetreBar(2, 2),
    MetreBar(3, 4),
    MetreBar(4, 4),
    MetreBar(6, 8),
    MetreBar(9, 8),
    MetreBar(12, 16),
    MetreBar(5, 8),  // 3+2/8
  ];
  int _activeMetre = 0;
*/
  final int duration = 1000;
  bool _notify = true;

  double _itemExtent;
  ScrollController _controller;
  CustomScrollPhysics _physics;

  MetreBarState();

  void finishUpdate(_)
  {
    widget.update = false;
    _notify = true;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _controller = new ScrollController(initialScrollOffset: widget.activeMetre * widget.size.width);
    _controller.addListener(() {
      if (_controller.position.haveDimensions && _physics == null && widget.metres.length > 1)
      {
        setState(() {
          double dimension = widget.metres.length > 1 ? _controller.position.maxScrollExtent / (widget.metres.length - 1) : 1;
          _itemExtent = dimension;
          _physics = CustomScrollPhysics(itemDimension: dimension);
        });
      }
    });
  }

  Widget metreBuilder(BuildContext context, int index)
  {
    final int beats = widget.metres[index].beats;
    //final List<int> metres = Prosody.getSimpleMetres(widget.beats, widget.pivoVodochka);
    // Simple metre array
    final List<int> metres = widget.metres[index].simpleMetres();
    final List<int> accents = widget.metres[index].accents;

    final List<Widget> notes = new List<Widget>();
    int j = 0;  // Simple metre 1st note index
    for (int i = 0; i < metres.length; i++)
    {
      //final List<int> accents = widget.accents?.sublist(j, j + metres[i]);
      final List<int> accents1 = accents.sublist(j, j + metres[i]);
      j += metres[i];

      //TODO Width
      double width = widget.size.width * metres[i] / beats;

      //print('widget.accents $index - $i');
      //print(accents1);
      //print(widget.size);

      final Widget wix = new NoteWidget(
        subDiv: metres[i],
        denominator: widget.noteValue,
        active: -1,
        colorPast: Colors.black,
        colorNow: Colors.black,
        colorFuture: Colors.black,
        colorInner: Colors.black,
        accents: accents1,
        maxAccentCount: 3,
        coverWidth: widget.beats > 5,// true,
        showTuplet: false,
        showAccent: true,
        size: new Size(width, widget.size.height),
      );
      notes.add(wix);
    }
    // Need size here to be defined
    return new Container(
      //color: Colors.blue,
      width: widget.size.width,
      height: widget.size.height,
      alignment: Alignment.center,
      //padding: EdgeInsets.symmetric(horizontal: 5),
      child: Wrap(children: notes),
    );
    return new FittedBox(
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
    double width = widget.size.width / widget.metres.length;
    if (widget.beats == 2)
      width /= 3;
    else if (widget.beats == 3)
      width /= 2;
    else if (widget.beats == 4)
      width /= 1.5;
    width = widget.size.width;

    print("MetreBar::build - ${widget.activeMetre} - ${widget.beats} - ${widget.noteValue} - ${widget.pivoVodochka} - ${widget.size}");
    //TextStyle textStyleColor = widget.textStyle.copyWith(color: widget.color);

    // To prevent reenter via widget.onBeat/NoteChanged::setState
    // when position is changing via jumpToItem/animateToItem
    if (widget.update)
    {
      _notify = false;
      print('MetreBar::update1 ${widget.beats}');
      //TODO Need?
      final int activeMetre = clampLoop(widget.activeMetre, 0, widget.metres.length - 1);
      _controller.jumpTo(widget.size.width * activeMetre);
      finishUpdate(0);
    }

    final ListView listView = new ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: _controller,
      physics: _physics,
      itemExtent: widget.size.width,
      itemCount: widget.metres.length,
      itemBuilder: metreBuilder,
    );

    if (_controller != null && _controller.hasClients)
    {
    //&& _controller.position?.haveDimensions)
      double dimension = widget.metres.length > 1 ? _controller.position.maxScrollExtent / (widget.metres.length - 1) : 1;
      if (_itemExtent != dimension)
        _physics?.itemDimension = dimension;
      //_controller.jumpTo(widget.size.width * widget.activeMetre);
    }

    /*
return Container(
    width: widget.size.width,
    height: widget.size.height,
    child: ListView.builder(
    scrollDirection: Axis.horizontal,
    //controller: _controller,
    //physics: _physics,
    itemExtent: 50,//widget.size.width,
    itemCount: 5,//widget.metres.length,
    itemBuilder: metreBuilder,
    ));
*/

    return Container(
        width: widget.size.width,
        height: widget.size.height,
        //TODO color: widget.metres[widget.activeMetre].regularAccent ? widget.color : widget.colorIrregular,
        child:
      GestureDetector(
        onTap: () {
          int currentIndex = widget.activeMetre + 1;
          if (currentIndex >= widget.metres.length)
            currentIndex = 0;
          print("MetreBar::onTap ${widget.metres[currentIndex].beats} - ${widget.metres[currentIndex].note}");
          widget.onSelectedChanged(currentIndex);
          _controller.jumpTo(widget.size.width * currentIndex);

          //setState(() {});
          //Provider.of<MetronomeState>(context, listen: false)
          //.setActiveState(widget.id, widget.subbeatCount);
        },
/*
        onHorizontalDragEnd: (DragEndDetails details) {
          int index = _activeMetre - details.primaryVelocity.sign.toInt();
          index = loopClamp(index, 0, _metreList.length - 1);
          _activeMetre = index;
          widget.onChanged(_metreList[_activeMetre].beats, _metreList[_activeMetre].note);
        },
*/
        onVerticalDragEnd: (DragEndDetails details) {
          print("onVerticalDragEndonVerticalDragEnd");
          widget.onOptionChanged(!widget.pivoVodochka);
          //setState(() {});
        },
        onDoubleTap: () {
          print("onDoubleTaponDoubleTap");
          widget.onOptionChanged(!widget.pivoVodochka);
        },
        onLongPressStart: (LongPressStartDetails details) {
          print("onLongPress");
          widget.onOptionChanged(true);
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification)
          {
            //ScrollStartNotification
            //ScrollEndNotification
            print("NotificationListener 1");
            if (notification.depth == 0 &&
              widget.onSelectedChanged != null &&
              notification is ScrollUpdateNotification)
            {
              final ScrollMetrics metrics = notification.metrics;
              final int currentIndex = _getItemFromOffset(
                offset: metrics.pixels,
                itemExtent: _itemExtent,
                minScrollExtent: metrics.minScrollExtent,
                maxScrollExtent: metrics.maxScrollExtent,
              );
              print("NotificationListener currentIndex: $currentIndex - $_notify");

              if (currentIndex != widget.activeMetre && _notify)
              {
                print("NotificationListener 2");
                widget.onSelectedChanged(currentIndex);
              }
              return true;
            }
            return false;
          },
          child: listView,
        ),
      )
    );
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
  }
}

class CustomScrollPhysics extends ScrollPhysics
{
  double itemDimension;

  CustomScrollPhysics({this.itemDimension, ScrollPhysics parent}): super(parent: parent);

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
