import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'beat_metre.dart';
import 'tempo.dart';
import 'AccentBeat.dart';

/// State of current metronome activity

class MetronomeState with ChangeNotifier
{
  BeatMetre beatMetre = new BeatMetre();
  /// Active BeatMetre (note)
  int _activeBeat = -1;
  /// Active subbeat
  int _activeSubbeat = 0;


  ///  start time of A first beat (in microseconds)
  int _timeOrg;

  ///Время, когда начинать играть (in microseconds)
  ///Пока не наступило - не анимируемся (еще не отыгран буфер тишины)
  ///Используется лишь один раз
  ///(может быть полезно для статистики).
  int timeOfTheFirstBeat=(2<<53); //end of time

  //Tempo tempo;

  int beatsPerMinute;

  //AccentBeat melody; //IS: Why?
  //Position pos;

  //DateTime _time0 = new DateTime.fromMillisecondsSinceEpoch(0);
  //Stopwatch _timer;
  //List<Int32> _list;
  //Int32List _list;

  //BeatMetre get BeatMetre => _beat;
  int get activeBeat => _activeBeat;
  int get activeSubbeat => _activeSubbeat;

  //UnmodifiableInt32ListView get list => _list;
  //UnmodifiableListView<Int32> get list => UnmodifiableListView<Int32>(_list);

  MetronomeState()
  {
    //tempo = new Tempo();
    //pos = new Position(-1, 0); //ToDo: (-1,0)?
    //_timer = new Stopwatch();
  }

  void start(int initTime)
  {
     //_timeOrg = DateTime.now().microsecondsSinceEpoch;  //IS: No(((

     timeOfTheFirstBeat=initTime;
     _timeOrg=initTime;


    /*
    _timer.reset();
    __time0 = _timer.elapsedMicroseconds;
    if (!_timer.isRunning)
      _timer.start();
     */
  }

  void stop()
  {
/*
    if (_timer.isRunning)
      _timer.stop();
*/
  }

  void reset()
  {
    _activeBeat = _activeSubbeat = 0;
    //_activeBeat=-1; _activeSubbeat = 0;//IS: Test//ToDo
    //pos.reset();
  }

  /* IS: Пока убрал
  /// Synchronize metronome state with current sound state from Java
  void sync(int index, double offset, int beat, int subbeat, int time)
  {
    _timeOrg = DateTime.now().microsecondsSinceEpoch;//IS: Oh, why? //TODO
    //TODO Use pair/tuple
    List<int> pair = beatMetre.beatPair(index);
    // Correct reference sync time as a beat metre start time
    double t = beatMetre.timeOfBeat( beatsPerMinute, pair[0], pair[1]);
    _timeOrg -= (1e+6 * (t + offset)) ~/ 1; //IS:   ??
    //VG Do we need to use Java current beat state?
    //_activeBeat = pair[0];
    //_activeSubbeat = pair[1];
  }
   */

  bool update()
  {
    bool changed = false;
    if (_timeOrg == null)
      return changed;

    int time = DateTime.now().microsecondsSinceEpoch;

    if (time<timeOfTheFirstBeat) return changed;//звука пока нет
    //Нужно что-то поумнее придумать в этот период. Новости там пользователю
    //предложить почитать или что еще...

    double dt = 1e-6 * (time - _timeOrg);  // in seconds



    List<int> pair = beatMetre.timePosition(dt, beatsPerMinute);
    int curBeat = pair[0];
    int curSubbeat = pair[1];
    
    if (curBeat != _activeBeat || curSubbeat != _activeSubbeat)
    {
      changed = true;
      _activeBeat = curBeat;
      _activeSubbeat = curSubbeat;
    }
    return changed;
  }

   /* //IS:прикрыл, чтобы разобраться в коде.
  /// Не используется?
  bool updateCycle()
  {
    bool changed = false;
    int time = DateTime.now().microsecondsSinceEpoch;
    int dt = time - _timeOrg;
    if (melody != null)
    {
      pos = melody.timePosition(1e-6 * dt);
      List<int> pair = beatMetre.beatPair(pos.n);
      int curBeat = pair[0];
      int subbeat = pair[1];
      if (curBeat != _activeBeat || subbeat != _activeSubbeat)
      {
        changed = true;
        _activeBeat = curBeat;
        _activeSubbeat = subbeat;
      }
    }
    return changed;
  }
*/
   /*
  void setTempo(int tempoBpm/*, int noteValue*/)
  {
    beatsPerMinute = tempoBpm;
    //tempo.denominator = noteValue;

  //  int _bars = 1;
    //melody.cycle.setTempo(tempo, _bars);
  }*/

  /// Устанавливаем начальное время и BMP.
  ///
  /// !!!!Устанавливать только по согласованию с явой!!!!
  /// Иначе разойдутся анимация и видео.
  ///
  /// Эти два параметра необходимы и достаточны для синхронизации
  /// звука. Почему достаточны - понятно (можно не ссылаться на теорему Коши).
  ///
  /// Важно! - Почему они необходимы?
  /// Мы не можем устанавливать темп независимо от начального времени.
  /// Действительно, мы не знаем в принципе, сколько времени шли сообщения от флаттера к яве
  /// и, что более существенно,  сколько времени доигрывалась мелодия в старом темпе -
  ///  ей заполнен буфер  (это могут быть сотни миллисекунд).
  ///
  void sync(int initTime, int tempoBpm)
  {
    beatsPerMinute = tempoBpm;
    _timeOrg=initTime;
    //tempo.denominator = noteValue;

    //  int _bars = 1;
    //melody.cycle.setTempo(tempo, _bars);
  }

  bool isActiveBeat(int id)
  {
    return id == _activeBeat;
  }

  int getActiveSubbeat(int id)
  {
    return id == _activeBeat ? _activeSubbeat : -1;
  }

  int getActiveState()
  {
    return (_activeBeat << 16) | (_activeSubbeat & 0xFFFF);
  }

  int getBeatState(int id)
  {
    return id == _activeBeat ? ((_activeBeat << 16) | (_activeSubbeat & 0xFFFF)) : 0xFFFF;
  }

  void setActiveState(int beat, int subbeat)
  {
    _activeBeat = beat;
    _activeSubbeat = subbeat;
    notifyListeners();
  }
}
