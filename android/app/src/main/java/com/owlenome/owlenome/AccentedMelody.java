package com.owlenome.owlenome;

import java.util.List;



//То, что мы будем играть. Определено с точностью до
// темпа (темп регулируется через setTempo)
class AccentedMelody
{


  byte[][] setOfNotes;


  BipAndPause[] _bipAndPauseSing;
  private int _nativeSampleRate;
  public BipPauseCycle cycle;


  // Number of nOfBeats
  int nOfBeats;


  /**
   * @param musicScheme
   * @param nativeSampleRate
   * @param nOfBeats
   * //@param accents
   * @param subBeats
   */
  public AccentedMelody(
                    MusicScheme2Bips musicScheme, int nativeSampleRate,
                    // Number of nOfBeats
                    int nOfBeats,
                    //int[] accents,
                    List<Integer> subBeats
                    )
  {

//    Это сейчас не нужно - использовалось в песенке Singsing для несжимаемой паузы
//    (иначе ритм ломался):
//    //ToDo Понадобится, когда будем делать ноты с паузами:)
//    byte[] pause = melodyTools.getSilence(framesInQuorta * 2);


    this.nOfBeats=nOfBeats;

    _nativeSampleRate=nativeSampleRate;

    int maxSubBeatCount = 1;
    int totalSubBeats = 0;  // nOfBeats * subBeatCount
    for (int i = 0; i < subBeats.size(); i++)
    {
      totalSubBeats += subBeats.get(i);
      if (subBeats.get(i) > maxSubBeatCount)
        maxSubBeatCount = subBeats.get(i);
    }

    //Теперь расставляем акценты.
    //Тут живёт особая философия, и делать это можно по-разному.
    //ToDo:   пробовать  по-разному и слушать.
    byte accents[]=GeneralProsody.getAccents1(nOfBeats,false); //false - чтобы распевней

    //Создаём реальные массивы акцентированных звуков.
    musicScheme.load(nativeSampleRate);



    //Ноты. Сначала сильные, потом слабые
    setOfNotes = new byte[musicScheme.setOfStrongNotes.length+musicScheme.setOfWeakNotes.length][];
    for(int i=0;i<musicScheme.setOfStrongNotes.length;i++){
      setOfNotes[i]=musicScheme.setOfStrongNotes[i];    }
    for(int i=0;i<musicScheme.setOfWeakNotes.length;i++){
      setOfNotes[i+musicScheme.setOfStrongNotes.length]=musicScheme.setOfWeakNotes[i]; }


    int[] symbols = new int[totalSubBeats];
    int elasticSymbol = -1;

    //Хватит всегда. ToDo:DoubleCheck!
    //Это какой-то странный способ я тут придумал... Вроде же просто нужно
    //найти число, которое больше, чем ...
    //чтобы...
    double totalLengthOfBeat=(musicScheme.weakBeat.length+musicScheme.strongBeat.length+2)*maxSubBeatCount;

    _bipAndPauseSing = new BipAndPause[totalSubBeats];
    int k = 0;
    for (int i = 0; i < nOfBeats; i++) {
      byte weakAccents[] = GeneralProsody.getAccents1(subBeats.get(i), false);
      for (int j = 0; j < subBeats.get(i); j++, k++) {
        if (j == 0) {//сильная доля
          symbols[k] = accents[i];
        } else {
          symbols[k] = musicScheme.setOfStrongNotes.length + weakAccents[j];
        }
        int noteLength = setOfNotes[symbols[k]].length;
        _bipAndPauseSing[k] = new BipAndPause(
                noteLength / 2,
                (totalLengthOfBeat / (subBeats.get(i) * noteLength / 2)) - 1
        );
      }
    }

    cycle = new BipPauseCycle(symbols, elasticSymbol, _bipAndPauseSing, 1);

      //ToDo: IS: Should we remove (in release)  all this stuff like printAcc1 etc? Seems to create memory leak!
    System.out.printf("AccentedMelody %d %d \n", nOfBeats, totalSubBeats);
/*
//VG: Это не нужно для метронома/без визуализации?
IS: Надо забыть код ниже (у нас нет сейчас пауз в мелодии, и они не нужны).

    // Даём паузам в мелодии значение тишины - это нужно для рисования, чтобы
    // лучше видеть разницу аудио и видео
    for (int i = 0; i < bipCount; i++)
    {
      cycle.cycle[2 * i + 1].a = cycle.elasticSymbol;
    }
 */
  }

