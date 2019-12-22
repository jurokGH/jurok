import 'dart:core';
import 'tempo.dart';

/// Metronome beat melody configuration
/// Represents rhythm

class BeatMetre
{
  /// Number of beats
  int _beatCount;
  /// Number of subbeats if they are the same for all beats
  /// Used as default if number of beats is increasing
  int _subBeatCount;
  /// Number of subbeats in each i-th beat
  /// _beatCount == subBeats.length
  List<int> subBeats;

  /// Subdivision of beat melody to simple metres (rows)
  /// notes.length - number of simple metres in metronome beat melody
  List<int> metres;

  /// Indices of accented beats in each simple metre (row)
  /// accents.length == metres.length
  List<int> accents;

  /// notes[i] - i-th notes (bips)
  /// notes[i][j] - musical char of j-th subdivision of i-th note (bip)
  List<List<int>> notes;

  BeatMetre()
  {
    _beatCount = 4;
    _subBeatCount = 1;
    subBeats = new List<int>.filled(_beatCount, 1, growable: true);
    metres = new List<int>.filled(1, _beatCount, growable: true);
    accents = new List<int>.filled(1, 0, growable: true);
    //subBeats.length = _beatCount;
    //for (int i = 0; i < subBeats.length; i++)
    //  subBeats[i] = _subBeatCount;
  }

  ///TODO For now
  int get accent => accents.length > 0 ? accents[0] : 0;

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
      //print('$i - ${subBeats[i]}');
      if (index < subBeats[i])
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

  /// Start time (in seconds) of [beat, subbeat] sound relating to begin of this beat metre
  /// bpm - tempo, beats per minute

  double timeOfBeat(int tempoBpm, int beat, int subbeat)
  {
    double bps = tempoBpm / 60;
    beat %= beatCount;
    //assert(subbeat < subBeats[beat]);
    return (beat + subbeat / subBeats[beat]) / bps;
  }

  /// time - time from begin in seconds
  List<int> timePosition(double time, Tempo tempo)
  {
    double duration = _beatCount * 60.0 / tempo.beatsPerMinute;
    //Position pos = new Position(0, 0);
    int cycle = time ~/ duration;
    if (time < 0)
      time = -time;

    //print('timePosition0 $duration');

    double timeInBeat = time % duration;
    duration /= _beatCount;  // Duration of 1 beat
    int beat = timeInBeat ~/ duration;
    //print('timePosition1 $duration - $timeInBeat - $beat - ${subBeats[beat]}');
    double time1 = timeInBeat % duration;
    duration /= subBeats[beat];  // Duration of 1 subbeat of a given beat
    int subbeat = time1 ~/ duration;
    double offset = time1 % duration;

    //print('timePosition $time1 - $duration - offset $beat - $subbeat - ${subBeats[beat]}');

    return [beat, subbeat];
  }
}

/*


/// Beat sound configuration boilerplate

 //IS: I suppose that it has nothing to do with the rhythm notion


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
*/