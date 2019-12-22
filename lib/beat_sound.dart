import 'dart:core';
import 'tempo.dart';

/// Beat sound configuration boilerplate

class BeatSound
{
  /// Regular (weak) beat
  /// Frequency in milliHz
  int beatFreq;  // in milliHz
  /// Duration in milliSec
  int beatDuration;
  /// Accented (strong) beat
  int accentFreq;
  int accentDuration;

  BeatSound()
  {
    beatFreq = 440000;
    beatDuration = 25;
    accentFreq = 523250;
    accentDuration = 25;
  }
}

class BeatSoundScheme
{
  /// Scheme number
  /// scheme = -1 - use notes (simple <sinusoid> notes)
  int scheme;
  List<BeatSound> notes;
}
