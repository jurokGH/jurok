package com.owlenome.owlenome;

import android.content.res.Resources;


//Этот класс представляет собой данные, нужные для создания массива двух бипов (музыкальной схемы).
//Он нужен для того, чтобы определить музыкальные схемы, но не загружать
//их сразу (это было бы расточительно).
//Объект этого класса используется (когда бипы будет реально нужны) для генерации
//реального звука.
//
// //ToDo:
//Флаттеру нужно знать кое-что еще - а именно, картинку, представляющую схему.
//А вот данные о звуковых файлах ему не нужно знать. В любом случае,
//мы должны согласовывать руками всю эту бадягу.
class MusicSchemeMix {
    //adHoc, под нашу задачу. Хватает для деления на 12 долей/поддолей
    final int absoluteMaxOfStrongAccents =4;
    final int absoluteMaxOfWeakAccents =4;

    //ToDo: убрать
    enum SyntesType {
        from2files, syntesSimple, syntesSophisticated
    }

    final SyntesType type;
    final String name;

    final GeneralProsody.AccentationType strongAccentationType;
    final GeneralProsody.AccentationType weakAccentationType;

    /**
     * Из частот, простые бипы-дудочка (синусоида), как игралось в шарманке
     *
     * @param name
     * @param beatFreq       /// Frequency (Hz)  of weak beat
     * @param beatDuration   ///duration (millisec) of weak beat
     * @param accentFreq     /// Frequency (Hz)  of weak beat
     * @param accentDuration ///duration (millisec) of weak beat
     */
    MusicSchemeMix(String name,
                   double beatFreq, int beatDuration,
                   double accentFreq, int accentDuration,
                   GeneralProsody.AccentationType strongAccentationType,
                   GeneralProsody.AccentationType weakAccentationType
    ) {
        this.type = SyntesType.syntesSimple;
        this.name = name;
        this.beatDuration = beatDuration;
        this.beatFreq = beatFreq;
        this.accentFreq = accentFreq;
        this.accentDuration = accentDuration;
        this.strongAccentationType=strongAccentationType;
        this.weakAccentationType=weakAccentationType;
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
                   GeneralProsody.AccentationType strongAccentationType,
                   GeneralProsody.AccentationType weakAccentationType) {
        this.res = res;
        this.name = name;
        this.type = SyntesType.from2files;
        this.strongFileIndex = strongFileIndex;
        this.weakFileIndex = weakFileIndex;
        this.strongAccentationType=strongAccentationType;
        this.weakAccentationType=weakAccentationType;
    }

    Resources res;
    int strongFileIndex, weakFileIndex;


    //параметры для sintesSimple

    double beatFreq;
    int beatDuration;
    /// Frequency (Hz) and duration (millisec) of accent (strong) beat
    double accentFreq;
    int accentDuration;

    //
    //Параметры для сложной схемы
    //...todo...
    //---

    byte[] weakBeat;
    byte[] strongBeat;


    byte[][] setOfStrongNotes;
    byte[][] setOfWeakNotes;




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
        switch (strongAccentationType){
            case Dynamic:
                setOfStrongNotes=GeneralProsody.dynamicAccents(strongBeat,
                        absoluteMaxOfStrongAccents);

                break;
        }

        switch (weakAccentationType) {
            case Dynamic:
                setOfWeakNotes = GeneralProsody.dynamicAccents(weakBeat,
                        absoluteMaxOfWeakAccents);

                break;
        }



        /*

        //TODO: убрать!!! ПОЛИГОН
        for(int i=0; i<setOfWeakNotes.length;i++){
            setOfWeakNotes[i]=MelodyToolsPCM16.changeVolume(setOfWeakNotes[i],0.12);
        }

        //TODO: убрать!!! ПОЛИГОН
        for(int i=0; i<setOfStrongNotes.length;i++){
            MelodyToolsPCM16.mixTMPPROBAPERA(setOfStrongNotes[i],setOfWeakNotes[0]);
        }*/
    }

    //Из частот. ДОЛГАЯ!
    private  void loadFromSinusoids(int nativeSampleRate) {


        MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

        int lengthWeak = (int) Utility.nanoSec2samples(nativeSampleRate, beatDuration * 1000000);
        int lengthStrong = (int) Utility.nanoSec2samples(nativeSampleRate, accentDuration * 1000000);


        weakBeat = melodyTools.getFreq(beatFreq, lengthWeak, 2, 2);
        strongBeat = melodyTools.getFreq(accentFreq, lengthStrong, 2, 2);
    }

    //Из ресурсов. ДОЛГАЯ! Линейна по длительности звуков, с большими коэффициентами (даблы, чтение из файлов, жуть)
    private  void loadFromRes(int nativeSampleRate){
        weakBeat= WavResources.getSoundFromResID(res,weakFileIndex,nativeSampleRate);
        strongBeat= WavResources.getSoundFromResID(res,strongFileIndex,nativeSampleRate);
    }

    /*
    //Из двух готовых звуков - может, это самое прекрасное, что можно придумать? Быстрая:)
    private  void loadFromBytes(byte[] weakBeat, byte[] strongBeat )
    {        this.strongBeat=strongBeat; this.weakBeat=weakBeat;  //ОПАСНО. Не надо так  }*/



}




