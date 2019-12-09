import 'dart:core';
import 'dart:typed_data';

import 'SoundPCM16.dart';
import 'BipPauseCycle.dart';

// пределяем число samples в данном числе наносекунд
int nanoSec2samples(int freq, int time)
{
  return (time * freq * 1e-9).round();
}

// Определяем время в наносекундах из samples
int samples2nanoSec(int freq, int samplesN)
{
  return (1e+9 * samplesN / freq).round();
}

// Возвращает время игры бипа согласно штампу и номеру сэмла
// Интерполирует через nativeSampleRate;
int samplePlayTime(int freq, int frameToPlayN, int stampTime, int stampFrame)
{
  return stampTime + samples2nanoSec(freq, frameToPlayN - stampFrame);
}

class BeatMelody extends Melody
{
  BeatMelody(int nativeFreq, double quortaInMSec, int bars, int numerator):
    super(nativeFreq, quortaInMSec, bars, numerator)
  {
    //int framesInQuorta = getSamplesNFromNanos(nativeFreq, (1e+6 * quortaInMSec).toInt());

    SoundPCM16 pcm16 = new SoundPCM16(nativeFreq);

    Uint8List noteB5half = pcm16.noteB5(framesInQuorta * 2, 2, 2);
    Uint8List pause8 = pcm16.silence(framesInQuorta * 2);

    List<Uint8List> notes = [noteB5half, pause8];
    List<int> pauses = [1]; //, 2];
    super.init(notes, pauses);
    //cycle.printFinal();
  }
}

class SingSingMelody extends Melody
{
  SingSingMelody(int nativeFreq, double quortaInMSec):
    super(nativeFreq, quortaInMSec, 9, 1)
  {
    //int framesInQuorta = getSamplesNFromNanos(nativeFreq, (1e+6 * quortaInMSec).toInt());

    SoundPCM16 pcm16 = new SoundPCM16(nativeFreq);

    Uint8List noteB5half = pcm16.noteB5(framesInQuorta * 2, 2, 2);
    Uint8List noteA5half = pcm16.noteA5(framesInQuorta * 2, 2, 2);
    Uint8List noteG5half = pcm16.noteG5(framesInQuorta * 2, 2, 2);
    Uint8List noteB5quorta = pcm16.noteB5(framesInQuorta, 2, 2);
    Uint8List noteB5eighth = pcm16.noteB5(framesInQuorta ~/ 2, 2, 2);
    Uint8List noteA5quorta = pcm16.noteA5(framesInQuorta, 2, 2);
    Uint8List noteG5quorta = pcm16.noteG5(framesInQuorta, 2, 2);
    Uint8List noteE6quorta  = pcm16.noteE6(framesInQuorta, 2, 2);
    Uint8List noteB4half = pcm16.noteB4(framesInQuorta * 2, 2, 2);
    Uint8List noteG5eighth = pcm16.noteG5(framesInQuorta ~/ 2, 2, 2);
    Uint8List noteE5quortaTuk = pcm16.noteE5(framesInQuorta, 2, 4);
    Uint8List pause8 = pcm16.silence(framesInQuorta ~/ 2);

    List<Uint8List> notes = [
      noteB5half, noteA5half,
      noteG5half, noteA5half, //4
      pause8, noteB5quorta, noteB5eighth, noteA5quorta, noteA5quorta, //9
      noteG5quorta, noteA5quorta, noteB5half,
      noteE6quorta, noteE6quorta, noteB5half,
      noteE6quorta, noteE6quorta, noteB5half, //18
      noteB5quorta, noteG5quorta, noteA5quorta, noteB5quorta, //22
      noteA5quorta, noteG5eighth, noteE5quortaTuk, pause8, pause8, pause8, //28
      pause8, pause8, pause8, pause8, pause8, pause8, pause8, pause8, //36
    ];
    //Даём паузам в мелодии значение тишины - это нужно для рисования, чтобы
    //лучше видеть разницу аудио и видео
    List<int> pauses = [4, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35];

    super.init(notes, pauses);
    //cycle.printFinal();
  }

}

// Пример музыкальной схемы: есть конкретные бипы, и соответствующий  им цикл.

class Melody
{
  int frequency;
  int framesInQuorta;

  // Сколько целых тактов в мелодии.
  final int bars;
  final int numerator;

  List<Uint8List> melody;
  List<BipAndPause> bipAndPause;
  BipPauseCycle cycle;

  Melody(this.frequency, double quortaInMSec, this.bars, this.numerator)
  {
    this.framesInQuorta = nanoSec2samples(frequency, (1e+6 * quortaInMSec).toInt());
  }

  void init(List<Uint8List> notes, List<int> pauses)
  {
    melody = notes;

    double pauseFactor = 1.0;//Годится любое неотрицательное значение.
    // ToDo: протестировать арфиметику: задать разные pauseFactor и
    // убедиться, что наименьший темп не меняется. Он зависит лишь от длительности
    // quortaInMSec (ToDo: поменять, это неудобно)
    // TODO vg Why /2?
    bipAndPause = new List<BipAndPause>.generate(melody.length,
        (int i) => new BipAndPause(melody[i].length ~/ 2, pauseFactor));
    /*
    for (int i = 0; i < bipAndPause.length; i++)
    {
      //TODO vg Why /2?
      bipAndPause[i] = new BipAndPause(melody[i].length ~/ 2, pauseFactor);
    }
    */
    cycle = new BipPauseCycle.fromMelody(frequency, bipAndPause, numerator);
    //pausesNms = new int[]{1};//, 2};
    for (int i = 0; i < pauses.length; i++)
      cycle.cycle[pauses[i] * 2].a = cycle.elasticSymbol;
  }
}
