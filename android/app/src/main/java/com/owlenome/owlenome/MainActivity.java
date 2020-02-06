package com.owlenome.owlenome;

import android.content.Context;

import android.media.AudioManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;


import android.content.res.Resources;

//import  android.R; //Test: for raw
//import  android.R.raw; //Test: for raw
//import  com.owlenome.owlenome.R; //Test: for raw
//import  com.owlenome.owlenome.R.raw;
//IS: Ничего не помогло  проекту, открытому во флаттере,
//увидеть R корректно. Всё работает, но подчеркивает красным поля R
//VS, вот что по этому поводу я нашел, но понять там ничего не смог, может, ты сможешь понять?
//https://github.com/flutter/flutter-intellij/issues/3136
//https://github.com/flutter/flutter/wiki/Upgrading-pre-1.12-Android-projects

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;







public class MainActivity extends FlutterActivity implements MethodChannel.MethodCallHandler
{
  private static final String SOUND_CHANNEL = "samples.flutter.io/owlenome";

  private MethodChannel channel;

  int nativeSampleRate = 0;
  int nativeBuffer;
  //int latencyUntested;
  // Previous tempo value to compare with a new one
  //Tempo _tempo  = new Tempo(1, 1);
  //int _beatsPerMinute = 1;
  // Beat setOfNotes
  /**
   * Тонкое место. Переменная beatMelody ссылкается
   * на ту мелодию, которая отправлена в metroAudio для
   * установки. Это не значит, что она играется прямо сейчас.
   */
  AccentedMelodyMix beatMelody = null;
  MetroAudioMix metroAudio;

  // Sound schemes
  // Сюда собираем пары звуков.
  List<MusicSchemeMix> soundSсhemes;//ToDo
  MusicSchemeMix musicSсhemeTunable;
  int currentMusicScheme = 0;

  BeatMetre beatRecieved=null;

