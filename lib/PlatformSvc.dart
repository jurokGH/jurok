import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';

/// /////////////////////////////////////////////////////////////////////////
/// Flutter-Java inter operation
///

typedef ValueChanged<T> = void Function(T value);
typedef ValueChanged2<T1, T2> = void Function(T1 value1, T2 value2);
typedef ValueChanged3<T1, T2, T3> = void Function(T1 value1, T2 value2, T3 value3);

class PlatformSvc
{
  /// Flutter-Java connection channel
  static const MethodChannel _channel =
    MethodChannel('samples.flutter.io/owlenome');

  final ValueChanged onStart;
  final ValueChanged3 onSync;
  final ValueChanged onLimitTempo;
  String _infoMsg = "";

  PlatformSvc(this.onStart, this.onSync, this.onLimitTempo)
  {
    // Channel callback from hardware Java code
    _channel.setMethodCallHandler(_handleMsg);
    // Query native hardware audio parameters
    //_getAudioParams();
  }

  Future<dynamic> _handleMsg(MethodCall call) async
  {
    //MetronomeState state = Provider.of<MetronomeState>(context, listen: false);

    if (call.method == 'warm')
    {
      debugPrint('START-STABLE');
      //int warmupFrames = call.arguments;
      int initTime = call.arguments;
      debugPrint('Time in Flutter of stable time (mcs) $initTime');
      onStart(initTime);
      //state.startAfterWarm(initTime, _tempoBpm);
      //_start();
    }
    else if (call.method == 'Cauchy')
    {
      //IS:Устанавливаем время начала первого бипа и темп
      int tempoBpm = call.arguments['bpm'];
      // timeOfAFirstToSet
      int newTime = call.arguments['nt']; //новое время
      int startTime = call.arguments['dt']; //время, когда менять время
      //state.sync(newTime, tempoBpm, startTime);
      onSync(newTime, tempoBpm, startTime);

      /*
      //test:
      int timeNow = DateTime
          .now()
          .microsecondsSinceEpoch;
      int timeNowRem = timeNow % 1000000000;

      int dtime = (timeNow - timeOfAFirstToSet) ~/ 1000;
       */

      //debugPrint('MsgTest:  BPM in Flutter $bpmToSet\n');
      //debugPrint('MsgTest:  Time now mCs mod 10^9  in Flutter $timeNowRem');
      //debugPrint('MsgTest:  d-from-frst in Flutter $dtime\n');

      /*int newBPMMax=call.arguments['maxBpm'];
      if (_tempoBpmMax!=newBPMMax) {
        setState(() { _tempoBpmMax = newBPMMax; });
        /*
        _tempoBpmMax = newBPMMax;
        setState(() {}); //IS: VS, Витя, это правильно так делать?
         */
      }*/
    }
    /*
    else if (call.method == 'sync')
    {
      int index = call.arguments['index'];
      int beatIndex = call.arguments['beat'];
      int subbeatIndex = call.arguments['sub'];
      int offset = call.arguments['offset'];
      int cycle = call.arguments['cycle'];
      int time = call.arguments['time'];

      //debugPrint('SYNC $index - $offset - $time');

      //warmupFrames = call.arguments;
      //state.sync(index, 1e-6 * offset, beatIndex, subbeatIndex, time);
    }*/
    /*IS: Obsolete:
    else if (call.method == 'timeFrame')
    {
      int beatOrder = call.arguments['index'];
      int offset = call.arguments['offset'];
      int cycle = call.arguments['cycle'];

      List<int> pair = _beat.beatPair(beatOrder);

      //beatOrder += _timeTick;
      //_activeBeat =  beatOrder ~/ _subBeatCount;
      if (_beat.beatCount == 1 && _beat.subBeatCount == 1)
        //_activeBeat %= 2;
        _activeBeat = (_activeBeat + 1) % 2;
      else
        _activeBeat = pair[0];
      _activeSubbeat = pair[1];

      //_timeTick++;

      //debugPrint('NOTECOUNT $beatOrder - $offset - $cycle - $_timeTick - $_activeBeat - $_activeSubbeat');
      //state.setActiveState(_activeBeat, _activeSubbeat);
      redraw = true;
    }*/
    return new Future.value('');
  }

  Future<int> togglePlay(int tempoBpm, int beatCount, bool screenOn) async
  {
    //MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    //state.setTempo(_tempoBpm/*, _noteValue*/);

    //List<BipAndPause> bipsAndPauses = new List<BipAndPause>();
    int res = 0;
    try
    {
      final Map<String, int> args =
      <String, int>{
        'tempo': tempoBpm,
        'screen': screenOn ? 1 : 0,
        //'note': _beat.beatCount,//_noteValue,//IS: VS, Полагаю, beatCount тут - опечатка. В любом случае, это больше не нужно.
        //'quorta': _quortaInMSec.toInt(),
        'numerator': beatCount,
      };
      int res =  await _channel.invokeMethod('start', args);
      if (res == 0)
      {
        _infoMsg = 'Failed starting/stopping';
        debugPrint(_infoMsg);
      }
      else
      {
/*
        setState(() {
          state.reset();//IS: TEST
          //_tempoBpm = realTempo;
        });
*/
      }
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed to start playing';
    }
    return new Future.value(res);
  }

  /// Send beat music to Java sound player and state.beatMetre
  Future<int> setBeat(int beatCount, int subbeatCount, int tempoBpm,
      int soundScheme, List<int> subBeats, List<int> accents) async
  {
    //MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    /*
    state.melody = new AccentBeat(nativeSampleRate, _quortaInMSec,
      _beat,
      0.001 * _soundConfig.beatFreq, _soundConfig.beatDuration,
      0.001 * _soundConfig.accentFreq, _soundConfig.accentDuration,
      _bars, 1);
     */
    //state.beatMetre = _beat;

    int res = 0;
    //Tempo tempo = new Tempo(beatsPerMinute: _subBeatCount * _tempoBpm.toInt(), denominator: _noteValue);
    //List<BipAndPause> bipsAndPauses = new List<BipAndPause>();
    try
    {
      //IS:
      final List<int> config = [
        beatCount,
        subbeatCount,
        soundScheme,
        tempoBpm,
        beatCount,//_noteValue
//        _soundConfig.beatFreq,
//        _soundConfig.beatDuration,
//        _soundConfig.accentFreq,
//        _soundConfig.accentDuration,
//        _bars,
//        _beat.beatCount,
//        _quortaInMSec.toInt(),
      ];

      final Map<String, List<int>> args = <String, List<int>>{
        'config': config,
        'subBeats': subBeats,
        'accents': accents,
      };

      final int limitTempo = await _channel.invokeMethod('setBeat', args);

      if (limitTempo == 0)
      {
        _infoMsg = 'Failed setting beat';
        debugPrint(_infoMsg);
      }
      else if (limitTempo == -1)
      {
        // - это значит что мы первый раз посылали beat,
        //и схема (нужная для получения скорости, для которой нужен beat) еще не определена.
      }
      else
      {
        res = 1;
        onLimitTempo(limitTempo);
      }
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed setting beat';
    }
    return new Future.value(res);
  }

  /// Send music tempo to Java sound player
  Future<int> setTempo(int tempoBpm) async
  {
    int res = 0;
    // MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    //state.setTempo(_tempoBpm/*, _noteValue*/);//IS: Почему сначала меняется tempo у состояния?

    //В любом случае, новый темп для анимации устанавливать рано -
    //Ява начнет играть с данным темпом не сразу.
    //Есом мы раньше явы поменяем BPM в state,
    //и, кроме того, не учтем, что изменилось время начального бипа
    //(то, которое мы бы имели, играя с данным темпом),
    //то у нас разойдутся звук и анимация
    //("путешествия в прошлое").
    try
    {
      final Map<String, int> args = <String, int>{
        'tempo' : tempoBpm,
        //'note' : _beat.beatCount,//_noteValue IS: Это ява не использует.
      };
      //Нам не нужно ниже переопределять мак. темп,
      //ява сама пришлёт, когда установит
      //_channel.invokeMethod('setTempo', args);

      res = await _channel.invokeMethod('setTempo', args);
      //assert(result == 1);
      if (res == 0)
      {
        _infoMsg = 'Failed setting tempo';
        debugPrint(_infoMsg);
      }
      else
      { //темп придёт позже, когда ява узнает время его начала
        /*
        setState(() {
          /*_tempoBpmMax = limitTempo;
          if (_tempoBpm > _tempoBpmMax)
            _tempoBpm = _tempoBpmMax;*/
        });*/
      }
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed setting tempo';
    }
    //metroAudio.reSetTempo(progress + minimal_tempoBpm);
    //tempo.beatsPerMinute = BPMfromSeekBar;
    //realBPM = singSingSing.setTempo(tempo);

    //barrelOrgan.reSetAngles(cycle);
    //this.bipPauseCycle=cycle;
    //setAngles();

    /*
    if (_mode)
      barrelOrgan?.setTempo(i_tempoBpm, _noteValue);
    else
    {
      if (melody != null)
      {
        int realBpM = melody.cycle.setTempo(tempo, _bars);
        double dur = melody.cycle.tempoToCycleDuration(
          tempo, _bars, nativeSampleRate);
        //metronome1?.setCycle(melody.cycle, latency);
        metronome1?.setTempo(_tempoBpm, nativeSampleRate, _noteValue, dur);
      }
    }
     */
    return new Future.value(res);
  }

  /// Send music volume to Java sound player
  Future<int> setVolume(int volume) async
  {
    int res = 0;
    try
    {
      res = await _channel.invokeMethod('setVolume', {'volume' : volume});
      //assert(result == 1);
      if (res != 1)
      {
        _infoMsg = 'Failed setting volume';
        debugPrint(_infoMsg);
      }
    } on PlatformException {
      _infoMsg = 'Exception: Failed setting volume';
    }
    return new Future.value(res);
  }

  /// Send sound scheme number to Java sound player
  Future<int> setSoundScheme(int musicScheme) async
  {
    int res = 0;
    try
    {
      final int limitTempo = await _channel.invokeMethod('setScheme', {'scheme': musicScheme});
      if (limitTempo <=0) {
        _infoMsg = 'Failed setting music scheme, lay-la,la-la-la-lay-lay-la-la-la...';
        debugPrint(_infoMsg);
      }
      else
      {
//        debugPrint('###############_setMusicSchemes_SetMusicSchemes');
//        debugPrint('${_activeSoundScheme} - ${_soundSchemes.length}');
        res = 1;
        onLimitTempo(limitTempo);
        /*
        setState(() {
          _tempoBpmMax = limitTempo;
          if (_tempoBpm > _tempoBpmMax)
            _tempoBpm = _tempoBpmMax;
        });*/
      }
    } on PlatformException {
      _infoMsg = 'Exception: Failed setting  music scheme';
    }
    return new Future.value(res);
  }

  Future<List<String>> getSoundSchemes(int soundScheme) async
  {
    List<String> soundSchemes = new List<String>();
    try
    {
      List<dynamic> result = await _channel.invokeMethod('getSchemes', {'scheme': soundScheme});
//      debugPrint('??????????????_getMusicSchemes_getMusicSchemes');
//      debugPrint('${result.length} - ${_soundSchemes.length}');
      if (result.isNotEmpty)
      {
        //_soundSchemes = new List<String>();
        for (int i = 0; i < result.length; i++)
          soundSchemes.add(result[i]);

//        bool doSet = _activeSoundScheme < 0;  // 1st run on app startup
//        if (_activeSoundScheme >= _soundSchemes.length)
//          _activeSoundScheme = 0;

        if (0 < soundScheme && soundScheme < soundSchemes.length)
          await setSoundScheme(soundScheme);
      }
    } on PlatformException {
      _infoMsg = 'Exception: Failed getting music schemes';
    }
    return new Future.value(soundSchemes);
  }
}

/*
  Future<void> _getAudioParams() async {
    try {
      final Map<String, dynamic> result =
          await _channel.invokeMapMethod('getAudioParams');
      if (result != null) {
        nativeSampleRate = result['nativeSampleRate'];
        nativeBuffer = result['nativeBuffer'];
        latencyUntested = result['latencyUntested'];
        _infoMsg = 'Native audio params: $nativeSampleRate - $nativeBuffer - $latencyUntested';
      }
      else
        _infoMsg = 'Failed to get audio params';
    }
    on PlatformException
    {
      _infoMsg = 'Failed to get audio params';
    }

    debugPrint(_infoMsg);
    setState(() {});  // Update UI
}*/
