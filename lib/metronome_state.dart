import 'package:flutter/foundation.dart';

import 'beat_metre.dart';

/// время начального бита,  скорость,
/// и время, когда они должны быть применены.
/// Пока время не пришло - ничего не меняем.

class Cauchy
{
  int timeOrg;
  int bpm;
  int timesToChangeTime;

  Cauchy(this.timeOrg, this.bpm, this.timesToChangeTime);
}

/// State of current metronome (playing) activity

class MetronomeState with ChangeNotifier
{
  BeatMetre beatMetre;
  /// Current active (playing) beat (note)
  int _activeBeat = -1;
  /// Current active (playing) subbeat of current beat
  int _activeSubbeat = -1;
  int _activeTime = 0;
  List<int> _activeTimes;

  int get activeBeat => _activeBeat;
  int get activeSubbeat => _activeSubbeat;

  double btnSmallSize = 0;

  ///  start time of A first beat (in microseconds)
  int _timeOrg;

  ///Время, когда знаем время первого  звука (microseconds)
  ///Пока не наступило - не анимируемся (еще не отыгран буфер тишины)
  ///Используется лишь один раз
  ///(и может быть полезно для статистики).
  int _timeOfTheFirstBeat = (2<<53); //end of time

  int _beatsPerMinute;

  /// Помимо синхронизации начального времени, есть  следующая (небольшая, но забавная) проблема.
  /**
      При изменении скорости мы можем продолжить играть анимацию со старой, или перейти
      сразу на новую скорость анимации. В обоих случаях мы какое-то время не знаем,
      что реально происходит со звуком: мы получим ответ от явы, потратив, скажем, 20 мс
      на обмен посланиями и плюс время,
      пока Ява ждёт  в тесном цикле возможности изменить темп
      (то есть время на запись числа сэмплов framesToWriteAtOnce в audio потоке).
      На это время анимация разъедется со звуком из за разницы в скоростях.
      Потом всё будет хорошо, и в принципе это не сильный баг
      (если очень постараться, то можно добиться такого визуального эффекта,
      когда будет "отскок" анимации - перерисовка  предыдущего состояния).
      Как уменьшить время неопределнности?

      Пусть:
      b - время проигрывания  уже записанного в буфер
      (большой буфер в нашем аудио потомке, сейчас 160мс);
      fj - время на сообщение от флаттера к яве   (условно, 20 мс)
      s - время ожидания в тесном потоке для изменения скорости аудио (ограничивается сверху упомянутой выше
      константой framesToWriteAtOnce, эквивалентной сейчас 80 мс).


      Если играем анимацию сразу с новой скоростью,
      то суммарное время расхожения T будет порядка
      b+jf+s
      Поэтому T легко может превысить четверть секунды.

      Если же играем анимацию со старой скоростью, то за счет того,
      что в большом буфере всё будет играться с такой же еще какое-то время,
      мы можем узнать от явы о том, когда именно начинается новая скорость
      раньше, чем доиграется большой буфер!
      А именно, мы будем знать ответ через
      fj+s+jf,
      где jf - время на сообщение от от явы к флаттеру   (условно, 20 мс).
      Получаем: fj+s+jf<b.
   */

  ///Новые времена и нравы (скорости), и когда они применимы. Пока время не пришло - ничего не меняем.
  List<Cauchy> _conditions;
  //bool bWaitingForNewBPM;

  //AccentBeat melody; //IS: Why?
  //Position pos;
  //DateTime _time0 = new DateTime.fromMillisecondsSinceEpoch(0);
  //Stopwatch _timer;
  //List<Int32> _list;
  //Int32List _list;
  //UnmodifiableInt32ListView get list => _list;
  //UnmodifiableListView<Int32> get list => UnmodifiableListView<Int32>(_list);

  //BeatMetre get BeatMetre => _beat;

  MetronomeState(List<int> subBeats0, List<int> accents0)
  {
    beatMetre = new BeatMetre(subBeats0, accents0);
    reset();
    _activeTimes = new List<int>.filled(subBeats0.length, 0);
    //tempo = new Tempo();
    //pos = new Position(-1, 0);
    //_timer = new Stopwatch();
  }

  /// Вызываем перед началом разогрева
  /// До начала анимации - условно 100 - 500 мс
  void reset()
  {
    _activeBeat = -1;
    _activeSubbeat = -1;
    _conditions = new List<Cauchy>();
  }

  ///Вызываем, когда разогрелись и точно знаем звучание первого бита.
  ///Опережает на время большого буфера Явы начало анимации (условно, 100мс)
  void startAfterWarm(int initTime, int bpm)
  {
    //_timeOrg = DateTime.now().microsecondsSinceEpoch;  //IS: No((( Злой латенси еще...
    _timeOfTheFirstBeat = initTime;
    _timeOrg = initTime;
    _beatsPerMinute = bpm;
    /*
    _timer.reset();
    __time0 = _timer.elapsedMicroseconds;
    if (!_timer.isRunning)
      _timer.start();
     */
  }

