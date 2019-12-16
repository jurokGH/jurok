package com.owlenome.owlenome;

/**
 * Пример музыкальной схемы: есть конкретные бипы, и соответствующий  им цикл.
 */
class SingSingMelody extends Melody
{
  /**
   * Создаёт схему с длительностями нот.
   * Играем "sing, sing, sing".
   *
   * @param quortaInMSec Определяет длительность четвертного бипа и соответственно
   *                     всех остальных несжимаемых звуков. Это эмуляция реальной
   *                     звуковой схемы (там длительности бипов будут фиксированы изначально).
   */
  public SingSingMelody(int nativeSampleRate, int quortaInMSec)
  {
    super(nativeSampleRate, quortaInMSec, 9, 1);

    MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

    byte[] noteB5half = melodyTools.noteB5(framesInQuorta * 2, 2, 2);
    byte[] noteA5half = melodyTools.noteA5(framesInQuorta * 2, 2, 2);
    byte[] noteG5half = melodyTools.noteG5(framesInQuorta * 2, 2, 2);
    byte[] noteB5quorta = melodyTools.noteB5(framesInQuorta, 2, 2);
    byte[] noteB5eighth = melodyTools.noteB5(framesInQuorta / 2, 2, 2);
    byte[] noteA5quorta = melodyTools.noteA5(framesInQuorta, 2, 2);
    byte[] noteG5quorta = melodyTools.noteG5(framesInQuorta, 2, 2);
    byte[] noteE6quorta = melodyTools.noteE6(framesInQuorta, 2, 2);
    byte[] noteB4half = melodyTools.noteB4(framesInQuorta * 2, 2, 2);
    byte[] noteG5eighth = melodyTools.noteG5(framesInQuorta / 2, 2, 2);
    byte[] noteE5quortaTuk = melodyTools.noteE5(framesInQuorta, 2, 4);
    byte[] pause8 = melodyTools.getSilence(framesInQuorta / 2);

    //noteB5half = melodyTools.noteB5(framesInQuorta*2,2, 2);
    byte[][] notes = new byte[][]{
      noteB5half, noteA5half,
      noteG5half, noteA5half,//4
      pause8, noteB5quorta, noteB5eighth, noteA5quorta, noteA5quorta,//9
      noteG5quorta, noteA5quorta, noteB5half,
      noteE6quorta, noteE6quorta, noteB5half,
      noteE6quorta, noteE6quorta, noteB5half,//18
      noteB5quorta, noteG5quorta, noteA5quorta, noteB5quorta, //22
      noteA5quorta, noteG5eighth, noteE5quortaTuk, pause8, pause8, pause8,//28
      pause8, pause8, pause8, pause8, pause8, pause8, pause8, pause8,//36
    };
    int[] pauses = new int[]{4, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35};
    super.init(notes, pauses);
    //cycle.printFinal();
  }
}

/*
// Пример музыкальной схемы: есть конкретные бипы, и соответствующий  им цикл.
class  SingSingSing
{
  // Сколько целых тактов в мелодии.
  private final int bars;

  final  public BipPauseCycle cycleSing;

  BipAndPause[] _bipAndPauseSing;

  final byte[] noteB5half;
  final byte[] noteA5half;
  final byte[] noteG5half;
  final byte[] noteB5quorta;
  final byte[] noteB5eighth;
  final byte[] noteA5quorta;
  final byte[] noteG5quorta;
  final byte[] noteE6quorta;
  final byte[] noteB4half;
  final byte[] noteG5eighth;
  final byte[] noteE5quortaTuk;


  final byte[][] setOfNotes;
  final byte[] pause8;


  /**
   * Создаёт схему с длительностями нот.
   * Играем "sing, sing, sing".
   * @param quortaInMSec  Определяет длительность четвертного бипа и соответственно
   *                       всех остальных несжимаемых звуков. Это эмуляция реальной
   *                       звуковой схемы (там длительности бипов будут фиксированы изначально).
   *
   *
  public  SingSingSing(double quortaInMSec, boolean sing)
  {
    int framesInQuorta = (int) nanoSec2samples((long) (1e6 * quortaInMSec));

    noteB5half = melodyTools.noteB5(framesInQuorta*2,2,2);
    noteA5half = melodyTools.noteA5(framesInQuorta*2,2,2);
    noteG5half = melodyTools.noteG5(framesInQuorta*2,2,2);
    noteB5quorta = melodyTools.noteB5(framesInQuorta,2,2);
    noteB5eighth = melodyTools.noteB5(framesInQuorta/2,2,2);
    noteA5quorta = melodyTools.noteA5(framesInQuorta,2,2);
    noteG5quorta = melodyTools.noteG5(framesInQuorta,2,2);
    noteE6quorta  = melodyTools.noteE6(framesInQuorta,2,2);
    noteB4half = melodyTools.noteB4(framesInQuorta*2,2,2);
    noteG5eighth = melodyTools.noteG5(framesInQuorta/2,2,2);
    noteE5quortaTuk  = melodyTools.noteE5(framesInQuorta,2,4);

    //noteB5half = melodyTools.noteB5(framesInQuorta*2,2, 2);
    if (sing)
    {
      pause8 = melodyTools.getSilence(framesInQuorta/2);

      bars = 9;
      setOfNotes = new byte[][]{
        noteB5half, noteA5half,
        noteG5half, noteA5half,//4
        pause8, noteB5quorta, noteB5eighth, noteA5quorta, noteA5quorta,//9
        noteG5quorta, noteA5quorta, noteB5half,
        noteE6quorta, noteE6quorta, noteB5half,
        noteE6quorta, noteE6quorta, noteB5half,//18
        noteB5quorta, noteG5quorta, noteA5quorta, noteB5quorta, //22
        noteA5quorta, noteG5eighth, noteE5quortaTuk, pause8, pause8, pause8,//28
        pause8, pause8, pause8, pause8, pause8, pause8, pause8, pause8,//36
      };
    }
    else
    {
      pause8 = melodyTools.getSilence(framesInQuorta*2);

      bars = 1;
      setOfNotes = new byte[][]{noteB5half, pause8};
    }

    double pauseFactor = 1.0;//Годится любое неотрицательное значение.
    //ToDo: протестировать арфиметику: задать разные pauseFactor и
    //убедиться, что наименьший темп не меняется. Он зависит лишь от длительности
    //quortaInMSec (ToDo: поменять, это неудобно)
    BipAndPause[] bipAndPauseSing = new BipAndPause[setOfNotes.length];
    for (int i = 0; i < bipAndPauseSing.length; i++)
    {
      //TODO vg Why /2?
      bipAndPauseSing[i] = new BipAndPause(setOfNotes[i].length / 2, pauseFactor);
    }

    _bipAndPauseSing = bipAndPauseSing;

    cycleSing = new BipPauseCycle(bipAndPauseSing, 1);

    //Даём паузам в мелодии значение тишины - это нужно для рисования, чтобы
    //лучше видеть разницу аудио и видео
    int[] pausesNms;
    if (sing)
    {
      pausesNms = new int[] {4, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35};
    }
    else
    {
      pausesNms = new int[]{1};//, 2};
    }
    for (int j = 0; j < pausesNms.length; j++)
    {
      cycleSing.cycle[pausesNms[j] * 2].a = cycleSing.elasticSymbol;
    }
    System.out.println("SING-SING");
    for (int j = 0; j < cycleSing.cycle.length; j++)
    {
      System.out.println(cycleSing.cycle[j].a);
    }
  }
}
*/