import 'dart:collection';
import 'dart:typed_data';

class Subbeat
{
  static const int maxSubbeatCount = 8;

  /// Loop through subdivision list: 1, 2, 4, 3
  static int next(int subBeat)
  {
    subBeat++;
    if (subBeat == 3)
      subBeat = 4;
    else if (subBeat == 4)
      subBeat = 1;
    else if (subBeat >= 5)
      subBeat = 3;
    return subBeat;
  }
}

// Пришло время расставить акценты!
// Содержит набор быстрых простеньких процедур (на 19.12.19 - набор состоит из одной),
// расставляющих акценты для данного числа долей (или поддолей).
//
// VG, это правильнее было бы написать на Dart, а потом переслать уже в яву.
// Но сегодня (в ночь на 19.12) мне приехали только accents, а ноты не передались.
// Вместо того, чтобы заниматься передачей двумерного массива по каналам, я
// решил написать пока этот простенький код в Java.   Потом можно будет
// переписать его в Дарт, использовать там для расстановки акцентов в долях и
// поддолях, а сюда  отправлять уже готовые акценты (ноты). Также можно использовать
// для определения силы совы.

enum AccentationType
{
  Dynamic,
  Agogic
}

class Prosody
{
  /// Ниже этой громкости звук не уменьшится
  static const double leastVolume = 0.0;
  /// на что делим, уменьшая акцент днот (Sibelius: 1.5; плохо выделяет)
  static const double beatDynamic = 2;
  /// на что делим, уменьшая акцент поднот (Sibelius: 1.5; плохо выделяет)
  static const double subBeatDynamic = 1.5;
  /// Untested. Не докнца понято
  static const double strongMultiplier = 3; //todo: в константы

  //IS: VG, Для выбора совы для отрисовки при числе долей <=12:
  // 0 - сильная, res[1] - слабая.
  //остальные расположены между ними, это относительно сильные,
  //чем меньше - тем сильнее.

  /// Расставляем акценты внутри музыкального интервала (такта или доли),
  /// разбитого на равные части.
  ///
  /// "Пиво-Водочка": как смещаем акцент (раньше или позже) в случае, когда
  /// число долей не  делится ни на 2 ни на 3.
  ///
  /// Индекс 1 у имени процедуры значит, что мы находимся в филосовском поиске.
  /// В частности, получить семидольный размер 2+3+2 не получится,
  /// будут лишь 3+2+2 при pivoVodochka, или же 2+2+3.
  ///
  /// @param noteNumber
  /// @return массив акцентов длины noteNumber.
  /// 0 представляет самый сильный акцент, чем больше значение - тем слабее доля.
  ///
  /// Несколько фактов (легко проверяются индукцией по числу долей):
  /// Значение 0 всегда у первого, и только у него.
  /// Встречаются все акценты между самым сильным и самым слабым.
  ///
  /// (Думал еще, что у второй ноты значение всегда самое большое, то есть самое слабое.
  /// Доказательства не обнаружил, зато обнаружил контрпримеры ыы: 17, false; 19,true;)
  /// ToDo: что за мистика? Разобраться.
  ///
  /// Соотетвтует музыкальным канонам и покрывает все стандартные размеры в случаях,
  /// когда число долей имеет лишь делители 2 и 3
  /// Тем не менее, никто не мешает, например, сначала
  /// делить число долей на 3, а не на 2. Или же стараться приблизится к трёхдольному
  /// размеру в нерегулярных случаях, а не к двудольному.
  /// Тут начинается Римский-Корсаков и могут получится очень любопытные звучания.
  ///
  static List<int> getAccents(int noteNumber, bool pivoVodochka, [int level = 0, bool inc = true])
  {
    //TODO Use byte instead of int?
    //Uint16List (byte)
    if (noteNumber == 0)
      return [];
    if (noteNumber == 1)
      return [0];

    //Cледующие две строки кода избыточны, они частный случай этой рекурсивной процедуры.
    //Я привожу их для наглядности. (Если их удалить, на работу алгоритма это не повлияет.)

    //Простой двудольный размер:
    if (noteNumber == 2)
      return [1, 0];

    //Простой трёхдольный размер:
    if (noteNumber == 3)
      return [1, 0, 0];

    if (noteNumber == 7)
      return pivoVodochka ? [2, 0, 0, 1, 0, 1, 0] : [2, 0, 1, 0, 1, 0, 0];

    //byte[] res = new byte[noteNumber];
    List<int> accents = new List<int>(noteNumber);

    //Делим на два равных
    if (noteNumber % 2 == 0)
    {
      int middle = noteNumber ~/ 2;
      List<int> left = getAccents(middle, pivoVodochka, level + 1, inc);
      for (int i = 0; i < middle; i++)
        accents[i + middle] = accents[i] = left[i];// > 0 ? left[i] + 1 : 0; // лишняя операция при i = 0
      accents[0]++;
    }
    // На два равных не делится. Если не делится на 3 (этот случай разобран далее, то делим на два неравных
    else if (noteNumber % 3 != 0)
    {
      int middle = noteNumber ~/ 2;
      if (!pivoVodochka)
        middle++;  // Make vOdOchkA-pIvO
      List<int> left = getAccents(middle, pivoVodochka, level + 1, inc && true);
      List<int> right = getAccents(noteNumber - middle, pivoVodochka, level + 1, false);
      for (int i = 0; i < middle; i++)
        accents[i] = left[i];// > 0 ? left[i] + 1 : 0;
      for (int i = middle; i < noteNumber; i++)
        accents[i] = right[i - middle];// > 0 ? right[i - middle] + 1 : 0;
      //accents[middle]--;
      accents[0]++;
    }
    else
    {
      int third = noteNumber ~/ 3;
      List<int> left = getAccents(third, pivoVodochka, level, inc);
      for (int i = 0; i < third; i++)
        accents[i + third + third] = accents[i + third] = accents[i] = left[i];
          //left[i] > 0 ? left[i] + 1 : 0; //лишняя операция при i=0;
      accents[0]++;
    }
    return accents;
  }

