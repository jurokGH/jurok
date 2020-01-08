package com.owlenome.owlenome;

import java.util.ArrayList;
import java.util.List;


class BipAndPause//ToDo: Зачем? Дублирует Pair
{
  int bipDuration;
  double pauseFactor;

  BipAndPause(int bipDuration, double pauseFactor)
  {
    this.bipDuration = bipDuration;
    this.pauseFactor = pauseFactor;
  }

  public double duration()
  {
    return (1 + pauseFactor) * bipDuration;
  }
}

/**
 * Представляет ритм. Чередующиеся длительности звуков и пауз.
 * Длительности звуков - положительные целые, соответствующая звуку пауза -
 * положительное действительное число (более точно - неотрицательное, но в этом случае
 * нельзя изменять абсолютную длительность).
 * <p>
 * Длительность паузы после bipsLengths[i] равна d[i]* bipsLengths[i]
 * <p>
 * //ToDo: убрать.
 * class TempoScheme{
 * BipAndPause[] lengths;
 * int totalLength;
 * }
 */

/**
 * Имеется цикл четной длины 2n, представленный последовательностью
 * пар (a_0,l_0), (e,l_0*d_0)..., (a_{n-1},l_{n-1}), (e,l_{n-1}*d_{n-1}).
 * Пара - элемент некоторого множества (алфавита), и его длительность.
 * На нечетных позициях находится специальный символ e (elastic). Он представляет
 * переменную длину (паузу).
 * Длины нечетных элементов можно менять, длины четных - нельзя.
 * Элементы на четных позициях называются звуками (или бипами).
 *
 * На месте бипа может быть эластик, но его длина не будет меняться.
 * На месте эластика звука быть не должно. (Эластик может быть бипом, но не наоборот)
 *
 * У цикла есть длительность - действительное число, равное суммам его длин.
 * А также есть целочисленная суммарная длина.
 */
public class BipPauseCycle
{
  /**
   * Представляет элемент цикла:
   * a - элемент алфавита
   * l - его длина
   */
  class Pair
  {
    public int a;  // Alphabet's char
    public int l;  // Its length

    public Pair(int a, int l)
    {
      this.a = a;
      this.l = l;
    }
  }

  /**
   * Кусок цикла, представляющий непрерывный отрезок.
   * В первом символе нужно начать читать с позиции startInFirst.
   *
   * То есть, если мы генерируем массивы для записи в буфер, то алгоритм выглядит так:
   * для последовательности массивов symbol[i], 0<=i<n,
   * пишем: в Melody[i] пишем durations[i] byte,  начиная от start, где
   * если i=0, то start=startInFirst, иначе start=0
   */
  class TempoLinear
  {
    Integer[] symbols;
    Integer[] durations;
    int startInFirst;

    //Position pos; //IS: Зачем может быть нужна позиция в этом списке?
    //


    /**
     * Контрольная. Вернёт считанную суммарную длину. Она всегда должна равняться
     * той, которую мы задаём в TempoCycle, иначе будет крах.
     * @return Общая длительность
     */
    int totalLength()
    {
      int result = 0;
      for (int dur : durations)
        result += dur;
      return result;
    }

    /**
     * К первому elastic символу  (если он есть) дописываем целую часть от shareMe
     * и возвращаем дробную часть. Если нет - возвращаем, что было.
     *
     * Это решает проблему с копящейся погрешностью: если время измерять
     * в единицах 1/frequency, то за время работы метронома
     * порядка часа можно набрать  существенное (треть секунды?)
     * отклонение от данного tempo.
     *
     * Более точным решением было бы распределить накопившуюся погрешность
     * между всеми бипами, но следующее рассуждение показывает, что этого можно не делать.
     *
     * А именно, мы полагаем, что длина бипов фиксирована, и мы знаем их время точно.
     * Ошибка не накапливается в них, она накапливается за
     * счет длины тишины (elastic elements).
     * Если тищина и бипы чередуются, то за один  цикл записи
     * (который и представляет TempoLinear)
     * погрешность составит порядка symbols.length/2 сэмплов.
     *
     * Привер: частота 44100, размер буфера 1024,
     * желаемое время на размер буфера 160мс. Получится (при округлении
     * до целого числа буферов на половину большого буфера) порядка 186 мс
     * на цикл.  При максимальной скорости 240 и 16х долях имеем
     * погрешность <1 фрейма за 62.5 мс, то есть не более трёх за итерацию записи в буфер.
     * Это порядка 0.07 мс. Можно не парится и не распределять, и прицепить к первой
     * тишине.
     * //ToDo:
     * больше не нужна, реализвана прямо при выгрузке. Храним из-за прекрасного
     *  комментария.
     */
    private double compensate(double addMe)
    {
      for (int i = 0; i < symbols.length; i++)
      {
        if (symbols[i] == elasticSymbol)
        {
          int inc = (int) addMe;
          durations[i] += inc;
          return addMe - inc;
        }
      }
      return addMe;
    }


