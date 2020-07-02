package com.owlenome.owlenome;

import android.content.res.Resources;

//Этот класс представляет собой данные, нужные для создания массива из двух бипов (музыкальной схемы).
//Он нужен для того, чтобы определить музыкальные схемы, но не загружать
//их сразу (это было бы расточительно).
//Объект этого класса используется (когда бипы будет реально нужны) для генерации
//реального звука.
//
// //ToDo:
//Флаттеру нужно знать кое-что еще - а именно, картинку, представляющую схему.
//А вот данные о звуковых файлах ему не нужно знать. В любом случае,
//мы должны согласовывать руками всю эту бадягу.
class MusicSchemeMix
{
    //adHoc, под нашу задачу. Хватает для деления на 12 долей/поддолей
    final int absoluteMaxOfNoteAccents = 4;
    final int absoluteMaxOfSubAccents = 4;

    //ToDo: убрать
    enum SyntesType {
        from2files, syntesSimple, syntesSophisticated
    }

    final SyntesType type;
    //final
    String name;

    final GeneralProsody.AccentationType beatAccentationType;
    final GeneralProsody.AccentationType subBeatAccentationType;

    /**
     * Из частот, простые бипы-дудочка (синусоида), как игралось в шарманке
     *
     * @param name
     * @param subBeatFreq       /// Frequency (Hz)  of beat
     * @param subBeatDuration   ///duration (millisec) of  beat
     * @param beatFreq     /// Frequency (Hz)  of subbeat
     * @param beatDuration ///duration (millisec) of subbeat
     */
    MusicSchemeMix(String name,
                   double beatFreq, int beatDuration,
                   double subBeatFreq, int subBeatDuration,
                   GeneralProsody.AccentationType beatAccentationType,
                   GeneralProsody.AccentationType subBeatAccentationType
    ) {
        this.type = SyntesType.syntesSimple;
        this.name = name;
        this.subBeatDur = subBeatDuration;
        this.subBeatFreq = subBeatFreq;
        this.beatFreq = beatFreq;
        this.beatDuration = beatDuration;
        this.beatAccentationType =beatAccentationType;
        this.subBeatAccentationType =subBeatAccentationType;
    }


    /**
     * Из ресурсов
     *
     * @param name
     * @param res
     * @param strongFileIndex
     * @param weakFileIndex
     */
    MusicSchemeMix(String name, Resources res,
                   int strongFileIndex, int weakFileIndex,
                   GeneralProsody.AccentationType beatAccentationType,
                   GeneralProsody.AccentationType subbeatAcentationType) {
        this.res = res;
        this.name = name;
        this.type = SyntesType.from2files;
        this.beatFileIndex = strongFileIndex;
        this.weakFileIndex = weakFileIndex;
        this.beatAccentationType =beatAccentationType;
        this.subBeatAccentationType =subbeatAcentationType;
    }

    Resources res;
    int beatFileIndex, weakFileIndex;


    //параметры для sintesSimple

    double subBeatFreq;
    int subBeatDur;

    /// Frequency (Hz) and duration (millisec) of beat
    double beatFreq;
    int beatDuration;

    //
    //Параметры для сложной схемы
    //...todo...
    //---

    byte[] beatSound;
    byte[] subBeatSound;


    byte[][] setOfNotes;
    byte[][] setOfSubNotes;




    //Из частот и длительностей. ДОЛГАЯ! Линейна по длительности звуков, с большими коэффициентами (даблы, синусы, жуть)
    void load(int nativeSampleRate) {

        //Загружаем два базовых звука
        switch (type) {
            case syntesSimple: loadFromSinusoids(nativeSampleRate);
                break;

            case  from2files: loadFromRes(nativeSampleRate);
                break;

            default:

        }

        //Теперь создаём из них все нужные звуки
        switch (beatAccentationType) {
            case Dynamic:
                setOfNotes = GeneralProsody.dynamicAccents(beatSound,
                        absoluteMaxOfNoteAccents, GeneralProsody.beatDynamic);
                break;

            case Agogic://ToDo: тут ничего не нормализуется. Название - старый рудимент. И просодия - динамическая.
                setOfNotes = GeneralProsody.agogicAccentsNormalizedTmp(beatSound, subBeatSound,
                        absoluteMaxOfNoteAccents);
                break;

        }


        setOfSubNotes = GeneralProsody.dynamicAccents(subBeatSound,
                absoluteMaxOfSubAccents,GeneralProsody.subBeatDynamic);



        /*

        //TODO: убрать!!! ПОЛИГОН
        for(int i=0; i<setOfSubNotes.length;i++){
            setOfSubNotes[i]=MelodyToolsPCM16.changeVolume(setOfSubNotes[i],0.12);
        }

        //TODO: убрать!!! ПОЛИГОН
        for(int i=0; i<setOfNotes.length;i++){
            MelodyToolsPCM16.mixTMPPROBAPERA(setOfNotes[i],setOfSubNotes[0]);
        }*/
    }

    //Из частот. ДОЛГАЯ!
    private  void loadFromSinusoids(int nativeSampleRate) {


        MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

        int lengthWeak = (int) Utility.nanoSec2samples(nativeSampleRate, subBeatDur * 1000000);
        int lengthStrong = (int) Utility.nanoSec2samples(nativeSampleRate, beatDuration * 1000000);


        beatSound = melodyTools.getFreq(beatFreq, lengthWeak, 3, 2);//
        subBeatSound = melodyTools.getFreq(subBeatFreq, lengthStrong, 1, 3);//TODO BAD 2
    }

    //Из ресурсов. ДОЛГАЯ! Линейна по длительности звуков, с большими коэффициентами (даблы, чтение из файлов, жуть)
    private  void loadFromRes(int nativeSampleRate){
        beatSound = WavResources.getSoundFromResID(res,beatFileIndex,nativeSampleRate);
        subBeatSound = WavResources.getSoundFromResID(res, weakFileIndex,nativeSampleRate);
    }

    /*
    //Из двух готовых звуков - может, это самое прекрасное, что можно придумать? Быстрая:)
    private  void loadFromBytes(byte[] beatSound, byte[] subBeatSound )
    {        this.subBeatSound=subBeatSound; this.beatSound=beatSound;  //ОПАСНО. Не надо так  }
    */
}
