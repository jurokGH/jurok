/**
 * Законсервировано 29.04.19
 * <p>
 * Годно для теста разогрева аудио. Годно гонять по кругу мелодию.
 * <p>
 * Штампы стабилизируются на
 * на моём LG,  на эмуляторе с api25, аудио не разогревается на эмуляторе J1 (api 21)
 * <p>
 * В этой версии нет утечки, если убрать laterLog.
 * При этом если не убрать, то утечка будет большой даже если noMessages=true
 * (видимо, из-за строкового аргумента)
 **/
//ToDo: вместо пустого звука нужно просто смещаться внутри буфера, если его переочистить вначале
//ToDo: убрать щелчок при выключении (e.g., последняя порция,  скармливаемая в буфер, сворачивается с гладкой функцией

package com.owlenome.owlenome;

import android.media.AudioFormat;
import android.media.AudioManager;
import android.media.AudioTimestamp;
import android.media.AudioTrack;
import android.os.Build;
import android.os.Handler;
import android.os.Message;

import java.nio.ByteBuffer;

///ToDo:
///Уровень API >= 21 (возможно, 19, но не проверял).
///
///Время между бипами про 240 bpm;16-е доли - 1/16 секунды. Сюда должен поместиться бип и тишина

public class MetroAudioProbnik
{
  // Initial constants
  private final static int cTempoBpM = 60;
  private final static int cNnoteValue = 4;
  private final static int cMinTempoBpm = 4;//20;


  /**
   * Частота, с которой работает audioTrack.
   * Для эффективной работы этот параметр (переданый в конструктор при создании)
   * должен совпадать с железными данными звуковой карты. Их можно получить так:
   * <p>
   * AudioManager am = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
   * String sampleRateStr = am.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE);
   * nativeSampleRate = Integer.parseInt(sampleRateStr);
   * if (nativeSampleRate == 0) nativeSampleRate = 48000;
   */
  private final int nativeSampleRate;

  /**
   * Размер минимального буфера. Большой буфер audioTrack будет состоять
   * из четного числа таких буферов. Аналогично nativeSampleRate, этот параметр
   * должен быть получен исходя из железных данных звука. E.g.:
   * <p>
   * String framesPerBuffer = am.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER);
   * nativeBuffer = Integer.parseInt(framesPerBuffer);
   * if (nativeBuffer == 0) nativeBuffer = 960;
   */
  private final int nativeBufferInFrames;

  /**
   * Середина большого буфера.
   */
  private final int centerInFrames;


  /**
   * Звуковые переменные
   */
  private AudioTrack audioTrack;

  private float _minVolume;
  private float _maxVolume;
  private float _volume = 0.5f;
  //private final float initVolume=(float) 0.5;

  /**
   * Ноты, волны данной частоты
   */
  private MelodyToolsPCM16 melodyTools;

  /**
   *  Последовательность байт для тишины. ОДИН ЖЕЛЕЗНЫЙ БУФЕР!
   *  Пишется при разогреве.
   */
  //private final byte[] smallBufferOfSilence;

  /**
   * Половина большого буфера тишины.
   */
  //private final byte[] halfOfBigBufferOfSilence;

  /**
   * Сколько буферов нужно на половину большой шкалы
   */
  int buffsPerHalf;

  /**
   * Начало работы. Не означает время старта метронома. Отладочное.
   * in nanoseconds
   */
  long initTime;

  /**
   * Записанные в процессе разогрева samples
   */
  long totalWarmUpFrames;

  /**
   * Всего записано
   */
  long totalWrittenFrames;

  /**
   * Всего потеряно
   */
  long totalLostFrames;

  /**
   * Сколько мы хотим писать за один раз. Разумным представляется писать за раз половину большого
   * буфера.
   */
  //final int framesToWriteAtOnce;

  //ByteBuffer byteBuffer;
  MelodyBuffer melodyBuffer;

  AccentedMelody melody;
  //BipAndPause _bipAndPauseSing;
  boolean newMelody = false;

  //ToDo: TEST
  private boolean newTempo = false;
  private Tempo _tempo;

  boolean doPlay; //ToDo: логика состояния

  // Sound writer task
  MetroRunnable _task = null;

  public int setMelody(AccentedMelody m, Tempo tempo)
  {
    //TODO
    melody = m;

    if (tempo.beatsPerMinute < cMinTempoBpm)
      tempo.beatsPerMinute = cMinTempoBpm;
    _tempo = tempo;
    if (state == STATE_PLAYING)
      newMelody = true;

    return (int) melody.getMaxTempo(tempo);
  }

  int getTempo()
  {
    return _task == null ? _tempo.beatsPerMinute : _task.realBPM;
  }

  public int setTempo(Tempo tempo)
  {
    if (tempo.beatsPerMinute < cMinTempoBpm)
      tempo.beatsPerMinute = cMinTempoBpm;
    _tempo = tempo;
    if (state == STATE_PLAYING)
      newTempo = true;

    return melody != null ? (int) melody.getMaxTempo(tempo) : 0;
  }

  // volume = [0..100]
  public void setVolume(int volume)
  {
    assert (_maxVolume > _minVolume);
    float newVolume = _minVolume + 0.01f * volume * (_maxVolume - _minVolume);
    if (newVolume < _minVolume)
      newVolume = _minVolume;
    if (newVolume > _maxVolume)
      newVolume = _maxVolume;

    if (newVolume != _volume)
    {
      _volume = newVolume;
      if (audioTrack != null)
        audioTrack.setVolume(_volume);
    }
  }

