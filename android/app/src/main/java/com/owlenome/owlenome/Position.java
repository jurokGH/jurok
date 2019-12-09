package com.owlenome.owlenome;

// Представляет позицию в цикле:
// n - номер элемента цикла, offset - смещение.

public class Position
{
  public int n;  // Number of cycle's element
  public int offset;  // Offset inside cycle's element in samples
  public int cycleCount;

  public Position(int n, int offset)
  {
    this.n = n;
    this.offset = offset;
    cycleCount = 0;
  }

  void reset()
  {
    offset = n = 0; //Без этого - как пауза!!!
    cycleCount = 0;
  }
}
