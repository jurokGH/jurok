import 'dart:core';

import 'prosody.dart';
import 'util.dart';

/// Metre melody configuration: beats/note

class Metre
{
  /// Beat count (nominator)
  final int beats;
  /// Note value (denominator)
  final int note;

  Metre(this.beats, this.note);

  String toString() => beats.toString() + '/' + note.toString();
}

/// Metre bar configuration

class MetreBar extends Metre
{
  /// Beat accents
  /// accents.length == beats
  List<int> accents;
  /// Pivo-vodochka accentation option (>= 0)
  int accentOption;
  /// Store here to not compute every time
  List<int> _regularAccents;

  MetreBar(int beats, int note, [this.accentOption = 0, this.accents]): super(beats, note)
  {
    accents = Prosody.getAccents(beats, accentOption == 0);
    //TODO Define as regular if pivoVodochka = false?
    _regularAccents = Prosody.getAccents(beats, false);
  }

  /// Get simple metre division
  List<int> simpleMetres()
  {
    return Prosody.getSimpleMetres(beats, accentOption == 0);
  }

  /// Check if metre has regular accent scheme
  bool get regularAccent
  {
    //TODO only if _beatCount < 12
    if (beats == 5 || beats == 7 || beats == 11 ||
        accents.length != _regularAccents.length)
      return false;
    for (int i = 0; i < accents.length; i++)
      if (accents[i] != _regularAccents[i])
        return false;
    return true;
  }

  /// Check if metre has plain accent scheme: [1, 0, 0, ..]
  bool get plainAccent
  {
    return accents.isEmpty || (accents.length == 1 && accents[0] == 0) ||
      (accents[0] == 1 && accents.skip(1).every((int x) => x == 0));
  }

  /// Maximum accent
  //TODO Change to var?
  int get maxAccent =>  beats > 3 ? 3 : beats - 1;

  /// Set regular accent scheme
  void setRegularAccent()
  {
    for (int i = 1; i < accents.length; i++)
      accents[i] = _regularAccents[i];
    // TODO Should change? Should use for?
    //_regularAccents = Prosody.getAccents(beats, true);  //TODO Define as regular if pivoVodochka = true?
    //accents = new List.from(_regularAccents);
  }

  /// Set plain accent scheme: [1, 0, 0, ..]
  void setPlainAccent()
  {
    for (int i = 1; i < accents.length; i++)
      accents[i] = 0;
    if (accents.length > 0)
      accents[0] = accents.length > 1 ? 1 : 0;
  }

  /// Set beat accent
  void setAccent(int beat, int accent)
  {
    assert(0 <= beat && beat < beats);
    if (beat < beats && accent <= maxAccent)
      accents[beat] = accent;
  }

  /// Change beat accent by +-step
  void accentUp(int beat, int step)
  {
    assert(0 <= beat && beat < beats);

    //TODO -1;
    if (beat < beats)
      accents[beat] = clamp(accents[beat] + step, 0, maxAccent);
  }

  /// Set accentation option (>= 0)
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

  /// Change accentation option by +-dir
  bool nextAccentOption([int dir = 1])
  {
    accentOption = accentOption == 0 ? 1 : 0;
    accents = Prosody.getAccents(beats, accentOption == 0);
    return true;
  }

  String toString() => super.toString() + '-' + accentOption.toString();
}

/// Search (beast, note) in partly-_sorted_ metre list
/// return:
///   metre index if found
///   index where insert new metre if (beast, note) not found in list
int metreIndex(List<MetreBar> metreList, int beats, int note) {
  if (metreList.length == 0 || beats < metreList[0].beats)
    return 0;
  int i = 0;
  // Check if there is exactly same metre for unsorted metre lists
  for (; i < metreList.length; i++)
    if (beats == metreList[i].beats && note == metreList[i].note)
      return i;
  i = 0;
  while (i < metreList.length && beats > metreList[i].beats ||
      (beats == metreList[i].beats && note > metreList[i].note))
    i++;
  return i;
}