  public boolean isPlaying()
  {
    return audioTrack != null &&
      (audioTrack.getPlayState() == AudioTrack.PLAYSTATE_PLAYING ||
        state != STATE_READY);
  }

  public int play(Tempo tempo)
  {
    boolean res = true;
    _tempo = tempo;

    setState(STATE_STARTING);
    doPlay = true;

    initTrack();

    //TODO Every time?
    _maxVolume = audioTrack.getMaxVolume();
    _minVolume = audioTrack.getMinVolume();
    audioTrack.setVolume(_volume);

    //ToDo: обмен данными между потоками. Нужно получать скорость, и выдавать
    //привязку ко времени.
    _task = new MetroRunnable(melodyBuffer);
    new Thread(_task).start();
    //ToDo: сделать булевым, и если false - значит, мы не запустились

    double maxTempo = melody.getMaxTempo(tempo);
    return res ? (int) (tempo.beatsPerMinute >= maxTempo ? maxTempo : tempo.beatsPerMinute) : 0;
  }

  public void stop()
  {
    if (state == STATE_PLAYING || state == STATE_STARTING)
      setState(STATE_STOPPING);
    doPlay = false;

    dPrintAll();
  }

  /**
   * Используется для проверки стабильности stamps: считаем, что звуковая система разогрелась, когда
   * частота, полученная из stamps, удовлетворяет условию audioIsStable
   */
  final static double SAMPLE_RATE_INTENDED_ACCURACY = 0.0025;  // 0.25% from nativeSampleRate

  /**
   * Проверяем, достигло ли отношение частоты, вычисленной во двум сэмплам,
   * должной близости с частотой audioTrack.
   * Скорее всего, стабилизации не произойдет, если nativeSampleRate
   * был определен неверно.
   */
  boolean audioIsStable(AudioTimestamp stampOld, AudioTimestamp stampNew)
  {
    long deltaFrames = stampNew.framePosition - stampOld.framePosition;
    long deltaTime = stampNew.nanoTime - stampOld.nanoTime;
    //System.out.printf("################## %d, %d\n", deltaFrames, deltaTime);
    if (deltaTime != 0)
    {
      double frameRateFromStamps = 1e9 * deltaFrames / deltaTime;
      double accuracy = Math.abs(frameRateFromStamps / nativeSampleRate - 1.0);
      if (accuracy <= SAMPLE_RATE_INTENDED_ACCURACY)
      {
        return true;
      }
    }
    return false;
  }


  /**
   * Можно запускать
   */
  final static int STATE_READY = 1;

  /**
   * После запуска (инициализация трека и его разогрев)
   */
  final static int STATE_STARTING = 2;

  final static int STATE_PLAYING = 3;

  /**
   * Может доигрываться последняя итерация в цикле
   */
  final static int STATE_STOPPING = 4;


  Long staticLatencyInFrames;
  Long framesBeforeHeadToReallyPlay;
  Long staticLatencyInMs;

  long timeStable = 0;
  long timeSync = 0;
  int cycleSync = 0;

  /**
   * Состояние: STATE_READY, STATE_STARTING, STATE_PLAYING,   STATE_STOPPING
   */
  int state;
  Message msg;

  void setState(int newState)
  {
    state = newState;

    Message msg = handler.obtainMessage(state, (int) (totalWrittenFrames & 0xFFFFFFFFL), -1);
    handler.sendMessage(msg);
    /*
    msg = new Message(); //ToDo: где-то было сказано, что их нельзя передавать... Чушь, наверное. И наверное даст течь
    msg.what = state;
    //msg.arg2 = msg.arg1 = 0;
    msg.arg1 = (int) (totalWrittenFrames & 0xFFFFFFFFL);
    msg.arg2 = -1;
    handler.sendMessage(msg);
    */
  }

  void commandInvalidateIV()
  {
    //Message message = new Message(); //ToDo: где-то было сказано, что их нельзя
    // передавать... Да, их трогать нельзя.
    msg = new Message();
    msg.what = state;
    msg.arg1 = (int) (totalWrittenFrames & 0xFFFFFFFFL);
    msg.arg2 = (int) ((totalWrittenFrames >> 32) & 0xFFFFFFFFL);
    handler.sendMessage(msg);
  }

  void sendMessage(int cycleCount, int index, int offset, long time)
  {
    //sendMessage(pos.cycleCount, pos.n, pos.offset, time);
    Message msg = handler.obtainMessage(state, index, offset);  //pos.offset);
    handler.sendMessage(msg);
  }

  void sendMessage(Position pos)
  {
    Message msg = handler.obtainMessage(state,
      pos.n / 2, pos.cycleCount);  //pos.offset);
    handler.sendMessage(msg);
    /*
    //Message message = new Message(); //ToDo: где-то было сказано, что их нельзя
    // передавать... Да, их трогать нельзя.
    msg = new Message();
    msg.what = state;
    msg.arg1 = (int) (writtenSamples & 0xFFFFFFFFL);
    msg.arg2 = (int) ((writtenSamples >> 32) & 0xFFFFFFFFL);
    handler.sendMessage(msg);
    */
  }

  /**
   * Возвращает время игры бипа согласно штампу и номеру сэмла.
   * Интерполирует через nativeSampleRate;
   */
  long samplePlayTime(long frameToPlayN, long stampTime, long stampFrame)
  {
    return stampTime + samples2nanoSec(frameToPlayN - stampFrame);
  }

  /**
   * Определяем число samples в данном числе наносекунд.
   */
  long nanoSec2samples(long time)
  {
    return Math.round((double) time * nativeSampleRate * 1e-9);
  }

