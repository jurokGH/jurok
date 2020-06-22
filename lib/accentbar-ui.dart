///Виджет строки акцентов.


import 'package:flutter/material.dart';
import 'package:owlenome/BarBracket.dart';
import 'package:owlenome/NoteWidget.dart';
import 'package:owlenome/main.dart';
import 'package:owlenome/prosody.dart';
import 'package:owlenome/rhythms.dart';
import 'util.dart';

class AccentBarWidget extends StatefulWidget
{
  ///Переход по тапу
  final bReactOnTap;
  final ValueChanged<int> onChanged;
  final List<Rhythm> rhythms;
  final int position;//Позиция в списке
  final Size size;
  final int noteValue;
  final bool bForceRedraw;
  final int maxAccent;

  AccentBarWidget({
    this.rhythms,
    this.size,
    this.position,
    this.onChanged,
    this.noteValue,
    this.bForceRedraw,
    this.bReactOnTap=true,
    this.maxAccent,
  });

  @override
  State<StatefulWidget> createState() => AccentBarState();
}


class AccentBarState extends State<AccentBarWidget>
{


  FixedExtentScrollController controller;
  //FixedExtentScrollController controllerVert;
  final int duration = 1000;
  bool _notify = true;

  AccentBarState();


  void finishUpdate(_)
  {
    _notify = true;
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    controller = new FixedExtentScrollController(initialItem: widget.position);
    //controller.addListener(scrollListener);
  }




  Widget _builder(BuildContext context, BoxConstraints constraints)
  {


    Widget rhythmDrawW(Size size, Rhythm rhythm, int  noteValue)
    {
      //final MetreBar metreBar = widget.metres[widget.activeMetre];
      final int beats = rhythm.beats;
      // Simple metre array
      final List<int> subMetres = Prosody.groupNotes(rhythm.accents);
      //Prosody.getSimpleMetres(beats, false);
      final List<int> accents = rhythm.accents;


      final List<Widget> notes = new List<Widget>();


      final Size bracketSize = new Size(3.0 * size.width/30, size.height);
      final Size leftBracketSize = new Size(2.0 * size.width/30, size.height);
      ///справа надо чуть больше места, но лищь если хвостики. ToDo;
      final Size rightBracketSize = new Size(4.0 * size.width/30, size.height);

      notes.add(new BarBracketWidget(
          direction: BarBracketDirection.left,
          color: Colors.black,
          size: leftBracketSize,
      ));

      int j = 0;  // Simple metre 1st note index
      for (int i = 0; i < subMetres.length; i++)
      {
        // Build note with subbeats
        final List<int> accents1 = accents.sublist(j, j + subMetres[i]);
        j += subMetres[i];

        //TODO Width
        double width = (size.width - 3 * bracketSize.width) * subMetres[i] / beats;
        //width = (widget.size.width) * metres[i] / beats;

        //print('metreBuilder:width $width');
        //print('widget.accents $index - $i - ${metres[i]} - ${metreBar.note}');
        //print(accents1);

        final bool rests=((accents1.length>0)&&(accents1[0]==-1));

        double restsFactor= 1.5;
        if (beats<=2)restsFactor/=2;///Почему? Никто не знает...
        if (beats>6)restsFactor*=1.5;///вообще непонятно...
        if (beats>10)restsFactor*=1.5;///очень странно... //ToDo


        final Widget wix = new NoteWidget(
          subDiv: subMetres[i],
          denominator: noteValue,
          active: -2,
          colorPast: Colors.black,//ToDo
          colorNow: Colors.black,
          colorFuture: Colors.black,
          colorInner: Colors.black,
          accents: accents1,
          rests: rests,
          maxAccentCount: widget.maxAccent,
          coverWidth: beats > 5,// true,
          showTuplet: false,
          showAccent: true,
          size: new Size(width, size.height),
          relRadius: 0.07,
          relFlagHeight: 0.55/1.2,
          restsFactor: restsFactor,
        );
        notes.add(wix);
      }

      // Add right bracket
      notes.add(new BarBracketWidget(
          direction: BarBracketDirection.right,
          color: Colors.black,
          //size: rightBracketSize,//Не вышло - разъехались размеры...(((
          //Поэтому при 12/16 если каждую ноту сделать с акцентом (разгруппировать)
          //хвостик заедет в область над точками. Не очень красиво.
          size: leftBracketSize
      ));
      return new Container(
        //color: Colors.blue,
        width: size.width,
        height: size.height,
        alignment: Alignment.center,
        child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: notes
        ),
      );
    }

    final List<Widget> wixRhythmsDraw = new List<Widget>.generate(
      widget.rhythms.length,
          (int i) => new RotatedBox(
        quarterTurns: 1,
        child: rhythmDrawW(widget.size,widget.rhythms[widget.position],widget.noteValue),
      ),
    );

    return RotatedBox(
      quarterTurns: 3,
      child:
      GestureDetector(
        onTap: ()
        {
          if (!widget.bReactOnTap) return; //ISH: Is it a correct way? //ToDo
          int index = (widget.position  >= userRhythms.length)? widget.position :
          widget.position+1;
          //if (index >= tempoList.length || tempoList[index].minTempo > widget.maxTempo)
            //index = 0;
          controller.jumpToItem(index);
        },

        child:
        ListWheelScrollView.useDelegate(
          controller: controller,
          physics: new FixedExtentScrollPhysics(),
          diameterRatio: 1000.0,
          perspective: 0.000001,
          offAxisFraction: 0.0,
          useMagnifier: false,
          magnification: 1.0,
          itemExtent: widget.size.width,
          squeeze: 0.88,
          onSelectedItemChanged: (int index) {
              if (_notify)//ISH: не понимаю это, пробую наобум
                widget.onChanged(index);//Новый индекс?
          },
          clipToSize: true,
          renderChildrenOutsideViewport: false,
          childDelegate: ListWheelChildListDelegate(children: wixRhythmsDraw),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context)
  {
    debugPrint("rhytmscroll");
    int index = widget.position;
    assert(0 <= index && index < widget.rhythms.length);
    //final String txt = tempoList[_index].name;
    //print('Tempo:_builder $index - ${widget.tempo}');

    // To prevent reenter via widget.onBeat/NoteChanged::setState
    // when position is changing via jumpToItem/animateToItem
    //ISH: I do not see the problem.
    if ((index != widget.position || widget.bForceRedraw)&& _notify)
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

  }

}