    public void print()
    {
      System.out.println(tagForPrint + "------LINEAR------");

      System.out.printf(tagForPrint + "Total, offset in fist: %d, %d\n", totalLength(), startInFirst);

      String elements = "";
      for (Integer a : symbols)
      {
        elements += a.toString() + " ";
      }
      System.out.printf(tagForPrint + "Elements a_0,a_1...: " + elements + "\n");


      String lengthesS = "";
      for (Integer l : durations)
      {
        lengthesS += l.toString() + " ";
      }
      System.out.printf(tagForPrint + "durations: " + lengthesS + "\n");
    }
  }


  /**
   * Представляет позицию в цикле:
   *  n - номер элемента цикла, offset - смещение.
   */
  class CyclePosition {
    public int n;
    public int offset;
    public CyclePosition (int n, int offset){this.n=n; this.offset=offset;}
  }

  /**
   * Позиция в нашем цикле, меняющаяся при считывании через TempoLinear
   */
  CyclePosition position;

  /**
   * UNTESTED
   * сколько раз прошли по кругу, считывая из массива TempoLinear;
   */
  int cycleCount;

  public CyclePosition getPosition()
  {
    return position;
  }

  final int numerator;
  final Pair[] cycle;

  /**
   *  Начальные значения длины для длин нечетных элементов (пауз)
   */
  final double[] initElasticDurations;

    /*
     *
     *  Общая длительность бипов. Вроде больше не нужна ни для чего.
    final int totalNonElasticDuration;*/

  /**
   * Дробные части длин нечетных элементов цикла (пауз)
   */
  double[] fractionParts;

  /**
   * Накопившеяся ощибка. Принадлежит [0,2)
   */
  double accumulatedError;

  public long totalErrorsCorrected;

  /**
   * Все элементы на нечетных позициях (паузы) имеют этот символ
   */
  final int elasticSymbol;

  /**
   * Точная длительность всего цикла при создании.
   */
  final double initDuration;

  /**
   * Точная длительность всего цикла.
   */
  double duration;

  /**
   * Какую минимальную длительность мы можем потребовать от цикла.
   * leastDuration = initDuration * leastDilationRatio
   */
  final double leastDuration;

  /**
   *
   * Поскольку длины звуков мы не меняем, этот коэффициент равен
   * минимуму 1/(d_i+1), взятому по элементам цикла
   */
  final double leastDilationRatio;



  /**
   * Каков будет темп при данной длительности цикла в сэмплах. Зависит от bars и
   * частоты.
   *
   * IS: New, 05.01.2019
   *
   * @param durationInFrames какую длительность в сэмплах переводим в tempo
   * @param beatsInCycle   сколько битов в цикле
   * @return ударов, соответствующим denominator, в минуту при данной длине цикла
   */
  public double cycleDurationToBeatsPM(int frequency, double durationInFrames, int beatsInCycle)
  {
    double durInMins = durationInFrames / (frequency * 60.0);
    return ((double) beatsInCycle) / durInMins;
  }