  /// Устанавливаем время первого бита и BMP, и время, когда они вступают в силу.
  ///
  /// !!!!Устанавливать только после согласования с явой!!!!
  /// Иначе разойдутся анимация и видео.
  ///
  /// Эти параметры необходимы и достаточны для синхронизации
  /// звука.
  ///
  /// Важно! - Почему они необходимы?
  /// Мы не можем устанавливать темп независимо от начального времени.
  /// Действительно, мы не знаем в принципе, сколько времени шли сообщения от флаттера к яве,
  /// и сколько ява будет ждать в тесном цикле.
  /// Кроме того, существенное время будет доигрывалаться мелодия в старом темпе -
  ///  ей заполнен буфер  (это могут быть сотни миллисекунд).
  ///
  /// Задача в том, что мы должны успеть из флаттера пообщаться с явой быстрее, чем отыграется
  /// большой буфер. Послале яве запрос на новый темп, дождались, пока она там разберётся у себя,
  /// и ответит нам, когда ждать первого звука, с которого всё играется с новой скоростью.
  ///
  ///
  ///
  void sync(int initTime, int newBpm, int timeToChangeTime)
  {
    Cauchy condition=new Cauchy(initTime,newBpm,timeToChangeTime);
    _conditions.add(condition);

    /* ОДНОГО НАБОРА УСЛОВИЙ НЕ ХВАТИТ, если злой пользователь зажмет ручку скорости
    bWaitingForNewBPM=true;
    _newTimeOrg=initTime;
    newBPM = newBpm;
    this.timeToChangeTime=timeToChangeTime;
    */
    /*
    //test
    int l=_conditions.length;
    print('Sync length: $l');

    String s='Sync delta times (from now) : ';
    int prevTm=DateTime.now().microsecondsSinceEpoch;
    for (int i = 0; i<_conditions.length; i++){
      int t=_conditions[i].timesToChangeTime-prevTm;
      prevTm=_conditions[i].timesToChangeTime;
      s+=t.toString()+'; ';
    }
    print(s);*/
  }

  /*
  void stop()
  {
    if (_timer.isRunning)
      _timer.stop();
  }
*/

  /* IS: Старый синк
  /// Synchronize metronome state with current sound state from Java
  void sync(int index, double offset, int beat, int subbeat, int time)
  {
    _timeOrg = DateTime.now().microsecondsSinceEpoch;//IS: Oh, why? //TODO
    //TODO Use pair/tuple
    List<int> pair = beatMetre.beatPair(index);
    // Correct reference sync time as a beat metre start time
    double t = beatMetre.timeOfBeat( _beatsPerMinute, pair[0], pair[1]);
    _timeOrg -= (1e+6 * (t + offset)) ~/ 1; //IS:   ??
    //VG Do we need to use Java current beat state?
    //_activeBeat = pair[0];
    //_activeSubbeat = pair[1];
  }
   */

  bool update()
  {
    bool changed = false;
    if (_timeOrg == null)
      return changed;

    int time = DateTime.now().microsecondsSinceEpoch;

    if (time < _timeOfTheFirstBeat)
      return changed;  //IS: звука пока нет. Пока просто молчим.
    //Нужно что-то поумнее придумать в этот период. Новости там пользователю
    //предложить почитать или что еще... Закрытые глаза спящих сов стали полуоткрыты?
    //Совы вздрогнули?//ToDo

    while (_conditions.length > 0 && time >= _conditions[0].timesToChangeTime)
    {
      // пришло время жить с новой скоростью
      _timeOrg = _conditions[0].timeOrg;
      _beatsPerMinute = _conditions[0].bpm;
      _conditions.removeAt(0);  //IS: FiFo... Не знаю, как умно это сделать в dart

      String s = 'SYNC UPDATE: Delta times (from now) : ';
      int prevTm = DateTime.now().microsecondsSinceEpoch;
      for (int i = 0; i < _conditions.length; i++)
      {
        int t = _conditions[i].timesToChangeTime - prevTm;
        prevTm = _conditions[i].timesToChangeTime;
        s += t.toString() + '; ';
      }
      print(s);
    }
    //ToDo: Для теста.
    // Ситуация, когда while сработал больше одного раза означает,
    // что мы не успели получить данные от Явы вовремя, и
    // какое-то время (от начального condition но now) рисовали анимацию
    // по данным, отличных от тех, по которым игрался звук.
    // Нужно при выборе значения буфера
    // потестировать такие опоздания.

/* // Первый вариант. Позволяет злому пользователю сделать небольшой рассинхрон,
   // активно дергая ручку темпа.
    if (bWaitingForNewBPM&&(time>=timeToChangeTime)){//пришло время жить с новой скоростью
      bWaitingForNewBPM=false;
      _timeOrg=_newTimeOrg;
      _beatsPerMinute=newBPM;
    }*/

    double dt = 1e-6 * (time - _timeOrg);  // in seconds

    List<int> pair = timePosition(dt, _beatsPerMinute);
    int curBeat = pair[0];
    int curSubbeat = pair[1];
    _activeTime = pair[2];

//    if (_activeTimes.length != beatMetre.beatCount)
//      _activeTimes.length = beatMetre.beatCount;
//    for (int i = 0; i < _activeTimes.length; i++)

    if (curBeat != _activeBeat || curSubbeat != _activeSubbeat)
    {
      changed = true;
      _activeBeat = curBeat;
      _activeSubbeat = curSubbeat;
      //debugPrint('Active (beat, subbeat): $_activeBeat - $activeSubbeat');
    }
    return changed;
  }

