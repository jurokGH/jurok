import 'dart:core';

/*How to do this kind of generic functions in dart?
T loop<T>(T x, T left, T right)
{
  return x > left ? right : (x < right ? left : x);
}
*/

int clamp(int x, int left, int right)
{
  //print('loopClamp $x - $left - $right');
  return x > right ? right : (x < left ? left : x);
}

int clampLoop(int x, int left, int right)
{
  //print('loopClamp $x - $left - $right');
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