  /**
   * Это прообраз общей процедуры, определяющий максимальный темп по данной
   * звуковой схеме. Результат дробный, поэтому нужно его округлить
   * в "простой схеме" (когде нет свободного метра, а мы привязаны к музыкальной архаике).
   * Напонмю, что максимальная скорость (наименьшая длительность цикла) зависят от ужимаемых
   * elastic's и предшествующих несжимаемых звуков. Иными словами, она зависит от кратчайших бипов
   * в музыкальной схеме и их доле в сумме со следующей паузой.
   * Совсем огрубляя: чем короче бипы - тем быстрее можно играть (естественно).
   *
   *
   * IS: New, 05.01.2019
   *
   * @param beatsInCycle   сколько beats (с точни зрения BMP) в цикле
   * @return наибольший темп (BPM), который мы можем установить для цикла
   */
  public double getMaximalTempo(int frequency, int beatsInCycle)
  {
    return cycleDurationToBeatsPM(frequency, leastDuration, beatsInCycle);
  }


  /**
   * Каков будет темп при данной длительности цикла в сэмплах.
   *
   * @param durationInFrames какую длительность в сэмплах переводим в tempo
   * @param denominator      какой у темпо знаменатель
   * @return ударов, соответствующим denominator, в минуту при данной длине цикла
   */
  public double cycleDurationToBeatsPM(int frequency, double durationInFrames, int bars, int denominator)
  {
    double durInMins = durationInFrames / (frequency * 60.0);
    int totalBeatsPerCycle = bars * denominator;
    return ((double) totalBeatsPerCycle) / durInMins;
  }


  /**
   * Это прообраз общей процедуры, определяющий максимальный темп по данной
   * звуковой схеме. Результат дробный, поэтому нужно его округлить
   * в "простой схеме" (когде нет свободного метра, а мы привязаны к музыкальной архаике).
   * Напонмю, что максимальная скорость (наименьшая длительность цикла) зависят от ужимаемых
   * elastic's и предшествующих несжимаемых звуков. Иными словами, она зависит от кратчайших бипов
   * в музыкальной схеме и их доле в сумме со следующей паузой.
   * Совсем огрубляя: чем короче бипы - тем быстрее можно играть (естественно).
   *
   * @param denominator значения нот в чем исчисляется ритм (4,8,16)
   * @param bars скольно тактов в цикле
   * @return наибольший темп, который мы можем установить для цикла при данном знаменателе
   */
  public double getMaximalTempo(int frequency, int bars, int denominator)
  {
    return cycleDurationToBeatsPM(frequency, leastDuration, bars, denominator);
  }

  /**
   * Элементы цикла на нечетных местах меняют длину.
   * Если позиция указывает на такой элемент, то она меняется
   * внутри отрезка [начало bip, конец bip+silence] так,
   * чтобы отношение сыгранного к оставшемуся не поменялось.
   * Звуки же мы всегда доигрыаем до конца, иначе будут щелчки.
   *
   * @param newDuration Новая длительность. В силу арифметических причин ограничена снизу leastDuration.
   *                    Будет установлена (с определенной точностью), если не меньше  leastDuration+1.
   */
  public void setNewDuration(double newDuration)
  {
    accumulatedError = 0;

    // Математически верно так:  //VG ???
    // if (newDuration < leastDuration) newDuration = leastDuration;
    // Но вероятно могут возникнуть очень маленькие отрицательные
    // значения у новых длительностей.
    if (newDuration < leastDuration)
      newDuration = leastDuration;
    //ToDo: проверить без 1.1  //VG ???

    //Считаем новые длительности и остатки
    double ratio = newDuration / initDuration;
    double dur;
    int prevL;
    for (int i = 0; i < cycle.length / 2; i++)
    {
      prevL = cycle[2 * i].l;
      dur = (initElasticDurations[i] + prevL) * ratio - prevL;
      cycle[2 * i + 1].l = (int) dur;
      fractionParts[i] = dur % 1;

      //System.out.println(String.format("%d --- %d", i, cycle[2 * i + 1].l));
    }
    ratio = newDuration / duration;
    if (position.n % 2 == 1)
    {
      prevL = cycle[position.n - 1].l;
      position.offset = (int) Math.max((position.offset + prevL) * ratio - prevL, 0);
    }

    duration = 0;
    for (int i = 0; i < cycle.length / 2; i++)
      duration += cycle[2 * i].l + cycle[2 * i + 1].l + fractionParts[i];

    /*
    System.out.print("setNewDuration ");
    System.out.println(newDuration);
    System.out.println(duration);*/
  }

