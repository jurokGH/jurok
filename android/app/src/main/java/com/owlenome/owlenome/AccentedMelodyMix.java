package com.owlenome.owlenome;


import android.util.Log;

import static com.owlenome.owlenome.MelodyToolsPCM16.getSilence;

//То, что мы будем играть. Определено с точностью до
// темпа (темп регулируется через setTempo)
class AccentedMelodyMix
{


    final int elasticSymbol = -1;

    byte[][] setOfNotes;


    //    BipAndPause[] _bipAndPauseSing;
    private int _sampleRate;

    /**
     * Цикл долей
     */
    public BipPauseCycle cycle=null;

    private  BipPauseCycle newCycle=null;

    /**
     * Цикл поддолей.
     */
    public BipPauseCycle cycleDriven=null;
    public BipPauseCycle newCycleDriven=null;


    BeatMetre beats;
    BeatMetre newBeats;

    /**
     * Установленная скорость цикла
     */
    double tempo;

    private final static  double defaultTempo =123.0;



    /**
     *Number of beats in cycle
     */
    private int beatCount=0;

    /**
     *  Number of beats in newCycle
     */
    private int newBeatCount;



    MusicSchemeMix musicScheme;


    public AccentedMelodyMix(
            MusicSchemeMix musicScheme, int sampleRate,
            BeatMetre beats
            // Number of nOfBeats
            //int nOfBeats,
            //int[] accents,
            //List<Integer> subBeats
    ){
        this(musicScheme, sampleRate, beats, defaultTempo);
    }

    public AccentedMelodyMix(
            MusicSchemeMix musicScheme, int sampleRate,
            BeatMetre beats, double tempo
            // Number of nOfBeats
            //int nOfBeats,
            //int[] accents,
            //List<Integer> subBeats
    )
    {
        //Создаём реальные массивы акцентированных звуков.
        this.musicScheme=musicScheme;
        this.musicScheme.load(sampleRate);//Долгая. В аудио потоке не делать.
        //ToDo: мы точно безопасно её вызываем в MainActivity?

        _sampleRate =sampleRate;

        this.tempo=tempo;

        this.beats=beats;

        prepareNewCycle(beats);

        setNewCycle();
    }

