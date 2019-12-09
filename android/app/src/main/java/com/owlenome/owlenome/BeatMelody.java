package com.owlenome.owlenome;

/**
 * Пример музыкальной схемы: есть конкретные бипы, и соответствующий  им цикл.
 */
class BeatMelody extends Melody
{
  /**
   * Создаёт схему с длительностями нот.
   * Играем "sing, sing, sing".
   *
   * @param quortaInMSec Определяет длительность четвертного бипа и соответственно
   *                     всех остальных несжимаемых звуков. Это эмуляция реальной
   *                     звуковой схемы (там длительности бипов будут фиксированы изначально).
   */
  public BeatMelody(int nativeSampleRate, int quortaInMSec, int bars, int numerator)
  {
    super(nativeSampleRate, quortaInMSec, bars, numerator);

    MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

    byte[] noteB5half = melodyTools.noteB4(framesInQuorta * 2, 2, 2);
    byte[] pause8 = melodyTools.getSilence(framesInQuorta * 2);

    byte[][] notes = new byte[][]{noteB5half, pause8};
    int[] pauses = new int[]{1};

    super.init(notes, pauses);
    //cycle.printFinal();
  }
}
