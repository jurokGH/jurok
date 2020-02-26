import 'package:flutter/material.dart';
import 'util.dart';

class TempoListWidget extends StatefulWidget
{
  final int tempo;  // bpm
  final double width;
  final TextStyle textStyle;
  final ValueChanged<int> onChanged;

  TempoListWidget({
    this.tempo,
    this.width,
    @required this.textStyle,
    this.onChanged});

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
    TempoDef('marcia mod', 83, 85),  //S-
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

  int _index = 7;

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

    controller = new FixedExtentScrollController(initialItem: _index/*widget.beats*/);
    //beatController.addListener(_beatScrollListener);
    //noteController = new FixedExtentScrollController(initialItem: widget.noteIndex - widget.minNoteIndex);
  }

  @override
  Widget build(BuildContext context)
  {
    int index = tempoIndex(widget.tempo);
    assert(0 <= index && index < tempoList.length);
    //final String txt = tempoList[_index].name;

    // To prevent reenter via widget.onBeat/NoteChanged::setState
    // when position is changing via jumpToItem/animateToItem
    if (index != _index && _notify)
    {
      _notify = false;
      print('Tempo:update1 $index');
      _index = index;
      //TODO Need?
      if (false)
      {
        controller.jumpToItem(index);
        // finishUpdate:
        _notify = true;
      }
      else
      {
        //TODO Both run => when finishUpdate?
        controller.animateToItem(index,
          duration: Duration(milliseconds: duration), curve: Curves.ease)
          .catchError(finishUpdate).then<void>(finishUpdate);
      }
      print('Tempo:update2');
      //widget.update = false;
    }

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
        child: Text(tempoList[i].name,
          textAlign: TextAlign.center,
          style: widget.textStyle
        )
      )
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
          squeeze: 1.0,
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
