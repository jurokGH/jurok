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
  int _activeBeat = 0;
  /// Active subbeat
  int _activeSubbeat = 0;

  /// Start time of given beat metre in microseconds 
  int _timeOrg;
  Tempo tempo;
  AccentBeat melody;
  Position pos;

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
    tempo = new Tempo();
    pos = new Position(0, 0);
    //_timer = new Stopwatch();
  }

  void start()
  {
    _timeOrg = DateTime.now().microsecondsSinceEpoch;
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
    pos.reset();
  }

  /// Synchronize metronome state with current sound state from Java
  void sync(int index, double offset, int beat, int subbeat, int time)
  {
    _timeOrg = DateTime.now().microsecondsSinceEpoch;
    //TODO Use pair/tuple
    List<int> pair = beatMetre.beatPair(index);
    // Correct reference sync time as a beat metre start time
    double t = beatMetre.timeOfBeat(tempo.beatsPerMinute, pair[0], pair[1]);
    _timeOrg -= (1e+6 * (t + offset)) ~/ 1;
    //VG Do we need to use Java current beat state?
    //_activeBeat = pair[0];
    //_activeSubbeat = pair[1];
  }

  bool update()
  {
    bool changed = false;
    if (_timeOrg == null)
      return changed;

    int time = DateTime.now().microsecondsSinceEpoch;
    double dt = 1e-6 * (time - _timeOrg);  // in seconds

    List<int> pair = beatMetre.timePosition(dt, tempo);
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

  void setTempo(int tempoBpm, int noteValue)
  {
    tempo.beatsPerMinute = tempoBpm;
    tempo.denominator = noteValue;

    int _bars = 1;
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
