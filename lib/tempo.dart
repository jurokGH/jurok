import 'dart:core';

class Tempo
{
  int beatsPerMinute;
  int denominator;

  // Пример: темп 240 восьмых в минуту
  // @param beatsPerMinute ударов в минуту
  // @param denominator  длительность удара (четвертая, шестнадцатая, etc)
  Tempo({this.beatsPerMinute, this.denominator});
}

class BipAndPause
{
  int bipDuration;
  double pauseFactor;

  BipAndPause(this.bipDuration, this.pauseFactor);
}

// Представляет элемент цикла
// a - элемент алфавита (номер ноты)
// l - его длина

class Pair
{
  int char;
  int len;

  Pair(this.char, this.len);
}

// Представляет позицию в цикле:
// n - номер элемента цикла, offset - смещение.

class Position
{
  int n;
  int offset;
  int cycle;

  Position(this.n, this.offset)
  {
    cycle = 0;
  }

  void reset()
  {
    n = offset = 0;
    cycle = 0;
  }
}
