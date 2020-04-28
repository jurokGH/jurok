import 'dart:core';
import 'dart:math';
import 'dart:ui';

/*How to do this kind of generic functions in dart?
T loop<T>(T x, T left, T right)
{
  return x > left ? right : (x < right ? left : x);
}
*/

/// Clamp x into [left, right]
int clamp(int x, int left, int right)
{
  return x > right ? right : (x < left ? left : x);
}

/// Clamp x into [left, right] as a loop
int clampLoop(int x, int left, int right)
{
  return x > right ? left : (x < left ? right : x);
}

/// Return index of note in array of note values: [1, 1/2, 1/4, ...]
///   noteValue - denominator of note
int noteValue2index(int noteValue)
{
  int index = 0;
  while (noteValue > 1)
  {
    noteValue >>= 1;
    index++;
  }
  return noteValue >= 0 ? index : -1;
}

int index2noteValue(int index)
{
  int noteValue = 1;
  while (index > 0)
  {
    noteValue <<= 1;
    index--;
  }
  return index >= 0 ? noteValue : -1;
}

/// Compare 2 lists of integers
bool equalLists(List<int> a, List<int> b)
{
  if (a == null && b == null)
    return true;
  else if (a == null || b == null)
    return false;
  else if (a.length == b.length)
  {
    for (int i = 0 ; i < a.length; i++)
      if (a[i] != b[i])
        return false;
    return true;
  }
  else
    return false;
}

/// Return maximum value in list
int maxValue(List<int> list)
{
  int value = 0;
  for (int i = 0; i < list.length; i++)
    if (value < list[i])
      value = list[i];
  return value;
}

/// /////////////////////////////////////////////////////////////////////////
/// Layout helpers

/// Calculate tempo knob radius depending on control area size and other sizes
/// width, height - control area size
/// radiusT - radius of play button
/// sidePadding - min (x, y) padding between all controls and area edges
/// knobPadding - min (x, y) padding around knob
/// dist0 - min padding between knob and play button
List<double> knobRadius(double width, double height, double radiusT,
  Offset sidePadding, Offset knobPadding, double dist0, double radiusBtn)
{
  double padX = sidePadding.dx;
  double padY = sidePadding.dy;
  double padX0 = knobPadding.dx;
  double padY0 = knobPadding.dy;

  double x = 0.5 * width - radiusT - padX;
  double y = 0.5 * height - radiusT - padY;
  double radius1 = sqrt(x * x + y * y) - dist0 - radiusT;

  double y1 = height - padY0 - radiusT - padY;
  double a = radiusT + dist0;
  print('$x - $y - $y1 - $a - $radiusT');
  double radius2 = 0.5 * (x * x + y1 * y1 - a * a) / (a + y1);

  double radius = min(0.5 * height - padY0, 0.5 * width - padX0);
  //print('${0.5 * height - padY0} - ${0.5 * width - padX0}');
  //print('$radius - $radius1 - $radius2 - $width - $height');

  //if (radius > radius1)
  //radius = radius1;
  if (radius > radius2)
    radius = radius2;
  print('$radius');

  double x2 = 0.5 * width - 2 * padX;
  double y2 = radius + padY0 < 0.5 * height ? radius + padY0 : 0.5 * height;
  y2 -= padY;
  //double y2 = 0.5 * height - padY;
  double z2 = radius + dist0;
  //(radius + dist0 + radiusBtn)**2 = (0.5 * width - 3 * radiusBtn - 2 * padX)**2 + (0.5 * height - radiusBtn - padY)**2;
  //9 * xx * xx - 2 * xx * (3 * x2 + y2 + z2) + x2 * x2 + y2 * y2 - z2 * z2 = 0;
  double b = (3 * x2 + y2 + z2) / 9;
  double d = b * b - (x2 * x2 + y2 * y2 - z2 * z2) / 9;
  if (d >= 0)
    d = sqrt(d);
  else
    print("D < 0");
  double xx1 = b + d;
  double xx2 = b - d;
  double xx = xx1 < radius ? xx1 : xx2;
  //print("Button $radius - $xx1 - $xx2 - $radiusBtn");

  return [radius, xx];
}
