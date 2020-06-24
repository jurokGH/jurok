import 'dart:core';

import 'package:owlenome/rhythms.dart';

/// Metronome beat melody configuration
/// Represents rhythm
///
/// ISH: To actually represent it, I restore accents here

class BeatMetre
{
  /// Number of beats
  int _beatCount;
  /// Number of subbeats if they are the same for all beats
  /// Used as default if number of beats is increasing
  int _subBeatCount=1;
  /// Number of subbeats in each i-th beat
  /// _beatCount == subBeats.length
  List<int> subBeats;

  //String name="unnamed";

  /// Subdivision of beat melody to simple metres (rows)
  /// notes.length - number of simple metres in metronome beat melody
  //List<int> _metres;

  /// Indices of accented beats in each simple metre (row)
  /// accents.length == metres.length
  List<int> accents;
  //List<int> _regularAccents;
  //bool pivoVodochka = false;  // false - чтобы распевней

  // Unused
  /// notes[i] - i-th notes (bips)
  /// notes[i][j] - musical char of j-th subdivision of i-th note (bip)
  //List<List<int>> notes;

  BeatMetre(Rhythm rhythm)
  {
    subBeats = new List<int>.from(rhythm.subBeats, growable: true);
    _beatCount = subBeats.length;
    accents = List<int>.from(rhythm.accents, growable: true);

    if (subBeatsEqualAndExist()) _subBeatCount = subBeats[0];

//    name=rhythm.name;
  }


  /*
  BeatMetre(List<int> subBeats0, List<int> accents0)
  {
    subBeats = new List<int>.from(subBeats0, growable: true);
    _beatCount = subBeats.length;
    accents = List<int>.from(accents0, growable: true);

    if (subBeatsEqualAndExist()) _subBeatCount = subBeats[0];

    //_subBeatCount = subBeatsEqualAndExist()? subBeats[0]:1;

    //_metres = new List<int>.filled(1, _beatCount, growable: true);

    //TODO
    //accents = Prosody.getAccents(_beatCount, pivoVodochka);
    //_regularAccents = Prosody.getAccents(_beatCount, true);  //TODO Define as regular if pivoVodochka = true?
    //Попытка настройки начальной мелодии.
    //if (subBeats.length == accents0.length)
      //accents = new List<int>.from(accents0, growable: true);

    //subBeats.length = _beatCount;
    //for (int i = 0; i < subBeats.length; i++)
    //  subBeats[i] = _subBeatCount;
  }
   */

  bool subBeatsEqualAndExist(){
    if ((subBeats.length == 0) || (subBeats[0] == 0)) return false;
    int initSubBeat = subBeats[0];
    for (int i = 1; i < _beatCount; i++)
      if (subBeats[i] != initSubBeat) { return false;}
    return true;
  }


  void setAccent(int beat, int accent)
  {
    assert(0 <= beat && beat < _beatCount);
    if (beat < _beatCount && accent <= maxAccent)
      accents[beat] = accent;
  }

  int get maxAccent {
    int res=0;
    if (_beatCount<4) res=1;
    else if (_beatCount<10) res=2;
    else (res=3); //ToDo: double check with books about 10
    return res;
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

      List<int> newAccents = new List<int>.filled(count, 0, growable: true);
      for (int i = 0; i < _beatCount && i < accents.length; i++)
        newAccents[i] = accents[i];
      accents = newAccents;
    }
  }

  int get subBeatCount => _subBeatCount;
  set subBeatCount(int count)
  {
    assert(_beatCount == subBeats.length);
    //if (count > 0 && _subBeatCount != count)
    if (count > 0 )
    {
      _subBeatCount = count;
      for (int i = 0; i < subBeats.length; i++)
        subBeats[i] = count;
    }
  }


/*
  bool get regularAccent
  {
    //TODO only if _beatCount < 12
    if (_beatCount == 5 || _beatCount == 7 || _beatCount == 11 ||
      accents.length != _regularAccents.length)
    {
      print('regular:false 1');
      return false;
    }
    for (int i = 0; i < accents.length; i++)
      if (accents[i] != _regularAccents[i])
      {
        print('regular:false 2');
        return false;
      }
    print('regular:true');
    return true;
  }

  /// Test if this metre has plain accent scheme: [1, 0, 0, ..]
  bool get plainAccent
  {
    return accents.isEmpty || (accents.length == 1 && accents[0] == 0) ||
      (accents[0] == 1 && accents.skip(1).every((int x) => x == 0));
  }

  //TODO Change to var?
  int get maxAccent =>  _beatCount > 3 ? 3 : _beatCount - 1;


  void accentUp(int beat, int step)
  {
    assert(0 <= beat && beat < _beatCount);

    //TODO -1;
    if (beat < _beatCount)
      accents[beat] = clamp(accents[beat] + step, 0, maxAccent);
  }

  void setAccentOption(bool accentLean)
  {
    pivoVodochka = accentLean;
    accents = Prosody.getAccents(_beatCount, pivoVodochka);
  }

  void setRegularAccent()
  {
    // TODO Should change? Should use for?
    _regularAccents = Prosody.getAccents(_beatCount, true);  //TODO Define as regular if pivoVodochka = true?
    accents = new List.from(_regularAccents);
  }

  ///TODO For now Remove?
  int get accent => accents.length > 0 ? accents[0] : 0;
*/

  /// Return pair (beat, subBeat) by overall beat index
  /* Not used
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
  */

  /// Start time (in seconds) of [beat, subbeat] sound relating to begin of this beat metre
  /// bpm - tempo, beats per minute
/* Not used
  double timeOfBeat(int tempoBpm, int beat, int subbeat)
  {
    double bps = tempoBpm / 60;
    beat %= beatCount;
    //assert(subbeat < subBeats[beat]);
    return (beat + subbeat / subBeats[beat]) / bps;
  }
  /// time - time from begin in seconds
  List<int> timePosition(double time, int beatsPerMinute)
  {
    double duration = _beatCount * 60.0 / beatsPerMinute;
    //Position pos = new Position(0, 0);
    //int cycle = time ~/ duration;
    if (time < 0) {} //Такое может быть! Если latency большое, то легко.
       //time = -time;//IS:  это неверно. Даёт забавный эффект  -
    // если сделать к примеру размер большого буфера 300мс, то будем назад ехать:)

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
*/
}
