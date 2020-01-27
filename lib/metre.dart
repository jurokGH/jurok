import 'dart:core';

/// Metre melody configuration

class Metre
{
  final int beats;
  final int note;

  Metre(this.beats, this.note);

  String toString()
  {
    return beats.toString() + '/' + note.toString();
  }
}