    /**
     *  Готовим новый цикл (чтобы потом его можно было подменить в аудиоцикле).
     *  Возвращает максимальную скорость нового цикла.
     */
    public double prepareNewCycle(BeatMetre beats){
        if(beats.beatCount<=0) return -1.0;
        //ToDo  IS: VS, не знаю, что принято
        // делать в таких ситуациях - выйти, или ждать, пока само на 0 поделит с исключением?



//    звуки тишины у нас есть в тесном цикле
//    byte[] pause = melodyTools.getSilence(framesInQuorta * 2);


        int maxSubBeatCount = 1;
        int totalSubBeats = 0;  // nOfBeats * subBeatCount
        for (int i = 0; i < beats.subBeats.size(); i++)
        {
            totalSubBeats += beats.subBeats.get(i);
            if (beats.subBeats.get(i) > maxSubBeatCount)
                maxSubBeatCount = beats.subBeats.get(i);
        }

        ///Акценты приехали  из dart.
        byte accentsRecieved[] = beats.accents;

        ///Считаем, что они приехали как есть: 0 - слабый.
        byte max = Byte.MIN_VALUE; byte min=Byte.MAX_VALUE;
        for (int i = 0; i < accentsRecieved.length; i++)  {
            if (accentsRecieved[i] > max) max = accentsRecieved[i];
            if (accentsRecieved[i] < min) min = accentsRecieved[i];
            /*if ((accentsRecieved[i] < min)&&
            (accentsRecieved[i]>=0)) //паузу -1 не считаем
                    min = accentsRecieved[i];
             */
        }
        byte accents[]=new byte[accentsRecieved.length];
        for (int i = 0; i < accentsRecieved.length; i++){
            //пауза - в  паузу,  остальные переворачиваем
             accents[i]=-1;
            if  (accentsRecieved[i]>=0)  accents[i]= (byte)(max -accentsRecieved[i]);//ToDo?
        }

        //Ноты. Сначала доли, потом поддоли//ToDo: up
        setOfNotes = new byte[musicScheme.setOfNotes.length+musicScheme.setOfSubNotes.length][];
        for(int i = 0; i<musicScheme.setOfNotes.length; i++){
            setOfNotes[i]=musicScheme.setOfNotes[i];    }
        for(int i = 0; i<musicScheme.setOfSubNotes.length; i++){
            setOfNotes[i+musicScheme.setOfNotes.length]=musicScheme.setOfSubNotes[i]; }


        int[] symbols = new int[beats.beatCount];
        int[] symbolsDriven = new int[totalSubBeats];


        double totalLengthOfBeat=(musicScheme.beatSound.length+musicScheme.subBeatSound.length+2)*maxSubBeatCount;
        //ToDo:DoubleCheck
        //Это какой-то странноватый способ... Нужно
        //найти число,   удовлетворяющее для всех i неравенству
        //(totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) > 1



        /*
        int weakestAccent = 0;//ToDo: тут точно живёт глюк. Ну почти точно.
        //Upd: ну конечно. Просто неверно это.
        for (int i = 0; i < accents.length; i++)
        {
            if (weakestAccent < accents[i])
                weakestAccent = accents[i];
        }*/

        int weakestAccent=max-min;//ToDo up

        //Заглушка. Мы хотим качественно (agogic) отличить самый слабый акцент доли. Поэтому не накладываем там первый звук (акцент).
        //Заглушим его, сделав ноту слабейшего акцента тишиной. То же делаем, если и была тишина
        if (min<=0) {
            setOfNotes[weakestAccent] = getSilence(setOfNotes[weakestAccent].length / 2);
        }

        BipAndPause[] _bipAndPauseMainSing = new BipAndPause[beats.beatCount];
        for (int i = 0; i < beats.beatCount; i++)
        {
            if (musicScheme.beatAccentationType == GeneralProsody.AccentationType.Agogic//ToDo:убрать всю эту предваритеьную муть - теперь всегда так
                    &&
                    ((accents[i] == weakestAccent)||(accents[i] == -1))
            )
            {
                //самая слабая доля (максимум) пусть будет
                // самым сильным слабым звуком
                symbols[i] = musicScheme.setOfNotes.length; //ToDo: тут этому не место по логике вещей

                 //symbols[i] = elasticSymbol; //-- так не выходит, там где-то длина ноты вычисляется по этому символу

                symbols[i] = accents[i];

                symbols[i] =weakestAccent; //ToDo:третий вариант)))
            }
            else
            {
                symbols[i] = accents[i];
            }
            int noteLength = setOfNotes[symbols[i]].length;
            _bipAndPauseMainSing[i] = new BipAndPause(
                    noteLength / 2,
                    (totalLengthOfBeat / (noteLength / 2)) - 1
            );
        }

        BipAndPause[] _bipAndPauseSubSing = new BipAndPause[totalSubBeats];
        int k = 0;
        for (int i = 0; i < beats.beatCount; i++)
        {
            byte subBeatAccents[] = GeneralProsody.getAccents(beats.subBeats.get(i), false);
            for (int j = 0; j < beats.subBeats.get(i); j++, k++) {
                if (accents[i] >= 0)  //не тишина в ноте
                    symbolsDriven[k] = musicScheme.setOfNotes.length + subBeatAccents[j]; ///ToDo:сюда тишину впихну
                else symbolsDriven[k] = weakestAccent;//ToDo:неверно
                int noteLength = setOfNotes[symbolsDriven[k]].length;
                _bipAndPauseSubSing[k] = new BipAndPause(
                        noteLength / 2,
                        (totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) - 1
                );

                //ToDo: if symobls[i]==elasticSymbol ....  - в тишину всё
                /*if (j == 0)
                //Это пока не сделано нормально - при агогическом миксе становится тихим звук доли.
                {//начало доли
                    symbolsDriven[k] = elasticSymbol; //Можно и иначе.//ToDo: эксперимент
                }*/
            }
        }


        /* //ToDo:delete
        int k = 0;
        for (int i = 0; i < beats.beatCount; i++) {
            byte weakAccents[] = GeneralProsody.getAccents(beats.subBeats.get(i), false);
            for (int j = 0; j < beats.subBeats.get(i); j++, k++) {
                if (j == 0) {//сильная доля
                    symbols[k] = accents[i];
                } else {
                    symbols[k] = musicScheme.setOfNotes.length + weakAccents[j];
                }
                int noteLength = setOfNotes[symbols[k]].length;
                _bipAndPauseSing[k] = new BipAndPause(
                        noteLength / 2,
                        (totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) - 1
                );
            }
        }*/

        newCycle = new BipPauseCycle(symbols, elasticSymbol, _bipAndPauseMainSing, 1);
        newCycleDriven=new BipPauseCycle(symbolsDriven, elasticSymbol, _bipAndPauseSubSing, 1);



        //TODO: Check - длительности должны быть равны!

        newBeatCount= beats.beatCount;
        newBeats=beats;

        return newCycle.getMaximalTempo(_sampleRate, newBeatCount);
    }

