import 'package:flutter/material.dart';
import 'util.dart';

class TempoListWidget extends StatefulWidget
{
  final int tempo;  // bpm
  final int maxTempo;  // bpm
  final double width;
  final TextStyle textStyle;
  final ValueChanged<int> onChanged;

  TempoListWidget({
    this.tempo,
    this.maxTempo,
    this.width,
    @required this.textStyle,
    this.onChanged
  });

  @override
  State<StatefulWidget> createState() => TempoListState();
}

class TempoDef
{
  String name;
  int tempo;
  int minTempo;
  int maxTempo;

  TempoDef([name, minTempo, maxTempo, tempo])
  {
    this.name = name;
    this.minTempo = minTempo;
    this.maxTempo = maxTempo;
    this.tempo = tempo == null ? minTempo : tempo;
  }
}

class TempoListState extends State<TempoListWidget>
{
  //S- - Sposobin book: + sostenuto, comodo, vivo, veloce
  static final List<TempoDef> tempoList = <TempoDef>[
    // TempoDef('largamente', 10, ), //S-
    TempoDef('larghissimo', 1, 25, 20), //S-
    // TempoDef('lentissimo', 35, ), //S-
    //TempoDef('adagissimo', 45, ), //?  //S-
    TempoDef('grave', 25, 45),
    TempoDef('largo', 40, 60),
    TempoDef('lento', 45, 60),  //!!
    TempoDef('larghetto', 60, 66),
    TempoDef('adagio', 66, 76),
    TempoDef('adagietto', 70, 80),  //!!  //S-
    //TempoDef('lentamente', 80, ),  //?  //S-
    TempoDef('andante', 76, 108),
    TempoDef('andantino', 80, 108),
    //TempoDef('con moto', 100, ),  //?  //S-
    TempoDef('marcia mod', 83, 85),  //S-marcia mod
    TempoDef('andante mod', 92, 112),  //S-
    TempoDef('moderato', 108, 120),
    TempoDef('allegretto', 112, 120),

    TempoDef('allegro mod', 116, 120), //S-
    TempoDef('allegro', 120, 156),
    // TempoDef('allegramente', 160, ), //S-

    TempoDef('vivace', 156, 176),
    TempoDef('vivacissimo', 172, 176), //S-
    // TempoDef('allegrissimo', 190, ),  //S-
    TempoDef('presto', 184, 200), //TODO IS: 168?
    TempoDef('prestissimo', 200, 1000)
  ];

  static final Map<String, int> tempoList0 = {
    //'largamente' : 10,
    'larghissimo' : 20,  //?
    'lentissimo' : 35,  //?
    'adagissimo' : 45,  //?
    'grave' : 33,
    'largo' : 50,
    'lento' : 52,
    'larghetto' : 60,
    'adagio' : 70,
    'adagietto' : 75,
    'lentamente' : 80,  //?
    'andantino' : 66,
    'andante' : 90,
    'con moto' : 100,  //?
    'moderato' : 110,
    'allegretto' : 100,
    'vivace' : 126,
    'allegro' : 140,
    'allegramente' : 160,
    'presto' : 180,
    'allegrissimo' : 190,  //?
    'vivacissimo' : 195,  //?
    'prestissimo' : 200,
  };

  int _index;

  FixedExtentScrollController controller;
  FixedExtentScrollController controllerVert;
  final int duration = 1000;
  bool _notify = true;

  TempoListState();

  int tempoIndex(int tempo)
  {
    if (tempo >= tempoList.last.maxTempo)
      return tempoList.length - 1;
    for (int i = tempoList.length - 1; i >= 0; i--)
      if (tempoList[i].minTempo <= tempo && tempo < tempoList[i].maxTempo)
        return i;
    return 0;
  }

  void finishUpdate(_)
  {
    //widget.update = false;
    _notify = true;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _index = tempoIndex(widget.tempo);
    controller = new FixedExtentScrollController(initialItem: _index/*widget.beats*/);
    //controller.addListener(scrollListener);
  }

  Size _textSize(String str, TextStyle style)
  {
    final TextPainter textPainter = TextPainter(
        text: TextSpan(text: str, style: style), maxLines: 1,
        textDirection: TextDirection.ltr, textAlign: TextAlign.center)
      ..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size;
  }

