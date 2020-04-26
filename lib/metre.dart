import 'dart:core';

import 'prosody.dart';
import 'util.dart';

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

class MetreBar extends Metre
{
  int accentOption;
  List<int> accents;
  List<int> _regularAccents;

  MetreBar(int beats, int note, [this.accentOption = 0, this.accents]): super(beats, note)
  {
    accents = Prosody.getAccents(beats, accentOption == 0);
    _regularAccents = Prosody.getAccents(beats, true);  //TODO Define as regular if pivoVodochka = true?
  }

  List<int> simpleMetres(int accentOption)
  {
    return Prosody.getSimpleMetres(beats, accentOption == 0);
  }

  bool get regularAccent
  {
    //TODO only if _beatCount < 12
    if (beats == 5 || beats == 7 || beats == 11 ||
        accents.length != _regularAccents.length)
    {
      print('regular:false 1');
      return false;
    }
    for (int i = 0; i < accents.length; i++)
      if (accents[i] != _regularAccents[i])
      {
        print('regular:false 2');
        return false;
      }
    print('regular:true');
    return true;
  }

  /// Test if this metre has plain accent scheme: [1, 0, 0, ..]
  bool get plainAccent
  {
    return accents.isEmpty || (accents.length == 1 && accents[0] == 0) ||
      (accents[0] == 1 && accents.skip(1).every((int x) => x == 0));
  }

  //TODO Change to var?
  int get maxAccent =>  beats > 3 ? 3 : beats - 1;

  void setRegularAccent()
  {
    accents = _regularAccents;
  }

  void setPlainAccent()
  {
    for (int i = 1; i < accents.length; i++)
      accents[i] = 0;
    if (accents.length > 0)
      accents[0] = accents.length > 1 ? 1 : 0;
  }

  void setAccent(int beat, int accent)
  {
    assert(0 <= beat && beat < beats);
    if (beat < beats && accent <= maxAccent)
      accents[beat] = accent;
  }

  void accentUp(int beat, int step)
  {
    assert(0 <= beat && beat < beats);

    //TODO -1;
    if (beat < beats)
      accents[beat] = clamp(accents[beat] + step, 0, maxAccent);
  }

  int accentOptionCount()
  {
    return (beats == 5 || beats == 7 || beats == 7 || beats == 7) ? 2 : 1;
  }

  bool setAccentOption(int option)
  {
    //TODO
    if (option != accentOption) {
      accentOption = option;
      accents = Prosody.getAccents(beats, accentOption == 0);
      return true;
    }
    return false;
  }

  bool nextAccentOption([int dir = 1])
  {
    accentOption = accentOption == 0 ? 1 : 0;
    accents = Prosody.getAccents(beats, accentOption == 0);
    return true;
  }

  String toString()
  {
    return super.toString() + '-' + accentOption.toString();
  }
}
