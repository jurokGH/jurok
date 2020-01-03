//library owlenome;

import 'package:flutter/material.dart';

class TempoWidget extends StatefulWidget
{
  final int tempo;  // bpm
  final TextStyle textStyle;
  final ValueChanged<int> onChanged;

  TempoWidget({
    this.tempo,
    @required this.textStyle,
    this.onChanged});

  void setTempo(int bpm)
  {
  }

  @override
  State<StatefulWidget> createState() => TempoState();
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

class TempoState extends State<TempoWidget>
{
  static List<TempoDef> tempoList = <TempoDef>[
    //'largamente' : 10,
    TempoDef('larghissimo', 1, 24, 20),
    //TempoDef('adagissimo', 45, ), //?
    TempoDef('grave', 25, 45),
    TempoDef('largo', 40, 60),
    TempoDef('lento', 45, 60),  //!!
    TempoDef('larghetto', 60, 66),
    TempoDef('adagio', 66, 76),
    TempoDef('adagietto', 70, 80),  //!!
    //TempoDef('lentamente', 80, ,  //?
    TempoDef('andante', 76, 108),
    TempoDef('andantino', 80, 108),
    //TempoDef('con moto', 100, ,  //?
    TempoDef('marcia moderato', 83, 85),
    TempoDef('andante moderato', 92, 112),
    TempoDef('moderato', 108, 120),
    TempoDef('allegretto', 112, 120),

    TempoDef('allegro moderato', 116, 120),
    TempoDef('allegro', 120, 156),

    TempoDef('vivace', 156, 176),
    TempoDef('vivacissimo', 172, 176), //allegrissimo
    TempoDef('presto', 168, 200),
    TempoDef('prestissimo', 200, 1000)
  ];
  /*
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
*/
  static Map<String, int> tempoList0 = {
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

  TempoState();

  int tempoIndex(int bpmTempo)
  {
    if (tempoList[tempoList.length - 1].maxTempo <= bpmTempo)
      return tempoList.length - 1;
    for (int i = tempoList.length - 1; i >= 0; i--)
      if (tempoList[i].minTempo <= bpmTempo && bpmTempo < tempoList[i].maxTempo)
        return i;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    _index = tempoIndex(widget.tempo);
    assert(0 <= _index && _index < tempoList.length);
    final String txt = tempoList[_index].name;

    return GestureDetector(
      onTap: () {
        setState(() {
          _index++;
          if (_index >= tempoList.length)
            _index = 1;
        });
        widget.onChanged(tempoList[_index].tempo);
      },
      onHorizontalDragEnd: (DragEndDetails details) {
        _index -= details.primaryVelocity.sign.toInt();
        if (_index < 1)
          _index = tempoList.length - 1;
        if (_index >= tempoList.length)
          _index = 1;
        widget.onChanged(tempoList[_index].tempo);
      },
      child: Text(txt,
        style: TextStyle(color: Colors.white ,
            fontSize:  12),
      )
    );
  }
}
