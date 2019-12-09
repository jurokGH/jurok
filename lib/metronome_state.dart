import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'beat_metre.dart';

class MetronomeState extends ChangeNotifier
{
  BeatMetre _beat;

  int _activeBeat;
  int _activeSubbeat;

  //List<Int32> _list;
  Int32List _list;

  BeatMetre get beat => _beat;
  int get activeBeat => _activeBeat;
  int get activeSubbeat => _activeSubbeat;

  UnmodifiableInt32ListView get list => _list;
  //UnmodifiableListView<Int32> get list => UnmodifiableListView<Int32>(_list);

  void setActive(int beat, int subbeat)
  {
    _activeBeat = beat;
    _activeSubbeat = subbeat;
    notifyListeners();
  }
}
