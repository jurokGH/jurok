import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'owl_widget.dart';
import 'beat_metre.dart';

typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);

List<int> beatRowsList(int beatCount)
{
  List<int> beatRows = new List<int>(1 + (beatCount - 1) ~/ 4);
  if (beatCount <= 4)
    beatRows[0] = beatCount;
  else if (beatCount <= 8)
  {
    beatRows[1] = beatCount ~/ 2;
    beatRows[0] = beatCount - beatRows[1];
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

int maxValue(List<int> list)
{
  int value = 0;
  for (int i = 0; i < list.length; i++)
    if (value < list[i])
      value = list[i];
  return value;
}

class _OwlLayout extends MultiChildLayoutDelegate
{
  /// Maximum owl size over size when there are 4 owls in row
  static final double maxCoef4 = 1.0;
  static final double minPaddingX = 10;

  final int count;
  //final Size childSize;
  //final double width;
  final double aspect;
  final Size padding = new Size(10, 10);

  List<int> _layout;

  _OwlLayout({@required this.count, @required this.aspect,
    /*, Size this.padding*/}):
      assert(0 < count && count <= 12)
  {
    //if (padding == null)
    //  padding = new Size(10, 10);
    _layout = beatRowsList(count);
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
    double w = size.width > 0 ? (size.width - padding.width * (xCount - 1)) / xCount : 0;
    double h = size.height > 0 ? (size.height - padding.height * (yCount - 1)) / yCount : 0;
    // Width of 4 owls in row
    double width4 = (size.width - padding.width * 3) / 4;
    double width4h = (size.height - padding.height) / (4 * aspect);
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
    }
    else
    {
      w = h / aspect;
      y0 = 0;
      dy = h + padding.height;
    }

    //print('maxWidth123 $maxWidth - $w - $h');
    //TODO
    // Limit owl size by maxCoef4 coefficient
    if (w > maxWidth)
    {
      //w = maxWidth;
      //h = aspect * maxWidth;
    }
    //print('maxWidth123 $w - $h');

    int k = 0;
    for (int i = 0; i < _layout.length; i++)
    {
      double dx = size.width / _layout[i];
      if (!vertical)
      {
        x0 = (size.width - _layout[i] * w) / (2 * _layout[i]);
        dx = w + 2 * x0;
      }
      else
        dx = w + padding.width;

      double y = y0 + dy * i;

      for (int j = 0; j < _layout[i]; j++, k++)
        if (hasChild(k))  // Need it?
        {
          Size sz = layoutChild(k, BoxConstraints.tight(new Size(w, h)));
          //print('performLayout $w - $h - $sz');

          double x = x0 + j * dx;
          Offset offset = new Offset(x, y);

          positionChild(k, offset);
        }
    }
  }

  @override
  bool shouldRelayout(_OwlLayout oldDelegate) {
    return count != oldDelegate.count ||
    //final Size childSize;
    //final double width;
      aspect != oldDelegate.aspect ||
      padding != oldDelegate.padding;
  }
}

class OwlGrid extends StatefulWidget
{
//  /final double width;

  BeatMetre beat;
  final int beatCurrent;
  final int subBeatCurrent;
  final int noteValue;

  final ValueChanged2<int, int> onChanged;

  OwlGrid({@required this.beat, this.noteValue,
    this.beatCurrent, this.subBeatCurrent,
    this.onChanged,
    //this.width,
    });

  @override
  OwlGridState createState() => OwlGridState();
}

class OwlGridState extends State<OwlGrid>
{
  int subCount;
  int subCur;
  bool active;

  int _counter;

  OwlGridState()
  {
  }

  @override
  void initState() {
    super.initState();

    _counter = 0;
  }

  @override
  Widget build(BuildContext context) {
    //assert(widget.subBeatCount > 0);
    Size size = MediaQuery.of(context).size;

    List<int> beatRows = beatRowsList(widget.beat.beatCount);
    int maxCountX = maxValue(beatRows);
    maxCountX = 4;

    final List<Widget> wOwls = List<Widget>();
    int k = 0;
    for (int i = 0; i < beatRows.length; i++)
      for (int j = 0; j < beatRows[i]; j++, k++)
      {
        OwlWidget w = new OwlWidget(
          id: k,
          onTap: (int id, int subCount) {
            //assert(id < widget.beat.subBeats.length);
            //widget.beat.subBeats[id] = subCount;
            widget.onChanged(id, subCount);
          },
          accent: k == 0,
          active: k == widget.beatCurrent,
          denominator: widget.noteValue,
          subBeat: widget.subBeatCurrent,
          subBeatCount: widget.beat.subBeats[k]);

        wOwls.add(LayoutId(
          id: k,
          child: w
        ));
      }

    return Consumer<MetronomeState>(
      builder: (BuildContext context, MetronomeState metronome, Widget child) {
        return CustomMultiChildLayout(
          children: wOwls,
          delegate: _OwlLayout(
            count: widget.beat.beatCount,
            aspect: 2 * 668 / 546,
          )
        );
      }
    );
  }
}