  /**
   * Определяем время в наносекундах из samples
   */
  long samples2nanoSec(long samplesN)
  {
    return Math.round(1e9 * samplesN / nativeSampleRate);
  }

  Handler handler;

  /**
   * nativeSampleRate,  nativeBufferInFrames - через
   * AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE
   * и
   * AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER
   * bigBuffInMs - желаемое время на весь буфер.
   * ToDo:.....
   */
  public MetroAudioProbnik(int nativeSampleRate, int nativeBufferInFrames,
                           double bigBuffInMs,
                           Handler handler)
  //Bitmap bitmap,
  //Canvas cvOut,
  //RectF oval)
  {
    this.nativeSampleRate = nativeSampleRate;
    this.nativeBufferInFrames = nativeBufferInFrames;

    _tempo = new Tempo(cTempoBpM, cNnoteValue);

    this.handler = handler;

    ///Время на один железный буфер
    double timePerNativeBufMS = 1000.0 * nativeBufferInFrames / nativeSampleRate;
    ///считаем, сколько железных буферов нужно, чтобы покрыть bitTimeMS

    // buffsPerBip = (int)Math.ceil(bipTimeMS/timePerNativeBufMS); //ToDo: точно всё тут ок?

    ///http://audiobuffersize.appspot.com/:
    ///Время на один буфер - от 4 до 83 мс.

    //ToDo: Не сделать ли четным число буферов в половине?
    Double buffsPerHalfD = 0.5 * bigBuffInMs / timePerNativeBufMS;
    buffsPerHalf = (int) Math.max(Math.ceil(buffsPerHalfD), 1);
    centerInFrames = buffsPerHalf * nativeBufferInFrames;

/*
      framesToWriteAtOnce = centerInFrames;
      byteBuffer = ByteBuffer.allocate(framesToWriteAtOnce * 2);

      melodyTools = new MelodyToolsPCM16(nativeSampleRate);
      smallBufferOfSilence = melodyTools.getSilence(nativeBufferInFrames);
      halfOfBigBufferOfSilence = melodyTools.getSilence(centerInFrames);
*/
    melodyBuffer = new MelodyBuffer(nativeSampleRate, nativeBufferInFrames, centerInFrames);

    //singSingSing = new SingSingSing(30);
    //singSingSing = new SingSingSing(30, true);
    //singSingSing = new SingSingSing(50);

    state = STATE_READY; //ToDo: если отправить message при создании onCreate, падает...
    //setState(STATE_READY);

    //ToDo: При неполностью заполненном большом буфере ниего не играется.
    //ToDo: Кажется, что положение головки обновляется не чаще половины большого буфера.
    //ToDo: Положение головки обновляется не каждый раз при коротком
    //ToDo: шаге цикла   (20мс с большим буфером в 40мс).
    //ToDo: Стабильные параметры - 20, 160 (1 буфер на бип, и 8 буферов на всё, пишем бип+3 тишины)

    //графика
    //this.cvMetr=cvOut;
    //this.oval=oval;
    //barrelOrgan=new BarrelOrgan(singSingSing.cycleSing,
    //        //cvOut,
    //        bitmap,
    //        oval);
  }

  ///ToDo: на моём LD не могу создать audioTrack с буфером меньшим, чем 3848 (960*4 =3840)
  public void initTrack()
  {
      /*
      //CHECK API LEVEL!!! 21 (подходит для Lollipop)  23 (marshmallow)
      //Пробовал, отличия от new AudioTrack не видно
      //Api: 23
       audioTrack = new AudioTrack.Builder()
              .setAudioAttributes(new AudioAttributes.Builder()
                      .setUsage(AudioAttributes.USAGE_MEDIA)
                      .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                      .build())
              .setAudioFormat(new AudioFormat.Builder()
                      .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
                      .setSampleRate(nativeSampleRate)
                      .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build())
              .setBufferSizeInBytes(centerInFrames*2*2)
              .setTransferMode(AudioTrack.MODE_STREAM)
              .build();
          */


    ///ToDo
    ///Некоторые параметры не до конца понятны. См. ниже.
      /*
      AudioFormat audioFormat= new AudioFormat.Builder()
              .setEncoding(AudioFormat.ENCODING_PCM_16BIT)
              .setSampleRate(nativeSampleRate)
              .setChannelMask(AudioFormat.CHANNEL_OUT_MONO).build();


      audioTrack = new AudioTrack(
              new AudioAttributes.Builder()
                      .setUsage(AudioAttributes.USAGE_GAME) //USAGE_GAME???? USAGE_MEDIA
                      .setContentType(AudioAttributes.CONTENT_TYPE_MUSIC)
                      .build(),
              audioFormat, ///AudioManager.STREAM_MUSIC,???
              centerInFrames*2*2,
              AudioTrack.MODE_STREAM, AudioManager.AUDIO_SESSION_ID_GENERATE);*/

    audioTrack = new AudioTrack(AudioManager.STREAM_MUSIC,
      nativeSampleRate, AudioFormat.CHANNEL_OUT_MONO,
      AudioFormat.ENCODING_PCM_16BIT,
      centerInFrames * 2 * 2,
      AudioTrack.MODE_STREAM);

    // ToDo: проверить, что он создался.
    // На эмуляторе J1 с api 22 штампов нет

    // Вот какой прекрасныый совет :):):) даётся тут,  https://tekeye.uk/archive/android/avd-sound:
    // Is the PC volume turned up and sound muting off?
    // Are speakers plugged in? Or headphones in the headphone jack?
    // Uncheck Launch from snapshot when starting the AVD.
    // Edit the AVD config.ini file to set Audio playback support to yes.
    // Delete the AVD and recreate it.
    // Use a physical Android device.

    //audioTrack.flush(); //ToDo: надо?

    if (!noMessages)
    {
      boolean printLaterTmp = printLater;
      printLater = false;
      laterLog("------Init:------");

      laterLog("Native sample rate (samples/sec): " + Integer.toString(nativeSampleRate));

      laterLog("Native buffer, in frames and microSecs: " +
        Integer.toString(nativeBufferInFrames) + "\t" +
        Long.toString(Math.round(samples2nanoSec(nativeBufferInFrames) / 1000.0))
      );

      if (Build.VERSION.SDK_INT >= 23)
      {
        //ToDo: тут нужно 23 api. Юриковский J1Mini - 21
        laterLog("Big buffer, in frames and microSecs: " +
          Integer.toString(audioTrack.getBufferSizeInFrames()) + "\t" +
          Long.toString(Math.round(samples2nanoSec(audioTrack.getBufferSizeInFrames()) / 1000.0))
        );
        laterLog("intended buffer size: " + Integer.toString(centerInFrames * 2));
      }

      if (Build.VERSION.SDK_INT >= 24)
      {
        //ToDo: тут нужно 24 api. Не на чем проверить железном... Смысл этого значения непонятен.
        laterLog("Max buffer size: " + Integer.toString(audioTrack.getBufferCapacityInFrames()));
      }


      laterLog("Native buffers in the half: " + Long.toString(buffsPerHalf));
      printLater = printLaterTmp;
    }
  }

