package com.owlenome.owlenome;

import android.content.res.Resources;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.InputStream;

  class WavResources {

    static final int wavSampleRate=44100;
    static final int headerSize=44;

    /**
     *  По ресурсу и его номеру возвращает звук, сэмплированный под нужную частоту в
     *  формате PCM16
     */
    public  static byte[] getSoundFromResID(Resources res,  int resourceId, int nativeSampleRate){
        byte[] rawSound=WavResources.readWavFromRawDirectory(res,resourceId);
        return reSample(rawSound,wavSampleRate,nativeSampleRate);
    }


    /**
     *  Пересэмплируем, интерполируя линейно.
     *
     *  TODO: Сомнительное место - как интерпретировать сэмпл? Он длится, как константа,
     *  в этом случае наш массив представляет собой полуинтервал [a,b), или же это точка?
     *
     *  Ниже я считаю, что сэмпл действует на полуинтервале времени (длиной  1/oldSampleRate секунды).
     *  Получившаяся арифметика даёт следующий (сомнительный!) эффект:
     *  если newSampleRate в несколько раз превышает начальный,
     *  то  несколько значений в конце нового массива совпадут (интерполируется константа)
     *  Может ли это дать щелк или треск?
     *  (ToDo: Видимо, может дать щелчок. И просто катушку аудиокарты спалит, бугага.
     *  Хорошо, что таких совпадений в конце будет не больше, чем отношение частот.
     *  Не будет ни на что влиять, если файл заканчивается тишиной. Тишина в конце файла - золото!)
     *
     *  Математически верным будет лишь такое решение, при котором будут "транзитивность"
     *  и "рефлексивность":
     *
     *  F(F(S,r_1,r_2),r_2,r_3) ~ F(S,r_1,r_3) (допускается погрешность на последнем сэмпле)
     *  и
     *  F(S,r,r)=S.
     *
     *  Надо бы проверить. При случае. Если будет шуметь...
     */
    private static byte[] reSample(byte[] samples, int oldSampleRate, int newSampleRate){
        if (oldSampleRate==newSampleRate) return samples;
        if ((oldSampleRate==0)||(newSampleRate==0)) return  samples;
        if (samples.length<2) return samples; //нельзя интерполировать меньше двух точек


        //собираем по два байта
        //int newLinFrames=(samples.length/2)*newSampleRate/oldSampleRate;
        int[] samples16=new int[samples.length/2];
        for (int i=0;i<samples16.length;i++){
            //ToDo: DC
            //samples16[i]=(samples[2*i+1]<<8)+samples[2*i]; //А это верно? Второй же со знаком!!!
            samples16[i]=(samples[2*i+1]<<8)|(0xFF&samples[2*i]);
        }

        double delta=(double)oldSampleRate/newSampleRate;
        int[] newSamples16=new int[(int)(samples16.length/delta)];
        int xLeft;
        int f_1,f_2;
        double positionInOld=0;
        for (int i=0;i<newSamples16.length;i++){
            xLeft=(int)positionInOld;//всегда попадает в границы начального массива
            f_1=samples16[xLeft];

            //но следующее за xLeft уже может выйти на 1 за пределы начального массива
            if (xLeft<samples16.length-1){f_2=samples16[xLeft+1];} else {f_2=samples16[samples16.length-1];}

            double interpolant=//f_1;
             (positionInOld-xLeft)*f_2+(1.0+xLeft-positionInOld)*f_1;
            newSamples16[i]=(int)interpolant;

            positionInOld+=delta;
        }

        //разбираем новый звук по байтам, чередуя их порядок
        byte[] newSamplesByte=new byte[newSamples16.length*2];
        //ToDo: битовая арифметика без шорт. DC
        for (int i=0; i<newSamples16.length;i++) {
            int sample = newSamples16[i];
            newSamplesByte[2 * i] = (byte) (sample & 0x00ff);
            newSamplesByte[2 * i + 1] = (byte)((sample & 0xff00) >>> 8);
        }

        return newSamplesByte;
    }




    /**
     * Массив байт как есть из wav-файла, со спецификацией:
     * 16PCM, mono, 44100, тишина в конце
     * Prepare our wavs carefully!
     *
     * @param resourceId
     * @return
     */
    private static byte[] readWavFromRawDirectory(Resources res,  int resourceId){

        InputStream inpStream =res.openRawResource(resourceId);
        ByteArrayOutputStream outStream = new ByteArrayOutputStream();

        byte[] buff = new byte[4096];
        int hasRead;
        try {
            inpStream.read(buff, 0, headerSize);
            while ((hasRead = inpStream.read(buff, 0, buff.length)) != -1)
            {
                outStream.write(buff, 0, hasRead);
            }
            inpStream.close();
        }
        catch (IOException e) {  e.printStackTrace(); }
        return outStream.toByteArray();
    }






}


