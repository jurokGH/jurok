package com.owlenome.owlenome;


import android.util.Log;

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

        //Теперь расставляем акценты.
        //Тут живёт особая философия, и делать это можно по-разному.
        //ToDo:   пробовать  по-разному и слушать.
        //ToDo: отправить это в дарт
        byte accents[]=GeneralProsody.getAccents1(beats.beatCount,false); //false - чтобы распевней



        //Ноты. Сначала сильные, потом слабые
        setOfNotes = new byte[musicScheme.setOfStrongNotes.length+musicScheme.setOfWeakNotes.length][];
        for(int i=0;i<musicScheme.setOfStrongNotes.length;i++){
            setOfNotes[i]=musicScheme.setOfStrongNotes[i];    }
        for(int i=0;i<musicScheme.setOfWeakNotes.length;i++){
            setOfNotes[i+musicScheme.setOfStrongNotes.length]=musicScheme.setOfWeakNotes[i]; }


        int[] symbols = new int[beats.beatCount];
        int[] symbolsDriven = new int[totalSubBeats];


        double totalLengthOfBeat=(musicScheme.weakBeat.length+musicScheme.strongBeat.length+2)*maxSubBeatCount;
        //ToDo:DoubleCheck
        //Это какой-то странноватый способ... Нужно
        //найти число,   удовлетворяющее для всех i неравенству
        //(totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) > 1


        BipAndPause[] _bipAndPauseMainSing = new BipAndPause[beats.beatCount];
        for (int i = 0; i < beats.beatCount; i++) {
            symbols[i] = accents[i];
            int noteLength = setOfNotes[symbols[i]].length;
            _bipAndPauseMainSing[i]=new BipAndPause(
                    noteLength / 2,
                    (totalLengthOfBeat / (noteLength / 2)) - 1
            );
        }

        BipAndPause[] _bipAndPauseSubSing = new BipAndPause[totalSubBeats];
        int k = 0;
        for (int i = 0; i < beats.beatCount; i++) {
            byte weakAccents[] = GeneralProsody.getAccents1(beats.subBeats.get(i), false);
            for (int j = 0; j < beats.subBeats.get(i); j++, k++) {
                symbolsDriven[k] = musicScheme.setOfStrongNotes.length + weakAccents[j];
                int noteLength = setOfNotes[symbolsDriven[k]].length;
                _bipAndPauseSubSing[k] = new BipAndPause(
                        noteLength / 2,
                        (totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) - 1
                );
                if (j == 0) {//начало доли
                    symbolsDriven[k] = elasticSymbol; //Можно и иначе.//ToDo: эксперимент
                }
            }
        }


        /* //ToDo:delete
        int k = 0;
        for (int i = 0; i < beats.beatCount; i++) {
            byte weakAccents[] = GeneralProsody.getAccents1(beats.subBeats.get(i), false);
            for (int j = 0; j < beats.subBeats.get(i); j++, k++) {
                if (j == 0) {//сильная доля
                    symbols[k] = accents[i];
                } else {
                    symbols[k] = musicScheme.setOfStrongNotes.length + weakAccents[j];
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
     * Переустанавливает биты.
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
        cycleDriven.readTempoLinear(newPos);

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
        //ToDo: не работает
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
        //ToDo: проверить, чтобы длины циклов совпадали!
        //cycleDriven.duration=cycle.duration;//ToDo: ЭТО БЕСПРЕДЕЛ УЖЕ, просто чтоб заработало
        cycleDriven.reSetDuration(); cycleDriven.reset();
        cycleDriven.readTempoLinear((int)cycle.durationBeforePosition());
        //ToDo: fraction part, что ещё - всю логику перепроверить.
        // - уже ничего ен понимаю, просто запустить хочу....




        Log.d("Tempo",String.format(" Cycle dur: %f",cycle.duration));
        Log.d("Tempo",String.format(" Driven cycle dur:  %f",cycleDriven.duration));


        return BPMtoSet;
    }
}


