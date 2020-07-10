package com.owlenome.owlenome;



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

  /*
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
   * /
// in seconds //IS: IN SAMPLES
  final static private double tempoToCycleDurationObsolete(Tempo t, int bars, int nativeSampleRate)
  {
    //VG Note value (denominator) changes actual beat tempoTmpTmpTmp
    int totalBeatsPerCycle = bars * t.denominator;
    double samplesPerBeat = nativeSampleRate * 60.0 / t.beatsPerMinute;

    return samplesPerBeat * totalBeatsPerCycle;
  }*/
}


/**
 * Синтез звуков для PCM16.
 * //TODO Make static what is possible
 */
public class MelodyToolsPCM16
{
  int nativeSampleRate;

  public MelodyToolsPCM16(int nativeSampleRate)
  {
    this.nativeSampleRate = nativeSampleRate;
  }

  /**
   * Возвращает байтовый массив для проигрывания в форматие 16bitPCM
   * нужно числа сэмплов данной частоты. Звук сглаживается с помощью
   * fadeInOutPoly.
   *
   * @param freq            высота звука
   * @param lengthInSamples сколько сэмплов данной частоты нужно
   * @param degIn           степерь сглаживания начала звука
   * @param degOut          степерь сглаживания конца звука
   * @return
   */
  public byte[] getFreq(double freq, int lengthInSamples, int degIn, int degOut)
  {
    return doubleTo16BitPCM(fadeInOutPoly(sinusoid(lengthInSamples, freq), degIn, degOut));
  }

  /**
   * Затихаем с функцией 1-x^deg на [0,1] ([0,1] масштабированно по длине отрезка length-1).
   *
   * @param samples сэмплы, которые тушим
   * @param deg     степень затухания
   * @return Новые сэмплы
   */
  static double[] fadePoly(double[] samples, int deg)
  {
    double[] res = new double[samples.length];
    if (res.length <= 1) return res;
    for (int i = 0; i < res.length; i++)
    {
      double k1 = (double) i / (res.length - 1);
      double k2 = Math.pow(k1, deg);
      res[i] = samples[i] * (1 - k2);
    }
    return res;
  }

  /**
   * Возникаем и затихаем с функцией (2*x)^deg1 на
   * первой половин отрезка, и затухаем со скоростью, соответствующей deg2 на второй.
   * Нужно, чтобы не было щелчков. Хорошо звучат параметры 2 и 2.
   *
   * @param samples сэмплы, которые тушим
   * @param degIn   степень возникания
   * @param degOut  степень затухания
   * @return Новые сэмплы
   */
  static double[] fadeInOutPoly(double[] samples, double degIn, double degOut)
  {
    double[] res = new double[samples.length];
    if (res.length <= 1) return res;
    double center = (double) (res.length - 1) / 2;
    double k1, k2;
    for (int i = 0; i < res.length; i++)
    {
      if (i < center)
      { //усиляем громкость
        k1 = (center - i) / center;
        k2 = Math.pow(k1, degIn);
      }
      else
      {
        k1 = ((double) i - center) / center;
        k2 = Math.pow(k1, degOut);
      }
      res[i] = samples[i] * (1.0 - k2);
    }
    return res;
  }

  /**
   * Синусоида данной длины и частоты.
   */
  double[] sinusoid(int lengthInSamples, double frequency)
  {
    double[] samples = new double[lengthInSamples];
    for (int i = 0; i < lengthInSamples; i++)
      samples[i] = Math.sin(2 * Math.PI * frequency * i / nativeSampleRate);
    return samples;
  }

  /**
   * Массив нулевых байт двойной длины (видимо, можно сделать более быстрым образом)
   */
  static byte[] getSilence(int samplesN)
  {
    int resLength = 2 * samplesN;
    byte[] res = new byte[resLength];
    for (int i = 0; i < resLength; i++)
      res[i] = 0;
    return res;
  }

  /**
   * Переводим double сэмплы в массив байт. Значения double должны быть в отрезке [-1,+1]
   *
   * @param samples сэмплы в формате double
   * @return массив байт для проигрывания в формате 16bitPCM
   */
  static byte[] doubleTo16BitPCM(double[] samples)
  {
    ///Код из примера  https://masterex.github.io/archive/2012/05/28/android-audio-synthesis.html
    byte[] generatedSound = new byte[2 * samples.length];
    int index = 0;
    for (double sample : samples)
    {
      // scale to maximum amplitude
      short maxSample = (short) ((sample * Short.MAX_VALUE));
      // in 16 bit wav PCM, first byte is the low order byte
      generatedSound[index++] = (byte) (maxSample & 0x00ff);
      generatedSound[index++] = (byte) ((maxSample & 0xff00) >>> 8);
    }
    return generatedSound;
  }


