package com.owlenome.owlenome;

import android.content.Context;
import android.content.res.Resources;
import android.media.AudioManager;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.Message;
import android.util.Log;

import java.lang.reflect.Method;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import io.flutter.app.FlutterActivity;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugins.GeneratedPluginRegistrant;


// Same as beat_metre.dart::BeatMetre
class BeatMetre
{
  int beatCount;
  int subBeatCount;
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
}




public class MainActivity extends FlutterActivity implements MethodChannel.MethodCallHandler
{
  private static final String SOUND_CHANNEL = "samples.flutter.io/owlenome";

  private MethodChannel channel;

  int nativeSampleRate = 0;
  int nativeBuffer;
  int latencyUntested; //ToDo
  // Previous tempo value to compare with a new one
  Tempo _tempo = new Tempo(1, 1);
  // Beat setOfNotes
  AccentedMelody beatMelody = null;
  MetroAudioProbnik metroAudio;

  // Sound schemes
  // Сюда собираем пары звуков.
  List<MusicScheme2Bips> soundSсhemes;
  MusicScheme2Bips musicSсhemeTunable;
  int currentMusicScheme = 0;

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
      @Override
      public void handleMessage(Message msg)
      {
        if (msg.what == MetroAudioProbnik.STATE_PLAYING)
        {
          if (msg.arg2 == -1)
          {
            //STATE_STARTING
            System.out.println("WARMEDUP");
            channel.invokeMethod("warmedUp", msg.arg1);
          }
          else
          {
            //long totalWrittenFrames = (((long) msg.arg2) << 32) + (long) msg.arg1;
            //channel.invokeMethod("timeFrame", totalWrittenFrames);
            //long arg = (msg.arg1 & 0xFFFFFFFFL) & ((msg.arg2 >> 32) & 0xFFFFFFFFL);
            Map<String, Object> args = new HashMap<>();
            args.put("note", msg.arg1);
            args.put("offset", 0);
            args.put("cycle", msg.arg2);
            channel.invokeMethod("timeFrame", args);
          }
        }
      }
    };

    metroAudio = new MetroAudioProbnik(nativeSampleRate, nativeBuffer,
      120, //1000.0/8 --- 240;16,; 1280 - 64 буфера;
      // 160 - основной кандидат (8 моих буферов)
      handler);

    channel = new MethodChannel(getFlutterView(), SOUND_CHANNEL);
    channel.setMethodCallHandler(this);
  }

  @Override
  public void onMethodCall(MethodCall methodCall, MethodChannel.Result result)
  {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.KITKAT)
    {
      result.notImplemented();
      return;
    }

    BeatMetre beat = new BeatMetre();

    if (methodCall.method.equals("start"))
    {
      _tempo.beatsPerMinute = methodCall.argument("tempo");
      _tempo.denominator = methodCall.argument("note");

      boolean res = false;
      if (beatMelody != null)
        res = start(_tempo);
      if (res)
        //List<Map<Double, Integer> a = new HashMap<>
        result.success(res);
      else
        result.error("UNAVAILABLE", "Failed starting sound", null);
    }
    else if (methodCall.method.equals("setBeat"))
    {
      //IS:
      // Get beat parameters from Flutter
   //   BeatMetre beat = new BeatMetre();

      List<Integer> config = methodCall.argument("config");
      if (config.size() >= 3)
      {
        beat.beatCount = config.get(0);
        beat.subBeatCount = config.get(1);
        int schemeIndex = config.get(2);
        if (schemeIndex < soundSсhemes.size())
          currentMusicScheme = schemeIndex;
      }
      if (config.size() >= 7)
      {
        /*
        //ToDo: меняем параметры musicSсhemeTunable

        beat.beatFreq = 0.001 * config.get(3);
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
        assert (beat.subBeatCount == subBeats.size());
        beat.subBeats = new ArrayList<Integer>(subBeats);
      }
      else
      {
        beat.subBeats = new ArrayList<Integer>();
        assert (beat.subBeats.size() == beat.beatCount);
        for (int i = 0; i < beat.beatCount; i++)
          beat.subBeats.add(beat.subBeatCount);
      }

      //>>>>>> IS!
      // Accents array
      List<Integer> accents = methodCall.argument("accents");
      if (accents.size() > 0)
      {
        beat.accents = new ArrayList<Integer>(accents);
      }

      beatMelody = new AccentedMelody(soundSсhemes.get(currentMusicScheme),
        nativeSampleRate, beat.beatCount, beat.subBeats);
      //IS
      // Create new metronome beat setOfNotes
      metroAudio.setMelody(beatMelody);

/*//IS: Do we need this? Seems that we already have it.
        List<Double> bipsAndPauses = new ArrayList<Double>();
        for (int i = 0; i < metroAudio.melody._bipAndPauseSing.length; i++)
        {
          bipsAndPauses.add((double) metroAudio.melody._bipAndPauseSing[i].bipDuration);
          bipsAndPauses.add(metroAudio.melody._bipAndPauseSing[i].pauseFactor);
        }
        if (bipsAndPauses.size() > 0)
          //List<Map<Double, Integer> a = new HashMap<>
          result.success(bipsAndPauses);
        else
          result.error("UNAVAILABLE", "Failed creating sound", null);
*/
      //else
      //result.error("UNAVAILABLE", "Failed creating sound", null);
      result.success(1);
    }
    else if (methodCall.method.equals("setTempo"))
    {
      int tempoBpm = methodCall.argument("tempo");
      int noteValue = methodCall.argument("note");
      int res = setTempo(tempoBpm, noteValue);
      result.success(res);
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
      {
        Map<String, Object> reply = new HashMap<>();
        reply.put("nativeSampleRate", nativeSampleRate);
        reply.put("nativeBuffer", nativeBuffer);
        reply.put("latencyUntested", latencyUntested);
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
        result.success(1);
    }
      else
        result.success(0);
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
         */

        //Еще подход (не проверял, отсюда: https://developer.amazon.com/docs/fire-tv/audio-video-synchronization.html#section1-2
        //Method m = android.media.AudioTrack.class.getMethod("getLatency", (Class < ? > []) null);
        //long bufferSizeUs = isOutputPcm ? framesToDurationUs(bufferSize / outputPcmFrameSize) : C.TIME_UNSET;
        //int audioLatencyUs = (Integer) getLatencyMethod.invoke(audioTrack, (Object[]) null) * 1000L - bufferSi

        Log.d(MetroAudioProbnik.logTagSoundTest, "Latency (from the Method, uuu), ms: " + Integer.toString(latencyUntested));
      }
      catch (Exception e)
      {
        latencyUntested = 100;
        Log.d(MetroAudioProbnik.logTagSoundTest, "Latency (uneducated guess), ms: " + Integer.toString(latencyUntested));
      }
    }
  }

  // Start/stop with given tempo rate
  private boolean start(Tempo tempo)
  {
    boolean res = true;
    //_onStartStopBn(tempo);
    if (metroAudio.state == MetroAudioProbnik.STATE_READY)
    {
      _tempo = tempo;
      res = metroAudio.play(tempo);// + minimalTempoBPM);

      //ToDo: TEST
    }
    else
    {
      metroAudio.stop();
    }

    /*
    if (VERSION.SDK_INT >= VERSION_CODES.LOLLIPOP) {
    } else {
    }
    */
    return res;
  }

  // Set new tempo rate
  private int setTempo(int tempoBpm, int noteValue)
  {
    Tempo tempo = new Tempo(tempoBpm, noteValue);
    Log.d("setTempo", "Tempo: " + Integer.toString(tempo.beatsPerMinute));
    if (!_tempo.equals(tempo))
    {
      _tempo = tempo;
      metroAudio.setTempo(tempo);// + minimalTempoBPM);
      return 1;
    }
    else
      return 0;
  }

  public void _onStartStopBn(Tempo tempo)
  {
    if (metroAudio.state == MetroAudioProbnik.STATE_READY)
    {
      //ToDo: сделать булевым, и если false - значит, мы не запустились
      //metroAudio.play(seekBar.getProgress()+minimalTempoBPM);
      //int tempo = 300;

      metroAudio.play(tempo);// + minimalTempoBPM);

      _tempo = tempo;
      //ToDo: TEST
    /*
    BarrelOrgan.draw(cvMetr,metroAudio.singSingSing.cycleSing,
            0,
            oval,paint );
    ivMetr.invalidate();*/
      //  bnPlayStop.setText("Started");
    }
    else
    {
      //bnPlayStop.setText("Play");
      if (!_tempo.equals(tempo))
      {
        _tempo = tempo;
        metroAudio.setTempo(_tempo);// + minimalTempoBPM);
      }
      else
        metroAudio.stop();
    }
  }

  // Тут определяем музыкальные схемы
  private void initSoundSchemes()
  {
    soundSсhemes = new ArrayList<MusicScheme2Bips>();

    //Старые добрые бипы
    // ToDo: при настройке звуков из flutter, можно менять именно
    // эту схему, чтобы не плодить их.
    musicSсhemeTunable = new MusicScheme2Bips("Bips-A4C5",
      440, 25, 523.25, 35);
    soundSсhemes.add(musicSсhemeTunable);

    Resources res = getResources();
    soundSсhemes.add(
      new MusicScheme2Bips("Drums-1", res, R.raw.drum_accent_mono, R.raw.drum));
    soundSсhemes.add(
      new MusicScheme2Bips("WoodblockCabasa-1", res, R.raw.woodblock_short1, R.raw.cabasa1));
    soundSсhemes.add(
      new MusicScheme2Bips("ShortDrums-1", res, R.raw.short_drum_accent, R.raw.short_drum1));
    /*soundSсhemes.add(
            new MusicScheme2Bips("SomeUglyShortSeikoPirateDONOTUSE", res,
                    R.raw.drum_accent,R.raw.drum)
    ); //Где-то потерялся один из звуков, ну и нафиг не нужна эта схема.
    */
  }
}
