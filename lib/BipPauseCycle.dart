import 'dart:core';
import 'dart:math';
import 'tempo.dart';

///////////////////////////////////////////////////////////////////////////////
// Кусок цикла, представляющий непрерывный отрезок.
// В первом символе нужно начать читать с позиции startInFirst.

// То есть, если мы генерируем массивы для записи в буфер, то алгоритм выглядит так:
// для последовательности массивов symbol_i, 0<=i<n,
// пишем: в Melody[i] пишем durations[i] byte,  начиная от start, где
// если i=0, то start=startInFirst, иначе start=0

class TempoLinear
{
  List<int> symbols;
  List<int> durations;
  int startInFirst;

  // Контрольная. Вернёт считанную суммарную длину. Она всегда должна равняться
  // той, которую мы задаём в TempoCycle, иначе будет крах.
  // @return Общая длительность

  int totalLength()
  {
    int result = 0;
    for (int dur in durations)
      result += dur;
    return result;
  }

  // К первому elastic символу  (если он есть) дописываем целую часть от shareMe
  // и возвращаем дробную часть. Если нет - возвращаем, что было.

  // Это решает проблему с копящейся погрешностью: если время измерять
  // в единицах 1/frequency, то за время работы метронома
  // порядка часа можно набрать  существенное (треть секунды?)
  // отклонение от данного tempo.

  // Более точным решением было бы распределить накопившуюся погрешность
  // между всеми бипами, но следующее рассуждение показывает, что этого можно не делать.

  // А именно, мы полагаем, что длина бипов фиксирована, и мы знаем их время точно.
  // Ошибка не накапливается в них, она накапливается за
  // счет длины тишины (elastic elements).
  // Если тищина и бипы чередуются, то за один  цикл записи
  // (который и представляет TempoLinear)
  // погрешность составит порядка symbols.length/2 сэмплов.

  // Привер: частота 44100, размер буфера 1024,
  // желаемое время на размер буфера 160мс. Получится (при округлении
  // до целого числа буферов на половину большого буфера) порядка 186 мс
  // на цикл.  При максимальной скорости 240 и 16х долях имеем
  // погрешность <1 фрейма за 62.5 мс, то есть не более трёх за итерацию записи в буфер.
  // Это порядка 0.07 мс. Можно не парится и не распределять, и прицепить к первой
  // тишине.
  // ToDo:
  // больше не нужна, реализвана прямо при выгрузке. Храним из-за прекрасного
  //  комментария.

  double compensate(double addMe, int elasticSymbol)
  {
    for (int i = 0; i < symbols.length; i++)
    {
      if (symbols[i] == elasticSymbol)
      {
        int inc = addMe.toInt();
        durations[i] += inc;
        return  addMe - inc;
      }
    }
    return addMe;
  }

  final String tagForPrint = "TempoTest ";

  void printme()
  {
    print(tagForPrint + "------LINEAR------");

    int total = totalLength();
    print(tagForPrint + "Total, offset in fist: " + total.toString() + ", " + startInFirst.toString());

    String elements = "";
    for (int a in symbols){
      elements += a.toString()+" ";
    }
    print(tagForPrint + "Elements a_0,a_1...: " + elements);


    String lengthesS = "";
    for (int l in durations){
      lengthesS += l.toString() + " ";
    }
    print(tagForPrint + "durations: " + lengthesS);
  }
}

class BipPauseCycle
{
  //final int _bars = 9;
  int _nativeSampleRate;

  Position position;
  Position getPosition() => position;

  int numerator;
  List<Pair> cycle = [];

  // Все элементы на нечетных позициях имеют этот символ
  int elasticSymbol;
  // Начальные длины для длин нечетных элементов
  List<double> initElasticDurations = [];
  // Дробные части длин нечетных элементов цикла
  List<double> fractionParts = [];

  //  Общая длительность бипов. Вроде больше не нужна ни для чего.
  int totalNonElasticDuration;

  // Накопившеяся ощибка. Принадлежит [0,2)
  double accumulatedError;

  int totalErrorsCorrected; // TODO CHECK was long

  // Точная длительность всего цикла при создании
  double initDuration;

  // Точная длительность всего цикла
  double duration;

  // Какую минимальную длительность мы можем потребовать от цикла.
  // leastDuration=initDuration*leastDilationRatio
  double leastDuration;

  // Поскольку длины звуков мы не меняем, этот коэффициент равен
  // минимуму 1/(d_i+1), взятому по элементам цикла
  double leastDilationRatio;

