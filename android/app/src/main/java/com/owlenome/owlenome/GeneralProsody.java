package com.owlenome.owlenome;


import java.util.ArrayList;
import java.util.List;

// Same as beat_metre.dart::BeatMetre
class BeatMetre
{
    int beatCount;
    List<Integer> subBeats;
    // Indices of accented beats in each simple metre (row)
    byte accents[]; //ToDo

    BeatMetre()
    {
        beatCount = 4;
        subBeatCount = 1;
        subBeats = new ArrayList<Integer>();
        accents = new byte[0];
        //accents.set(0, 0);
    }

    int subBeatCount;
}


//Пришло время расставить акценты!
//Содержит набор быстрых простеньких процедур (на 19.12.19 - набор состоит из одной),
// расставляющих акценты для данного числа
//долей (или поддолей).
//
//VG, это правильнее было бы написать на Dart, а потом переслать уже в яву.
// Но сегодня (в ночь на 19.12) мне приехали только accents, а ноты не передались.
// Вместо того, чтобы заниматься передачей двумерного массива по каналам, я
// решил написать пока этот простенький код в Java.   Потом можно будет
//переписать его в Дарт, использовать там для расстановки акцентов в долях и
// поддолях, а сюда  отправлять уже готовые акценты (ноты). Также можно использовать
// для определения силы совы.
//

public class GeneralProsody {

    enum AccentationType{
        Dynamic,
        Agogic
    }





    /**
     * Расставляем акценты внутри музыкального интервала (такта или доли),
     * разбитого на равные части.
     *
     * "Пиво-Водочка": как смещаем акцент (раньше или позже) в случае, когда
     * число долей не  делится ни на 2 ни на 3.
     *
     * Индекс 1 у имени процедуры значит, что мы находимся в филосовском поиске.
     * В частности, получить семидольный размер 2+3+2 не получится,
     * будут лишь 3+2+2 при pivoVodochka, или же 2+2+3.
     *
     *
     * @param nOfEqualNotes
     * @return массив акцентов длины nOfEqualNotes.
     * 0 представляет самый сильный акцент, чем больше значение - тем слабее доля.
     *
     * Несколько фактов (легко проверяются индукцией по числу долей):
     * Значение 0 всегда у первого, и только у него.
     * Встречаются все акценты между самым сильным и самым слабым.
     *
     * (Думал еще, что у второй ноты значение всегда самое большое, то есть самое слабое.
     * Доказательства не обнаружил, зато обнаружил контрпримеры ыы: 17, false; 19,true;)
     * //ToDo: что за мистика? Разобраться.
     *
     *
     */
    public static byte[] getAccents(int nOfEqualNotes, boolean pivoVodochka){
        if (nOfEqualNotes==0) return new byte[0];
        if  (nOfEqualNotes==1) return new byte[] {0};

        //Cледующие две строки кода избыточны, они частный случай этой рекурсивной процедуры.
        //Я привожу их для наглядности. (Если их удалить, на работу алгоритма это не повлияет.)

        //Простой двудольный размер:
        if  (nOfEqualNotes==2) return new byte[] {0,1};
        //Простой трёхдольный размер:
        if  (nOfEqualNotes==3) return new byte[] {0,1,1};

        byte[] res=new byte[nOfEqualNotes];

        //Делим на два равных
        if (nOfEqualNotes%2==0) {
            int middle=nOfEqualNotes/2;
            byte[] leftArray= getAccents(middle,pivoVodochka);
            for (int i=0; i<middle; i++)
                    { res[i]=(byte)(leftArray[i]+1);//лишняя операция при i=0;
                        res[i+middle]=(byte)(leftArray[i]+1);}
            res[0]=leftArray[0];
            return res;
        }

        //На два равных не делится. Если не делится на 3 (этот случай разобран далее, то делим на два неравных
        if (nOfEqualNotes%3!=0) {
            int middle=nOfEqualNotes/2;
            if (!pivoVodochka) middle++;//vodochka-pivo
            byte[] leftArray= getAccents(middle,pivoVodochka);
            byte[] rightArray= getAccents(nOfEqualNotes-middle,pivoVodochka);
            res[0]=leftArray[0];
            for (int i=1; i<middle; i++)
            { res[i]=(byte)(leftArray[i]+1);}
            for (int i=middle; i<nOfEqualNotes; i++)
            { res[i]=(byte)(rightArray[i-middle]+1);}
            return res;
        }

        int third=nOfEqualNotes/3;
        byte[] leftArray= getAccents(third,pivoVodochka);
        for (int i=0; i<third; i++)
        { res[i]=(byte)(leftArray[i]+1);//лишняя операция при i=0;
            res[i+third]=(byte)(leftArray[i]+1);
            res[i+third+third]=(byte)(leftArray[i]+1);
            }
        res[0]=leftArray[0];
        return res;

        //IS: VG, Для выбора совы для отрисовки при числе долей <=12:
        // 0 - сильная, res[1] - слабая.
        //остальные расположены между ними, это относительно сильные,
        //чем меньше - тем сильнее.


        //То, что написано выше, соотетвтует в случаях, когда
        //число долей имеет лишь делители 2 и 3, музыкальным канонам и покрывает
        //все стандартные размеры. Тем не менее, никто не мешает, например, сначала
        //делить число долей на 3, а не на 2. Или же стараться приблизится к трёхдольному
        //размеру в нерегулярных случаях, а не к двудольному.
        //Тут начинается Римский-Корсаков и могут получится очень любопытные звучания.
        //Мы же пока на этом заканчиваем.
    }