  /**
   * Создаём цикл из последовательности букв и длин
   * (полагаем, что эти две последовательности одной длины; в противном случае
   * длина цикла определяется по более короткой).
   *
   * @param symbols символы для звуков
   * @param elasticSymbol символ для паузы
   * @param bipsAndPauses Длины звуков и следующих за ними пауз.
   *                      Длина следующей за бипом тишины определеятся как int(bipDuration * pauseFactor)
   *                      Паузы должны быть неотрицацельны.
   *
   * @param numerator  Сколько повторений внутри цикла.
   */
  public BipPauseCycle(int[] symbols, int elasticSymbol,
                       BipAndPause[] bipsAndPauses,
                       int numerator)
  {
    this.numerator = numerator;
    this.elasticSymbol = elasticSymbol;

    int lengthMin = Math.min(symbols.length, bipsAndPauses.length);
    cycle = new Pair[lengthMin * 2 * numerator];
    initElasticDurations = new double[lengthMin * numerator];
    fractionParts = new double[lengthMin * numerator];

    double dur;
    for (int j = 0; j < numerator; j++)
    {
      int pref = j * lengthMin;
      for (int i = 0; i < lengthMin; i++)
      {
        cycle[2 * (i + pref)] = new Pair(symbols[i], bipsAndPauses[i].bipDuration);
        dur = bipsAndPauses[i].bipDuration * bipsAndPauses[i].pauseFactor;
        cycle[2 * (i + pref) + 1] = new Pair(elasticSymbol, (int) (dur));
        //Хотим, чтобы накапливающаяся погрешность была положительна,
        // поэтому  берём целую часть. Если брать округление, но
        // тогда нужно следить за отрицательными погрешностями.
        fractionParts[i + pref] = dur % 1;
        initElasticDurations[i + pref] = dur;
      }
    }


    position = new CyclePosition(0, 0);
    cycleCount=0;

    //Определяем точную длительность.
    duration = 0.0;
    for (int i = 0; i < bipsAndPauses.length; i++)
    {
      duration += bipsAndPauses[i].duration();
      // vg duration += (1 + bipsAndPauses[i].pauseFactor) * bipsAndPauses[i].bipDuration;
    }
    duration *= numerator;
    initDuration = duration;

    //Определяем наименьший коэффициэнт сжатия и наименьшую длину.
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

    accumulatedError = 0;
    totalErrorsCorrected = 0;
  }

  /**
   *  Обнуляем счетчик и позицию
   */
  void reset(){
    position = new CyclePosition(0, 0);
    cycleCount=0;
  }

  /**
   * Конструктор для длинной мелодии
   * //ToDo: рассказть, почему и  как
   * @param bipsAndPauses
   * @param numerator
   */
  public BipPauseCycle(BipAndPause[] bipsAndPauses, int numerator)
  {
    this(diagonal(bipsAndPauses.length), bipsAndPauses.length, bipsAndPauses, numerator);
  }

  static int[] diagonal(int length)
  {
    int[] res = new int[length];
    for (int i = 0; i < res.length; i++)
      res[i] = i;
    return res;
  }


  private List<Integer> symbolsToRead;
  private List<Integer> sizesToRead;