  /// time - time from begin in seconds
  Position timePosition(double time)
  {
    double samples = time * _nativeSampleRate;
    Position pos = new Position(0, 0);
    pos.cycle = samples ~/ duration;
    samples = samples % duration;

    double dur = 0;
    for (int i = 0; i < cycle.length / 2; i++)
    {
      pos.n = i;
      double length = cycle[2*i].len + cycle[2*i+1].len + fractionParts[i];
      dur += length;
      if (dur > samples)
      {
        pos.offset = (length - dur + samples) ~/ 1;
        break;
      }
    }

    return pos;
  }

  // Элементы цикла на нечетных местах меняют длину.
  // Если позиция указывает на такой элемент, то она меняется
  // внутри отрезка
  // [начало bip, конец bip+silence] так, чтобы отношение сыгранного к оставшемуся
  // не поменялось.
  // Звуки же мы всегда доигрыаем до конца, иначе будут щелчки.

  // newDuration Новая длительность (seconds). В силу арифметических причин ограничена снизу leastDuration.
  //             Будет установлена (с определенной точностью), если не меньше  leastDuration+1.

  //vg TODO Support sound with 0 pause
  void setNewDuration(double newDuration)
  {
    accumulatedError = 0;

    print('setNewDuration::newDuration: $newDuration');

    // Математически верно так:
    // if (newDuration<leastDuration)newDuration=leastDuration;
    // Но вероятно могут возникнуть очень маленькие отрицательные
    // значения у новых длительностей.
    if (newDuration < leastDuration)
      newDuration = leastDuration;
    //ToDo: проверить без 1.1

    // Считаем новые длительности и остатки
    double ratio = newDuration / initDuration;
    // Stretch pauses keeping sounds at constant duration
    for (int i = 0; i < cycle.length / 2; i++)
    {
      int durSound = cycle[2*i].len;
      double durPause = (initElasticDurations[i] + durSound) * ratio - durSound;
      cycle[2*i+1].len = durPause.toInt();
      fractionParts[i] = durPause % 1;

      //print('$i - ${cycle[2*i +1].len}');
    }

    // Stretch current position if it's playing pause at the moment
    ratio = newDuration / duration;
    if (position.n % 2 == 1)
    {
      int durSound = cycle[position.n-1].len;
      position.offset = max((position.offset + durSound) * ratio - durSound, 0).toInt();
    }

    // Full new duration of cycle
    duration = 0;
    for (int i = 0; i < cycle.length / 2; i++)
      duration += cycle[2*i].len + cycle[2*i+1].len + fractionParts[i];

    //print(duration  );
  }

  // Создаём цикл из последовательности букв и длин
  // (полагаем, что эти две последовательности одной длины; в противном случае
  // длина цикла определяется по более короткой).

  // @param symbols символы для звуков
  // @param elasticSymbol символ для паузы
  // @param bipsAndPauses Длины звуков и следующих за ними пауз.
  //                      Длина следующей за бипом тишины определеятся как int(bipDuration*pauseFactor)
  //                      Паузы должны быть неотрицацельны.

  // @param numerator  Сколько повторений внутри цикла.

  BipPauseCycle(List<int> symbols, int elasticSymbol, List<BipAndPause> bipsAndPauses,
    int nativeSampleRate, int numerator)
  {
    this._nativeSampleRate = nativeSampleRate;
    this.numerator = numerator;
    this.elasticSymbol = elasticSymbol;

    position = new Position(0, 0);
    accumulatedError = 0;
    totalErrorsCorrected = 0;

    int lengthMin = min(symbols.length, bipsAndPauses.length);
    cycle = new List<Pair>(lengthMin * 2 * numerator);
    initElasticDurations = new List<double>(lengthMin * numerator);
    fractionParts = new List<double>(lengthMin * numerator);
    // Initialize cycle from SoundPause array
    for (int j = 0; j < numerator ; j++)
    {
      int pref = j * lengthMin;
      for (int i = 0; i < lengthMin; i++)
      {
        // Sound
        cycle[2*(i + pref)] = new Pair(symbols[i], bipsAndPauses[i].bipDuration);
        // Pause
        double dur = bipsAndPauses[i].bipDuration * bipsAndPauses[i].pauseFactor;
        cycle[2*(i + pref) + 1] = new Pair(elasticSymbol, dur.toInt());
        //vg ???
        // Хотим, чтобы накапливающаяся погрешность была положительна,
        // поэтому  берём целую часть. Если брать округление, но
        // тогда нужно следить за отрицательными погрешностями.
        fractionParts[i + pref] = dur % 1;
        initElasticDurations[i + pref] = dur;
      }
    }

    // Определяем точную длительность цикла
    double duration1 = bipsAndPauses.fold(0.0,
      (double prev, BipAndPause x) => prev + (1.0 + x.pauseFactor) * x.bipDuration);

    duration = 0.0;
    for (int i = 0; i < bipsAndPauses.length; i++)
      duration += (1.0 + bipsAndPauses[i].pauseFactor) * bipsAndPauses[i].bipDuration;
    assert(duration1 == duration);

    duration *= numerator;
    initDuration = duration;

    // Определяем наименьший коэффициэнт сжатия и наименьшую длину
    // vg??? The least possible pause duration can not be less than 0 OR 1 sample
    double leastDil = 0.0;
    double d;
    for (int i = 0; i < bipsAndPauses.length; i++)
    {
      d = 1.0 / (bipsAndPauses[i].pauseFactor + 1);
      if (leastDil < d)
        leastDil = d;
    }
    leastDilationRatio = leastDil;
    leastDuration = leastDilationRatio * initDuration;
  }