  class MelodyBuffer
  {
    private MelodyToolsPCM16 melodyTools;
    /**
     * Частота, с которой работает audioTrack.
     * Для эффективной работы этот параметр (переданый в конструктор при создании)
     * должен совпадать с железными данными звуковой карты. Их можно получить так:
     * <p>
     * AudioManager am = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
     * String sampleRateStr = am.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE);
     * nativeSampleRate = Integer.parseInt(sampleRateStr);
     * if (nativeSampleRate == 0) nativeSampleRate = 48000;
     */
    private final int nativeSampleRate;
    /**
     * Размер минимального буфера. Большой буфер audioTrack будет состоять
     * из четного числа таких буферов. Аналогично nativeSampleRate, этот параметр
     * должен быть получен исходя из железных данных звука. E.g.:
     * <p>
     * String framesPerBuffer = am.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER);
     * nativeBuffer = Integer.parseInt(framesPerBuffer);
     * if (nativeBuffer == 0) nativeBuffer = 960;
     */
    private final int nativeBufferInFrames;

    // Последовательность байт для тишины. ОДИН ЖЕЛЕЗНЫЙ БУФЕР!
    // Пишется при разогреве.
    private final byte[] smallBufferOfSilence;
    // Половина большого буфера тишины.
    private final byte[] halfOfBigBufferOfSilence;

    // Сколько мы хотим писать за один раз. Разумным представляется писать за раз половину большого буфера.
    // Середина большого буфера.
    private final int framesToWriteAtOnce;

    ByteBuffer buffer;
    byte[] silenceToWrite;

    MelodyBuffer(int nativeSampleRate, int nativeBufferInFrames, int framesToWriteAtOnce)
    {
      this.nativeSampleRate = nativeSampleRate;
      this.nativeBufferInFrames = nativeBufferInFrames;
      this.framesToWriteAtOnce = framesToWriteAtOnce;

      melodyTools = new MelodyToolsPCM16(nativeSampleRate);

      smallBufferOfSilence = melodyTools.getSilence(nativeBufferInFrames);
      halfOfBigBufferOfSilence = melodyTools.getSilence(framesToWriteAtOnce);

      buffer = ByteBuffer.allocate(framesToWriteAtOnce * 2);

      //ToDo: взять более пристойный способ. Например, buffer.Allocate делает всё нулями
      silenceToWrite = melodyTools.getSilence(framesToWriteAtOnce);
    }

    int copy2buffer(AccentedMelody melody, Position pos)
    {
      buffer.position(0);
      //long writtenSamples = -1;

      //Тестим цикл. //ToDo: поправить written's!
      int toWrite = 0;
      BipPauseCycle.TempoLinear linear = melody.cycle.readTempoLinear(framesToWriteAtOnce);
      pos.n = linear.pos.n;
      pos.offset = linear.pos.offset;
      pos.cycleCount = linear.pos.cycleCount;

      for (int i = 0; i < linear.durations.length; i++)
      {
        int offset = i == 0 ? linear.startInFirst * 2 : 0;
        if (linear.symbols[i] == melody.cycle.elasticSymbol)
        {
          buffer.put(silenceToWrite, 0,
            linear.durations[i] * 2);
        }
        else
        {
          buffer.put(melody.setOfNotes[linear.symbols[i]],
            //melodyTest[linear.symbols[i]],
            offset,
            linear.durations[i] * 2);
          assert (offset == 0);
          //writtenSamples = totalWrittenFrames + toWrite / 2 + offset;
          //sendMessage(writtenSamples);
        }
        toWrite += linear.durations[i] * 2;
      }
      buffer.position(0);

      //ToDo: то, что выше, нужно оформить как метод внутри setOfNotes
      if (!noMessages)
      {
        linear.print();
        melody.cycle.printPosition();
        System.out.printf("error, totalErrorsCorrected: %.3f, %d\n", melody.cycle.accumulatedError,
          melody.cycle.totalErrorsCorrected);
      }
      return toWrite;
    }
  }