  Size maxListItemSize()
  {
    int maxLength = 0;
    int maxIndex = -1;
    for (int i = 0; i < tempoList.length; i++)
    {
      int len = tempoList[i].name.length;
      if (len > maxLength) {
        maxLength = len;
        maxIndex = i;
      }
    }
    assert(maxIndex >= 0);
    Size maxTextSize = Size.zero;
    if (maxIndex >= 0) {
      maxTextSize = _textSize(tempoList[maxIndex].name, widget.textStyle);
    }
    return maxTextSize;
  }

  double maxFontSize(Size size)
  {
    // TODO
    size = new Size(0.9 * size.width, size.height);
    double fontSize = widget.textStyle.fontSize;
    //fontSize = 64;

    int maxLength = 0;
    int maxIndex = -1;
    for (int i = 0; i < tempoList.length; i++)
    {
      int len = tempoList[i].name.length;
      if (len > maxLength) {
        maxLength = len;
        maxIndex = i;
      }
    }
    assert(maxIndex >= 0);

    List<int> compare = new List<int>();
    for (int i = 0; i < tempoList.length; i++)
    {
      int len = tempoList[i].name.length;
      if (len >= maxLength)
        compare.add(i);
    }
    //print('compare');
    //print(compare.length);

    bool fit = false;
    for (; !fit && fontSize > 0; fontSize--)
    {
      Size textSize = Size.zero;
      for (int i = 0; i < compare.length; i++) {
        textSize = _textSize(tempoList[compare[i]].name,
            widget.textStyle.copyWith(fontSize: fontSize));
        //print('tt - $textSize');
        fit = textSize.width <= size.width && textSize.height <= size.height;
        if (!fit)
          break;
      }
      //print('textSize1 - $fontSize - $textSize - $size');
    }
    //print('textSize1 - $fontSize - $size');
    return fontSize;
  }

