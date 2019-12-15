package com.owlenome.owlenome;

import android.content.res.Resources;

import java.util.List;


class MusicScheme2sounds {
  byte[] weakBeat;
  byte[] strongBeat;




  //Из частот и длительностей. ДОЛГАЯ! Линейна по длительности звуков, с большими коэффициентами (даблы, синусы, жуть)
  MusicScheme2sounds(int nativeSampleRate,
                     /// Frequency (Hz) and duration (millisec) of beat
                     double beatFreq, int beatDuration,
                     /// Frequency (Hz) and duration (millisec) of accent (strong) beat
                     double accentFreq, int accentDuration){

    MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

    int lengthWeak=(int)Utility.nanoSec2samples(nativeSampleRate,beatDuration*1000000);
    int lengthStrong=(int)Utility.nanoSec2samples(nativeSampleRate,accentDuration*1000000);

    // Half notes
    //440, 523.25
    weakBeat = melodyTools.getFreq(beatFreq, lengthWeak, 2, 2);
    strongBeat = melodyTools.getFreq(accentFreq, lengthStrong, 2, 2);
  }


  //Из ресурсов. ДОЛГАЯ! Линейна по длительности звуков, с большими коэффициентами (даблы, чтение из файлов, жуть)
  MusicScheme2sounds(Resources res, int resIDWeakWav, int resIDStrongWav, int nativeSampleRate){
    weakBeat= WavResources.getSoundFromResID(res,resIDWeakWav,nativeSampleRate);
    strongBeat= WavResources.getSoundFromResID(res,resIDStrongWav,nativeSampleRate);
   //todo
  }

  //Из двух готовых звуков - может, это самое прекрасное, что можно придумать? Быстрая:)
  MusicScheme2sounds(byte[] weakBeat,
                     byte[] strongBeat){
    this.strongBeat=strongBeat; this.weakBeat=weakBeat;
  }


}


//Вместо AccentBeat (я не стал его пока удалять, но потом
//нужно будет заменить все ссылки на AccentBeat на ссылки на этот класс)
class AccentedMelody extends Melody{



    public AccentedMelody(int nativeSampleRate, int quortaInMSec,
                       MusicScheme2sounds musScheme,
                      // Number of beats
                      int beats,
                      // Number of subbeats in each i-th beat
                      int[] subBeats,

                       // Index of accented beat
                    int accent  //ToDo:  вычислять по числу долей
    )
    {
      //beatDuration == quortaInMSec;//IS: Why?
      super(nativeSampleRate, quortaInMSec, 1, 1);

      MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);


      //IS: Why do we need to know this? -
      int maxSubBeatCount = 1;
      int bipCount = 0;  // beats * subBeatCount
      for (int i = 0; i < subBeats.length; i++)
      {
        bipCount += subBeats[i];
        if (subBeats[i] > maxSubBeatCount)
          maxSubBeatCount = subBeats[i];
      }

      //super.init(notes, pauses);
      //cycle.printFinal();


      // Bip alphabet
      // #0 - pause
      // 1,2,4,8,... - symbols for strong
      // 3, 3*2, 3*4,... - symbols for weak

      melody = new byte[][]{musScheme.weakBeat, musScheme.strongBeat};
      int[] symbols = new int[bipCount];
      int elasticSymbol = 0;