  class MetroRunnable implements Runnable
  {
    MelodyBuffer mBuffer;

    BipPauseCycle cycle;
    //BipPauseCycle.TempoLinear linear;
    int realBPM;

    int _cnt;

    boolean warmingUp;

    //ToDo: убрать из public
    public long currentTime, prevTime;

    AudioTimestamp currentStamp, prevStamp;
    long veryFirstStampFrame, veryFirstStampTime;

    int headPosInFrames, prevHeadPosInFrames;

    MetroRunnable(MelodyBuffer melodyBuffer)
    {
      this.mBuffer = melodyBuffer;
    }

    boolean conditionToPrint()
    {
      return (!noMessages) && _cnt >= 0 &&
        ((warmingUp && warmingUpMessages) ||
          (_cnt % Math.pow(10, Math.ceil(Math.log10(_cnt + 1)) - 1) == 0));  // много будем писать - много придётся читать
    }

    @Override
    public void run()
    {
      realBPM = melody.setTempo(_tempo);

      melody.cycle.position.reset();

      cycle = melody.cycle;

      //barrelOrgan.reSetAngles(cycle);

      if (!noMessages)
        cycle.print();

      initTime = System.nanoTime();

      audioTrack.play();

      prevHeadPosInFrames = audioTrack.getPlaybackHeadPosition();
      prevTime = initTime;
      _cnt = 0;

      warmingUp = true;

      int written;

      //Весь буфер заполняем тишиной - без этого толку всё равно нет
      written = audioTrack.write(mBuffer.halfOfBigBufferOfSilence, 0, mBuffer.halfOfBigBufferOfSilence.length);
      written += audioTrack.write(mBuffer.halfOfBigBufferOfSilence, 0, mBuffer.halfOfBigBufferOfSilence.length);
      totalWarmUpFrames = written / 2;
      totalLostFrames = mBuffer.halfOfBigBufferOfSilence.length - totalWarmUpFrames;
      laterLog("Init silence, written and lost: " +
        Long.toString(totalWarmUpFrames) + " \t" + Long.toString(totalLostFrames));

      prevStamp = new AudioTimestamp();
      currentStamp = new AudioTimestamp();

      //ToDo: взять более пристойный способ. Например, buffer.Allocate делает всё
      //нулями
      //byte[] silenceToWrite = melodyTools.getSilence(framesToWriteAtOnce);

      while (doPlay && audioTrack != null &&
        audioTrack.getPlayState() == AudioTrack.PLAYSTATE_PLAYING)
      {
        if (warmingUp)
        {
          //пишем  один маленький буфер тишины
          //ToDo: Кажется, это не позволяет сэкономить сильно -
          //для стабилизации stamp нужно скормить еще несколько малых буферов (согласно экспериментам 24.02.19)

          written = audioTrack.write(mBuffer.smallBufferOfSilence, 0, mBuffer.smallBufferOfSilence.length);
          totalWarmUpFrames += mBuffer.smallBufferOfSilence.length / 2; //Это нужно, чтобы следить за головкой.
          totalLostFrames += (mBuffer.smallBufferOfSilence.length - written) / 2;
          totalWrittenFrames = totalWarmUpFrames;

          if (conditionToPrint())
          {
            if (mBuffer.smallBufferOfSilence.length > written)
              laterLog("!!!LOST LOST LOST!!!");
            laterLog("---- WarmingUp: " + Integer.toString(_cnt));
            laterLog("written and lost: " +
              Long.toString(totalWarmUpFrames) + " \t" + Long.toString(totalLostFrames));
          }

          /*//Можно писать половинами большого, можно четвертями -
          //эффект примерно тот же, что писать по одному малому буферу.
          audioTrack.write(halfOfBigBufferOfSilence,0, halfOfBigBufferOfSilence.length);
          totalWarmUpFrames += halfOfBigBufferOfSilence.length/2;  */

          //Сравниваем sampleRate, полученный исходя из данных двух stamps,
          //с настоящей частотой. Если они достаточно близки (что определяется константой
          //SAMPLE_RATE_INTENDED_ACCURACY и функцией audioIsStable), то разогрелись
          if (audioTrack.getTimestamp(currentStamp))
          {
            if (audioIsStable(prevStamp, currentStamp))
            {
              warmingUp = false;  // Разогрелись!
              veryFirstStampTime = currentStamp.nanoTime;
              veryFirstStampFrame = currentStamp.framePosition;

              setState(STATE_PLAYING);

              timeStable = System.nanoTime();
              //ToDo: ТЕСТ. Показал отличные, неразличимые на глаз результаты на моём телефоне
              Long playHeadTimeOfVeryFirstStamp = timeStable - // исходим из того, что играется уже равномерно
                samples2nanoSec(audioTrack.getPlaybackHeadPosition() - veryFirstStampFrame);
              staticLatencyInFrames = nanoSec2samples(veryFirstStampTime - playHeadTimeOfVeryFirstStamp);
              staticLatencyInMs = (long) ((playHeadTimeOfVeryFirstStamp - veryFirstStampTime) * 1e-6);

              _cnt = -1;

              if (!noMessages)
              {
                laterLog("\t-----------Audio is stable-----------");
                laterLog("\tWarming up statistics");
                laterLog("\ttotalWarmUpFrames: " + Long.toString(totalWarmUpFrames));
                laterLog("\tTime (mks): " + Long.toString((System.nanoTime() - initTime) / 1000));
                laterLog("\t Latency??? (frames, ms):" +
                  Long.toString(staticLatencyInFrames) + ", " + Long.toString(staticLatencyInMs));
                laterLog("--------------------------------------");
              }
            }
          }
          //ToDo: предусмотреть и другой способ окончания разогрева - если не удалось получить стабильные штампы
          //скажем,  за полсекунды (upd: мало, на железном J1mini  почти полсекунды штатный разогрев)
          // от начала не смогли стабилизироваться - нужно что-то делать.
          // Полсекунды - рисково. В наушниках как-то было больше трети - 20 малых буферов прошло.

          // Время на разогрев, в малых буферах сверху большого (без наушников - кажется,
          // это может повлиять)
          //
          // Обычно - 8-10 малых буферов хватает для 8 малых буферов в большом (160мс)
          // Хотя однажды было 20 (но в наушниках)
          // Если 1280 (64 буфера) - 13-33 буфера
          // 640 мс (32 буфера)  14 -17
          // 320 мс - 8-9

          /* Звук работает на J1Mini эмуляторе, но без разогрева.
          //Иногда там даже одна итерация при разогреве глючит, или
          //вообще не удается инициализировать audio track. Тогда надо всё перезагружать
          //
          if (_cnt>50) //ToDo:  !!!
          {
            warmingUp = false;  // Разогрелись.... кое-как
            veryFirstStampTime = System.nanoTime();
            veryFirstStampFrame = totalWrittenFrames;
            _cnt = -1;
          }
          */
        }
        else
        {
          //Кажется, что write "разблокируется" только в случаях, кратных половине откранного большого буфера
          //При этом, кажется, что эта половина еще и сама должна быть четной, иначе начинаются скачки
          //При этом, если очень короткое время (<100мс, например) на весь большой буфер,
          //тоже начинаются неровности (может быть, это связано с нихким приоритетом процесса?)
          //ToDo: отследить "входящий телефонный звонок"
          /*written1 = audioTrack.write(melodyOld[_cnt % melodyOld.length], 0, bipLengthInBytes);
          //остаток - тишина
          written2 = audioTrack.write(halfOfBigBufferOfSilence, 0, silenceLengthInBytes)+
                  audioTrack.write(halfOfBigBufferOfSilence, 0, halfOfBigBufferOfSilence.length);*/

          boolean sync = newTempo || newMelody;

          if (newMelody)
          {
            System.out.printf("---------SetNewMelody------");
            realBPM = melody.setTempo(_tempo);

            melody.cycle.position.reset();

            cycle = melody.cycle;
            newMelody = false;
          }
          if (newTempo)
          {
            System.out.printf("---------SetNewTempo------");
            //ToDo: Разобраться с переменными - какие в классе, какие в потоке
            if (!noMessages)
            {
              System.out.printf("---------NewTempo------");
              System.out.printf(String.format("Old length of cycle: %.3f\n", cycle.duration));
              System.out.printf(String.format("BPMFromSeekBarVal: %d", _tempo.beatsPerMinute));
              cycle.print();
            }

            realBPM = melody.setTempo(_tempo);
            newTempo = false;
            //tempo.beatsPerMinute = BPMfromSeekBar;
            //barrelOrgan.reSetAngles(cycle);

            if (!noMessages)
            {
              System.out.printf("New BPM, new length of cycle: %d, %.3f\n", realBPM, cycle.duration);
              cycle.print();
            }
          }

          if (sync)
          {
            Position pos = melody.cycle.position;
            long timeNow = System.nanoTime();
            long time = timeNow - timeStable;
            timeSync = time;
            timeStable = timeNow;
            int cycles = (int) (time / melody.cycle.duration);
            cycleSync = cycles;
            if (cycles != pos.cycleCount)
              System.out.printf("Error: Cycle count is different %d - %d\n", cycles, pos.cycleCount);

            int offset = pos.offset;
            if (pos.n % 2 != 0)
              offset += melody.cycle.cycle[pos.n - 1].l;
            sendMessage(pos.cycleCount, pos.n / 2, (int) (1e6 * offset / nativeSampleRate), time);
            //System.out.printf("FramesBeforeHeadToReallyPlay %d - %d\n", pos.n / 2, pos.cycleCount);
          }
          //byteBuffer.position(0);

          //long writtenSamples = -1;
          Position pos = new Position(-1, 0);
          int toWrite = mBuffer.copy2buffer(melody, pos);
/*
          if (pos.n >= 0)
          {
            sendMessage(pos);
            //System.out.printf("FramesBeforeHeadToReallyPlay %d - %d\n", pos.n / 2, pos.cycleCount);
          }
*/
          //Пишем звук
          //byteBuffer.position(0);
          written = audioTrack.write(mBuffer.buffer, mBuffer.framesToWriteAtOnce * 2,
            AudioTrack.WRITE_BLOCKING);

          int headJustAfterWrite = audioTrack.getPlaybackHeadPosition();
          totalLostFrames += (toWrite - written) / 2;
          totalWrittenFrames += written / 2;

          framesBeforeHeadToReallyPlay = staticLatencyInFrames + (totalWrittenFrames - headJustAfterWrite);

          if (conditionToPrint())
          {
            laterLog("-----MainCycle: " + Integer.toString(_cnt) + "-----");
            if (toWrite > written)
              laterLog("!!!LOST LOST LOST!!!");
            laterLog("written now, and lost now: " +
              Long.toString(written) + " \t" +
              Long.toString(toWrite - written));
            laterLog("Just after write, we are ahead of the head: " +
              Long.toString(totalWrittenFrames - headJustAfterWrite));
            laterLog("\t Time to play written (frames, ms):" +
              Long.toString(framesBeforeHeadToReallyPlay) + ", " +
              Long.toString((long) (samples2nanoSec(framesBeforeHeadToReallyPlay) * 1e-6)));
          }
        }

        currentTime = System.nanoTime();
        boolean stampIsGood = audioTrack.getTimestamp(currentStamp);
        headPosInFrames = audioTrack.getPlaybackHeadPosition();

        if (conditionToPrint())
        {
          collectInfo(stampIsGood);
        }

        //System.out.printf("Jframe %d - %d (%d - %d\n)", currentTime, headPosInFrames, currentStamp.framePosition, currentStamp.nanoTime);

        prevTime = currentTime;
        prevHeadPosInFrames = headPosInFrames;
        prevStamp.framePosition = currentStamp.framePosition;
        prevStamp.nanoTime = currentStamp.nanoTime;

        _cnt++;
      }
      // End of main work cycle

      if (audioTrack != null)
      {
        audioTrack.flush();
        audioTrack.stop();
        audioTrack.release();
      }
      setState(STATE_READY);
    }

