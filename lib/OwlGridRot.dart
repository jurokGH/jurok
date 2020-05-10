import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'HeadOwlWidget.dart';
import 'beat_metre.dart';
import 'SkinRot.dart';
import 'util.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

List<int> beatRowsList(int beatCount)
{
  List<int> beatRows = new List<int>(1 + (beatCount - 1) ~/ 4);
  if (beatCount <= 4)
    beatRows[0] = beatCount;
  else if (beatCount <= 8)
  {
    beatRows[0] = beatCount ~/ 2;
    beatRows[1] = beatCount - beatRows[0];
  }
  else if (beatCount <= 12)
  {
    beatRows[2] = beatCount ~/ 3;
    beatRows[1] = (beatCount - beatRows[2]) ~/ 2;
    beatRows[0] = beatCount - beatRows[1] - beatRows[2];
  }
  else
    beatRows = [];
  return beatRows;
}

class _OwlLayout extends MultiChildLayoutDelegate
{
  final int count;
  final double aspect;
  /// Maximum owl size over size when there are 4 owls in row
  final double maxCoef4;
  final Offset spacing;
  final EdgeInsets padding;
  /// layout[i] - number of Owls in each i-th row
  final List<int> layout;

  Size widgetSize;
  bool _horizontalBound;

  _OwlLayout({
    @required this.count,
    @required this.aspect,
    @required this.layout,
    this.maxCoef4 = 0,
    this.spacing = Offset.zero,
    this.padding = EdgeInsets.zero,
  }): assert(0 < count && count <= 12);

  /// Find Owl's rectangle occupied size
  Size calcImageSize(Size size)
  {
    // Grid: xCount x yCount
    final int xCount = maxValue(layout);
    final int yCount = layout.length;
    if (xCount <= 0 || yCount <= 0)
      return widgetSize = Size.zero;

    // Size is (0, 0) if display does not show (e.g. locked)
    double w = (size.width - (xCount - 1) * spacing.dx - padding.horizontal) / xCount;
    double h = (size.height - (yCount - 1) * spacing.dy - padding.vertical) / yCount;
    if (w <= 0 || h <= 0)
      return widgetSize = Size.zero;

    // Width of 4 owls in a row if constrained by overall grid width
    double width4 = (size.width - 3 * spacing.dx - padding.horizontal) / 4;
    // Width of 4 owls in a row if constrained by overall grid height
    double width4h = (size.height - padding.vertical) / (4 * aspect);
    // Max owl width is no more than maxCoef4 * (minimum of 2 widths)
    double maxWidth = maxCoef4 * (width4 > width4h ? width4h : width4);

    double x0, y0;
    x0 = y0 = 0;
    double dy;

    // Y > X
    _horizontalBound = h > aspect * w;
    if (_horizontalBound)  // Horizontally bound
    {
      h = aspect * w;
      y0 = (size.height - yCount * h) / (2 * yCount);
      dy = h + 2 * y0;
    }
    else  // Vertically bound
    {
      w = h / aspect;
      y0 = 0;
      dy = h + spacing.dy;
      print('vert');
    }

    //TODO
    // Limit owl size by maxCoef4 coefficient
    if (maxCoef4 > 0  && w > maxWidth && yCount == 1)
    {
      w = maxWidth;
      h = aspect * maxWidth;
    }
    debugPrint('calcImageSize $size - $w - $h');

    // TODO Cache-check with size?
    return widgetSize = new Size(w, h);
  }

  @override
  void performLayout(Size size)
  {
    //assert(count == layout.length);
    print('performLayout $size');

    double y0, dy;
    final int yCount = layout.length;
    final bool horizontalBound = widgetSize.height * yCount <
      size.height - (yCount - 1) * spacing.dy - padding.vertical;
    if (_horizontalBound)  // Horizontally bound
    {
      // MainAxisAlignment.spaceAround logic
      y0 = (size.height - yCount * widgetSize.height) / (2 * yCount);
      dy = widgetSize.height + 2 * y0;
      print('vert');
    }
    else  // Vertically bound
    {
      y0 = yCount == 1 ? (size.height - widgetSize.height) / 2 : padding.top;
      dy = widgetSize.height + spacing.dy;
      print('horz $y0 - ${widgetSize.height}');
    }

    //debugPrint('Layout widgetSize - $w - $h');

    int k = 0;
    for (int i = 0; i < layout.length; i++)
    {
      double x0, dx;
      final xCount = layout[i];
      final double spaceWidth = size.width - xCount * widgetSize.width;
      double w = (size.width - (xCount - 1) * spacing.dx - padding.horizontal) / xCount;
      // TODO! Remove case??
      if (spaceWidth > (xCount - 1) * spacing.dx + padding.horizontal)
      {
        // MainAxisAlignment.spaceAround logic
        x0 = spaceWidth / (2 * xCount);
        dx = widgetSize.width + 2 * x0;
      }
      else  // Horizontally bound
      {
        x0 = padding.left;
        dx = widgetSize.width + spacing.dx;
      }

      final double y = y0 + dy * i;

      for (int j = 0; j < layout[i]; j++, k++)
        if (hasChild(k))  // Need it?
        {
          final Size sz = layoutChild(k, BoxConstraints.tight(widgetSize));

          final double x = x0 + j * dx;
          final Offset offset = new Offset(x, y);
          debugPrint('performLayout $widgetSize - $sz = $widgetSize - $offset');

          positionChild(k, offset);
        }
    }
  }

  @override
  bool shouldRelayout(_OwlLayout oldDelegate)
  {
    return count != oldDelegate.count ||
      aspect != oldDelegate.aspect ||
      spacing != oldDelegate.spacing ||
      maxCoef4 != oldDelegate.maxCoef4 ||
      spacing != oldDelegate.spacing ||
      padding != oldDelegate.padding ||
      !equalLists(layout, oldDelegate.layout);
  }
}