  @Override
  protected void onCreate(Bundle savedInstanceState)
  {
    super.onCreate(savedInstanceState);
    GeneratedPluginRegistrant.registerWith(this);

    getNativeAudioParams();

    initSoundSchemes();


    // Receive messages from audio playing thread
    Handler handler = new Handler(Looper.getMainLooper())
    {

      /**
       *  Отладочное. Если сделать true, то будет играться только звук.
       *  (управления из флаттер кроме старт не будет).
       *  Используется для проверки нагрузки на процессор, создаваемой аудиопотоком.
       */
      boolean noGraphic=false;

      @Override
      public void handleMessage(Message msg)
      {
        if (noGraphic) return;
        //int whtmsg.what & 0x3
        if (msg.what == MetroAudioMix.STATE_PLAYING)
        {
          if (msg.arg2 == -1)
          {
            //STATE_STARTING
            System.out.println("WARMEDUP");
            //channel.invokeMethod("warm", msg.arg1);
            long toSend=metroAudio.timeOfVeryFirstBipMcs;
            channel.invokeMethod("warm", toSend);

            /*
            //test
            prevTime=toSend;
            double prevRel=0;
            // Log.d("MsgTest", "Time in Java of the very frst bip (mcs):  "+                    prevTime.toString());
            //System.out.printf("Time in Java of the very frst bip (mcs) %d",initTime);
            //_cnt=0;
            prevRel=0;
            prevBeat =0;

            for (int i=0; i<metroAudio.melody.cycle.cycle.length;i++){
              Long dur=
                      metroAudio.samples2nanoSec(
                              (long)metroAudio.melody.cycle.durationBeforePosition(i))/1000000;
              Log.d("MsgTest",
                      String.format("Before pos %d : %d", i, dur));
            }*/
          }
          else if (msg.arg2 == -2)//IS: Посылаем начальные условия
          {
            Map<String, Object> args = new HashMap<>();
            int bpm=msg.arg1; // metroAudio.getTempo();
            args.put("bpm", bpm);//новая скорость
            long time0=metroAudio.timeOfSomeFirstBipMcs;
            args.put("nt", time0);//новое время
            Long lastSampleToPlay= metroAudio.timeOfLastSampleToPlay;
            args.put("dt", lastSampleToPlay);//Когда начинать играть с новой скоростью

            channel.invokeMethod("Cauchy", args);

            //test
            Long lost=metroAudio.totalLostFrames;
            if(lost>0)//ToDo: нужно громко заявить
                 Log.d("MsgTest", String.format("Lost samples: %d",  lost));

            /*
            //test

            Long timeNow=metroAudio.timeNowMcs;
            Long latMs=(lastSampleToPlay-timeNow)/1000;
            Long deltaTimeMcsFrst=(timeNow-time0)/1000;
            //Log.relPos("MsgTest", "time to last sample: "+latMs.toString());
            //Log.relPos("MsgTest", "time since first sample: "+deltaTimeMcsFrst.toString());
            Double relPos=metroAudio.melody.cycle.relativeDurationBeforePosition();
            Double absPosition=relPos+metroAudio.melody.cycle.cycleCount;

            Log.d("MsgTest", "rel and abs. pos: "+String.format ("%f", relPos)
                    +"; " +String.format ("%f", absPosition));
            Log.d("MsgTest", "abs. pos, delta: "+//+String.format ("%f", relPos)+"; "
                    String.format ("%f", absPosition)+"; "+
                    String.format ("%f", absPosition-prevRel)+"; "
            );
            prevRel=absPosition;

            Integer nOfBeats=metroAudio.melody.cycle.cycle.length/2;
            Integer note=metroAudio.melody.cycle.position.n/2;
            Integer totalBeat=nOfBeats*metroAudio.melody.cycle.cycleCount+note;
            Integer deltaNote=totalBeat- prevBeat;
            Integer cycleC=metroAudio.melody.cycle.cycleCount;
            Log.d("MsgTest", "Cycle, note, totalNote, delta: \n"+
                    cycleC.toString()+ "; "+
                    //nOfBeats.toString()+ "; "+
                    note.toString()+"; "+
                    totalBeat.toString()+"; "+ deltaNote.toString());
            prevBeat =totalBeat;*/




          }
          /*
          else if (msg.arg2 == -3)//тест
          {
            if (!bFirstMessage){
              bFirstMessage=true;
            }
            _cnt++;
            Long lastSampleToPlay= metroAudio.timeOfLastSampleToPlay;
            Long latMs=(lastSampleToPlay-metroAudio.timeNowMcs)/1000;
            Long deltaTimeMcsFrst=(metroAudio.timeNowMcs-metroAudio.timeOfSomeFirstBipMcs);
            Integer cnt=msg.arg1;
            //Log.wtf("MsgTest", "Cnt, delta time: "+                     cnt.toString()+" (" + cnt.toString()+") "+                    deltaTimeMcs.toString());
            //   Log.wtf("MsgTest", "latency (ms): "+ latMs.toString());
            //   if (deltaTimeMcs<=0) {
            // System.out.printf("MsgTest; Time:  d-time: %d, d-from-frst %d \n", deltaTimeMcs, deltaTimeMcsFrst);
            // }
          }*/

          /*
          else
          {
            //long totalWrittenFrames = (((long) msg.arg2) << 32) + (long) msg.arg1;
            //channel.invokeMethod("timeFrame", totalWrittenFrames);
            //long arg = (msg.arg1 & 0xFFFFFFFFL) & ((msg.arg2 >> 32) & 0xFFFFFFFFL);
            Map<String, Object> args = new HashMap<>();
            args.put("index", msg.arg1);
            args.put("offset", 0);
            args.put("cycle", msg.arg2);
            channel.invokeMethod("timeFrame", args);
          }*/
            /*
          {
            //long totalWrittenFrames = (((long) msg.arg2) << 32) + (long) msg.arg1;
            //channel.invokeMethod("timeFrame", totalWrittenFrames);
            //long arg = (msg.arg1 & 0xFFFFFFFFL) & ((msg.arg2 >> 32) & 0xFFFFFFFFL);
            Map<String, Object> args = new HashMap<>();
            args.put("index", msg.arg1);
            args.put("beat", 0);
            args.put("sub", 0);
            args.put("offset", msg.arg2);
            args.put("cycle", metroAudio.cycleSync);
            args.put("time", metroAudio.timeSync);
            channel.invokeMethod("sync", args);
          }*/
          //IS:
          // ToDo: Законно ли то, что мы лазим в
          // другой поток за переменными? Точнее, что он обращается к тем переменным,
          // которые мы потом собираем тут? Не может ли
          // это блокировать его и вызвать потерянные сэмплы?
          // Я натыкался на статью или видео одного из гугловых звуковых гуру,
          // который рассказывал кошмары о том, как у него из-за print в потоке такое случалось
          // и как он неделю мучился. Лох эдакий, понабрали по объявлениям...
        }
      }

      /*
      //Some test vars
      boolean bFirstMessage=false;
      Long prevTime;
      double prevRel;
      int prevBeat;
      int _cnt=0;*/
    };


    metroAudio = new MetroAudioMix(nativeSampleRate, nativeBuffer,
            160,//TODO: TEST: 1000; //00;
            // 160 - основной кандидат (8 моих буферов)
            // Regular: 120; //1000.0/8 --- 240;16,; 1280 - 64 буфера;
            handler);

    channel = new MethodChannel(getFlutterView(), SOUND_CHANNEL);
    channel.setMethodCallHandler(this);
    //IS:  А в какой плсдедовательности запускаются эта процедура и
    //  init во флаттере?
  }


