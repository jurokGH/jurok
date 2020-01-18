package com.owlenome.owlenome;


//То, что мы будем играть. Определено с точностью до
// темпа (темп регулируется через setTempo)
class AccentedMelodyMix
{


    byte[][] setOfNotes;


    BipAndPause[] _bipAndPauseSing;
    private int _sampleRate;
    public BipPauseCycle cycle=null;
    private  BipPauseCycle newCycle=null;

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


        int[] symbols = new int[totalSubBeats];
        int elasticSymbol = -1;

        double totalLengthOfBeat=(musicScheme.weakBeat.length+musicScheme.strongBeat.length+2)*maxSubBeatCount;
        //ToDo:DoubleCheck
        //Это какой-то странноватый способ... Нужно
        //найти число,   удовлетворяющее для всех i неравенству
        //(totalLengthOfBeat / (beats.subBeats.get(i) * noteLength / 2)) > 1


        _bipAndPauseSing = new BipAndPause[totalSubBeats];
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
        }

        newCycle = new BipPauseCycle(symbols, elasticSymbol, _bipAndPauseSing, 1);

        newBeatCount= beats.beatCount;

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
        beatCount=newBeatCount;
        tempo=setTempo((int)tempo);
        //ToDo: ПЕРЕДЕЛАТЬ setTempo,  зачем я сделал эту глупость с int?

        int newPos =(int)(newPositionRel*cycle.duration);
        cycle.readTempoLinear(newPos);//ToDo: вешаем чайник; проматываем отыгранную длительность

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
    public int setTempo(int beatsPerMinute) //ToDo: нелогично, что это int.
    {
        int BPMtoSet = Math.min(
                (int) cycle.getMaximalTempo(_sampleRate,beatCount),
                beatsPerMinute
        );
        cycle.setNewDuration(
                Utility.beatsDurationInSamples(_sampleRate,beatCount,
                        BPMtoSet));

        tempo=BPMtoSet;
        return BPMtoSet;
    }

}


