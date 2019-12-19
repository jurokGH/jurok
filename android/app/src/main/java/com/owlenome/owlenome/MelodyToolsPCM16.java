package com.owlenome.owlenome;

/**
 * Синтез звуков для PCM16.
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
    return get16BitPcm(fadeInOutPoly(sinusoid(lengthInSamples, freq), degIn, degOut));
  }

  /**
   * Затихаем с функцией 1-x^deg на [0,1] ([0,1] масштабированно по длине отрезка length-1).
   *
   * @param samples сэмплы, которые тушим
   * @param deg     степень затухания
   * @return Новые сэмплы
   */
  double[] fadePoly(double[] samples, int deg)
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
  double[] fadeInOutPoly(double[] samples, double degIn, double degOut)
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
  byte[] getSilence(int samplesN)
  {
    int resLength = 2 * samplesN;
    byte[] res = new byte[resLength];
    for (int i = 0; i < resLength; i++)
      res[i] = 0;
    return res;
  }

  /**
   * Переводим double сэмплы в массив байт
   *
   * @param samples сэмплы в формате double
   * @return массив байт для проигрывания в формате 16bitPCM
   */
  byte[] get16BitPcm(double[] samples)
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
   * Изменяем громкость
   * @param samples сэмплы в байтах, массив четной длины
   * @param vol in [0,1]
   * @return
   */
  public static byte[] changeVolume(byte[] samples, double vol) {
    if (vol==1) return samples;
    int nOfSamples=samples.length/2;
    byte[] newSamplesByte=new byte[nOfSamples*2];
    //Бадяга дальше нужна, поскольку из-за огруглений нет дистибутивности:
    //если просто поэлементно умножим массив - будет много погрешностей
    for (int i=0; i<samples.length/2; i++){
      //ToDo: протестить типы и битовую арифметику.
      short newSample= (short) (vol* (samples[2*i+1]<<8)+vol*samples[2*i]);
      newSamplesByte[2 * i] = (byte) (newSample & 0x00ff);
      newSamplesByte[2 * i + 1] = (byte)((newSample & 0xff00) >>> 8);
    }
    return newSamplesByte;
  }



  //ToDo: генерировать ноты по полутонам, или по октавам и именам
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
