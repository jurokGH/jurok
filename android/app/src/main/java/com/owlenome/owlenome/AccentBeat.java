package com.owlenome.owlenome;

import java.util.List;

// Accented beat melody for metronome
// VG: Currently made ugly

class AccentBeat extends Melody
{
  public AccentBeat(int nativeSampleRate, int quortaInMSec,
                    // Number of beats
                    int beats,
                    // Index of accented beat
                    int accent,
                    /// Frequency (milliHz) and duration (millisec) of regular (weak) beat
                    double beatFreq, int beatDuration,
                    /// Frequency (milliHz) and duration (millisec) of accent (strong) beat
                    double accentFreq, int accentDuration,
                    int bars, int numerator,
                    // Number of subbeats in each i-th beat
                    List<Integer> subBeats)
  {
    //beatDuration == quortaInMSec;
    super(nativeSampleRate, beatDuration, bars, numerator);

    MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

    // Create

    // Half notes
    //440, 523.25
    byte[] note2 = melodyTools.getFreq(beatFreq, framesInQuorta * 2, 2, 2);
    byte[] accentNote2 = melodyTools.getFreq(accentFreq, framesInQuorta * 2, 2, 2);
    byte[] pause = melodyTools.getSilence(framesInQuorta * 2);

    int maxSubBeatCount = 0;
    int bipCount = 0;  // beats * subBeatCount
    for (int i = 0; i < subBeats.size(); i++)
    {
      bipCount += subBeats.get(i);
      if (subBeats.get(i) > maxSubBeatCount)
        maxSubBeatCount = subBeats.get(i);
    }

    //super.init(notes, pauses);
    //cycle.printFinal();

    //IS:
    // Bip alphabet
    // #0 - regular bip
    // #1 - accent bip
    // #2 - pause
    melody = new byte[][]{note2, accentNote2};
    int[] symbols = new int[bipCount];
    int elasticSymbol = 2;

    double pauseFactor = beats * 1.0;  // Годится любое неотрицательное значение.
    //ToDo: протестировать арфиметику: задать разные pauseFactor и
    //убедиться, что наименьший темп не меняется. Он зависит лишь от длительности
    //quortaInMSec (ToDo: поменять, это неудобно)
    BipAndPause[] bipAndPause = new BipAndPause[bipCount];
    int k = 0;
    for (int i = 0; i < beats; i++)
      for (int j = 0; j < subBeats.get(i); j++, k++)
      {
        int iNote = (i == accent && j == 0) ? 1 : 0;
        symbols[k] = iNote;
        //TODO vg Why /2?
        bipAndPause[k] = new BipAndPause(melody[iNote].length / 2, pauseFactor);
          //pauseFactor / subBeats.get(i));
      }

    cycle = new BipPauseCycle(symbols, elasticSymbol, bipAndPause, numerator);

    System.out.printf("AccentBeat %d %d %d %d %d %d\n", beats, bipCount, bars, numerator, accent, beatDuration);
    _bipAndPauseSing = bipAndPause;
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
}
