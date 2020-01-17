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
  public BipPauseCycle cycle=null;
  private  BipPauseCycle newCycle=null;

  /**
   * Установленная скорость цикла
   */
  double tempo;

  private final static  double defaultTempo =123.0;



  /**
   *Number of beats in cycle
   */
   private int beatCount=0;

  /**
   *  Number of beats in newCycle
   */
  private int newBeatCount;



  MusicScheme2Bips musicScheme;


  public AccentedMelody(
          MusicScheme2Bips musicScheme, int sampleRate,
          BeatMetre beats
          // Number of nOfBeats
          //int nOfBeats,
          //int[] accents,
          //List<Integer> subBeats
  ){
    this(musicScheme, sampleRate, beats, defaultTempo);
  }

  public AccentedMelody(
                    MusicScheme2Bips musicScheme, int sampleRate,
                    BeatMetre beats, double tempo
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

    this.tempo=tempo;

    prepareNewCycle(beats);

    setNewCycle();
  }

  /**
   *  Готовим новый цикл (чтобы потом его можно было подменить в аудиоцикле).
   *  Возвращает максимальную скорость нового цикла.
   */
  public double prepareNewCycle(BeatMetre beats){
    if(beats.beatCount<=0) return -1.0;
    //ToDo  IS: VS, не знаю, что принято
    // делать в таких ситуациях - выйти, или ждать, пока само на 0 поделит с исключением?



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
    byte accents[]=GeneralProsody.getAccents1(beats.beatCount,false); //false - чтобы распевней



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
    for (int i = 0; i < beats.beatCount; i++) {
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

    newCycle = new BipPauseCycle(symbols, elasticSymbol, _bipAndPauseSing, 1);

    newBeatCount= beats.beatCount;

    return newCycle.getMaximalTempo(_sampleRate, newBeatCount);
  }

  /**
   *
   * Переустанавливает биты.
   * Позиция не поменяется, если число бипов выросло,
   * и съедет на начальный бип в той же поддоле.
   *
   */
  public void setNewCycle(){

    if (newCycle==null) return;//ToDo ?


    //Вычисляем новую относительную позицию в цикле
    double newPositionRel=0;
    if (cycle!=null){//and hence, beatCount>0
      double beatDuration = cycle.duration / beatCount;
      int beatNow=(int)(cycle.durationBeforePosition()/beatDuration);


      if (beatNow> newBeatCount) {//надо будет переместить бегунок куда-то, если мы не попали в границы цикла.
        //Требование: не должен сбиться общий ритм (представим, что все звуки долей одинаковы -
        // изменение метра не должно быть различимо на слух.
        //Доигрываем  последний  бип
        double restInBeat=beatDuration-(cycle.durationBeforePosition() % beatDuration);
        newPositionRel=(1.0-restInBeat/cycle.duration)*beatCount/newBeatCount;
        //Ещё варианты:
        // Варианты:
        // 1. ставит в первую долю с сохранением поддоли:
        // newPositionRel = (cycle.durationBeforePosition() % beatDuration)/cycle.duration;
        // 2. 0 - плохо, основной темп собьётся
        // 3. остаток по модулю дины нового цикла;
        // 4.??
      }
      else {//Позиция (бит, подбит) не должна поменяться
        newPositionRel = cycle.relativeDurationBeforePosition()*beatCount/newBeatCount; }
    }


    cycle = newCycle;
    beatCount=newBeatCount;
    tempo=setTempo((int)tempo);
    //ToDo: ПЕРЕДЕЛАТЬ setTempo,  зачем я сделал эту глупость с int?

    int newPos =(int)(newPositionRel*cycle.duration);
    cycle.readTempoLinear(newPos);//ToDo: вешаем чайник; проматываем отыгранную длительность

    //ToDo: IS: VS, should we remove (in release)  all this stuff like printAcc1 etc? Seems to create memory leak!
    //System.out.printf("AccentedMelody %d %d \n", nOfBeats, totalSubBeats);

  }




  public double getMaxTempo()
  {
    return cycle.getMaximalTempo(_sampleRate, beatCount);
  }

  /**
   *
   * @param beatsPerMinute что хотим
   * @return что получилось
   */
  public int setTempo(int beatsPerMinute) //ToDo: нелогично, что это int.
  {
    int BPMtoSet = Math.min(
            (int) cycle.getMaximalTempo(_sampleRate,beatCount),
             beatsPerMinute
    );
    //Utility utility = new Utility();
    //System.out.printAcc1("BPMtoSet ");
    //System.out.println(BPMtoSet);
    cycle.setNewDuration(
            Utility.beatsDurationInSamples(_sampleRate,beatCount,
                    BPMtoSet));

    tempo=BPMtoSet;
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
  final static double beatsDurationInSamples(int nativeSampleRate, int nOfBeats, int BPM)
  { //ToDo: нелогично, что BPM - это int. Кажется, это не зачем ни нужно, просто я глупость
    // впопыхах написал

    //VG Note value (denominator) changes actual beat tempo
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
   * @param t музыкальный темп
   * @return какова должна быть длительность цикла при данном tempoTmpTmpTmp.
   */
// in seconds //IS: IN SAMPLES
  final static private double tempoToCycleDurationObsolete(Tempo t, int bars, int nativeSampleRate)
  {
    //VG Note value (denominator) changes actual beat tempoTmpTmpTmp
    int totalBeatsPerCycle = bars * t.denominator;
    double samplesPerBeat = nativeSampleRate * 60.0 / t.beatsPerMinute;

    return samplesPerBeat * totalBeatsPerCycle;
  }
}