    //Возвращает последовательность звуков по данному, где акценты расставлены
    //с помощью изменения громкости. 0-й акцент - самый сильный.

    /**
     *
     * @param initSound
     * @param nOfAccents
     * @param dynamic динамический коэффициент акцента
     * @return
     */
    public static  byte[][] dynamicAccents(byte[] initSound, int nOfAccents, double dynamic){
        byte[][] sounds=new byte[nOfAccents][];
        for(int acnt=0;acnt<sounds.length;acnt++) {
            sounds[acnt] =
                    MelodyToolsPCM16.changeVolume(initSound,
                            accentToVolumeFactor(acnt, dynamic));


            /*//TODO: Полигон. УБРАТЬ
            MelodyToolsPCM16 TmpTools=new MelodyToolsPCM16(48000);
            double[] tmp=TmpTools.doubleFrom16BitPCM(sounds[acnt]);
            sounds[acnt]=TmpTools.doubleTo16BitPCM(tmp);*/

        }

        return  sounds;
    }



    //Складываем пробно так, чтобы можно было бипы миксовать.
    //Пока - деля пополам!
    //Первый, сильный звук - длинный!
    public static  byte[][] agogicAccentsNormalized(byte[] longSound, byte[] shortSound,
                                          int nOfAccents){

        //byte[][] sounds=new byte[nOfAccents][];


        double[] longSndD=MelodyToolsPCM16.doubleFrom16BitPCM(longSound);//ToDo: переделать -
        double[] shortSndD=MelodyToolsPCM16.doubleFrom16BitPCM(longSound);// лень было по битам разбирать
        double maxAmp=0;
        for (int i=0; i<shortSndD.length; i++){
            double amp= Math.abs( longSndD[i]*strongMultiplier+shortSndD[i]);
            if (amp>maxAmp) maxAmp=amp;
        }
        double normalization=1.0;
        if (maxAmp!=0) normalization=1.0/maxAmp;//ToDo: то есть громкость можем и увеличить... ну ок.

        byte[] longNormalized = MelodyToolsPCM16.changeVolume(longSound,normalization*strongMultiplier);
        byte[] shortNormalized=MelodyToolsPCM16.changeVolume(shortSound,normalization);

        //ToDo - чтобы не нормализовать /2 в потоке
        //byte[] subsubSound=        MelodyToolsPCM16.changeVolume(shortSound,
                //accentToVolumeFactor(1, subBeatDynamic);

        //Создаем сильные просодированные, складываем с фиксированной  слабой, и меняем звук.
        byte[][] sounds =GeneralProsody.dynamicAccents(longNormalized,
                nOfAccents,GeneralProsody.beatDynamic);
        for (int i=0; i<sounds.length; i++) {
            MelodyToolsPCM16.mixNOTNormalized(sounds[i],shortNormalized);
        }
        return  sounds;
    }

    //Ниже этой громкости звук не уменьшится
    final static  double leastVolume=0.0;

    /**
     * на что делим, уменьшая акцент нот
     * Sibelius: 1.5; плохо выделяет
     */
    final static double beatDynamic =2;

    /**
     * на что делим, уменьшая акцент поднот
     * (Sibelius: 1.5; плохо выделяет)
     */
    final static double subBeatDynamic =1.5;


    //Untested. Не докнца понято
    final static double strongMultiplier=3;//todo: в константы


    /**
     * Возвращает множитель громкости по акценту с учетом коэффициента
     * динамики.
     * @param accent Натуральное, 0 -> 1;
     * @return Коэффициент уменьшения громкости
     */
    private  static double accentToVolumeFactor(int accent, double dynamic){

        double den=1.0;
        for (int i=0;i<accent;i++){den=dynamic*den;}


        return (1.0-leastVolume)/den+leastVolume;
    }





    /* всякий тест, please, do not delete

    public static void printAcc1(int n, boolean b){

        byte[] acc=getAccents(n, b);
        System.out.printf("%d:  ", n);
        for(int i=0;i<acc.length;i++)
        {
            System.out.printf("%d ",  acc[i]);
        }
        System.out.print("\n---\n");
    }

    private static void test(String[] args) {
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