      /* UNDER CONSTRUCTION

      double pauseFactor = beats * 256.0;  // Годится любое неотрицательное значение.
      //Важно: 256 - это значит, что нам хватит паузы, если мы будем играть

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
          bipAndPause[k] = new BipAndPause(melody[iNote].length / 2, //pauseFactor);
                  pauseFactor / subBeats.get(i));
        }

      cycle = new BipPauseCycle(symbols, elasticSymbol, bipAndPause, numerator);



      //System.out.printf("AccentBeat %d %d %d %d %d %d\n", beats, bipCount, bars, numerator, accent, beatDuration);
      _bipAndPauseSing = bipAndPause;

       */
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


// Accented beat melody for metronome
// VG: Currently made ugly
class AccentBeat extends Melody
{
  public AccentBeat(int nativeSampleRate,
                    // Number of beats
                    int beats,
                    // Index of accented beat
                    int accent,
                    /// Frequency (milliHz) and duration (millisec) of regular (weak) beat
                    //IS: Why milli? It seems that you use HZ (e.g. 440)
                    double beatFreq, int beatDuration,
                    /// Frequency (milliHz) and duration (millisec) of accent (strong) beat
                    double accentFreq, int accentDuration,
                    // Number of subbeats in each i-th beat
                    List<Integer> subBeats,
                    Resources res,
                    int[][] schemeFilesIndexes,
                    int indexOfScheme
                    )
  {
    //beatDuration == quortaInMSec;//IS: Why? Anyway, я эту свою муть выкинул отовсюду по возможности.
    super(nativeSampleRate, beatDuration, 1, 1);

    //MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);



    MusicScheme2sounds scheme = new MusicScheme2sounds(nativeSampleRate, beatFreq, beatDuration,  accentFreq, accentDuration);
    byte[] weakBeat =scheme.weakBeat;
    byte[] strongBeat=scheme.strongBeat;

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


    if (indexOfScheme==-1) {
      //IS:
      // Bip alphabet
      // #0 - regular bip
      // #1 - accent bip
      // #2 - pause
      melody = new byte[][]{weakBeat, strongBeat};
    }
    else {
      MusicScheme2sounds Scheme = new MusicScheme2sounds(res,
              schemeFilesIndexes[indexOfScheme][0], schemeFilesIndexes[indexOfScheme][1], nativeSampleRate);
      melody = new byte[][]{Scheme.weakBeat, Scheme.strongBeat};
    }

    int[] symbols = new int[bipCount];
    int elasticSymbol = 2;

    //ToDo:DoubleCheck! должно хватить.
    double totalLengthOfBeat=(weakBeat.length+strongBeat.length+1)*maxSubBeatCount;


    BipAndPause[] bipsAndPauses = new BipAndPause[bipCount];
    int k = 0;
    for (int i = 0; i < beats; i++)
      for (int j = 0; j < subBeats.get(i); j++, k++)
      {
        int iNote = (i == accent && j == 0) ? 1 : 0;
        symbols[k] = iNote;
        bipsAndPauses[k] = new BipAndPause(
                melody[iNote].length/2,
                (totalLengthOfBeat / (subBeats.get(i)*melody[iNote].length/2))-1
               );
      }

    cycle = new BipPauseCycle(symbols, elasticSymbol, bipsAndPauses, 1);

      //ToDo: IS: Should we remove all this stuff like print etc? Seems to create memory leak!
    System.out.printf("AccentBeat %d %d %d %d %d %d\n", beats, bipCount, 1, 1, accent, beatDuration);
    _bipAndPauseSing = bipsAndPauses;
/*
//IS: Это не нужно для метронома/без визуализации?
IS отвечает: Надо забыть комментарий ниже (у нас нет сейчас пауз в мелодии, и они не нужны). Но важно понять, как выглядит прямая речь, а то я путаюсь в комментах и тебя путаю:)
IS: Вить, это ты спрашиваешь или я?  "IS:" - это мне или я?  Юрик, может это ты?
    // Даём паузам в мелодии значение тишины - это нужно для рисования, чтобы
    // лучше видеть разницу аудио и видео
    for (int i = 0; i < bipCount; i++)
    {
      cycle.cycle[2 * i + 1].a = cycle.elasticSymbol;
    }
 */
  }


  public void reSetSubBeat(int subBeatIndex, int newSubBeatNumber){
    //TODO
    /**
     * Процедура создания мелодии (в части создания байтовых массивов под данную частоту) жирновата. Поэтому нужно будет
     * (в дальнейшем) написать эту простую процедуру.
     */
  }
}