    /**
     *
     * Переустанавливает бипы.
     * Позиция не поменяется, если число бипов выросло,
     * и съедет на начальный бип в той же поддоле.
     *
     */
    public void setNewCycle(){

        if (newCycle==null) return;//ToDo ?


        //Вычисляем новую относительную позицию в цикле
        double newPositionRel=0;
        if (cycle!=null){//and hence, beatCount>0
            double beatDuration = cycle.duration / beatCount;
            int beatNow=(int)(cycle.durationBeforePosition()/beatDuration);


            if (beatNow> newBeatCount) {//надо будет переместить бегунок куда-то, если мы не попали в границы цикла.
                //Требование: не должен сбиться общий ритм (представим, что все звуки долей одинаковы -
                // изменение метра не должно быть различимо на слух.
                //Доигрываем  последний  бип
                double restInBeat=beatDuration-(cycle.durationBeforePosition() % beatDuration);
                newPositionRel=(1.0-restInBeat/cycle.duration)*beatCount/newBeatCount;
                //Ещё варианты:
                // Варианты:
                // 1. ставит в первую долю с сохранением поддоли:
                // newPositionRel = (cycle.durationBeforePosition() % beatDuration)/cycle.duration;
                // 2. 0 - плохо, основной темп собьётся
                // 3. остаток по модулю дины нового цикла;
                // 4.??
            }
            else {//Позиция (бит, подбит) не должна поменяться
                newPositionRel = cycle.relativeDurationBeforePosition()*beatCount/newBeatCount; }
        }


        cycle = newCycle;
        beats=newBeats;
        beatCount=newBeatCount;//Избыточно
        cycleDriven=newCycleDriven;
        tempo=setTempo((int)tempo);
        //ToDo: ПЕРЕДЕЛАТЬ setTempo,  зачем я сделал эту глупость с int?
        // - А затем, чтобы не разошлось с флаттером, который не знает дробных темпов (пока)

        int newPos =(int)(newPositionRel*cycle.duration);
        cycle.readTempoLinear(newPos);//ToDo: вешаем чайник; проматываем отыгранную длительность
        cycleDriven.readTempoLinear(newPos); // ...и еще раз

    }




    public double getMaxTempo()
    {
        return cycle.getMaximalTempo(_sampleRate, beatCount);
    }



    /**
     *
     * @param beatsPerMinute что хотим
     * @return что получилось
     */
    public int setTempo(int beatsPerMinute)
    //ToDo: нелогично, что это int.
    // С другой стороны, в дарте у нас значения целочисленные...
    {
        int BPMtoSet = Math.min(
                (int) cycle.getMaximalTempo(_sampleRate,beatCount),
                beatsPerMinute
        );
        //Utility utility = new Utility();
        //System.out.printAcc1("BPMtoSet ");
        //System.out.println(BPMtoSet);
        cycle.setNewDuration(
                Utility.beatsDurationInSamples(_sampleRate,beatCount,
                        BPMtoSet));

        tempo=BPMtoSet;
        Log.d("Tempo",String.format(" now is %f",tempo));

        //А теперь мы вытаскиваем  цикл поддолей, возможно обсекая звуки.
        //ToDo: оформить в BipAndPause как бескомпромисный аналог setNewDuration
        double beatDuration=cycle.duration/beatCount;
        int subPos=0;
        for (int i=0;i<beatCount;i++) {
            int nOfSubBeats = beats.subBeats.get(i);
            double durOfSubBeat = beatDuration / nOfSubBeats;
            for (int j = 0; j < nOfSubBeats; j++, subPos++) {
                int durOfNoteCut;
                if (cycleDriven.cycle[2 * subPos].a==elasticSymbol){
                    //Весь подбит - тишина
                    durOfNoteCut=(int)durOfSubBeat;
                }
                else {
                    //int durOfNote = setOfNotes[cycleDriven.cycle[2 * subPos].a].length;
                    int durOfNote = cycleDriven.initBipsDurations[subPos];
                    durOfNoteCut = Math.min((int) durOfSubBeat, durOfNote);
                }
                cycleDriven.cycle[2 * subPos].l=durOfNoteCut;
                cycleDriven.cycle[2 * subPos+1].l=(int)durOfSubBeat-durOfNoteCut;
                cycleDriven.fractionParts[subPos]=durOfSubBeat%1;
            }
        }
        //проверить, чтобы длины циклов совпадали!  - ок
        cycleDriven.reSetDuration(); cycleDriven.reset();
        cycleDriven.readTempoLinear((int)cycle.durationBeforePosition());
        //ToDo: fraction part, что ещё - всю логику перепроверить.




        Log.d("Tempo",String.format(" Cycle dur: %f",cycle.duration));
        Log.d("Tempo",String.format(" Driven cycle dur:  %f",cycleDriven.duration));

        return BPMtoSet;
    }
}