  /**
   * обратная к doubleTo16BitPCM
   *(Почти обратная - тут нормализуем по 2^15, а в
   * doubleTo16BitPCM растягиваем по 2^15-1)
   *
   */
  static double[] doubleFrom16BitPCM(byte[] samples)
  {
    double[] samplesDouble=new double[samples.length/2];
    for (int i=0;i<samplesDouble.length;i++){ //ToDo: DC!!
      int sample= (samples[2*i+1]<<8)|(0xFF&samples[2*i]);//Вроде так правильно!
      samplesDouble[i]= 1.0/(Short.MAX_VALUE+1)*sample;
    }
    return samplesDouble;
  }


  /**
   * Изменяем громкость
   * @param samples сэмплы в байтах, массив четной длины
   * @param vol in [0,1]
   * @return
   */
  public static byte[] changeVolume(byte[] samples, double vol) {
    if (vol==1) return samples;
    int nOfSamples=samples.length/2;
    byte[] newSamplesByte=new byte[nOfSamples*2];
    //ToDo: Вся эта бадяга ниже  кажется просто чушь. - Почему нельзя просто поэлементно умножить?
    // Второй-то байт беззнаковый!
    for (int i=0; i<samples.length/2; i++){
      //ToDo: протестить типы и битовую арифметику. DC!!!!

      //short newSample= (short) (vol* (samples[2*i+1]<<8)+vol*samples[2*i]); -- WRONG!
      //Последний байт (второй, то есть первый, но меньший, ну понятно) -
      //Он же со знаком, а PCM его воспринимает без знака. Куда их было их складывать?!
      //
      //Эта херня выше создавала забавное звучание на сильной доле drums1 (drum_accent_mono)
      // - пиужжжжж, чистый бластер, которым убили манерного робота Вертера.

      short newSample= (short) (vol*
              ( (samples[2*i+1]<<8)|(0xFF&samples[2*i])  )
      );

      newSamplesByte[2 * i] = (byte) (newSample & 0x00ff);
      newSamplesByte[2 * i + 1] = (byte)((newSample & 0xff00) >>> 8);
    }
    return newSamplesByte;
  }


    //К первому сэмплу примиксовываем второй
    public static void mixTMPPROBAPERA(byte[] samples1, byte[] samples2){
      int lngsShort=Math.min(samples1.length,samples2.length)/2;
      for(int i=0;i<lngsShort;i++){
          int newSample1=  (samples1[2*i+1]<<8)|(0xFF&samples1[2*i]);
          int newSample2=  (samples2[2*i+1]<<8)|(0xFF&samples2[2*i]);
          int newSample=(newSample1+newSample2)/2;
          samples1[2 * i] = (byte) (newSample & 0x00ff);
          samples1[2 * i + 1] = (byte)((newSample & 0xff00) >>> 8);
      }
    }

    /**
     * !!!Только по рецепту!!!
     *
     * Сумма двух звуков. К первому сэмплу примиксовываем второй
     * !!! БЕЗ !!!
     * деления пополам
     *
     * UNTESTED.
     *
     **/
  public static void mixNOTNormalized(byte[] samples1, byte[] samples2){
    int lngsShort=Math.min(samples1.length,samples2.length)/2;
    for(int i=0;i<lngsShort;i++){
      int newSample1=  (samples1[2*i+1]<<8)|(0xFF&samples1[2*i]);
      int newSample2=  (samples2[2*i+1]<<8)|(0xFF&samples2[2*i]);
      int newSample=(newSample1+newSample2);//!!!!! //TODO: УБРАТЬ /2
      samples1[2 * i] = (byte) (newSample & 0x00ff);
      samples1[2 * i + 1] = (byte)((newSample & 0xff00) >>> 8);
    }
  }



