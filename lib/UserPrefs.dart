import 'package:shared_preferences/shared_preferences.dart';

import 'rhythms.dart';

const int _cIniTempo = 120;  //121 - идеально для долгого теста, показывает, правильно ли ловит микросекунды
/// Initial metre (beat, note) index from _metreList
const int _cIniActiveMetre = 1;//3

class UserPrefs
{
  bool loaded = false;
  int subbeats = 1;
  int bpm = _cIniTempo;
  int activeMetre = _cIniActiveMetre;
  double volume = 100;
  /// Active sound scheme can be stored and set up on app init
  int activeSoundScheme = 0;
  List<UserRhythm> userRhythms;

  Future<bool> load() async
  {
    //Future<SharedPreferences>
    SharedPreferences prefs = await SharedPreferences.getInstance();
    subbeats = prefs.getInt('subbeats') ?? 1;
    bpm = prefs.getInt('bpm') ?? _cIniTempo;
    activeMetre = prefs.getInt('activeMetre') ?? _cIniActiveMetre;
    activeSoundScheme = prefs.getInt('activeSoundScheme') ?? 0;
    volume = prefs.getDouble('volume') ?? 100;
    List<String> rythms = prefs.getStringList('rythms');
    for (int i = 0; i < rythms.length; i++)
      userRhythms.add(UserRhythm.parse(rythms[i]));
    loaded = true;
    return new Future.value(true);
  }

  Future<List<bool>> store(int subbeats, int bpm, int activeMetre, int activeSoundScheme, double volume, List<UserRhythm> userRhythms) async
  {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    Future<bool> f0 = prefs.setInt('subbeats', subbeats);
    Future<bool> f1 = prefs.setInt('bpm', bpm);
    Future<bool> f2 = prefs.setInt('activeMetre', activeMetre);
    Future<bool> f3 = prefs.setInt('activeSoundScheme', activeSoundScheme);
    Future<bool> f4 = prefs.setDouble('volume', volume);
    List<String> rythms = new List<String>();
    for (int i = 0; i < rythms.length; i++)
      rythms.add(rythms[i].toString());
    Future<bool> f5 = prefs.setStringList('rythms', rythms);
    return Future.wait([f0, f1, f2, f3, f4, f5]);
  }
}