  Widget _builder(BuildContext context, BoxConstraints constraints)
  {
    final Size size = constraints.biggest;
    //Size maxTextSize = maxListItemSize();
    double fontSize = maxFontSize(size);

    final List<Widget> wixTempo = new List<Widget>.generate(
      tempoList.length,
          (int i) => new RotatedBox(
        quarterTurns: 1,
        child:
      new Container(
//        color: Colors.blue,
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        //padding: EdgeInsets.symmetric(horizontal: 5),
//        child: FittedBox(
//          fit: BoxFit.contain,
          child: Text(tempoList[i].name,
              //textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              //style: widget.textStyle
              style: widget.textStyle.copyWith(fontSize: fontSize)
          ),
        ),
      ),
    );

    return RotatedBox(
      quarterTurns: 3,
      child:
      GestureDetector(
        onTap: () {
          int index = _index + 1;
          // Cycle back to 0 if limited by maximum tempo
          if (index >= tempoList.length || tempoList[index].minTempo > widget.maxTempo)
            index = 0;
          controller.jumpToItem(index);
//          _index = index;
//          widget.onChanged(tempoList[index].tempo);

//          setState(() {
//            _index++;
//            if (_index >= tempoList.length)
//              _index = 1;
//          });
        },
        /*
        onHorizontalDragEnd: (DragEndDetails details) {
          _index += details.primaryVelocity.sign.toInt();
          if (_index < 1)
            _index = tempoList.length - 1;
          if (_index >= tempoList.length)
            _index = 1;
          widget.onChanged(tempoList[_index].tempo);
        },
*/
//    child: Container(
//    //color: widget.color,
//    width: height,//double.infinity,
//    height: width,

        child:
        ListWheelScrollView.useDelegate(
          controller: controller,
          physics: new FixedExtentScrollPhysics(),
          diameterRatio: 1000.0,
          perspective: 0.000001,
          offAxisFraction: 0.0,
          useMagnifier: false,
          magnification: 1.0,
          itemExtent: widget.width,
          squeeze: 0.88,
          onSelectedItemChanged: (int index) {
            // To prevent reentering via widget.onChanged::setState
            // Limit by maximum tempo
            if (tempoList[index].minTempo <= widget.maxTempo)
            {
              _index = index;
              if (_notify)
                widget.onChanged(tempoList[index].tempo);
            }
          },
          clipToSize: true,
          renderChildrenOutsideViewport: false,
          childDelegate: ListWheelChildListDelegate(children: wixTempo),
        ),
/*
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          //cacheExtent:,
          controller: ScrollController(),
          //dragStartBehavior: DragStartBehavior.down,
          //physics: ,
          //semanticChildCount: children.length,
          //anchor:,
          slivers: <Widget>[
            //SliverPadding(padding: const EdgeInsets.all(20.0), sliver:
            SliverList(
              delegate: SliverChildListDelegate.fixed(children,
                //addRepaintBoundaries: false
              ),
            ),
          ],
        ),
*/
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    int index = tempoIndex(widget.tempo);
    assert(0 <= index && index < tempoList.length);
    //final String txt = tempoList[_index].name;
    //print('Tempo:_builder $index - ${widget.tempo}');

    // To prevent reenter via widget.onBeat/NoteChanged::setState
    // when position is changing via jumpToItem/animateToItem
    if (index != _index && _notify)
    {
      _notify = false;
      //print('Tempo:update1 $index');
      //TODO Need?
      if (true)
      {
        controller.jumpToItem(index);
        _notify = true;
      }
      else
      {
        // BUG When new tempo comes while animating. Try simples Scroll
        //TODO Both run => when finishUpdate?
        controller.animateToItem(index,
          duration: Duration(milliseconds: duration), curve: Curves.ease)
          .catchError(finishUpdate).then<void>(finishUpdate);
      }
      //print('Tempo:update2');
    }

    return LayoutBuilder(
      builder: _builder
    );

    final List<Widget> wixTempo = new List<Widget>.generate(
      tempoList.length,
          (int i) => new RotatedBox(
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
          child: Text(tempoList[i].name,
              textAlign: TextAlign.center,
              style: widget.textStyle
          ),
        ),
      ),
    );

    return RotatedBox(
      quarterTurns: 3,
      child:
      GestureDetector(
        onTap: () {
          print('TempoList:onTap');
          int index = _index + 1;
          //loopClamp(widget.noteIndex + 1, widget.minNoteIndex, widget.maxNoteIndex);
          if (index >= tempoList.length)
            index = 0;
          controller.jumpToItem(index);
//          _index = index;
//          widget.onChanged(tempoList[index].tempo);

//          setState(() {
//            _index++;
//            if (_index >= tempoList.length)
//              _index = 1;
//          });
        },
    /*
        onHorizontalDragEnd: (DragEndDetails details) {
          _index += details.primaryVelocity.sign.toInt();
          if (_index < 1)
            _index = tempoList.length - 1;
          if (_index >= tempoList.length)
            _index = 1;
          widget.onChanged(tempoList[_index].tempo);
        },
*/
//    child: Container(
//    //color: widget.color,
//    width: height,//double.infinity,
//    height: width,

        child:
        ListWheelScrollView.useDelegate(
          controller: controller,
          physics: new FixedExtentScrollPhysics(),
          diameterRatio: 1000.0,
          perspective: 0.000001,
          offAxisFraction: 0.0,
          useMagnifier: false,
          magnification: 1.0,
          itemExtent: widget.width,
          squeeze: 0.88,
          onSelectedItemChanged: (int index) {
            print(index);
            if (_notify)  // To prevent reenter via widget.onBNotehanged::setState
            {
              _index = index;
              widget.onChanged(tempoList[index].tempo);
            }
            //setState(() {});
          },
          clipToSize: true,
          renderChildrenOutsideViewport: false,
          childDelegate: ListWheelChildListDelegate(children: wixTempo),
        ),
/*
        child: CustomScrollView(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          //cacheExtent:,
          controller: ScrollController(),
          //dragStartBehavior: DragStartBehavior.down,
          //physics: ,
          //semanticChildCount: children.length,
          //anchor:,
          slivers: <Widget>[
            //SliverPadding(padding: const EdgeInsets.all(20.0), sliver:
            SliverList(
              delegate: SliverChildListDelegate.fixed(children,
                //addRepaintBoundaries: false
              ),
            ),
          ],
        ),
*/
      ),
    );
  }

/*
    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _index++;
            if (_index >= tempoList.length)
              _index = 1;
          });
          widget.onChanged(tempoList[_index].tempo);
        },
        onHorizontalDragEnd: (DragEndDetails details) {
          _index += details.primaryVelocity.sign.toInt();
          if (_index < 1)
            _index = tempoList.length - 1;
          if (_index >= tempoList.length)
            _index = 1;
          widget.onChanged(tempoList[_index].tempo);
        },
        child: Text(txt,
          style: widget.textStyle
        )
      )
    );
*/
}
