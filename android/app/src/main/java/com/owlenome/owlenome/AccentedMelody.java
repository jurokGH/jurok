package com.owlenome.owlenome;

import java.util.List;


// Accented beat setOfNotes for metronome
class AccentedMelody //extends Melody
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
    //beatDuration == quortaInMSec;//IS: Why? Anyway, я эту свою муть выкинул отовсюду по возможности.
   // super(nativeSampleRate, beatDuration, 1, 1);

    //MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);




    /* obsolete
    // Half notes
    //440, 523.25
    byte[] note2 = melodyTools.getFreq(beatFreq, framesInQuorta * 2, 2, 2);
    byte[] accentNote = melodyTools.getFreq(accentFreq, framesInQuorta * 2, 2, 2);
     */


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

    //super.init(notes, pauses);
    //cycle.printFinal();

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
