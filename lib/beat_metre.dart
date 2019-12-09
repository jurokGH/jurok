import 'dart:core';

/// Metronome beat melody configuration

class BeatMetre
{
  /// Number of beats
  int _beatCount;
  /// Number of subbeats if they are the same for all beats
  /// Used if number of beats is increasing
  int _subBeatCount;
  /// Index of accented beat
  int accent;
  /// Number of subbeats in each i-th beat
  /// _beatCount == subBeats.length
  List<int> subBeats;

  /// Subdivision of beat melody to simple metres (rows)
  /// notes.length - number of simple metres in metronome beat melody
  List<int> metres;

  /// notes[i] - i-th notes (bips)
  /// notes[i][j] - musical char of j-th subdivision of i-th note (bip)
  List<List<int>> notes;

  BeatMetre()
  {
    _beatCount = 4;
    accent = 0;
    _subBeatCount = 1;
    subBeats = new List<int>.filled(_beatCount, 1, growable: true);
    //subBeats.length = _beatCount;
    //for (int i = 0; i < subBeats.length; i++)
    //  subBeats[i] = _subBeatCount;
  }

  int get beatCount => _beatCount;
  set beatCount(int count)
  {
    assert(_beatCount == subBeats.length);
    if (count > 0 && _beatCount != count)
    {
      subBeats.length = count;
      for (int i = _beatCount; i < subBeats.length; i++)
        subBeats[i] = _subBeatCount;
      _beatCount = count;
    }
  }

  int get subBeatCount => _subBeatCount;
  set subBeatCount(int count)
  {
    assert(_beatCount == subBeats.length);
    if (count > 0 && _subBeatCount != count)
    {
      _subBeatCount = count;
      for (int i = 0; i < subBeats.length; i++)
        subBeats[i] = count;
    }
  }

  /// Return pair (beat, subBeat) by overall beat index
  List<int> beatPair(int index)
  {
    //beatOrder %= _beatCount;
    assert(_beatCount == subBeats.length);
    int beat, subBeat;
    beat = subBeat = 0;
    //print('beatPair $index - ${subBeats.length}');
    for (int i = 0; i < subBeats.length; i++)
    {
      print('$i - ${subBeats[i]}');
      if (index - subBeats[i] < 0)
      {
        beat = i;
        subBeat = index;
        break;
      }
      else
        index -= subBeats[i];
    }
    return [beat, subBeat];
  }

  int count()
  {
    assert(_beatCount == subBeats.length);
    int count = 0;
    for (int i = 0; i < subBeats.length; i++)
      count += subBeats[i];
    return count;
  }
}

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
