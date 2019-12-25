package com.owlenome.owlenome;

import android.content.res.Resources;

import com.owlenome.owlenome.GeneralProsody;


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

    private byte[] weakBeat;
    private byte[] strongBeat;


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
            case Agogic:
                setOfStrongNotes=GeneralProsody.agodicAccents(strongBeat,
                        absoluteMaxOfStrongAccents);

                break;
        }

        switch (weakAccentationType) {
            case Agogic:
                setOfStrongNotes = GeneralProsody.agodicAccents(weakBeat,
                        absoluteMaxOfWeakAccents);

                break;
        }
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

