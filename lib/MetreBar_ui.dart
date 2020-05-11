import 'dart:math';
import 'package:flutter/material.dart';

import 'BarBracket.dart';
import 'NoteWidget.dart';
import 'metre.dart';
import 'util.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

int _getItemFromOffset({
  double offset, double itemExtent,
  double minScrollExtent, double maxScrollExtent,})
{
  return (min(max(offset, minScrollExtent), maxScrollExtent) / itemExtent).round();
}

/// Metre bar widget

class MetreBarWidget extends StatefulWidget
{
  /// TODO Update flag
  bool update;
  /// Metre list to display
  final List<MetreBar> metres;
  /// Current active metre in list
  final int activeMetre;
  /// Widget size
  Size size;
  /// Background color of regular metre
  final Color color;
  /// Background color of irregular metre
  final Color colorIrregular;
  /// Notes color
  final Color noteColor;
  /// Current metre changed callback
  final ValueChanged<int> onSelectedChanged;
  /// Accentation option changed callback
  final ValueChanged<bool> onOptionChanged;
  /// Reset metre to regular callback
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
  double _itemExtent = 0;  /// List item width
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
    //_itemExtent = 288;
    //_physics = CustomScrollPhysics(itemDimension: _itemExtent);

    _controller = new ScrollController(initialScrollOffset: widget.activeMetre * widget.size.width);
    _controller.addListener(updateExtent);
  }

  void updateExtent()
  {
    if (_controller.position.haveDimensions && widget.metres.length > 1 &&
      (_physics == null || _itemExtent != widget.size.width) )
    {
      //setState(() {
      // TODO
      double dimension = widget.metres.length > 1 ? _controller.position.maxScrollExtent / (widget.metres.length - 1) : 1;
      _itemExtent = widget.size.width;
      print('MetreBarState::updateExtent $dimension - $_itemExtent - ${widget.size}');
      _physics = CustomScrollPhysics(itemDimension: _itemExtent);
      //});
    }
  }

  Widget metreBuilder(BuildContext context, int index)
  {
    final MetreBar metreBar = widget.metres[widget.activeMetre];
    final int beats = metreBar.beats;
    // Simple metre array
    final List<int> metres = metreBar.simpleMetres();
    final List<int> accents = metreBar.accents;

    print('metreBuilder $index');
    print(accents);
    print(metres);

    final List<Widget> notes = new List<Widget>();

    final double btnPadding = 0.2 * Theme.of(context).buttonTheme.height;
    final Size bracketSize = new Size(3.0 * btnPadding, widget.size.height);
    print('bracketSize $bracketSize');
    // Add left bracket
    notes.add(new Container(
      width: 0.5 * bracketSize.width,
      height: bracketSize.height,
    ));
    notes.add(new BarBracketWidget(
        direction: BarBracketDirection.left,
        color: Colors.black,
        size: bracketSize
    ));

    int j = 0;  // Simple metre 1st note index
    for (int i = 0; i < metres.length; i++)
    {
      // Build note with subbeats
      final List<int> accents1 = accents.sublist(j, j + metres[i]);
      j += metres[i];

      //TODO Width
      double width = (widget.size.width - 3 * bracketSize.width) * metres[i] / beats;
      //width = (widget.size.width) * metres[i] / beats;

      print('metreBuilder:width $width');
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

    // Add right bracket
    notes.add(new BarBracketWidget(
        direction: BarBracketDirection.right,
        color: Colors.black,
        size: bracketSize
    ));
    notes.add(new Container(
      width: 0.5 * bracketSize.width,
      height: bracketSize.height,
    ));

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: notes
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
      //widget.size = new Size(0.9 * constraints.maxWidth, widget.size.height);

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
        //print('MetreBar::_physics $dimension - $_itemExtent - ${widget.size}');
        if (_itemExtent != dimension) {
          print('MetreBar::_physics $dimension - $_itemExtent - ${widget.size}');
          ;//_physics?.itemDimension = dimension;
        }
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
              /// Select and display next metre in list
              int currentIndex = widget.activeMetre + 1;
              if (currentIndex >= widget.metres.length)
                currentIndex = 0;
              print("MetreBar::onTap $currentIndex - ${widget.metres[currentIndex].beats} - ${widget.metres[currentIndex].note}");
              widget?.onSelectedChanged(currentIndex);
              print("MetreBar::onTap1 $currentIndex ${widget.size.width}");
              _notify = false;
              _controller.jumpTo(widget.size.width * currentIndex);
              _notify = true;
              print("MetreBar::onTap2 $currentIndex");
              //TODO setState(() {});
              //TODO Provider.of<MetronomeState>(context, listen: false)
            },
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
                if (notification.depth == 0 &&
                    notification is ScrollStartNotification)
                {
                  print("ScrollStartNotification");
                  return false;
                }
                print("NotificationListener $_notify");
                if (_notify && notification.depth == 0 &&
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

                  // Change current selected metre
                  if (currentIndex != widget.activeMetre)
                  {
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
    });
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print("didChangeDependencies");
  }

  @override
  void didUpdateWidget(MetreBarWidget oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    print("didUpdateWidget");
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
  bool get allowImplicitScrolling => true;
}
