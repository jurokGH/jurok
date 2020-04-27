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
  final List<MetreBar> metres;
  final int activeMetre;
  final Size size;
  final Color color;
  final Color colorIrregular;
  final Color noteColor;
  final ValueChanged<int> onSelectedChanged;
  final ValueChanged<bool> onOptionChanged;
  final Function onResetMetre;

  MetreBarWidget({
    this.update = false,
    this.metres,
    this.activeMetre,
    this.size,
    this.color,
    this.colorIrregular,
    this.noteColor = Colors.black,
    this.onSelectedChanged,
    this.onOptionChanged,
    this.onResetMetre,
  });

  @override
  State<StatefulWidget> createState() => MetreBarState();
}

class MetreBarState extends State<MetreBarWidget>
{
  // Moved out static List<MetreBar> _metreList;
  // int _activeMetre = 0;
  // final int duration = 1000;

  ScrollController _controller;
  CustomScrollPhysics _physics;
  double _itemExtent;  /// List item width
  bool _notify = true;

  MetreBarState();

  void finishUpdate(_)
  {
    widget.update = false;
    _notify = true;
  }

  @override
  void initState()
  {
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
    final MetreBar metreBar = widget.metres[widget.activeMetre];
    final int beats = metreBar.beats;
    // Simple metre array
    final List<int> metres = metreBar.simpleMetres();
    final List<int> accents = metreBar.accents;

    //print('metreBuilder $index');
    //print(accents);
    //print(metres);

    final List<Widget> notes = new List<Widget>();
    int j = 0;  // Simple metre 1st note index
    for (int i = 0; i < metres.length; i++)
    {
      // Build note with subbeats
      final List<int> accents1 = accents.sublist(j, j + metres[i]);
      j += metres[i];

      //TODO Width
      double width = widget.size.width * metres[i] / beats;

      //print('widget.accents $index - $i - ${metres[i]} - ${metreBar.note}');
      //print(accents1);

      final Widget wix = new NoteWidget(
        subDiv: metres[i],
        denominator: metreBar.note,
        active: -2,
        colorPast: widget.noteColor,
        colorNow: Colors.black,
        colorFuture: Colors.black,
        colorInner: Colors.black,
        accents: accents1,
        maxAccentCount: 3,
        coverWidth: beats > 5,// true,
        showTuplet: false,
        showAccent: true,
        size: new Size(width, widget.size.height),
      );
      notes.add(wix);
    }
/*
    return Container(
      width: widget.size.width,
      height: widget.size.height,
      alignment: Alignment.center,
      color: Color((Random().nextDouble() * 0xFFFFFF).toInt() << 0).withOpacity(1.0),
      child: Text(index.toString()),
    );
*/
    // Need size to be defined here!
    return new Container(
      //color: Colors.blue,
      width: widget.size.width,
      height: widget.size.height,
      alignment: Alignment.center,
      //padding: EdgeInsets.symmetric(horizontal: 5),
      // TODO LayoutBuilder
      child: Row(
        children: notes
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    final MetreBar metreBar = widget.metres[widget.activeMetre];
    print("MetreBar::build - ${widget.activeMetre} - ${metreBar.beats} - ${metreBar.note} - ${metreBar.accentOption} - ${widget.size}");
    print(widget.metres);
    //print(widget.accents);
    //TextStyle textStyleColor = widget.textStyle.copyWith(color: widget.color);

    // To prevent reenter via widget.onBeat/NoteChanged::setState
    // when position is changing via jumpToItem/animateToItem
    if (widget.update)
    {
      _notify = false;
      //TODO Need?
      final int activeMetre = clampLoop(widget.activeMetre, 0, widget.metres.length - 1);
      print('MetreBar::update1 $activeMetre');
      _controller.jumpTo(widget.size.width * activeMetre);
    }
    if (false && _controller != null && _controller.hasClients)
    {
      double dimension = widget.metres.length > 1 ? _controller.position.maxScrollExtent / (widget.metres.length - 1) : 1;
      print('MetreBar::_physics $dimension - $_itemExtent - ${widget.size}');
      if (_itemExtent != dimension)
        _physics?.itemDimension = dimension;
    }

    final ListView listView = new ListView.builder(
      scrollDirection: Axis.horizontal,
      controller: _controller,
      physics: _physics,
      itemExtent: widget.size.width,
      itemCount: widget.metres.length,
      itemBuilder: metreBuilder,
    );

    if (widget.update)
      finishUpdate(0);

    return Container(
      width: widget.size.width,
      height: widget.size.height,
      //TODO color: widget.metres[widget.activeMetre].regularAccent ? widget.color : widget.colorIrregular,
      child: GestureDetector(
        onTap: ()
        {
          int currentIndex = widget.activeMetre + 1;
          if (currentIndex >= widget.metres.length)
            currentIndex = 0;
          print("MetreBar::onTap $currentIndex - ${widget.metres[currentIndex].beats} - ${widget.metres[currentIndex].note}");
          widget?.onSelectedChanged(currentIndex);
          print("MetreBar::onTap1 $currentIndex");
          _notify = false;
          _controller.jumpTo(widget.size.width * currentIndex);
          _notify = true;
          print("MetreBar::onTap2 $currentIndex");
          //TODO setState(() {});
          //TODO Provider.of<MetronomeState>(context, listen: false)
        },
/*      onVerticalDragEnd: (DragEndDetails details) {
          print("onVerticalDragEndonVerticalDragEnd");
          final int accentOption = widget.metres[widget.activeMetre].accentOption;
          widget?.onOptionChanged(!);
          //setState(() {});
        },*/
        onDoubleTap: () {
          print("onDoubleTaponDoubleTap");
          final bool pivoVodochka = widget.metres[widget.activeMetre].accentOption == 0;
          widget?.onOptionChanged(!pivoVodochka);
        },
        onLongPressStart: (LongPressStartDetails details) {
          print("onLongPress");
          widget?.onResetMetre();
        },
        child: NotificationListener<ScrollNotification>(
          onNotification: (ScrollNotification notification)
          {
            //ScrollStartNotification, ScrollEndNotification
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
                widget?.onSelectedChanged(currentIndex);
              }
              return true;
            }
            return false;
          },
          child: listView,
        ),
      )
    );
  }
}

/// Scroll physics to return to current item on half swipe
class CustomScrollPhysics extends ScrollPhysics
{
  double itemDimension;

  CustomScrollPhysics({this.itemDimension, ScrollPhysics parent}): super(parent: parent);

  @override
  CustomScrollPhysics applyTo(ScrollPhysics ancestor) {
    return CustomScrollPhysics(itemDimension: itemDimension, parent: buildParent(ancestor));
  }

  double _getPage(ScrollPosition position) {
    return position.pixels / itemDimension;
  }

  double _getPixels(double page) {
    return page * itemDimension;
  }

  double _getTargetPixels(ScrollPosition position, Tolerance tolerance, double velocity)
  {
    double page = _getPage(position);
    if (velocity < -tolerance.velocity)
      page -= 0.5;
    else if (velocity > tolerance.velocity)
      page += 0.5;
    return _getPixels(page.roundToDouble());
  }

  @override
  Simulation createBallisticSimulation(ScrollMetrics position, double velocity)
  {
    print('createBallisticSimulation');
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