class OwlGridRot extends StatefulWidget
{
  BeatMetre beat;
  final int noteValue;
  final int activeBeat;
  final int activeSubbeat;
  final bool playing;
  final List<int> accents;
  final int maxAccent;
  final Offset spacing;
  final EdgeInsetsGeometry padding;  //TODO
  final OwlSkinRot skin;
  final Size size;//TODO

  final ValueChanged2<int, int> onChanged;
  //final ValueChanged<int> onCountChanged;
  final ValueChanged2<int, int> onAccentChanged;

  OwlGridRot({
    @required this.beat,
    this.noteValue,
    this.accents,
    this.activeBeat,
    this.activeSubbeat,
    this.playing = false,
    this.onChanged,
    this.onAccentChanged,
    this.maxAccent,
    this.skin,
    this.size,
    this.spacing = Offset.zero,
    this.padding = EdgeInsets.zero,
    });

  @override
  OwlGridRotState createState() => OwlGridRotState();
}

class OwlGridRotState extends State<OwlGridRot> with SingleTickerProviderStateMixin<OwlGridRot>
{
  AnimationController _controller;
  int _period = 60000;
  //duration: new Duration(days: 3653)

  //OwlSkinRot widget.skin;
  double _imageHeightRatio = 0.67;  // 0.7;//3/7.0

  //int subCount;
  //int subCur;
  //bool active;

  OwlGridRotState()
  {
    //widget.skin = new OwlSkinRot();
  }

  void toggleAnimation()
  {
    if (widget.playing)
    {
      debugPrint('toggleAnimation');
      if (!_controller.isAnimating)
        _controller.repeat().orCancel;
    }
    else
    {
      if (_controller.isAnimating)
        _controller.stop();
    }
  }

  @override
  void initState()
  {
    super.initState();

    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    );
    //TODO ..addListener(onTimer);

    //widget.skin.init();
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context)
  {
    //assert(widget.subBeatCount > 0);
    final Size size = widget.size;
    double widthSquare = size.width > size.height ? size.height : size.width;
    //size = new Size.square(widthSquare);

    if (widthSquare == 0)
      return Container();

    final double aspect = widget.skin.aspect / _imageHeightRatio;
    //aspect *= 1.7;//1.8;  // for NoteWidget
    final int currentMaxAccent = maxValue(widget.accents);
    final List<int> beatRows = beatRowsList(widget.beat.beatCount);//TODO

    final _OwlLayout layout = new _OwlLayout(
      count: widget.beat.beatCount,
      aspect: aspect,
      layout: beatRows,
      maxCoef4: 3,
      //1.75 * 306 / 250 //2 * 668 / 546,
      spacing: widget.spacing,
      padding: widget.padding,
    );

    // TODO Check image size
    final Size owlSize = layout.calcImageSize(size);

    double w = owlSize.width;
    double h = _imageHeightRatio * owlSize.height;
//    if (aspect > h / w)
//      w = h / aspect;
//    else
//      h = w * aspect;
    //Size imageSize = new Size(w, widget.skin.aspect * w);
    Size imageSize = new Size(w, h);
    //TODO Test: Move loadImages to initState, but keep precacheImages here?
    widget.skin.cacheImages(context, imageSize);
    print('OwlGrid $imageSize - $aspect - $owlSize');
    int n = widget.skin.images.length;
    print('widget.skin.images $n - ${widget.skin.images}');

    //TODO Recreate only on beatRows change
    final List<Widget> wOwls = List<Widget>();
    int k = 0;
    for (int i = 0; i < beatRows.length; i++)
      for (int j = 0; j < beatRows[i]; j++, k++)
      {
        bool accent = k == 0;
        int nAccent = widget.accents[k];
        HeadOwlWidget w = new HeadOwlWidget(
          id: k,
          accent: accent,
          nAccent: nAccent,
          maxAccent: widget.maxAccent,
          active: k == widget.activeBeat,
          activeSubbeat: k == widget.activeBeat ? widget.activeSubbeat : -1,
          subbeatCount: widget.beat.subBeats[k],
          denominator: widget.noteValue,
          animation: _controller.view,
          imageHeightRatio: _imageHeightRatio,
          maxAngle: 40 / 180.0 * pi,  // in radians
          size: owlSize,
          images: widget.skin.images,//[accent ? 0 : 1]),
          headImages: widget.skin.headImages,//[accent ? 0 : 1]),
          getImageIndex: (int accent, int subbeat, int subbeatCount) {
            // Need to pass currentMaxAccent onto Skin::getImageIndex
            return widget.skin.getImageIndex(accent, subbeat, currentMaxAccent, subbeatCount);
          },
          onTap: (int id, int accent) {
            //assert(id < widget.beat.subBeats.length);
            //widget.beat.subBeats[id] = subCount;
            widget.onAccentChanged(id, accent);
          },
          onNoteTap: (int id, int subCount) {
            //assert(id < widget.beat.subBeats.length);
            //widget.beat.subBeats[id] = subCount;
            widget.onChanged(id, subCount);
          });

        wOwls.add(LayoutId(
          id: k,
          child: w
        ));
      }

    toggleAnimation();

    return CustomMultiChildLayout(
      children: wOwls,
      delegate: layout,
    );
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
    print("Head:didChangeDependencies");
  }

  @override
  void didUpdateWidget(OwlGridRot oldWidget) {
    // TODO: implement didUpdateWidget
    super.didUpdateWidget(oldWidget);
    print("Head:didUpdateWidget");
  }
}