    /**
     * Отладочное. Сокращения для использования в collectInfo
     */
    private long startTimeFromHead, startTimeFromWritten,
      startTimeFromStamp, startTimeFromFirstStamp,
      deltaStampFrames, deltaStampTime;

    /**
     * Собираем данные после записи в буфер
     */
    private void collectInfo(boolean currentStampIsGood)
    {
      if (noMessages || audioTrack == null ||
        audioTrack.getPlayState() != AudioTrack.PLAYSTATE_PLAYING)
        return;

      if (!currentStampIsGood)
      {
        laterLog("Stamp is bad.");
      }
      else
        laterLog("Stamp is good.");

      laterLog("Written, head,  stampPos:");
      laterLog(Long.toString(totalWrittenFrames) + " \t" +
        Integer.toString(headPosInFrames) + " \t" +
        Long.toString(currentStamp.framePosition));

      laterLog("written-Head, Head-stampPos, stampPos-written:");
      laterLog(Long.toString(totalWrittenFrames - headPosInFrames) + " \t" +
        Long.toString(headPosInFrames - currentStamp.framePosition) + " \t" +
        Long.toString(currentStamp.framePosition - totalWrittenFrames));

      if (!warmingUp)
      {
        laterLog("Analysing firstSampleToPlayTime according to:");
        laterLog("head and sysTime; written and sysTime; stamp; veryFirstStamp(mks, relative initTime).");
        startTimeFromHead = currentTime - samples2nanoSec(headPosInFrames - totalWarmUpFrames);
        startTimeFromWritten = currentTime - samples2nanoSec(totalWrittenFrames - totalWarmUpFrames);
        startTimeFromStamp = currentStamp.nanoTime - samples2nanoSec(currentStamp.framePosition - totalWarmUpFrames);
        startTimeFromFirstStamp = samplePlayTime(totalWarmUpFrames, veryFirstStampTime, veryFirstStampFrame);

        laterLog("Their differences: by_head - by_written, by_written-by_stamp, by_stamp - by_stamp0, by_stamp0 - by_head:");
        laterLog(Long.toString((startTimeFromHead - startTimeFromWritten) / 1000) + " \t" +
          Long.toString((startTimeFromWritten - startTimeFromStamp) / 1000) + " \t" +
          Long.toString((startTimeFromStamp - startTimeFromFirstStamp) / 1000) + " \t" +
          Long.toString((startTimeFromStamp - startTimeFromHead) / 1000)
        );
      }

      laterLog("nanoTimeDiff (mks): " + Long.toString((currentTime - prevTime) / 1000));
      laterLog("nanoTimeDiff in frames: " + Long.toString(
        nanoSec2samples(currentTime - prevTime)
        )
      );

      laterLog("Diff in HeadPos, frames and buffs: " + Integer.toString(headPosInFrames - prevHeadPosInFrames) +
        " \t " +
        Integer.toString((headPosInFrames - prevHeadPosInFrames) / nativeBufferInFrames)
      );

      laterLog("HeadPos-StampPos: " +
        Integer.toString(headPosInFrames - (int) currentStamp.framePosition)
      );

      deltaStampFrames = currentStamp.framePosition - prevStamp.framePosition;
      deltaStampTime = currentStamp.nanoTime - prevStamp.nanoTime;

      laterLog("stamp deltas, frames and time (mks): " +
        Long.toString(deltaStampFrames) + " \t" +
        Long.toString(deltaStampTime / 1000)
      );
      laterLog("stamp, frame: " +
        Long.toString(currentStamp.framePosition)
      );

      if (deltaStampTime != 0)
      {
        laterLog("Frequency from stamps: " +
          Long.toString(Math.round(
            1e9 * deltaStampFrames / deltaStampTime
            )
          )
        );
      }
    }

  }