  /// @return Array of simple metres, i-th element - simple metre length, array size - number of simple meters
  static List<int> getSimpleMetres(int noteNumber, bool pivoVodochka, [int level = 0])
  {
    //TODO Use byte instead of int?
    //Uint16List (byte)
    if (noteNumber == 0)
      return [];
    else if (noteNumber < 4)
      return [noteNumber];
//    else if (noteNumber == 4 && level == 0)
//      return [4];

    //Делим на два равных
    if (noteNumber % 2 == 0)
    {
      int middle = noteNumber ~/ 2;
      List<int> left = getSimpleMetres(middle, pivoVodochka, level + 1);
      return left + left;
    }
    // На два равных не делится. Если не делится на 3 (этот случай разобран далее, то делим на два неравных
    else if (noteNumber % 3 != 0)
    {
      int middle = noteNumber ~/ 2;
      if (!pivoVodochka)
        middle++;  // Make vOdOchkA-pIvO
      List<int> left = getSimpleMetres(middle, pivoVodochka, level + 1);
      List<int> right = getSimpleMetres(noteNumber - middle, pivoVodochka, level + 1);
      return left + right;
    }
    else
    {
      int third = noteNumber ~/ 3;
      List<int> left = getSimpleMetres(third, pivoVodochka, level + 1);
      return left + left + left;
    }
  }

  static List<int> reverseAccents(List<int> accents)
  {
    int max = 0;
    for (int i = 0; i < accents.length; i++)
      if (accents[i] > max)
        max = accents[i];
    return new List<int>.generate(accents.length, (int index) => max - accents[index]);
  }