  public double getMaxTempo()
  {
    return cycle.getMaximalTempo(_nativeSampleRate, nOfBeats);
  }

  public int setTempo(int beatsPerMinute)
  {
    int BPMtoSet = Math.min(
            (int) cycle.getMaximalTempo(_nativeSampleRate,nOfBeats),
             beatsPerMinute);
    //Utility utility = new Utility();
    //System.out.printAcc1("BPMtoSet ");
    //System.out.println(BPMtoSet);
    cycle.setNewDuration(
            Utility.beatsDurationInSamples(_nativeSampleRate,nOfBeats,
                    BPMtoSet));
    return BPMtoSet;
  }


}




//IS: Нам не нужно знать в яве ничего про знаменатели. Кроме того, они ужасно путают всё.
//Больше не используется.
class TempoObsolete
{
  int beatsPerMinute;
  int denominator;

  /**
   * Пример: темп 240 восьмых в минуту
   *
   * @param beatsPerMinute ударов в минуту
   * @param denominator    длительность удара (четвертая, шестнадцатая, etc)
   */
  public TempoObsolete(int beatsPerMinute, int denominator)
  {
    this.beatsPerMinute = beatsPerMinute;
    this.denominator = denominator;
  }

  boolean equals(TempoObsolete tempo)
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
  final static public long samplePlayTime(int frequency, long frameToPlayN, long stampTime, long stampFrame)
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
   * Пересчитываем  темпо (число нот в минуту BPM) в длительность цикла в сэмплах
   * BipPauseCycle исходя из того, сколько там bars (то есть, какова его длина в нотах)
   * и частоты (то есть, длительности одного сэмпла). Может быть больше, чем
   * возможная длина.
   * @param nativeSampleRate
   * @param nOfBeats
   * @param BPM
   * @return длительность в сэмплах данного числа битов при данном tempo (BMP) и частоте
   */
  final static double beatsDurationInSamples(int nativeSampleRate, int nOfBeats, int BPM) {
    //VG Note value (denominator) changes actual beat tempoTmpTmpTmp
    //int totalBeatsPerCycle = bars * tempoTmpTmpTmp.denominator;
    double samplesPerBeat = nativeSampleRate * 60.0 / BPM;
    return samplesPerBeat * nOfBeats;
  }

  /**
   *
   *  Больше не нужно
   *
   * Пересчитываем  темпо (традиционный, дуракций) в длительность цикла в сэмплах
   * BipPauseCycle исходя из того, сколько там bars (то есть, какова его длина в нотах)
   * и частоты (то есть, длительности одного сэмпла). Может быть больше, чем
   * возможная длина.
   * <p>
   * (В случае простого метронома bars=1.)
   *
   * @param tempoTmpTmpTmp музыкальный темп
   * @return какова должна быть длительность цикла при данном tempoTmpTmpTmp.
   */
// in seconds //IS: IN SAMPLES
  final static private double tempoToCycleDurationObsolete(TempoObsolete tempoTmpTmpTmp, int bars, int nativeSampleRate)
  {
    //VG Note value (denominator) changes actual beat tempoTmpTmpTmp
    int totalBeatsPerCycle = bars * tempoTmpTmpTmp.denominator;
    double samplesPerBeat = nativeSampleRate * 60.0 / tempoTmpTmpTmp.beatsPerMinute;

    return samplesPerBeat * totalBeatsPerCycle;
  }
}