  /**
   *  SilentLog
   *
   *  Запасаем отладочные данные и печатаем потом командой dPrintAll.
   *
   *  Если noMessages=false (как по умолчание), то
   *  чтобы печатать сразу, нужно использовать printLater =false,
   *  и наоборот, чтобы запасать.
   *
   *  Если noMessages=true, то строки не запасаются и не печатаются.
   */

  /**
   * Использовать для профилирования.
   * Если true, то сообщения не запасаются.
   */
  final boolean noMessages = true;

  /**
   * Если noMessages=true - сообщения не будут собираться/печататься.
   * В противном случае указывает, печатать сразу или запасать сообщения.
   */
  private boolean printLater = false;

  /**
   * Если noMessages=true - сообщения не будут собираться/печататься.
   * В противном случае указывает, что делать при разогреве.
   */
  private boolean warmingUpMessages = true;

  public static final String logTagSoundTest = "SoundTest";

  private String[] dMessages = new String[5000];  //ToDo: поменять это безобразие
  private int stringsWritten = 0;

  /**
   * Отложенный вывод сообщений, если printLater =true.
   * Сделано на всякий случай, чтобы не заниматься выводом из потока, обрабатывющего звук.
   * Если noMessages, то ничего не делает вообще.
   */
  void laterLog(String message)
  {
    if (noMessages) return;
    if (!printLater)
    {
      //Log.d(logTagSoundTest,message);
      System.out.println("logTagSoundTest \t" + message);
    }
    else
    {
      if (stringsWritten < dMessages.length)
      {
        dMessages[stringsWritten] = message;
        stringsWritten++;
      }
    }
  }