  @Override
  public void onMethodCall(MethodCall methodCall, MethodChannel.Result result)
  {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT)
    {
      result.notImplemented();
      return;
    }//IS: Why? We cannot use this anyway


    //BeatMetre beat = new BeatMetre();

    if (methodCall.method.equals("start"))
    {
      int _beatsPerMinute = methodCall.argument("tempo");
      //_tempo.denominator = methodCall.argument("note");

      //int realTempo = 0;
      if (beatMelody != null)
         start(_beatsPerMinute);
      //List<Map<Double, Integer> a = new HashMap<>
      result.success(1);
    }
    else if (methodCall.method.equals("setBeat"))
    {

      beatRecieved = new BeatMetre();
      //IS:
      // Get beat parameters from Flutter
      //   BeatMetre beat = new BeatMetre();

      List<Integer> config = methodCall.argument("config");
      if (config.size() >= 3)
      {
        beatRecieved.beatCount = config.get(0);
        beatRecieved.subBeatCount = config.get(1);
        int schemeIndex = config.get(2);
        if (schemeIndex < soundSсhemes.size())
          currentMusicScheme = schemeIndex;
        //_beatsPerMinute = config.get(3);
        //_tempo.denominator = config.get(4);
      }
      if (config.size() >= 7)
      {
        /*
        // меняем параметры musicSсhemeTunable

        beat.subBeatFreq = 0.001 * config.get(3);
        beat.beatDuration = config.get(4);
        beat.accentFreq = 0.001 * config.get(5);
        beat.accentDuration = config.get(6);*/
      }
      if (config.size() >= 10)
      {
        //bars = config.get(7);
        // numerator = config.get(8);
        //quortaDuration = config.get(9);
      }

      //IS: VG Hack!!!
      // numerator = 1;

      List<Integer> subBeats = methodCall.argument("subBeats");
      if (subBeats.size() > 0)
      {
        assert (beatRecieved.subBeatCount == subBeats.size());
        beatRecieved.subBeats = new ArrayList<Integer>(subBeats);
      }
      else
      {
        beatRecieved.subBeats = new ArrayList<Integer>();
        assert (beatRecieved.subBeats.size() == beatRecieved.beatCount);
        for (int i = 0; i < beatRecieved.beatCount; i++)
          beatRecieved.subBeats.add(beatRecieved.subBeatCount);
      }

      // Accents array
      List<Integer> accents = methodCall.argument("accents");
      if (accents.size() > 0)
      {
        beatRecieved.accents = new byte[accents.size()];
        for (int i = 0 ; i < accents.size(); i++)
          beatRecieved.accents[i] = accents.get(i).byteValue();
/*
        byte maxAccent = 0;
        for (int i = 0 ; i < accents.size(); i++)
        {
          beatRecieved.accents[i] = accents.get(i).byteValue();
          if (beatRecieved.accents[i] > maxAccent)
            maxAccent = beatRecieved.accents[i];
        }
        for (int i = 0 ; i < accents.size(); i++)
          beatRecieved.accents[i] = (byte) (maxAccent - beatRecieved.accents[i]);
*/
      }

      /*
      beatMelody = new AccentedMelody(soundSсhemes.get(currentMusicScheme),
              nativeSampleRate, beat.beatCount, beat.subBeats);
       */
      //так не надо; при изменении битов надо менять
      //чуть мелодию, а не грузить её всю.


      if (beatMelody != null)
      {
        double newMaxTempo = metroAudio.reSetBeats(beatRecieved);
        result.success((int) newMaxTempo);
      }
      else
      {
        result.success(-1);//
      //В первый раз получили beat,
      //  мелодии пока нет, ограничений - тоже
      }
    }
    else if (methodCall.method.equals("setTempo"))
    {
      int tempoBpm = methodCall.argument("tempo");
      //int noteValue = methodCall.argument("note");//IS: Не нужно.
      //int maxTempo = setTempoA(tempoBpm/*, noteValue*/);
      metroAudio.setTempo(tempoBpm);
      //result.success(maxTempo);
      result.success(1);
    }
    else if (methodCall.method.equals("setVolume"))
    {
      int volume = methodCall.argument("volume");
      if (metroAudio != null)
        metroAudio.setVolume(volume);
      result.success(1);
    }
    else if (methodCall.method.equals("getAudioParams"))
    {
      if (nativeSampleRate > 0)
      {//ToDo: больше не нужно
        Map<String, Object> reply = new HashMap<>();
        reply.put("nativeSampleRate", nativeSampleRate);
        reply.put("nativeBuffer", nativeBuffer);
        //reply.put("latencyUntested", latencyUntested);
        result.success(reply);
      }
      else
      {
        result.error("UNAVAILABLE", "Failed to get audio params", null);
      }
    }
    else if (methodCall.method.equals("setScheme"))
    {
      int schemeIndex = methodCall.argument("scheme");
      if (schemeIndex < soundSсhemes.size())
      {
        currentMusicScheme = schemeIndex;


        /*beatMelody = new AccentedMelody(soundSсhemes.get(currentMusicScheme),
                nativeSampleRate, beat.beatCount, beat.subBeats);
         */

        //ToDo: тут я исхожу из того, что flutter пришлёт сначала beat,
        // а потом melody. Так делать конечно нельзя...

        //AccentedMelody melody=new AccentedMelody(soundSсhemes.get(currentMusicScheme),
          //      nativeSampleRate, beatRecieved.beatCount, beatRecieved.subBeats);
        AccentedMelodyMix melody=new AccentedMelodyMix(soundSсhemes.get(currentMusicScheme),
              nativeSampleRate, beatRecieved);
        metroAudio.setMelody(melody);
        beatMelody=melody;
        result.success((int)beatMelody.getMaxTempo());
      }
      else
        result.success(0);
    }
    else if (methodCall.method.equals("getSchemes"))
    {
      ArrayList<String> names = new ArrayList<String>();
      for (int i = 0; i < soundSсhemes.size(); i++)
        names.add(soundSсhemes.get(i).name);
      //if (names.size() > 0)
      result.success(names);
      //channel.invokeMethod("foo", args, new MethodChannel.Result(){
    }
    else
    {
      result.notImplemented();
    }
  }

  void getNativeAudioParams()
  {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN_MR1)
    {
      //Кусок из документации
      AudioManager am = (AudioManager) getSystemService(Context.AUDIO_SERVICE);
      String sampleRateStr = am.getProperty(AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE);
      nativeSampleRate = Integer.parseInt(sampleRateStr);
      if (nativeSampleRate == 0)
        nativeSampleRate = 48000;

      ///Кажется, это физический буфер.
      // См. https://github.com/googlesamples/android-audio-high-performance/issues/92
      String framesPerBuffer = am.getProperty(AudioManager.PROPERTY_OUTPUT_FRAMES_PER_BUFFER);
      nativeBuffer = Integer.parseInt(framesPerBuffer);
      if (nativeBuffer == 0)
        nativeBuffer = nativeSampleRate / 50;

      /*
      //ToDo: незаконно
      try
      {
        //Дало 80 на моём телефоне. Незаконно.
        Method m = am.getClass().getMethod("getOutputLatency", int.class);
        latencyUntested = (Integer) m.invoke(am, AudioManager.STREAM_MUSIC);

        //ToDo: Жесть и мрак - см. файл AudioTrack.java
        /* Returns this track's estimated latency in milliseconds. This includes the latency due
         * to AudioTrack buffer size, AudioMixer (if any) and audio hardware driver.
         *
         * DO NOT UNHIDE. The existing approach for doing A/V sync has too many problems. We need
         * a better solution.
         * @hide
         * /

        //Еще подход (не проверял, отсюда: https://developer.amazon.com/docs/fire-tv/audio-video-synchronization.html#section1-2
        //Method m = android.media.AudioTrack.class.getMethod("getLatency", (Class < ? > []) null);
        //long bufferSizeUs = isOutputPcm ? framesToDurationUs(bufferSize / outputPcmFrameSize) : C.TIME_UNSET;
        //int audioLatencyUs = (Integer) getLatencyMethod.invoke(audioTrack, (Object[]) null) * 1000L - bufferSi

        Log.d(MetroAudioMix.logTagSoundTest, "Latency (from the Method, uuu), ms: " + Integer.toString(latencyUntested));
      }
      catch (Exception e)
      {
        latencyUntested = 100;
        Log.d(MetroAudioMix.logTagSoundTest, "Latency (uneducated guess), ms: " + Integer.toString(latencyUntested));
      }*/
    }
  }

  // Start/stop with given tempo rate
  private void start(int beatsPerMinute)
  {
    //int realTempo = 0;
    //_onStartStopBn(tempo);
    if (metroAudio.state == MetroAudioMix.STATE_READY)
    {
      //_beatsPerMinute = beatsPerMinute;
      metroAudio.play(beatsPerMinute);
      //realTempo = metroAudio.play(beatsPerMinute);

      //ToDo: TEST
    }
    else
    {
      metroAudio.stop();
      //  realTempo = metroAudio.getTempo();
    }

    //if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {

    //return realTempo;
  }

  /*
  // Set new tempo rate
  private int setTempoA(int tempoBpm/*, int noteValue* /)
  {
    int maxTempo = 0;
    //TODO if (!_tempo.equals(tempo))
    {
      //_beatsPerMinute = tempoBpm;//IS: TEST
      maxTempo = metroAudio.setTempo(tempoBpm);
    }
    return maxTempo;
  }*/

  // Тут определяем музыкальные схемы
  private void initSoundSchemes()
  {

    soundSсhemes = new ArrayList<MusicSchemeMix>();
    Resources res = getResources();

    soundSсhemes.add(new MusicSchemeMix("Xylo-marimba,ag", res, R.raw.xylomarimba880, R.raw.xylomarimba440,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Celesta,ag", res, R.raw.celesta880, R.raw.celesta440,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Triangle+claves,ag", res, R.raw.triangle, R.raw.claves,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Pizzakato-Lev,ag", res, R.raw.pizz880, R.raw.pizz440,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("bass(ac)&snare(el),ag", res, R.raw.buss_ac, R.raw.snaredrumelectric232,
            GeneralProsody.AccentationType.Agogic,GeneralProsody.AccentationType.Dynamic));



    //initSoundSchemesExtra();
  }

  /**
   snaredrumelectric232 лучше акустического snaredrumacoustic240
   buss1 лучше акустического buss_ac
   ноты не соединяются с барабанами
   гобой отлично звучит для метра
   */

  private void initSoundSchemesExtra() {


    Resources res = getResources();


    soundSсhemes.add(new MusicSchemeMix("Kuuu", res, R.raw.ku, R.raw.ma,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Cucarecu-Ag", res, R.raw.cucareculong, R.raw.cucarecushort,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("bassandtumb&snare(el),ag", res, R.raw.bassandtumb280, R.raw.snaredrumelectric232,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("oboeA4&snare(el),ag", res, R.raw.oboe_a4_250, R.raw.snaredrumelectric232,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("oboeA4&snare(el),ag", res, R.raw.oboe_a4_250, R.raw.snaredrumacoustic240,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));


    soundSсhemes.add(new MusicSchemeMix("Cucarecu-Ag", res, R.raw.cucareculong, R.raw.cucarecushort,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Cucarecu-Dyn", res, R.raw.cucareculong, R.raw.cucarecushort,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Owls-1", res, R.raw.owl_long, R.raw.owl_short,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("ExtraShort",
            880, 15, 440, 15,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic));

    //Старые добрые бипы
    // ToDo: при настройке звуков из flutter, можно менять именно
    // эту схему, чтобы не плодить их.
    musicSсhemeTunable = new MusicSchemeMix("Bips-A4C5",
            523.25, 30, 440, 30,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic
    );
    soundSсhemes.add(musicSсhemeTunable);


    soundSсhemes.add(new MusicSchemeMix("ShortDrums-1Ag", res, R.raw.short_drum_accent, R.raw.pedal_hihat_weak120,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("ShortDrums-1", res, R.raw.short_drum_accent, R.raw.pedal_hihat_weak120,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Workspace-2Agogic", res, R.raw.bassandtumb280, R.raw.pedal_hihat_weak120,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Workspace-2", res, R.raw.bassandtumb280, R.raw.pedal_hihat_weak120,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Drums-1-Agogic", res, R.raw.drum, R.raw.drum_accent_mono,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("Drums-1", res, R.raw.drum, R.raw.drum_accent_mono,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic));



/*
    soundSсhemes.add( new MusicSchemeMix("ExtraShortAg",
      440, 15, 440, 15,
      GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));
*/
    /*
    soundSсhemes.add(musicSсhemeTunable = new MusicSchemeMix("Bips-agog",
      523.25, 30,440, 25,
      GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));
    */
    soundSсhemes.add(new MusicSchemeMix("WoodblockCabasa-1",
            res, R.raw.woodblock_short1, R.raw.cabasa1,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("WoodblockCabasa-AGOG",
            res, R.raw.woodblock_short1, R.raw.cabasa1,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("WoodblockCabasa-1",
            res, R.raw.woodblock_short1, R.raw.cabasa1,
            GeneralProsody.AccentationType.Dynamic, GeneralProsody.AccentationType.Dynamic));

    soundSсhemes.add(new MusicSchemeMix("WoodblockCabasa-Ag",
            res, R.raw.woodblock_short1, R.raw.cabasa1,
            GeneralProsody.AccentationType.Agogic, GeneralProsody.AccentationType.Dynamic));

    /* //Шлак.
    soundSсhemes.add(
            new MusicSchemeMix("Workspace-1", res, R.raw.bassandtumb60, R.raw.pedal_hihat_weak60,
                    GeneralProsody.AccentationType.Dynamic,GeneralProsody.AccentationType.Dynamic
            ));

    soundSсhemes.add(
            new MusicSchemeMix("Workspace-1Ag", res, R.raw.bassandtumb60, R.raw.pedal_hihat_weak60,
                    GeneralProsody.AccentationType.Agogic,GeneralProsody.AccentationType.Dynamic
            ));
    */
    /*
    soundSсhemes.add(
            new MusicScheme2Bips("SomeUglyShortSeikoPirateDONOTUSE", res,
                    R.raw.drum_accent,R.raw.drum)
    ); //Где-то потерялся один из звуков, ну и нафиг не нужна эта схема.
    */
  }
}
