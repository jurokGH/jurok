import 'dart:typed_data';
import 'package:flutter/foundation.dart';

import 'beat_metre.dart';

/// State of current metronome activity

class MetronomeState with ChangeNotifier
{
 // BeatMetre _beat;
  /// Active beat (note)
  int _activeBeat = 0;
  /// Active subbeat
  int _activeSubbeat = 0;

  //List<Int32> _list;
  Int32List _list;

  //BeatMetre get beat => _beat;
  int get activeBeat => _activeBeat;
  int get activeSubbeat => _activeSubbeat;

  UnmodifiableInt32ListView get list => _list;
  //UnmodifiableListView<Int32> get list => UnmodifiableListView<Int32>(_list);

  MetronomeState();

  void reset()
  {
    _activeBeat = _activeSubbeat = 0;
  }

  int getActiveState()
  {
    return (_activeBeat << 16) | (_activeSubbeat & 0xFFFF);
  }

  void setActiveState(int beat, int subbeat)
  {
    _activeBeat = beat;
    _activeSubbeat = subbeat;
    notifyListeners();
  }
}