  /**
   * Печатает накопленные сообщения
   */
  void dPrintAll()
  {
    for (int i = 0; i < stringsWritten; i++)
    {
      //Log.d(logTagSoundTest,dMessages[i]);
      System.out.println("logTagSoundTest \t" + dMessages[i]);
    }
    stringsWritten = 0;
  }
}

/**
 * Пересчитываем  темпо (традиционный, дуракций) в длительность цикла в сэмплах,
 * исходя из того, сколько там bars (то есть, какова его длина в нотах)
 * и частоты (то есть, длительности одного сэмпла). Может быть больше, чем
 * возможная длина.
 * <p>
 * (В случае простого метронома bars=1.)
 *
 * @param tempo музыкальный темп
 * @return какова должна быть длительность цикла при данном tempo.
 * <p>
 * Каков будет темп при данной длительности цикла в сэмплах. Зависит от bars и
 * частоты.
 * @param durationInFrames какую длительность в сэмплах переводим в tempo
 * @param denominator какой у темпо знаменатель
 * @return ударов, соответствующим denominator, в минуту при данной длине цикла
 * <p>
 * Это прообраз общей процедуры, определяющий минимальный темп по данной
 * звуковой схеме. Результат дробный, поэтому нужно его округлить
 * в "простой схеме" (когде нет свободного метра, а мы привязаны к музыкальной архаике).
 * Напонмю, что максимальная скорость (наименьшая длительность цикла) зависят от ужимаемых
 * elastic's и предшествующих несжимаемых звуков. Иными словами, она зависит от кратчайших бипов
 * в музыкальной схеме и их доле в сумме со следующей паузой.
 * Совсем огрубляя: чем короче бипы - тем быстрее можно играть (естественно).
 * @param denominator в чем исчисляется ритм (4,8,16)
 * @return наибольший темп, который мы можем установить для цикла при данном знаменателе
 * <p>
 * Устанавливаем новую длительность цикла. Имеется арифметическое ограничение снизу
 * (см. getMaximalTempo).
 * @param tempo музыкальный ритм
 * @return установленных ударов в минуту
 */
// in seconds
      /*
      private double tempoToCycleDuration(Tempo tempo)
      {
        int totalBeatsPerCycle = bars * tempo.denominator;
        double framesPerBeat = nativeSampleRate * 60.0 / tempo.beatsPerMinute;

        System.out.println(String.format("tempoToCycleDuration: %d, %d, %d, %d", tempo.beatsPerMinute, tempo.denominator,
          bars, nativeSampleRate));

        return framesPerBeat * totalBeatsPerCycle;
      }
       */
/**
 * Каков будет темп при данной длительности цикла в сэмплах. Зависит от bars и
 *  частоты.
 * @param durationInFrames какую длительность в сэмплах переводим в tempo
 * @param denominator какой у темпо знаменатель
 * @return ударов, соответствующим denominator, в минуту при данной длине цикла
 */
      /*
      private double cycleDurationToBeatsPM(double durationInFrames, int denominator){
          double durInMins=durationInFrames/(nativeSampleRate*60.0);
          int totalBeatsPerCycle=bars*denominator;
          return ((double)totalBeatsPerCycle)/durInMins;
      }
       */
/**
 * Это прообраз общей процедуры, определяющий минимальный темп по данной
 * звуковой схеме. Результат дробный, поэтому нужно его округлить
 * в "простой схеме" (когде нет свободного метра, а мы привязаны к музыкальной архаике).
 * Напонмю, что максимальная скорость (наименьшая длительность цикла) зависят от ужимаемых
 * elastic's и предшествующих несжимаемых звуков. Иными словами, она зависит от кратчайших бипов
 * в музыкальной схеме и их доле в сумме со следующей паузой.
 * Совсем огрубляя: чем короче бипы - тем быстрее можно играть (естественно).
 *
 * @param denominator в чем исчисляется ритм (4,8,16)
 * @return наибольший темп, который мы можем установить для цикла при данном знаменателе
 */
      /*
      public double getMaximalTempo(int denominator)
      {
        return cycleDurationToBeatsPM(cycleSing.leastDuration, denominator);
      }
       */
/**
 * Устанавливаем новую длительность цикла. Имеется арифметическое ограничение снизу
 * (см. getMaximalTempo).
 *
 * @param tempo музыкальный ритм
 * @return установленных ударов в минуту
 */
      /*
      public int setTempo(Tempo tempo)
      {
        int BPMtoSet = Math.min((int) getMaximalTempo(tempo.denominator),
          tempo.beatsPerMinute);
        cycleSing.setNewDuration(tempoToCycleDuration(new Tempo(BPMtoSet, tempo.denominator)));
        return BPMtoSet;
      }

    }
  }
*/