  public static int mixNormalized(byte[] samples1, byte[] samples2, int previousSample,
                                  long stepsPer2, boolean bConnect ){
    int res=0;
    int lngsShort=Math.min(samples1.length,samples2.length)/2;
    for(int i=0;i<samples1.length/2;i++){
      int newSample1=  (samples1[2*i+1]<<8)|(0xFF&samples1[2*i]);
      int newSample2=0;
      if (i<lngsShort){       newSample2=  (samples2[2*i+1]<<8)|(0xFF&samples2[2*i]);}
      int newSample=(newSample1+newSample2)/2;
      samples1[2 * i] = (byte) (newSample & 0x00ff);
      samples1[2 * i + 1] = (byte)((newSample & 0xff00) >>> 8);
      res=newSample;
    }

    //Пробуем срастить начало с initValueApprox. Experiment; НЕ РАБОТАЕТ - щелкает
    /*
    if (!bConnect) return  res;
    int initSample=(samples1[1]<<8)|(0xFF&samples1[0]);
    long delta=previousSample-initSample;
    double doubleDelta=0.5/(Short.MAX_VALUE+1)*Math.abs(delta);
    long n=Math.min(samples1.length/2, (int)(stepsPer2*doubleDelta));
    for (int i=0; i<n; i++)
    {
      int oldSample=  (samples1[2*i+1]<<8)|(0xFF&samples1[2*i]);
      int newSample = (int)(oldSample + (delta*(n-i)/(n+1)));
      samples1[2 * i] = (byte) (newSample & 0x00ff);
      samples1[2 * i + 1] = (byte)((newSample & 0xff00) >>> 8);
    }*/
    return res;
  }



  /**
   *     Проверка микса без биттовой арифметики. Не использовать в мирных целях. Tested.
   */
  public static void mixNormalizedViaDoubleTEST(byte[] samples1, byte[] samples2) {

    double[] longSndD=MelodyToolsPCM16.doubleFrom16BitPCM(samples1);// Чтобы по битам не разбирать
    double[] shortSndD=MelodyToolsPCM16.doubleFrom16BitPCM(samples2);//
    double[] resD=new double[longSndD.length];
    for(int i=0; i<longSndD.length; i++){
      double d=(i<shortSndD.length)?shortSndD[i]:0;
      resD[i]=(d+longSndD[i])*0.5;
    }
    byte[] resB=MelodyToolsPCM16.doubleTo16BitPCM(resD);
    for(int i=0;i<resB.length;i++){
      samples1[i]=resB[i];    }
  }

  /**
   *  Область миксования.
   *
   * https://stackoverflow.com/questions/376036/algorithm-to-mix-sound
   * https://dsp.stackexchange.com/questions/3581/algorithms-to-mix-audio-signals-without-clipping
   *
   *
   * Check: где-то мелькал принцип миксования  для аудасити //ToDo
   * https://www.audacityteam.org/community/developers/#git
   *
   * Так не делать, это объяснили во многих местах:
   * WRONG
   * http://atastypixel.com/blog/how-to-mix-audio-samples-properly-on-ios/comment-page-1/#comment-6310
   * http://www.vttoth.com/CMS/index.php/technical-notes/68
   *
   */

  public interface NormOperator {
    double operator(double d1, double d2);
  }

  public static class HalfSum implements  NormOperator {
    public double operator(double d1, double d2){
     return (d1+d2)*0.5;}
  };

  public static class NormHyperbolicTangent implements  NormOperator {
    public double operator(double d1, double d2){
      return Math.tanh(d1+d2);}
  };
//ToDo: Нужен микс, при котором простое сложение до определенного уровня,  а если
// приближаемся к границе, то тогда нормализуем через tanh

//ToDo:   Гиперболический тангенс используется в миксовании. Однако
// не является ли этот выбор произвольным - просто удобная функция R->(-1,1).

//Что такое функция миксования?
//f - непрерывная R->(-1,1),
//Близка к x=y 'внутри' [-1,1], чтобы не терять в громкости. Что за нутрь - непонятно.
// дифференцируемая (?)


  public static class NormHyperbolicTangentAmp implements  NormOperator {
    //у гиперболического тангенса побольше?
    //10 - искажение.
    //0.01 - тишина
    public double operator(double d1, double d2){
      ///Если мы сделаем угол наклона в 0
      double amplifier = 2;
      return Math.tanh(amplifier *(d1+d2));}
  };



  public static class NormExperiment implements  NormOperator {
    //public double amplifier= 2*1.5;
    //public double strongWeight= 0.7;
    //10 - искажение. Кажется, 2 уже искажение? (какие-то барабаны. надо слушать
    //на железе)
    //0.01 - тишина
    public double operator(double d1, double d2){
      double attenuator=0.7;//Ослабляем слабый звук.
      ///Общее усиление:
      double amplifier = 2.0/(attenuator+1); ///1.0/(attenuator+0.5) - это 'как бы' без искажений, сумма - до двух
      //При маленьком attenuator, amplifier даст плохой эффект: акценты перестанут различаться между собой
      return Math.tanh((d1+(d2*attenuator)));}
  };

