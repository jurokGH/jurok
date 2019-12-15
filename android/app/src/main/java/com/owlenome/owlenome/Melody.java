package com.owlenome.owlenome;

class Tempo
{
  int beatsPerMinute;
  int denominator;

  /**
   * Пример: темп 240 восьмых в минуту
   *
   * @param beatsPerMinute ударов в минуту
   * @param denominator    длительность удара (четвертая, шестнадцатая, etc)
   */
  public Tempo(int beatsPerMinute, int denominator)
  {
    this.beatsPerMinute = beatsPerMinute;
    this.denominator = denominator;
  }

  boolean equals(Tempo tempo)
  {
    return beatsPerMinute == tempo.beatsPerMinute &&
      denominator == tempo.denominator;
  }
}

class Utility
{
  /**
   * Возвращает время игры бипа согласно штампу и номеру сэмла.
   * Интерполирует через nativeSampleRate;
   */
  final static  public long samplePlayTime(int frequency, long frameToPlayN, long stampTime, long stampFrame)
  {
    return stampTime + samples2nanoSec(frequency, frameToPlayN - stampFrame);
  }

  /**
   * Определяем число samples в данном числе наносекунд.
   */
  final static public long nanoSec2samples(int frequency, long time)
  {
    return Math.round((double) time * frequency * 1e-9);
  }

  /**
   * Определяем время в наносекундах из samples
   */
  final static  public long samples2nanoSec(int frequency, long samplesN)
  {
    return Math.round(1e9 * samplesN / frequency);
  }

  /**
   * Пересчитываем  темпо (традиционный, дуракций) в длительность цикла в сэмплах,
   * BipPauseCycleисходя из того, сколько там bars (то есть, какова его длина в нотах)
   * и частоты (то есть, длительности одного сэмпла). Может быть больше, чем
   * возможная длина.
   * <p>
   * (В случае простого метронома bars=1.)
   *
   * @param tempo музыкальный темп
   * @return какова должна быть длительность цикла при данном tempo.
   */
// in seconds
  final static public double tempoToCycleDuration(Tempo tempo, int bars, int nativeSampleRate)
  {
    //VG Note value (denominator) changes actual beat tempo
    int totalBeatsPerCycle = bars * tempo.denominator;
    double samplesPerBeat = nativeSampleRate * 60.0 / tempo.beatsPerMinute;

    return samplesPerBeat * totalBeatsPerCycle;
  }
}

// Мелодия - последовательность звуков (бипов) и пауз между ними

class Melody
{
  private int _frequency;
  public int framesInQuorta;
  private int _nativeSampleRate;

  // Количество целых тактов в мелодии
  private int _bars;
  // Количество долей в такте мелодии
  private int _numerator;

  public BipPauseCycle cycle;
  // Bip alphabet
  byte[][] melody;//ToDo: rename; they are just a set of sounds, not a melody.
  // To be removed
  BipAndPause[] _bipAndPauseSing;

  /**
   * Создаёт схему с длительностями нот.
   * (когда-то играло "Sing, sing, sing.").
   *
   * @param quortaInMSec Определяет длительность четвертного бипа и соответственно
   *                     всех остальных несжимаемых звуков. Это эмуляция реальной
   *                     звуковой схемы (там длительности бипов будут фиксированы изначально).
   */
  public Melody(int nativeSampleRate, int quortaInMSec, int bars, int numerator)
  {
    _bars = bars;
    _nativeSampleRate = nativeSampleRate;
    _numerator = numerator;

    //Utility utility = new Utility();
    framesInQuorta = (int) Utility.nanoSec2samples(_nativeSampleRate, (long) (1e+6 * quortaInMSec));
  }

  public void init(byte[][] notes, int[] pauses)
  {
    melody = notes;

    double pauseFactor = 1.0;//Годится любое неотрицательное значение.
    //ToDo: протестировать арфиметику: задать разные pauseFactor и
    //убедиться, что наименьший темп не меняется. Он зависит лишь от длительности
    //quortaInMSec (ToDo: поменять, это неудобно)
    BipAndPause[] bipAndPauseSing = new BipAndPause[melody.length];
    for (int i = 0; i < bipAndPauseSing.length; i++)
    {
      //TODO vg Why /2?
      bipAndPauseSing[i] = new BipAndPause(melody[i].length / 2, pauseFactor);
    }

    _bipAndPauseSing = bipAndPauseSing;

    cycle = new BipPauseCycle(bipAndPauseSing, _numerator);

    //Даём паузам в мелодии значение тишины - это нужно для рисования, чтобы
    //лучше видеть разницу аудио и видео
    for (int i = 0; i < pauses.length; i++)
    {
      cycle.cycle[pauses[i] * 2].a = cycle.elasticSymbol;
    }
  }

  /**
   * Устанавливаем новую длительность цикла. Имеется арифметическое ограничение снизу
   * (см. getMaximalTempo).
   *
   * @param tempo музыкальный ритм
   * @return установленных ударов в минуту
   */
  public int setTempo(Tempo tempo)
  {
    int BPMtoSet = Math.min((int) cycle.getMaximalTempo(_nativeSampleRate, _bars, tempo.denominator),
      tempo.beatsPerMinute);
    //Utility utility = new Utility();
    //System.out.print("BPMtoSet ");
    //System.out.println(BPMtoSet);
    cycle.setNewDuration(Utility.tempoToCycleDuration(new Tempo(BPMtoSet, tempo.denominator),
      _bars, _nativeSampleRate));
    return BPMtoSet;
  }
}