  /// Start time (in seconds) of [beat, subbeat] sound relating to begin of this beat metre
  /// bpm - tempo, beats per minute
  /// time - time from begin in seconds
  List<int> timePosition(double time, int bpm)
  {
    double duration = beatMetre.beatCount * 60.0 / bpm;  // in seconds
    //Position pos = new Position(0, 0);
    //int cycle = time ~/ duration;
    if (time < 0) {} //Такое может быть! Если latency большое, то легко.
    //time = -time;//IS:  это неверно. Даёт забавный эффект  -
    // если сделать к примеру размер большого буфера 300мс, то будем назад ехать:)

    //print('timePosition0 $duration');

    double timeInMetre = time % duration;
    duration /= beatMetre.beatCount;  // Duration of a beat
    int beat = timeInMetre ~/ duration;  // Active beat number
    //print('timePosition1 $duration - $timeInBeat - $beat - ${subBeats[beat]}');
    double timeInBeat = timeInMetre % duration;
    double timeInBeatRel = (timeInMetre % duration) / duration;
    duration /= beatMetre.subBeats[beat];  // Duration of a subbeat of an active beat
    int subbeat = timeInBeat ~/ duration;  // Active subbeat number
    double offset = timeInBeat % duration;

    double timeInSubbeat = (timeInBeat % duration) / duration;

    //for (int i = 0; i < beatMetre.beatCount; i++)

    //print('timePosition $time1 - $duration - offset $beat - $subbeat - ${subBeats[beat]}');

    double msec = 0;
    // Active vs all owls swing their heads
    bool allOwlsSingHeads = true;
    if (allOwlsSingHeads)
      msec = (time % (2 * duration * beatMetre.beatCount)) * 1000000;  // in microseconds
    else
      msec = timeInSubbeat * 1000000;  // in microseconds
    //double msec = (time % (2 * duration * beatMetre.beatCount)) * 1000000;  // in microseconds

    return [beat, subbeat, msec.toInt()];
  }

  /* //IS:прикрыл, чтобы разобраться в коде.
  /// Не используется.
  bool updateCycle()
  {
    bool changed = false;
    int time = DateTime.now().microsecondsSinceEpoch;
    int dt = time - _timeOrg;
    if (melody != null)
    {
      pos = melody.timePosition(1e-6 * dt);
      List<int> pair = beatMetre.beatPair(pos.n);
      int curBeat = pair[0];
      int subbeat = pair[1];
      if (curBeat != _activeBeat || subbeat != _activeSubbeat)
      {
        changed = true;
        _activeBeat = curBeat;
        _activeSubbeat = subbeat;
      }
    }
    return changed;
  }
*/
  /*
  void setTempo(int tempoBpm/*, int noteValue*/)
  {
    _beatsPerMinute = tempoBpm;
    //tempo.denominator = noteValue;

  //  int _bars = 1;
    //melody.cycle.setTempo(tempo, _bars);
  }*/

  bool isActiveBeat(int id)
  {
    return id == _activeBeat;
  }

  int getActiveSubbeat(int id)
  {
    return id == _activeBeat ? _activeSubbeat : -1;
  }

  int getActiveTime(int id)
  {
    // Active vs all owls swing their heads
    bool allOwlsSingHeads = true;
    if (allOwlsSingHeads)
    {
      double period = 120.0 / _beatsPerMinute; // in seconds
      int t = _activeTime;
      t = ((_activeTime - 1000000 * period * id) /
          (beatMetre.beatCount * period)).round();
      return t;
    }
    else
      return id == _activeBeat ? _activeTime : 0;
  }

  int getActiveState()
  {
    return (_activeBeat << 16) | (_activeSubbeat & 0xFFFF);
  }

  int getBeatState(int id)
  {
    return id == _activeBeat ? ((_activeBeat << 16) | (_activeSubbeat & 0xFFFF)) : 0xFFFF;
  }

  void setActiveState(int beat, int subbeat)
  {
    _activeBeat = beat;
    _activeSubbeat = subbeat;
    notifyListeners();
  }
}