  // Конструктор для длинной мелодии
  // ToDo: рассказть, почему и  как
  // @param bipsAndPauses
  // @param numerator

  BipPauseCycle.fromMelody(int nativeSampleRate, List<BipAndPause> bipsAndPauses, int numerator):
    this(diagonal(bipsAndPauses.length), bipsAndPauses.length, bipsAndPauses, nativeSampleRate, numerator);

  static List<int> diagonal(int length)
  {
    //List<int> res = new List<int>(length);
    //for (int i = 0; i < res.length; i++)
    //  res[i] = i;
    return new List<int>.generate(length,  (int i) => i);
  }

  List<int> symbolsToRead;
  List<int> sizesToRead;

  // Выбираем по кругу от данной позиции, пока не наберём суммарную длину
  // элементов алфавита.

  // Это решает проблему с копящейся погрешностью: если время измерять
  // в единицах 1/frequency, то за время работы метронома
  // порядка часа можно набрать  существенное (треть секунды?)
  // отклонение от данного tempo. Поэтому мы копим дробную ошибку  в пределах
  // [0,2) и периодически уменьшаем её на 1, дописывая (один сэпмл) к длительности
  // выгружаемого  elastic.

  // samples - длина элементов в сэмплах
  // @return считанный массив символов,  с указанием начала воспроизведения
  // в первом символе и того, сколько нужно записать в буфер

  TempoLinear readTempoLinear(int samples)
  {
    TempoLinear result = new TempoLinear();
    result.startInFirst = position.offset;

    symbolsToRead = new List<int>();
    sizesToRead = new List<int>();

    int freeSpace;
    int lastToRead;
    int toRead = samples;
    bool compensateError;
    while (toRead > 0)
    {
      //элемент алфевита для выбираемой пары:
      symbolsToRead.add(cycle[position.n].char);
      //сколько места осталось в данном элементе цикла:
      freeSpace = cycle[position.n].len - position.offset;

      //compensateError указывает, что мы в тишине и накопилась погрешность
      compensateError = (position.n % 2 == 1) && (accumulatedError >= 1);
      if (compensateError)
        freeSpace += 1;

      if (freeSpace <= toRead) //идём в след. элемент цикла
      {
        lastToRead = freeSpace;

        //Увеличив раньше на 1 freespace, мы скомпенсировали ошибку
        if (compensateError)
        {
          accumulatedError -= 1;
          totalErrorsCorrected++;
        }
        //Мы дочитали кусок тишины, и нам нужно сохранить его погрешность
        if (position.n % 2 == 1)
        {
          accumulatedError += fractionParts[position.n ~/ 2];
        }

        //Теперь переходим:
        position.n = (position.n + 1) % cycle.length;
        position.offset = 0;
        toRead -= freeSpace; //считали всё, что было в этом элементе, до конца
      }
      else
      {
        position.offset += toRead;
        lastToRead = toRead;
        toRead = 0;
      }
      sizesToRead.add(lastToRead);
    }
    result.symbols = symbolsToRead;
      //new Integer[0]); //Тип объекта определяется через пустую последовательность этих объектов.
    result.durations = sizesToRead;
    // .toArray(new Integer[0]); //Какой же уёбищный язык...)))
    return result;
  }

  final String tagForPrint="TempoTest ";

  void printme()
  {
    printFinal();
    printVariable();
  }

