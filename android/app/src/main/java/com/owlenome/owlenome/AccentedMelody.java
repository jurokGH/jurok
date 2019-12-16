package com.owlenome.owlenome;

import java.util.List;


//То, что мы будем играть. Определено с точностью до темпа (темп регулируется через setTempo)
class AccentedMelody
{

  byte[][] setOfNotes;
  BipAndPause[] _bipAndPauseSing;
  private int _nativeSampleRate;
  public BipPauseCycle cycle;
  public AccentedMelody(
                    MusicScheme2Bips musicScheme,int nativeSampleRate,
                    // Number of beats
                    int beats,
                    //int[] accents,//ToDo
                    List<Integer> subBeats
                    )
  {

//    Это сейчас не нужно - использовалось в песенке Singsing для несжимаемой паузы
//    (иначе ритм ломался).
//    //ToDo Понадобится, когда будем делать ноты с паузами:)
//    byte[] pause = melodyTools.getSilence(framesInQuorta * 2);


    _nativeSampleRate=nativeSampleRate;

    int maxSubBeatCount = 0;
    int bipCount = 0;  // beats * subBeatCount
    for (int i = 0; i < subBeats.size(); i++)
    {
      bipCount += subBeats.get(i);
      if (subBeats.get(i) > maxSubBeatCount)
        maxSubBeatCount = subBeats.get(i);
    }



    //Создаём реальные массивы звуков
    musicScheme.load(nativeSampleRate);

    byte[] weakBeat =musicScheme.weakBeat;
    byte[] strongBeat=musicScheme.strongBeat;

    setOfNotes = new byte[][]{weakBeat, strongBeat};


    int[] symbols = new int[bipCount];
    int elasticSymbol = 2;

    //ToDo:DoubleCheck! должно хватить.
    double totalLengthOfBeat=(weakBeat.length+strongBeat.length+1)*maxSubBeatCount;


    _bipAndPauseSing = new BipAndPause[bipCount];
    int k = 0;
    for (int i = 0; i < beats; i++)
      for (int j = 0; j < subBeats.get(i); j++, k++)
      {
        int iNote = (i == 0 && j == 0) ? 1 : 0; //ToDo: accents
        symbols[k] = iNote;
        _bipAndPauseSing[k] = new BipAndPause(
                setOfNotes[iNote].length/2,
                (totalLengthOfBeat / (subBeats.get(i)* setOfNotes[iNote].length/2))-1
               );
      }

    cycle = new BipPauseCycle(symbols, elasticSymbol, _bipAndPauseSing, 1);

      //ToDo: IS: Should we remove (in release)  all this stuff like print etc? Seems to create memory leak!
    System.out.printf("AccentedMelody %d %d \n", beats, bipCount);
/*
//IS: Это не нужно для метронома/без визуализации?
IS отвечает: Надо забыть код ниже (у нас нет сейчас пауз в мелодии, и они не нужны). Но важно понять, как выглядит прямая речь, а то я путаюсь в комментах и тебя путаю:)
IS: Вить, это ты спрашиваешь или я?  "IS:" - это мне или я?  Юрик, может это ты?
    // Даём паузам в мелодии значение тишины - это нужно для рисования, чтобы
    // лучше видеть разницу аудио и видео
    for (int i = 0; i < bipCount; i++)
    {
      cycle.cycle[2 * i + 1].a = cycle.elasticSymbol;
    }
 */
  }

  public int setTempo(Tempo tempo)
  {
    int BPMtoSet = Math.min((int) cycle.getMaximalTempo(_nativeSampleRate, 1, tempo.denominator),
            tempo.beatsPerMinute);
    //Utility utility = new Utility();
    //System.out.print("BPMtoSet ");
    //System.out.println(BPMtoSet);
    cycle.setNewDuration(Utility.tempoToCycleDuration(new Tempo(BPMtoSet, tempo.denominator),
            1, _nativeSampleRate));
    return BPMtoSet;
  }


  public void reSetSubBeat(int subBeatIndex, int newSubBeatNumber){
    //TODO
    /**
     * Процедура создания мелодии (в части создания байтовых массивов под данную частоту) жирновата.
     * Поэтому нужно будет
     * (в дальнейшем) написать эту простую процедуру.
     */
  }
}


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
   * Пересчитываем  темпо (традиционный, дуракций) в длительность цикла в сэмплах
   * BipPauseCycle исходя из того, сколько там bars (то есть, какова его длина в нотах)
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
