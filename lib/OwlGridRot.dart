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
  /// Maximum owl size over size when there are 4 owls in row
  //static final double maxCoef4 = 1.5;//1.5;
  //static final double minPaddingX = 10;

  final int count;
  //final Size childSize;
  //final double width;
  final double aspect;
  final double maxCoef4;
  final Size spacing = new Size(10, 0);
  //final EdgeInsetsGeometry padding;

  /// _layout[i] - number of Owls in each i-th row
  List<int> _layout;

  _OwlLayout({@required this.count, @required this.aspect, this.maxCoef4 = 1.5
    /*, Size this.padding*/}):
      assert(0 < count && count <= 12)
  {
    //if (padding == null)
    //  padding = new Size(10, 10);
    _layout = beatRowsList(count);
  }

  Size calcImageSize(Size size)
  {
    double x0, y0;
    x0 = y0 = 0;

    // Grid: xCount x yCount
    int xCount = maxValue(_layout);
    int yCount = _layout.length;

    // Size is (0, 0) if display does not show (e.g. locked)
    double w = size.width > 0 ? (size.width - spacing.width * (xCount - 1)) / xCount : 0;
    double h = size.height > 0 ? (size.height - spacing.height * (yCount - 1)) / yCount : 0;

    // Width of 4 owls in row if constrained by width
    double width4 = (size.width - spacing.width * 3) / 4;
    // Width of 4 owls in row if constrained by height
    double width4h = (size.height - spacing.height) / (4 * aspect);
    width4h = size.height / (4 * aspect);
    // Choose minimum of 2 widths
    double maxWidth = width4 > width4h ? width4h : width4;
    // Max owl width
    maxWidth *= maxCoef4;

    double dy;

    bool vertical = h > aspect * w;
    if (vertical)
    {
      h = aspect * w;
      y0 = (size.height - yCount * h) / (2 * yCount);
      dy = h + 2 * y0;
    }
    else
    {
      w = h / aspect;
      y0 = 0;
      dy = h + spacing.height;
    }

    //TODO
    // Limit owl size by maxCoef4 coefficient
    if (maxCoef4 > 0  && w > maxWidth && yCount == 1)
    {
      w = maxWidth;
      h = aspect * maxWidth;
    }
    debugPrint('calcImageSize $size - $w - $h');

    return new Size(w, h);
  }

  @override
  void performLayout(Size size)
  {
    //assert(count == _layout.length);
    print('performLayout $size');

    double x0, y0;
    x0 = y0 = 0;

    int xCount = maxValue(_layout);
    int yCount = _layout.length;

    // Size is (0, 0) if display does not show (e.g. locked)
    double w = size.width > 0 ? (size.width - spacing.width * (xCount - 1)) / xCount : 0;
    double h = size.height > 0 ? (size.height - spacing.height * (yCount - 1)) / yCount : 0;
    // Width of 4 owls in row
    double width4 = (size.width - spacing.width * 3) / 4;
    double width4h = (size.height - spacing.height) / (4 * aspect);
    width4h = size.height / (4 * aspect);
    // Choose minimum of 2 widths
    double maxWidth = width4 > width4h ? width4h : width4;
    maxWidth *= maxCoef4;

    double dy;

    bool vertical = h > aspect * w;
    if (vertical)
    {
      h = aspect * w;
      y0 = (size.height - yCount * h) / (2 * yCount);
      dy = h + 2 * y0;
      print('vert');
    }
    else
    {
      w = h / aspect;
      y0 = 0;
      print('horz');
      if (yCount == 1) {
        y0 = (size.height - h) / 2;
        print('horz $y0 - $h');
      }
      dy = h + spacing.height;
    }

    //debugPrint('Layout $maxWidth - $w - $h');
    //TODO
    // Limit owl size by maxCoef4 coefficient
    if (maxCoef4 > 0  && w > maxWidth && yCount == 1)
    {
      w = maxWidth;
      h = aspect * maxWidth;

      y0 = (size.height - h) / 2;
      //dy = h + 2 * y0;
      print('maxCoef4');
    }
    print('maxWidth123 $w - $h');

    int k = 0;
    for (int i = 0; i < _layout.length; i++)
    {
      double dx = size.width / _layout[i];
      // TODO! Remove case??
      if (!vertical)
      {
        x0 = (size.width - _layout[i] * w) / (2 * _layout[i]);
        dx = w + 2 * x0;
      }
      else
      {
        x0 = (size.width - _layout[i] * w) / (2 * _layout[i]);
        //dx = w + padding.width;
        dx = w + 2 * x0;
      }

      double y = y0 + dy * i;

      for (int j = 0; j < _layout[i]; j++, k++)
        if (hasChild(k))  // Need it?
        {
          Size sz = layoutChild(k, BoxConstraints.tight(new Size(w, h)));

          double x = x0 + j * dx;
          Offset offset = new Offset(x, y);
          debugPrint('performLayout $w - $h - $sz = $offset');

          positionChild(k, offset);
        }
    }
  }

  @override
  bool shouldRelayout(_OwlLayout oldDelegate) {
    return count != oldDelegate.count ||
      aspect != oldDelegate.aspect ||
      spacing != oldDelegate.spacing ||
      maxCoef4 != oldDelegate.maxCoef4;
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
  final int animationType;
  final int maxAccent;
  final EdgeInsetsGeometry padding;
  final OwlSkinRot skin;

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
    this.animationType = 0,
    this.maxAccent,
    this.skin,
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
  double _imageHeightRatio = 0.6;  // 0.7;//3/7.0

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
    widget.skin.animationType = widget.animationType;

    //assert(widget.subBeatCount > 0);
    Size size = MediaQuery.of(context).size;
    //debugPrint('OwlGridState $size');
    double widthSquare = size.width > size.height ? size.height : size.width;
    size = new Size.square(widthSquare);

    if (widthSquare == 0)
      return Container();

    double aspect = widget.skin.aspect / _imageHeightRatio;
    //aspect *= 1.7;//1.8;  // for NoteWidget

    _OwlLayout layout = new _OwlLayout(
      count: widget.beat.beatCount,
      aspect: aspect,
      maxCoef4: 3,
      //1.75 * 306 / 250 //2 * 668 / 546,
    );

    // TODO Check image size
    Size owlSize = layout.calcImageSize(size);

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

    List<int> beatRows = beatRowsList(widget.beat.beatCount);
    //final int maxCountX = maxValue(beatRows);
    //maxCountX = 4;
    final int currentMaxAccent = maxValue(widget.accents);

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