  /**
   * Выбираем по кругу от данной позиции, пока не наберём суммарную длину
   * элементов алфавита.
   *
   * Это решает проблему с копящейся погрешностью: если время измерять
   * в единицах 1/frequency, то за время работы метронома
   * порядка часа можно набрать  существенное (треть секунды?)
   * отклонение от данного tempo. Поэтому мы копим дробную ошибку  в пределах
   * [0,2) и периодически уменьшаем её на 1, дописывая (один сэпмл) к длительности
   * выгружаемого  elastic.
   *
   * @param totalLength суммарная длина элементов
   * @return считанный массив символов,  с указанием начала воспроизведения
   * в первом символе и того, сколько нужно записать в буфер
   */
  public TempoLinear readTempoLinear(int totalLength)
  {
    TempoLinear result = new TempoLinear();
    result.startInFirst = position.offset;
    //result.pos = new Position(-1, 0);
    symbolsToRead = new ArrayList<>();
    sizesToRead = new ArrayList<>();

    int freeSpace;
    int lastToRead;
    int toRead = totalLength;
    boolean compensateError;

    while (toRead > 0)
    {
      /* IS: Смысл того, что ниже, непонятен.
      //Что представляет  позиция в линейном цикле? Что значит там счетчик цикла?
      //Почему нужно делать это много раз? Ведь следующее значение не зависит от
      //предыдущего?   Почему n не должно быть эластик? А если встретилась только
      //она, то почему позиция будет (-1,0)?
      // Поскольку это нигде не нужно, прячу.

      //элемент алфевита для выбираемой пары:
      //int note = cycle[position.n].a;
      if (note != elasticSymbol)
      {
        result.pos.n = position.n;
        result.pos.offset = position.offset;
        result.pos.cycleCount = position.cycleCount;
      }
      symbolsToRead.add(note);*/

      //элемент алфевита для выбираемой пары:
      symbolsToRead.add(cycle[position.n].a);
      //сколько места осталось в данном элементе цикла:
      freeSpace = cycle[position.n].l - position.offset;

      compensateError = (position.n % 2 == 1) && (accumulatedError >= 1);
      //compensateError указывает, что мы в тишине и накопилась погрешность
      if (compensateError)
        freeSpace += 1;

      if (freeSpace <= toRead) //идём в след. элемент цикла
      {
        lastToRead = freeSpace;

        //Увеличив раньше на 1 freespace, мы скомпенсировали ошибку
        if (compensateError)
        {
          accumulatedError = accumulatedError - 1;
          totalErrorsCorrected++;
        }
        //Мы дочитали кусок тишины, и нам нужно сохранить его погрешность
        if (position.n % 2 == 1)
        {
          accumulatedError += fractionParts[position.n / 2];
        }

        //Теперь переходим:
        if (position.n + 1 >= cycle.length)
        {
          cycleCount++;
        }
        position.n = (position.n + 1) % cycle.length;
        position.offset = 0;
        toRead -= freeSpace;  //считали всё, что было в этом элементе, до конца
      }
      else
      {
        position.offset += toRead;
        lastToRead = toRead;
        toRead = 0;
      }
      sizesToRead.add(lastToRead);
    }
    result.symbols = symbolsToRead.toArray(new Integer[0]);  //Тип объекта определяется через пустую последовательность этих объектов.
    result.durations = sizesToRead.toArray(new Integer[0]);  //Какой же уёбищный язык...)))
    return result;
  }

  final String tagForPrint = "TempoTest ";

  public void print()
  {
    printFinal();
    printVariable();
  }

  public void printFinal()
  {
    System.out.println(tagForPrint + "CYCLE, final");

    String elements = "";
    for (Pair pair : cycle)
    {
      elements += " (" + Integer.toString(pair.a) + "," + Integer.toString(pair.l) + ")";
    }
    System.out.printf(tagForPrint + "Elements: (a_0,length_0), (a_1,length_1)...:" + elements + "\n");

    System.out.printf(tagForPrint +
      "Init duration, least Duration, leastDilationRatio: " +
      String.format("%.3f, %.3f, %.4f", initDuration,
        leastDuration,
        leastDilationRatio) + "\n");

    elements = "";
    for (double d : initElasticDurations)
    {
      elements += " " + String.format("%.3f", d);
    }
    System.out.printf(tagForPrint + "initElasticDurations: " + elements + "\n");


  }

  public void printPosition()
  {
    System.out.printf(tagForPrint + "Position: number=%d, offset=%d \n", position.n, position.offset);
  }

  public void printVariable()
  {
    System.out.println(tagForPrint + "CYCLE, variable");
    System.out.printf(tagForPrint + "Position: number=%d, offset=%d \n", position.n, position.offset);

    System.out.printf(tagForPrint + "Duration, error, frames corrected: " +
      String.format("%.3f, %.3f, %d", duration, accumulatedError, totalErrorsCorrected) + "\n");

    String elements = "";

    for (int i = 0; i < cycle.length / 2; i++)
    {
      elements += " " + String.format("%d, %.3f;", cycle[2 * i + 1].l, fractionParts[i]);
    }
    System.out.printf(tagForPrint + "elasticLengths, fractionParts: " + elements + "\n");
  }
}
