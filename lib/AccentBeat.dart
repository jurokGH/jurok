import 'dart:core';
import 'dart:math';
import 'package:flutter/cupertino.dart';

import 'BipPauseCycle.dart';
import 'beat_metre.dart';
import 'Melody.dart';

class AccentBeat extends Melody
{
  //final int _bars = 9;
  //int _nativeSampleRate;

  AccentBeat(int nativeFreq, double quortaInMSec,
    BeatMetre beat,
    /// Frequency (milliHz) and duration (millisec) of regular (weak) beat
    double beatFreq, int beatDuration,
    /// Frequency (milliHz) and duration (millisec) of accent (strong) beat
    double accentFreq, int accentDuration,
    int bars, int numerator):
    super(nativeFreq, quortaInMSec, bars, numerator)
  {
    //beatDuration == quortaInMSec;
    //super(nativeSampleRate, beatDuration, bars, numerator);

    //MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

    // Create

    // Half notes
    //440, 523.25
    //byte[] note2 = melodyTools.getFreq(beatFreq, framesInQuorta * 2, 2, 2);
    //byte[] accentNote2 = melodyTools.getFreq(accentFreq, framesInQuorta * 2, 2, 2);
    //byte[] pause = melodyTools.getSilence(framesInQuorta * 2);

    int maxSubBeatCount = 0;
    int bipCount = 0;  // beats * subBeatCount
    for (int i = 0; i < beat.subBeats.length; i++)
    {
      bipCount += beat.subBeats[i];
      if (beat.subBeats[i] > maxSubBeatCount)
        maxSubBeatCount = beat.subBeats[i];
    }

    //super.init(notes, pauses);
    //cycle.printFinal();

    //IS:
    // Bip alphabet
    // #0 - regular bip
    // #1 - accent bip
    // #2 - pause
  //melody = new byte[][]{note2, accentNote2};
  List<int> symbols = new List<int>(bipCount);
  int elasticSymbol = 2;

  double pauseFactor = beat.beatCount * 1.0;  // Годится любое неотрицательное значение.
  //ToDo: протестировать арфиметику: задать разные pauseFactor и
  //убедиться, что наименьший темп не меняется. Он зависит лишь от длительности
  //quortaInMSec (ToDo: поменять, это неудобно)
  List<BipAndPause> bipAndPause = new List<BipAndPause>(bipCount);
  int k = 0;
  for (int i = 0; i < beat.beatCount; i++)
    for (int j = 0; j < beat.subBeats[i]; j++, k++)
    {
      int iNote = (i == beat.accent && j == 0) ? 1 : 0;
      symbols[k] = iNote;
      //TODO vg Why /2?
      bipAndPause[k] = new BipAndPause(framesInQuorta * 2, pauseFactor);
      //pauseFactor / subBeats.get(i));
    }

  cycle = new BipPauseCycle(symbols, elasticSymbol, bipAndPause, nativeFreq, numerator);

  //System.out.printf("AccentBeat %d %d %d %d %d %d\n", beats, bipCount, bars, numerator, accent, beatDuration);
  //_bipAndPauseSing = bipAndPause;
/*
//IS: Это не нужно для метронома/без визуализации?
    // Даём паузам в мелодии значение тишины - это нужно для рисования, чтобы
    // лучше видеть разницу аудио и видео
    for (int i = 0; i < bipCount; i++)
    {
      cycle.cycle[2 * i + 1].a = cycle.elasticSymbol;
    }
 */
  }

  Position timePosition(double time)
  {
    return cycle?.timePosition(time);
  }
}