  /**
   *     Микс разными способами. Даблы, интерфейсы какие-то...
   *     Сколько будет жрать ресурсов - никто не знает. (J1: 5-7 % Moto: не видать)
   *     Не использовать в мирных целях.
   */
  public static void mixViaDoubleNormOperator(byte[] samples1, byte[] samples2,
                                              NormOperator norm
                                      ) {

    double[] longSndD=MelodyToolsPCM16.doubleFrom16BitPCM(samples1);// Чтобы по битам не разбирать
    double[] shortSndD=MelodyToolsPCM16.doubleFrom16BitPCM(samples2);//
    double[] resD=new double[longSndD.length];
    for(int i=0; i<longSndD.length; i++){
      double d=(i<shortSndD.length)?shortSndD[i]:0;

      resD[i]=norm.operator(longSndD[i],d);

    }
    byte[] resB=MelodyToolsPCM16.doubleTo16BitPCM(resD);
    for(int i=0;i<resB.length;i++){
      samples1[i]=resB[i];    }
  }



    //Проще генерировать ноты по полутонам, или по октавам и именам...
  //http://pages.mtu.edu/~suits/notefreqs.html
  public byte[] noteA4(int samplesN, int degIn, int degOut)
  {
    return getFreq(440, samplesN, degIn, degOut);
  }

  public byte[] noteB4(int samplesN, int degIn, int degOut)
  {
    return getFreq(987.77 / 2.0, samplesN, degIn, degOut);
  }

  public byte[] noteC5(int samplesN, int degIn, int degOut)
  {
    return getFreq(523.25, samplesN, degIn, degOut);
  }

  public byte[] noteD5(int samplesN, int degIn, int degOut)
  {
    return getFreq(587.33, samplesN, degIn, degOut);
  }

  public byte[] noteE5(int samplesN, int degIn, int degOut)
  {
    return getFreq(659.25, samplesN, degIn, degOut);
  }

  public byte[] noteF5(int samplesN, int degIn, int degOut)
  {
    return getFreq(698.46, samplesN, degIn, degOut);
  }

  public byte[] noteG5(int samplesN, int degIn, int degOut)
  {
    return getFreq(783.99, samplesN, degIn, degOut);
  }

  public byte[] noteA5(int samplesN, int degIn, int degOut)
  {
    return getFreq(880.00, samplesN, degIn, degOut);
  }

  public byte[] noteB5(int samplesN, int degIn, int degOut)
  {
    return getFreq(987.77, samplesN, degIn, degOut);
  }

  public byte[] noteC6(int samplesN, int degIn, int degOut)
  {
    return getFreq(523.25 * 2, samplesN, degIn, degOut);
  }

  public byte[] noteB6(int samplesN, int degIn, int degOut)
  {
    return getFreq(987.77 * 2, samplesN, degIn, degOut);
  }

  public byte[] noteD6(int samplesN, int degIn, int degOut)
  {
    return getFreq(587.33 * 2, samplesN, degIn, degOut);
  }

  public byte[] noteE6(int samplesN, int degIn, int degOut)
  {
    return getFreq(659.25 * 2, samplesN, degIn, degOut);
  }

    /*noteA4 =melodyTools.noteA4(buffsPerBip*nativeBufferInFrames,2,2);
    // Щелкает:
    // noteC5 = melodyTools.noteC5(buffsPerBip*nativeBufferInFrames,1,7);
    //проверять ноты на паузах между ними
    noteC5 = melodyTools.noteC5(buffsPerBip*nativeBufferInFrames,2,2);
    noteE5= melodyTools.noteE5(buffsPerBip*nativeBufferInFrames,2,2);
    noteF5= melodyTools.noteF5(buffsPerBip*nativeBufferInFrames,2,2);
    noteG5= melodyTools.noteG5(buffsPerBip*nativeBufferInFrames,2,2);
    noteA5= melodyTools.noteA5(buffsPerBip*nativeBufferInFrames,2,2);
    noteB5= melodyTools.noteB5(buffsPerBip*nativeBufferInFrames,2,2);
    noteC6 = melodyTools.noteC6(buffsPerBip*nativeBufferInFrames,2,2);
    noteD6 = melodyTools.noteD6(buffsPerBip*nativeBufferInFrames,2,2);
    noteD5 = melodyTools.noteD5(buffsPerBip*nativeBufferInFrames,2,2);
    noteC6tuk = melodyTools.noteC6(buffsPerBip*nativeBufferInFrames,3,5);
    bip=noteA4;
    shortSilenceBytes =melodyTools.getSilence(nativeBufferInFrames);
    melodyOld = new byte[][] {noteC5, noteE5, noteG5,
    noteF5,noteA5,noteC6,
    noteG5, noteB5,noteD6,
    noteC6,noteC6tuk,shortSilenceBytes,
    noteC5, noteE5, noteG5,
    noteF5,noteA5,noteC6,
    noteG5, noteB5,noteD6,
    noteC6tuk,shortSilenceBytes,shortSilenceBytes
    };*/
}