  /// Возвращает последовательность звуков по данному, где акценты расставлены
  /// с помощью изменения громкости. 0-й акцент - самый сильный.
  /// @param initSound
  /// @param nOfAccents
  /// @param dynamic динамический коэффициент акцента
  /// @return
/*
  static byte[][] dynamicAccents(byte[] initSound, int nOfAccents, double dynamic)
  {
    byte[][] sounds = new byte[nOfAccents][];
    for (int acnt = 0; acnt < sounds.length; acnt++)
    {
      sounds[acnt] = MelodyToolsPCM16.changeVolume(initSound, _accentToVolumeFactor(acnt, dynamic));
    /*//TODO: Полигон. УБРАТЬ
    MelodyToolsPCM16 TmpTools=new MelodyToolsPCM16(48000);
    double[] tmp=TmpTools.doubleFrom16BitPCM(sounds[acnt]);
    sounds[acnt]=TmpTools.doubleTo16BitPCM(tmp);*/
    }

    return sounds;
  }

  //Складываем пробно так, чтобы можно было бипы миксовать.
  //Пока - деля пополам!
  //Первый, сильный звук - длинный!
  static byte[][] agogicAccentsNormalized(byte[] longSound, byte[] shortSound, int nOfAccents)
  {
    //byte[][] sounds=new byte[nOfAccents][];
    double[] longSndD = MelodyToolsPCM16.doubleFrom16BitPCM(longSound);//ToDo: переделать -
    double[] shortSndD = MelodyToolsPCM16.doubleFrom16BitPCM(longSound);// лень было по битам разбирать
    double maxAmp = 0;
    for (int i = 0; i < shortSndD.length; i++)
    {
      double amp = Math.abs(longSndD[i] * strongMultiplier + shortSndD[i]);
      if (amp > maxAmp)
        maxAmp = amp;
    }
    double normalization = 1.0;
    if (maxAmp != 0)
      normalization = 1.0 / maxAmp;//ToDo: то есть громкость можем и увеличить... ну ок.

    byte[] longNormalized = MelodyToolsPCM16.changeVolume(longSound, normalization * strongMultiplier);
    byte[] shortNormalized = MelodyToolsPCM16.changeVolume(shortSound, normalization);

    //ToDo - чтобы не нормализовать /2 в потоке
    //byte[] subsubSound=        MelodyToolsPCM16.changeVolume(shortSound,
    //accentToVolumeFactor(1, subBeatDynamic);

    //Создаем сильные просодированные, складываем с фиксированной  слабой, и меняем звук.
    byte[][] sounds = GeneralProsody.dynamicAccents(longNormalized, nOfAccents,
      GeneralProsody.beatDynamic);
    for (int i = 0; i < sounds.length; i++)
      MelodyToolsPCM16.mixNOTNormalized(sounds[i], shortNormalized);
    return  sounds;
  }
*/
  /// Возвращает множитель громкости по акценту с учетом коэффициента динамики.
  /// @param accent Натуральное, 0 -> 1;
  /// @return Коэффициент уменьшения громкости

  static double _accentToVolumeFactor(int accent, double dynamic)
  {
    double den = 1.0;
    for (int i = 0; i < accent; i++)
      den = dynamic * den;
    return (1.0 - leastVolume) / den + leastVolume;
  }

/* всякий тест, please, do not delete
    static void printAcc1(int n, bool b)
    {
        byte[] acc=getAccents(n, b);
        System.out.printf("%d:  ", n);
        for(int i=0;i<acc.length;i++)
            System.out.printf("%d ",  acc[i]);
        System.out.print("\n---\n");
    }

    private static void test(String[] args)
    {
	    print(2,true);
	    print(3,true);
	    print(4,true);
	    print(5,true);
	    print(5,false);
	    print(6,true);
	    print(7,false);
	    print(7,true);
	    print(8,true);
      //Два хороших, контрпримерных случая
      print(17,false);
	    print(19,true);
    }
2:  0 1
---
3:  0 1 1
---
4:  0 2 1 2
---
5:  0 2 1 2 2
---
5:  0 2 2 1 2
---
6:  0 2 2 1 2 2
---
7:  0 3 2 3 1 2 2
---
7:  0 2 2 1 3 2 3
---
8:  0 3 2 3 1 3 2 3
---
9:  0 2 2 1 2 2 1 2 2
---
12:  0 3 3 2 3 3 1 3 3 2 3 3
---
17:  0 3 3 2 3 3 2 3 3 1 4 3 4 2 4 3 4
---
19:  0 3 3 2 3 3 2 3 3 1 4 3 4 4 2 4 3 4 4
*/

}