  void printFinal(){
    print(tagForPrint + "CYCLE, final");

    String elements = "";
    for (Pair pair in cycle)
    {
      elements+= " (" + pair.char.toString()+"," + pair.len.toString() + ")";
    }
    print(tagForPrint+"Elements: (a_0,length_0), (a_1,length_1)...:"+elements+"\n");

    print(tagForPrint +
      "Init duration, least Duration, leastDilationRatio: " +
        initDuration.toString() + ", " +
        leastDuration.toString() + ", " +
        leastDilationRatio.toString());
    // TODO  String.format("%.3f, %.3f, %.4f",

    elements = "";
    for (double d in initElasticDurations)
    {
      elements += " " + d.toString();  // TODO String.format("%.3f"
    }
    print(tagForPrint + "initElasticDurations: " + elements + "\n");
  }

  void printPosition()
  {
    print(tagForPrint + "Position: number=" + position.n.toString() + ", offset=" + position.offset.toString());
  }

  void printVariable()
  {
    print(tagForPrint + "CYCLE, variable");
    print(tagForPrint + "Position: number=" + position.n.toString() + ", offset=" + position.offset.toString());

    print(tagForPrint+"Duration, error, frames corrected: "+
      duration.toString() + ", " + accumulatedError.toString() + ", " + totalErrorsCorrected.toString());  // TODO String.format("%.3f, %.3f, %d"

    String elements="";

    for (int i = 0; i < cycle.length/2; i++)
    {
      elements += " " + cycle[2*i+1].len.toString() + ", " + fractionParts[i].toString() + ";";  // TODO String.format("%d, %.3f;"
    }
    print(tagForPrint + "elasticLengths, fractionParts: " + elements);
  }

  // Пересчитываем  темпо (традиционный, дуракций) в длительность цикла в сэмплах,
  // исходя из того, сколько там bars (то есть, какова его длина в нотах)
  // и частоты (то есть, длительности одного сэмпла). Может быть больше, чем
  // возможная длина.
  // (В случае простого метронома bars=1.)
  // tempo - музыкальный темп
  // @return - длительность цикла при данном tempo (in seconds)
  double tempoToCycleDuration(Tempo tempo, int bars, int nativeSampleRate)
  {
    print('tempoToCycleDuration: ${tempo.beatsPerMinute}, ${tempo.denominator}, $bars, $nativeSampleRate');

    int beatsPerCycle = bars * tempo.denominator;
    double samplesPerBeat = nativeSampleRate * 60.0 / tempo.beatsPerMinute;
    return samplesPerBeat * beatsPerCycle;
  }

  // Каков будет темп при данной длительности цикла в сэмплах. Зависит от bars и
  //  частоты.
  // @param durationInFrames какую длительность в сэмплах переводим в tempo
  // @param denominator какой у темпо знаменатель
  // @return ударов, соответствующим denominator, в минуту при данной длине цикла
  double cycleDurationToBeatsPM(double durationInFrames, int denominator,
    int bars, int nativeSampleRate)
  {
    double durInMins = durationInFrames / (nativeSampleRate * 60.0);
    int totalBeatsPerCycle = bars * denominator;
    return totalBeatsPerCycle.toDouble() / durInMins;
  }

  // Это прообраз общей процедуры, определяющий минимальный темп по данной
  // звуковой схеме. Результат дробный, поэтому нужно его округлить
  // в "простой схеме" (когде нет свободного метра, а мы привязаны к музыкальной архаике).
  // Напонмю, что максимальная скорость (наименьшая длительность цикла) зависят от ужимаемых
  // elastic's и предшествующих несжимаемых звуков. Иными словами, она зависит от кратчайших бипов
  // в музыкальной схеме и их доле в сумме со следующей паузой.
  // Совсем огрубляя: чем короче бипы - тем быстрее можно играть (естественно).
  // @param denominator в чем исчисляется ритм (4,8,16)
  // @return наибольший темп, который мы можем установить для цикла при данном знаменателе
  double getMaximalTempo(int denominator, int bars)
  {
    return cycleDurationToBeatsPM(leastDuration, denominator, bars, _nativeSampleRate);
  }


  // Устанавливаем новую длительность цикла. Имеется арифметическое ограничение снизу
  // (см. getMaximalTempo).
  // @param tempo музыкальный ритм
  // @return установленных ударов в минуту
  int setTempo(Tempo tempo, int bars)
  {
    int newBpM = min(getMaximalTempo(tempo.denominator, bars).toInt(),
      tempo.beatsPerMinute);
    setNewDuration(tempoToCycleDuration(
      new Tempo(beatsPerMinute: newBpM, denominator: tempo.denominator),
      bars, _nativeSampleRate));
    return newBpM;
  }
}
