package com.owlenome.owlenome;

import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.PorterDuff;
import android.graphics.RectF;

/**
 * Рисует цикл в зависимости от позиции и задержки latency
 */
public class BarrelOrgan
{

  final Canvas canvas;
  final RectF oval;
  final Paint paint;

  float centerX;
  float centerY;
  float rad;

  BipPauseCycle bipPauseCycle;

  BarrelOrgan(BipPauseCycle bipPauseCycle,
              //Canvas canvas,
              Bitmap bitmap,
              RectF oval)
  {
    //this.canvas=canvas;
    this.bipPauseCycle = bipPauseCycle;
    this.oval = oval;

    paint = new Paint();
    paint.setStyle(Paint.Style.STROKE);
    //paint.setAntiAlias(true);//ToDo:???

    centerX = 0.5F * (oval.left + oval.right);
    centerY = 0.5F * (oval.top + oval.bottom);
    rad = Math.min(oval.right - oval.left, oval.bottom - oval.top) * 0.5F;

    setAngles();

    canvas = new Canvas(bitmap);
  }

  /**
   * Вызывается при изменении цикла (в частности, при изменении tempo)
   *
   * @param cycle Новый цикл.
   *              В теории может никак не быть свзязан со старым, но
   *              это пока не тестировалось.
   *              Работает корректно при изменении длин эластиков (изменении темпа)
   */
  public void reSetAngles(BipPauseCycle cycle)
  {
    this.bipPauseCycle = cycle;
    setAngles();
  }

  private void setAngles()
  {
    length = bipPauseCycle.cycle.length;
    totalDurInt = 0; //Игнорируем дробные части
    // TODO VG
    for (int i = 0; i < length; i++)
      totalDurInt += bipPauseCycle.cycle[i].l;
    if (totalDurInt == 0) return;

    //Получаем углы.
    samplesToDegree = 360F / totalDurInt;
    anglesDeg = new float[length + 1];
    anglesRad = new double[length + 1];
    anglesDeg[0] = 0F;
    anglesDeg[length] = 360F;
    for (int i = 1; i < length; i++)
    {
      anglesDeg[i] = anglesDeg[i - 1] + (samplesToDegree * bipPauseCycle.cycle[i - 1].l);
      //С ног на голову...
      anglesRad[i] = degreeToRad(anglesDeg[i]);
    }
  }

  /**
   * Нужны для дурацкого овала
   */
  private float[] anglesDeg;
  /**
   * Человеческие углы цикла (в радианах)
   */
  private double[] anglesRad;
  private int length, totalDurInt, totalPlayed;
  float rotateAngleDeg;
  double rotateAngleRad;

  float samplesToDegree;

  public void draw(long latencyInFrames)
  {
    totalPlayed = 0;
    for (int i = 0; i < bipPauseCycle.position.n; i++)
      totalPlayed += bipPauseCycle.cycle[i].l;
    totalPlayed += bipPauseCycle.position.offset;

    rotateAngleDeg = 90F + samplesToDegree * (latencyInFrames - totalPlayed);
    rotateAngleRad = degreeToRad(rotateAngleDeg);


    //Рисуем
    canvas.drawColor(Color.TRANSPARENT, PorterDuff.Mode.CLEAR);
    //canvas.drawColor(Color.WHITE);


    //Линии
    paint.setColor(Color.BLUE);
    paint.setStrokeWidth(7);

    for (int i = 0; i < length; i++)
    {
      if (bipPauseCycle.cycle[i].a != bipPauseCycle.elasticSymbol)
      {
        //     canvas.drawArc(oval, anglesDeg[i]+rotateAngleDeg, anglesDeg[i + 1] - anglesDeg[i], true, paint);


        //ToDo: лишний счет
        canvas.drawLine(centerX + rad * (float) Math.cos(anglesRad[i] + rotateAngleRad),
          centerY + rad * (float) Math.sin(anglesRad[i] + rotateAngleRad),
          centerX + rad * (float) Math.cos(anglesRad[i + 1] + rotateAngleRad),
          centerY + rad * (float) Math.sin(anglesRad[i + 1] + rotateAngleRad), paint);
      }
    }
    paint.setColor(Color.BLACK);
    paint.setStrokeWidth(3);
    canvas.drawArc(oval, 89.5F, 1F, true, paint);
  }

    /*
     void drawLineOnCircle(float angle1rad, float angle2rad){
        canvas.drawLine(centerX+rad*(float)Math.cos(angle1rad),
                centerY+rad*(float) Math.sin(angle1rad),
                centerX+rad*(float)Math.cos(angle2rad),
                centerY+rad*(float)Math.sin(angle2rad), paint);
    }*/

  double degreeToRad(float angl)
  {
    return angl * Math.PI / 180F;
  }

}
