import 'dart:core';
import 'dart:typed_data';

import 'tempo.dart';
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
      cycle.cycle[pauses[i] * 2].char = cycle.elasticSymbol;
  }
}