//Этот класс представляет собой данные, нужные для создания массива двух бипов (музыкальной схемы).
//Он нужен для того, чтобы определить музыкальные схемы, но не загружать
//их сразу (это было бы расточительно).
//Объект этого класса используется (когда бипы будет реально нужны) для генерации
//реального звука.
//
// //ToDo:
//Флаттеру нужно знать кое-что еще - а именно, картинку, представляющую схему.
//А вот данные о звуковых файлах ему не нужно знать. В любом случае,
//мы должны согласовывать руками всю эту бадягу.
class MusicScheme2Bips {
    //adHoc, под нашу задачу. Хватает для деления на 12 долей/поддолей
    final int absoluteMaxOfStrongAccents =4;
    final int absoluteMaxOfWeakAccents =4;

    enum SyntesType {
        from2files, syntesSimple, syntesSophisticated
    }

    final SyntesType type;
    final String name;

    final GeneralProsody.AccentationType strongAccentationType;
    final GeneralProsody.AccentationType weakAccentationType;

    /**
     * Из частот, простые бипы-дудочка (синусоида), как игралось в шарманке
     *
     * @param name
     * @param beatFreq       /// Frequency (Hz)  of weak beat
     * @param beatDuration   ///duration (millisec) of weak beat
     * @param accentFreq     /// Frequency (Hz)  of weak beat
     * @param accentDuration ///duration (millisec) of weak beat
     */
    MusicScheme2Bips(String name,
                     double beatFreq, int beatDuration,
                     double accentFreq, int accentDuration,
                      GeneralProsody.AccentationType strongAccentationType,
                     GeneralProsody.AccentationType weakAccentationType
                     ) {
        this.type = SyntesType.syntesSimple;
        this.name = name;
        this.beatDuration = beatDuration;
        this.beatFreq = beatFreq;
        this.accentFreq = accentFreq;
        this.accentDuration = accentDuration;
        this.strongAccentationType=strongAccentationType;
        this.weakAccentationType=weakAccentationType;
    }


    /**
     * Из ресурсов
     *
     * @param name
     * @param res
     * @param strongFileIndex
     * @param weakFileIndex
     */
    MusicScheme2Bips(String name, Resources res,
                     int strongFileIndex, int weakFileIndex,
                     GeneralProsody.AccentationType strongAccentationType,
                     GeneralProsody.AccentationType weakAccentationType) {
        this.res = res;
        this.name = name;
        this.type = SyntesType.from2files;
        this.strongFileIndex = strongFileIndex;
        this.weakFileIndex = weakFileIndex;
        this.strongAccentationType=strongAccentationType;
        this.weakAccentationType=weakAccentationType;
    }

    Resources res;
    int strongFileIndex, weakFileIndex;


    //параметры для sintesSimple

    double beatFreq;
    int beatDuration;
    /// Frequency (Hz) and duration (millisec) of accent (strong) beat
    double accentFreq;
    int accentDuration;

    //
    //Параметры для сложной схемы
    //...todo...
    //---

     byte[] weakBeat;
     byte[] strongBeat;


    byte[][] setOfStrongNotes;
    byte[][] setOfWeakNotes;




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
        switch (strongAccentationType){
            case Dynamic:
                setOfStrongNotes=GeneralProsody.dynamicAccents(strongBeat,
                        absoluteMaxOfStrongAccents);

                break;
        }

        switch (weakAccentationType) {
            case Dynamic:
                setOfWeakNotes = GeneralProsody.dynamicAccents(weakBeat,
                        absoluteMaxOfWeakAccents);

                break;
        }



        /*

        //TODO: убрать!!! ПОЛИГОН
        for(int i=0; i<setOfWeakNotes.length;i++){
            setOfWeakNotes[i]=MelodyToolsPCM16.changeVolume(setOfWeakNotes[i],0.12);
        }

        //TODO: убрать!!! ПОЛИГОН
        for(int i=0; i<setOfStrongNotes.length;i++){
            MelodyToolsPCM16.mixTMPPROBAPERA(setOfStrongNotes[i],setOfWeakNotes[0]);
        }*/
    }

    //Из частот. ДОЛГАЯ!
    private  void loadFromSinusoids(int nativeSampleRate) {


        MelodyToolsPCM16 melodyTools = new MelodyToolsPCM16(nativeSampleRate);

        int lengthWeak = (int) Utility.nanoSec2samples(nativeSampleRate, beatDuration * 1000000);
        int lengthStrong = (int) Utility.nanoSec2samples(nativeSampleRate, accentDuration * 1000000);


        weakBeat = melodyTools.getFreq(beatFreq, lengthWeak, 2, 2);
        strongBeat = melodyTools.getFreq(accentFreq, lengthStrong, 2, 2);
    }

    //Из ресурсов. ДОЛГАЯ! Линейна по длительности звуков, с большими коэффициентами (даблы, чтение из файлов, жуть)
    private  void loadFromRes(int nativeSampleRate){
        weakBeat= WavResources.getSoundFromResID(res,weakFileIndex,nativeSampleRate);
        strongBeat= WavResources.getSoundFromResID(res,strongFileIndex,nativeSampleRate);
    }

    //Из двух готовых звуков - может, это самое прекрасное, что можно придумать? Быстрая:)
    private  void loadFromBytes(byte[] weakBeat, byte[] strongBeat )
    {        this.strongBeat=strongBeat; this.weakBeat=weakBeat;    }



}




