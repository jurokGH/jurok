import 'dart:math';
import 'dart:typed_data';

// Синтез звуков для PCM16

class SoundPCM16
{
  static const int _ShortMaxValue = 65535;
  int nativeFreq;

  SoundPCM16(this.nativeFreq);

  // Возвращает байтовый массив для проигрывания в форматие 16bitPCM
  // нужно числа сэмплов данной частоты. Звук сглаживается с помощью
  // fadeInOutPoly.
  // @param freq высота звука
  // @param lengthInSamples сколько сэмплов данной частоты нужно
  // @param degIn степерь сглаживания начала звука
  // @param degOut степерь сглаживания конца звука
  // @return

  Uint8List getFreq(double freq, int lengthInSamples, int degIn, int degOut)
  {
    return get16BitPcm(fadeInOutPoly(sinusoid(lengthInSamples, freq), degIn.toDouble(), degOut.toDouble()));
  }
  
  // Затихаем с функцией 1-x^deg на [0,1] ([0,1] масштабированно по длине отрезка length-1).
  // @param samples сэмплы, которые тушим
  // @param deg степень затухания
  // @return Новые сэмплы
  List<double> fadePoly(List<double> samples, int deg)
  {
    return new List<double>.generate(samples.length,
        (int i) => samples[i] * (1.0 - pow(i / (samples.length - 1.0), deg)));

    List<double> res = new List<double>(samples.length);
    if (res.length <= 1)
      return res;
    for (int i = 0; i < res.length; i++)
    {
      double k1= i / (res.length - 1);
      double k2 = pow(k1, deg);
      res[i] = samples[i] * (1.0 - k2);
    }
    return res;
  }

  // Возникаем и затихаем с функцией (2*x)^deg1 на
  // первой половин отрезка, и затухаем со скоростью, соответствующей deg2 на второй.
  // Нужно, чтобы не было щелчков. Хорошо звучат параметры 2 и 2.
  // @param samples сэмплы, которые тушим
  // @param degIn степень возникания
  // @param degOut степень затухания
  // @return Новые сэмплы
  List<double> fadeInOutPoly(List<double> samples, double degIn, double degOut)
  {
    double center = (samples.length - 1.0) / 2.0;
    int mid = center.toInt();
    //int mid = (samples.length - 1) ~/ 2;
    return new List<double>.generate(samples.length,
      (int i) => samples[i] * (1.0 -
        pow((i <= mid ? center - i : i - center) / center,
          i <= mid ? degIn : degOut)));

    List<double> res = new List<double>(samples.length);
    if (res.length <= 1)
      return  res;
    double k1, k2;
    for (int i = 0; i < res.length; i++)
    {
      if (i < center)
      {
        //усиляем громкость
        k1 = (center - i) / center;
        k2 = pow(k1, degIn);
      }
      else
      {
        k1 = (i - center) / center;
        k2 = pow(k1, degOut);
      }
      res[i] = samples[i] * (1.0 - k2);
    }
    return res;
  }

  // Синусоида данной длины и частоты
  List<double> sinusoid(int lengthInSamples, double frequency)
  {
    frequency *= 2 * pi;  // TODO nativeFreq
    return new List<double>.generate(lengthInSamples, (int i) => sin(frequency * i / nativeFreq));

    List<double> samples = new List<double>(lengthInSamples);
    for (int i = 0; i < lengthInSamples; i++)
      samples[i] = sin(2 * pi * frequency * i / nativeFreq);
    return samples;
  }

  // Массив нулевых байт двойной длины (видимо, можно сделать более быстрым образом)
  Uint8List silence(int samplesN)
  {
    return Uint8List(2 * samplesN);  // 0-initialized

    int resLength = 2 * samplesN;
    Uint8List res = new Uint8List(resLength);
    for (int i = 0; i < resLength; i++)
      res[i] = 0;
    return res;
  }

  // Переводим double сэмплы в массив байт
  // @param samples   сэмплы в формате double
  // @return массив байт для проигрывания в формате 16bitPCM
  Uint8List get16BitPcm(List<double> samples)
  {
    // Код из примера  https://masterex.github.io/archive/2012/05/28/android-audio-synthesis.html
    Uint8List generatedSound = new Uint8List(2 * samples.length);
    int index = 0;
    for (double sample in samples)
    {
      // scale to maximum amplitude
      int maxSample = (sample * _ShortMaxValue).toInt();
      // in 16 bit wav PCM, first byte is the low order byte
      generatedSound[index++] = maxSample & 0x00ff;
      generatedSound[index++] = (maxSample & 0xff00) >> 8;
    }
    return generatedSound;
  }

  // ToDo: генерировать ноты по полутонам, или по октавам и именам
  // http://pages.mtu.edu/~suits/notefreqs.html
  Uint8List noteA4(int samplesN, int degIn, int degOut){
    return getFreq(440.00, samplesN, degIn, degOut);
  }
  Uint8List noteB4(int samplesN, int degIn,int degOut){
    return getFreq(987.77 / 2.0, samplesN, degIn, degOut);
  }
  Uint8List noteC5(int samplesN, int degIn,int degOut){
    return getFreq(523.25, samplesN, degIn, degOut);
  }
  Uint8List noteD5(int samplesN, int degIn,int degOut){
    return getFreq(587.33, samplesN, degIn, degOut);
  }
  Uint8List noteE5(int samplesN, int degIn,int degOut){
    return getFreq(659.25, samplesN, degIn, degOut);
  }
  Uint8List noteF5(int samplesN, int degIn,int degOut){
    return getFreq(698.46, samplesN, degIn, degOut);
  }
  Uint8List noteG5(int samplesN, int degIn,int degOut){
    return getFreq(783.99, samplesN, degIn, degOut);
  }
  Uint8List noteA5(int samplesN, int degIn,int degOut){
    return getFreq(880.00, samplesN, degIn, degOut);
  }
  Uint8List noteB5(int samplesN, int degIn,int degOut){
    return getFreq(987.77, samplesN, degIn, degOut);
  }
  Uint8List noteC6(int samplesN, int degIn,int degOut){
    return getFreq(523.25 * 2, samplesN, degIn, degOut);
  }
  Uint8List noteB6(int samplesN, int degIn,int degOut){
    return getFreq(987.77 * 2, samplesN, degIn, degOut);
  }
  Uint8List noteD6(int samplesN, int degIn,int degOut){
    return getFreq(587.33 * 2, samplesN, degIn, degOut);
  }
  Uint8List noteE6(int samplesN, int degIn,int degOut){
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
  shortSilenceBytes =melodyTools.silence(nativeBufferInFrames);
  melodyOld = new Uint8List[] {noteC5, noteE5, noteG5,
    noteF5,noteA5,noteC6,
    noteG5, noteB5,noteD6,
    noteC6,noteC6tuk,shortSilenceBytes,
    noteC5, noteE5, noteG5,
    noteF5,noteA5,noteC6,
    noteG5, noteB5,noteD6,
    noteC6tuk,shortSilenceBytes,shortSilenceBytes
  };*/
}
