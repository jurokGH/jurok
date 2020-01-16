package com.owlenome.owlenome;

import java.util.ArrayList;
import java.util.List;



//То, что мы будем играть. Определено с точностью до
// темпа (темп регулируется через setTempo)
class AccentedMelody
{


  byte[][] setOfNotes;


  BipAndPause[] _bipAndPauseSing;
  private int _sampleRate;
  public BipPauseCycle cycle;


  // Number of beats
  int nOfBeats=0;


  MusicScheme2Bips musicScheme;


  public AccentedMelody(
                    MusicScheme2Bips musicScheme, int sampleRate,
                    BeatMetre beats
                    // Number of nOfBeats
                    //int nOfBeats,
                    //int[] accents,
                    //List<Integer> subBeats
                    )
  {
    //Создаём реальные массивы акцентированных звуков.
    this.musicScheme=musicScheme;
    this.musicScheme.load(sampleRate);//Долгая. В аудио потоке не делать.

    _sampleRate =sampleRate;

    setBeats(beats);
  }


  /**
   * Переустанавливает биты.
   * Позиция не поменяется, если число бипов выросло,
   * и съедет на начальный бип в той же поддоле.
   *
   * Сразу после этого следует переустановить tempo.
   *
   */
  public void setBeats(BeatMetre beats){

    if(beats.beatCount==0) return; //IS: VS, не знаю, что принято
    //делать в таких ситуациях - выйти, или ждать, пока само на 0 поделит с исключением?


    int oldCount=nOfBeats;

    nOfBeats=beats.beatCount;

//    //ToDo Понадобится, когда будем делать ноты с паузами:)
//     Нужно для несжимаемой паузы - то есть молчащего бипа.
//    byte[] pause = melodyTools.getSilence(framesInQuorta * 2);


    int maxSubBeatCount = 1;
    int totalSubBeats = 0;  // nOfBeats * subBeatCount
    for (int i = 0; i < beats.subBeats.size(); i++)
    {
      totalSubBeats += beats.subBeats.get(i);
      if (beats.subBeats.get(i) > maxSubBeatCount)
        maxSubBeatCount = beats.subBeats.get(i);
    }

    //Теперь расставляем акценты.
    //Тут живёт особая философия, и делать это можно по-разному.
    //ToDo:   пробовать  по-разному и слушать.
    //ToDo: отправить это в дарт
    byte accents[]=GeneralProsody.getAccents1(nOfBeats,false); //false - чтобы распевней



    //Ноты. Сначала сильные, потом слабые
    setOfNotes = new byte[musicScheme.setOfStrongNotes.length+musicScheme.setOfWeakNotes.length][];
    for(int i=0;i<musicScheme.setOfStrongNotes.length;i++){
      setOfNotes[i]=musicScheme.setOfStrongNotes[i];    }
    for(int i=0;i<musicScheme.setOfWeakNotes.length;i++){
      setOfNotes[i+musicScheme.setOfStrongNotes.length]=musicScheme.setOfWeakNotes[i]; }


    int[] symbols = new int[totalSubBeats];
    int elasticSymbol = -1;

    double totalLengthOfBeat=(musicScheme.weakBeat.length+musicScheme.strongBeat.length+2)*maxSubBeatCount;
    //ToDo:DoubleCheck
    //Это какой-то странноватый способ... Нужно
    //найти число,   удовлетворяющее для всех i неравенству
    //(totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) > 1


    _bipAndPauseSing = new BipAndPause[totalSubBeats];
    int k = 0;
    for (int i = 0; i < nOfBeats; i++) {
      byte weakAccents[] = GeneralProsody.getAccents1(beats.subBeats.get(i), false);
      for (int j = 0; j < beats.subBeats.get(i); j++, k++) {
        if (j == 0) {//сильная доля
          symbols[k] = accents[i];
        } else {
          symbols[k] = musicScheme.setOfStrongNotes.length + weakAccents[j];
        }
        int noteLength = setOfNotes[symbols[k]].length;
        _bipAndPauseSing[k] = new BipAndPause(
                noteLength / 2,
                (totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) - 1
        );
      }
    }


    //Вычисляем новую относительную позицию в цикле
    double newPosition=0;
    if (cycle!=null){
      if (oldCount> nOfBeats) {//уменьшилось число долей
        //Если число бит уменьшилось, нам надо будет переместить бегунок в первую ноту
        double beatDuration = cycle.duration / nOfBeats;
        //В новом цикле сместимся на это значение:
        newPosition = (cycle.durationBeforePosition() % beatDuration)/cycle.duration;
      }
      else {
        newPosition = cycle.relativeDurationBeforePosition();
      }
    }

    cycle = new BipPauseCycle(symbols, elasticSymbol, _bipAndPauseSing, 1);
    int i =(int)(newPosition*cycle.duration);
    cycle.readTempoLinear(i);//ToDo: вешаем чайник; проматываем отыгранную длительность


    //ToDo: IS: VS, should we remove (in release)  all this stuff like printAcc1 etc? Seems to create memory leak!
    //System.out.printf("AccentedMelody %d %d \n", nOfBeats, totalSubBeats);

  }




  public double getMaxTempo()
  {
    return cycle.getMaximalTempo(_sampleRate, nOfBeats);
  }

  /**
   *
   * @param beatsPerMinute что хотим
   * @return что получилось
   */
  public int setTempo(int beatsPerMinute)
  {
    int BPMtoSet = Math.min(
            (int) cycle.getMaximalTempo(_sampleRate,nOfBeats),
             beatsPerMinute
    );
    //Utility utility = new Utility();
    //System.out.printAcc1("BPMtoSet ");
    //System.out.println(BPMtoSet);
    cycle.setNewDuration(
            Utility.beatsDurationInSamples(_sampleRate,nOfBeats,
                    BPMtoSet));
    return BPMtoSet;
  }

}


// Same as beat_metre.dart::BeatMetre
class BeatMetre
{
  int beatCount;
  List<Integer> subBeats;
  // Indices of accented beats in each simple metre (row)
  List<Integer> accents; //ToDo

  BeatMetre()
  {
    beatCount = 4;
    subBeatCount = 1;
    subBeats = new ArrayList<Integer>();
    accents = new ArrayList<Integer>();
    //accents.set(0, 0);
  }

  int subBeatCount;
}


//IS: Нам не нужно знать в яве ничего про знаменатели. Кроме того, они ужасно путают всё.
//Больше не используется.
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
  static public long samplePlayTime(int frequency, long frameToPlayN, long stampTime, long stampFrame)
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
  final static private double tempoToCycleDurationObsolete(Tempo tempoTmpTmpTmp, int bars, int nativeSampleRate)
  {
    //VG Note value (denominator) changes actual beat tempoTmpTmpTmp
    int totalBeatsPerCycle = bars * tempoTmpTmpTmp.denominator;
    double samplesPerBeat = nativeSampleRate * 60.0 / tempoTmpTmpTmp.beatsPerMinute;

    return samplesPerBeat * totalBeatsPerCycle;
  }
}
