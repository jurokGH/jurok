import 'package:flutter/foundation.dart';
import 'package:owlenome/prosody.dart';


class Rhythm {
  static String sOnlyFist = "Only first beat is strong"; //ToDo
  static String sOneStrong = "One strong"; //ToDo
  static String sOneWeak = "One weak"; //ToDo

  //final
  String name;

  //final
  List<int> subBeats;
  //final
  List<int> accents;

  int get beats {
    return accents.length;
  }

  ///Сигнализирует, что нужно поменять подбиты;
  ///Нужно для красивых ритмов типа Болеро
  bool bSubBeatDependent = false;

  ///Стандартный ли размер? Введено, чтобы имя было вида m/n
  bool bStandard = false;

  Rhythm(
      {this.name = "",
      this.subBeats,
      this.accents,
      this.bSubBeatDependent = false});

  ///Переводим акценты в строку n1+n2+...
  ///Не очень понятно, как отображать их силу, и корректно ли так писать для
  ///ритма, начинающегося со слабой доли
  ///ToDo: и ещё паузы надо проверить (см. группировку в строке акцентов)
  Rhythm.fromAccents(List<int> accents) {
    name = accentsToName(accents);
    bStandard=Prosody.standardBeatNth.contains(accents.length+1);
    this.accents = accents;
    this.subBeats = List<int>.filled(accents.length, 1);
  }



  ///  fromAccents, но со стандартными именами ритмов
  Rhythm.fromAccentsWithStandardNames(List<int> accents) {
    name="noname";
    this.accents = accents;
    this.subBeats = List<int>.filled(accents.length, 1);
    int nOfBeats=accents.length;
    bStandard=Prosody.standardBeatNth.contains(nOfBeats);
    if (bStandard&&
        listEquals(Prosody.getAccents(nOfBeats, true), accents))
        {
      switch (nOfBeats) {
        case 2:
          name = "Simple Duple Time";
          break;
        case 3:
          name = "Simple Triple Time";
          break;
        case 4:
          name = "Simple Quadruple Time";
          break;
        case 6:
          name = "Compound Duple Time";
          break;
        case 9:
          name = "Compound Triple Time";
          break;
        case 12:
          name = "Compound Quadruple Time";
          break;
      }
    }
    else  name = accentsToName(accents);
  }


  ///Не очень понятно, как писать паузы. Этого я не знаю.
  String accentsToName(List<int> accents) {
    if (accents == null) return null;
    if (accents.length == 0) return "";
    List<int> summands = [1];
    for (int i = 1; i < accents.length; i++) {
      if (accents[i] == 0)
        summands[summands.length - 1]++;
      else
        summands.add(1);
    }
    ///Для пауз можно попробовать что-то такое... Но не очень понятно, верно ли это будет.
    /// (-1,0,0) - это какая строка? (-)-2? Или что?
    ///
    /*
    String summandToString(int summand){
      if (summand>0) return summand.toString();
      if (summand==-1) return '(-)';
      return "?";
    }
     */
    String res = summands[0].toString();
    for (int i = 1; i < summands.length; i++) {
      res += "+" + summands[i].toString();
    }
    if (summands.length==1) res+= ' beats ';
    return res;
  }


  ///Есль ли ритм среди списка (в точности совпадающий)
  int isInTheList(List<Rhythm> rhythms){
    if (rhythms==null) return -1;
    for (int i=0; i<rhythms.length; i++){
      Rhythm r=rhythms[i];
      if (listEquals(accents, r.accents))
        if (listEquals(subBeats, r.subBeats))
          return i;
        }
      return -1;
  }

  Rhythm.onlyFirst(int nOfBeats) {
    name = sOnlyFist;
    this.subBeats = List<int>.filled(nOfBeats, 1);
    this.accents = List<int>.filled(nOfBeats, 0);
    if (nOfBeats > 0) accents[0] = 1;
  }

  Rhythm.oneStrong() {
    name = sOneStrong;
    this.subBeats = [1];
    this.accents = [1];
  }

  Rhythm.oneWeak() {
    name = sOneWeak;
    this.subBeats = [1];
    this.accents = [0];
  }

  ///Зона модных ритмов
  ///
  ///https://rhythmnotes.net/latin-grooves/
  ///    //fancy.add(Rhythm.rumBaTMP());
  //    //fancy.add(Rhythm.ChopinAMinor());
  //    //fancy.add(Rhythm.ChaikovskyWaltzIn5());
  //    //Совы нежные
  //    //https://en.wikipedia.org/wiki/Tresillo_(rhythm)
  //    //Чайковский вальс 5/8
  //    //https://en.wikipedia.org/wiki/Polska_(dance)
  //    //https://en.wikipedia.org/wiki/Leventikos

  Rhythm.tresillo() {
    name = "Tresillo";
    bSubBeatDependent = true;
    accents = [2, -1, -1, 0, -1, -1, 1, 0];
    subBeats = List<int>.filled(accents.length, 1);
  }

  Rhythm.bolero12() {
    name = "Bolero";
    bSubBeatDependent = true;
    subBeats = [1, 3, 1, 3, 1, 1, 1, 3, 1, 3, 3, 3];
    accents = [2, 0, 1, 0, 1, 0, 2, 0, 1, 0, 1, 0];
  }

  Rhythm.warmGun() {
    //Draft; Beatles, Happiness is a warm gun
    name = "Happiness is a warm gun [draft]";
    bSubBeatDependent = true;
    accents = [2, 0, 0, 1, 0, 0, 2, 0, 1, 0];
    subBeats = List<int>.filled(accents.length, 1);
  }

  ///MUST HAVE:  https://youtu.be/SeObEEpn5zc?t=91
  Rhythm.soca() {
    //Draft; Soca ///ToDo: это не соха, а херня
    name = "Soca-draft";
    bSubBeatDependent = true;
    accents = [2, 0, 0, 1, 2, 0, 1, 0];
    subBeats = [1, 1, 1, 1, 1, 1, 1, 1];
  }

  ///Это лучше. Но не могу сместить акцент во второй доле, поэтому его нет. Не очень.
  /// https://nicksdrumlessons.com/multimedia-archive/soca-drum-lesson-part-1/
  Rhythm.socaPart1() {
    //Draft; Soca
    name = "Soca1-draft";
    bSubBeatDependent = true;
    accents = [2, 0, 1, 0];
    subBeats = [1, 2, 1, 1];
  }

  ///https://cnx.org/contents/5O_NUnsW@10/Caribbean-Music-Calypso-and-Found-Percussion
  Rhythm.calypso1() {
    name = "calypso1-draft";
    bSubBeatDependent = true;
    accents = [2, 0, 1, 1];
    subBeats = List<int>.filled(4, 2);
  }

  Rhythm.moneyPF() {
    //
    name = "guess what";
    bSubBeatDependent = true;
    accents = [1, 0, 0, 2, 0, 0, 0]; // TODO
    subBeats = List<int>.filled(accents.length, 1);
    subBeats[1] = 2; //там-татат-там-
    // там -там-там -там Это верн
  }

  ///Отчлично слышны акценты у танго в разных видах
  ///https://www.youtube.com/watch?v=URm5RoE2Emo

  Rhythm.tangoHabanera1() {
    //Draft; tango; need pauses? -  https://www.youtube.com/watch?v=hp-zU7nIiJ4
    //https://www.youtube.com/watch?v=zNow1XilN0I - вот отсюда взять.
    //3 habaneras: https://african-americanandlatinamericanstylesofmusic.weebly.com/habanera-rhythm.html
    //https://composerfocus.com/how-to-write-a-tango/
    name = "First habanera";
    bSubBeatDependent = true;
    accents = [2, 0, 0, 1, 2, 0, 1, 0]; //First habanera
    //accents=[0,-1,-1,1,2,-1,0,-1];//Верно, но скучно
    subBeats = List<int>.filled(accents.length, 1);
  }

  Rhythm.tangoHabanera2() {
    //Draft; tango; need pauses https://www.youtube.com/watch?v=hp-zU7nIiJ4
    //https://www.youtube.com/watch?v=zNow1XilN0I - вот отсюда взять.
    //3 habaneras: https://african-americanandlatinamericanstylesofmusic.weebly.com/habanera-rhythm.html
    ///4/4; 3+3+2; sincopa
    name = "Second habanera (a)"; //(sincopa)
    bSubBeatDependent = true;
    accents = [2, 1, 0, 1, 1, 0, 1, 0];
    subBeats = List<int>.filled(accents.length, 1);
    //https://composerfocus.com/how-to-write-a-tango/
  }

  Rhythm.tangoHabanera2prime() {
    //Draft; tango; need pauses https://www.youtube.com/watch?v=hp-zU7nIiJ4
    //https://www.youtube.com/watch?v=zNow1XilN0I - вот отсюда взять.
    //3 habaneras: https://african-americanandlatinamericanstylesofmusic.weebly.com/habanera-rhythm.html
    ///4/4; 3+3+2; sincopa
    name = "Second habanera  (b)"; //(sincopa)
    bSubBeatDependent = true;
    accents = [2, 1, 0, 0, 1, 0, 1, 0];
    subBeats = List<int>.filled(accents.length, 1);
    //https://composerfocus.com/how-to-write-a-tango/
  }

  ///Это просто 3+3+2; можно сделать в трёх долях, поскольку акценты не смещены
  Rhythm.tangoHabanera3in8() {
    //Draft; tango; need pauses https://www.youtube.com/watch?v=hp-zU7nIiJ4
    //https://www.youtube.com/watch?v=zNow1XilN0I - вот отсюда взять.
    //3 habaneras: https://african-americanandlatinamericanstylesofmusic.weebly.com/habanera-rhythm.html
    ///4/4; 3+3+2; sincopa
    name = "Third habanera"; //Good
    bSubBeatDependent = true;
    accents = [2, 0, 0, 1, 0, 0, 1, 0];
    subBeats = List<int>.filled(accents.length, 1);
    //https://composerfocus.com/how-to-write-a-tango/
  }

  ///Это просто 3+3+2; можно сделать в трёх долях, поскольку акценты не смещены
  ///Но тогда не выделяем первую долю (механикой не предусмотрен акцент 2 в 3х долях
  ///для простоты жизни пользователя.
  Rhythm.tangoHabanera3in3() {
    //Draft; tango; need pauses https://www.youtube.com/watch?v=hp-zU7nIiJ4
    //https://www.youtube.com/watch?v=zNow1XilN0I - вот отсюда взять.
    //3 habaneras: https://african-americanandlatinamericanstylesofmusic.weebly.com/habanera-rhythm.html
    ///4/4; 3+3+2; sincopa
    name = "Third habanera";
    bSubBeatDependent = true;
    accents = [1, 1, 1]; //Вместо 3+3+2 //Good
    subBeats = [3, 2, 2];
    //accents=[2,0,0,1,0,0,1,0]; //Вместо 3+3+2
    //subBeats=List<int>.filled(beats.length,1);
    //https://composerfocus.com/how-to-write-a-tango/
  }

  ///ToDo: crackle? drum roll? Нужно корректное музыкальное имя
  Rhythm.roll8(int beats) {
    //
    if (beats < 1) {
      name = "0 beats";
      return;
    }
    name = "Roll in $beats  beats";
    bSubBeatDependent = true;
    accents = List<int>.filled(beats, 1);
    //accents[0] = 1;
    subBeats = List<int>.filled(beats, 8);
  }

  Rhythm.twoBubBum() {
    //
    name = "Some crackle";
    bSubBeatDependent = true;
    accents = [1, 1];
    subBeats = [8, 4];
  }

  Rhythm.strangeIn3() {
    //
    name = "crackle in 3 beats";
    bSubBeatDependent = true;
    accents = [0, 1, 1];
    subBeats = [2, 8, 8];
  }

/*
  Rhythm.rumBaTMP(){ //Undested; Rumba
    name = "Rumbu (under constr)";
    bSubBeatDependent=true;
    accents=[zzzz];
    subBeats=[zzz];
  }*/
}


class UserRhythm extends Rhythm {
  bool bDefined = false;
  UserRhythm(List<int> subBeats, List<int> accents)
      : bDefined = (subBeats.length > 0),
        super(
          bSubBeatDependent: true,
          name: "Last edited in " + subBeats.length.toString() + "beats",
          ///ToDo:
          ///Это надо поменять. Решится генерацией разумного имени.
          subBeats: subBeats,
          accents: accents,
        );

  void _inheritName(Rhythm rhythm)
  {
    name= rhythm.name+' (users)';
  }

  ///Модифицируем имя из стандартного для ритма, измененного пользователем
  void inheritName()
  {
    name= Rhythm.fromAccentsWithStandardNames(accents).name
        +' (edited)';
  }


/* Не доделано и вроде можно обойтись пока
  RhythmComparisonResult compare(List<Rhythm> rhythmsToCompare){
    RhythmComparisonResult res;
    if (rhythmsToCompare==null) return res;
    List<Rhythm> rhythms=rhythmsToCompare.where((rhythm) => (rhythm.beats==beats)).toList();
    if (rhythms.length==0) return res;
  }*/


}

class RhythmComparisonResult {
  int indOfClosest = -1;
  bool equal = false;
  bool equalAccents=false;
}

class FancyRhythms {
  ///Список по поддолям
  List<List<Rhythm>> fancyRhythms;

  FancyRhythms() {
    ///Добавляем подряд всё, что нам нравится
    List<Rhythm> fancy = [];

    fancy.add(Rhythm.tresillo());

    //12 долей
    fancy.add(Rhythm.bolero12());

    ///drafts
    //10 долей
    for (int i = 3; i < 12; i++) fancy.add(Rhythm.roll8(i + 1));

    //fancy.add(Rhythm.warmGun());
    fancy.add(Rhythm.soca());
    fancy.add(Rhythm.socaPart1());
    fancy.add(Rhythm.calypso1());
    fancy.add(Rhythm.tangoHabanera1());
    fancy.add(Rhythm.tangoHabanera2());
    fancy.add(Rhythm.tangoHabanera2prime());
    fancy.add(Rhythm.tangoHabanera3in8());
    fancy.add(Rhythm.moneyPF());
    fancy.add(Rhythm.twoBubBum());
    fancy.add(Rhythm.strangeIn3());

    fancyRhythms = List<List<Rhythm>>.generate(12, (n) => []);
    for (int i = 0; i < fancy.length; i++) {
      fancy[i].bSubBeatDependent = true; //на всякий случай, если забыли
      //сортируем по номерам
      fancyRhythms[fancy[i].subBeats.length - 1].add(fancy[i]);
    }
  }
}

///Простая просодия - ритмы по числу долей
class RhythmsByBeatN {
  ///Список по поддолям
  List<List<Rhythm>> rhythms;



  RhythmsByBeatN() {
    ///Добавляем подряд всё, что нам нравится
    List<Rhythm> simple = [];

    ///Ритмы из 1 бита
    simple += [Rhythm.oneStrong(), Rhythm.oneWeak()];

    ///Остальные; если стандартное число бит - то добавляем один стандартный ритм;
    ///если нет - то пиво-водочка
    for (int i = 1; i < 12; i++) {
      simple.add(Rhythm.fromAccentsWithStandardNames(Prosody.getAccents(i + 1, true)));
      if (!simple.last.bStandard) //нужно добавить ещё пива
        simple.add(Rhythm.fromAccents(Prosody.getAccents(i + 1, false)));
    }

    ///теперь добавляем разбиения нестандартных долей, не попавшее в пиво-водочку
    ///ToDo
    simple.add(Rhythm.fromAccents([2, 0, 1, 0, 0, 1, 0])); //7 долей

    simple.add(Rhythm.fromAccents([2, 0, 0, 1, 0, 1, 0, 0])); //8 долей

    rhythms = List<List<Rhythm>>.generate(12, (n) => []);
    for (int i = 0; i < simple.length; i++) {
      simple[i].bSubBeatDependent = false; //на всякий случай, если забыли
      //сортируем по номерам
      rhythms[simple[i].subBeats.length - 1].add(simple[i]);
    }
  }
}

class PredefinedRhythms {
  ///Список по числу долей
  List<List<Rhythm>> all;

  ///Это ритмы, которые предлагаются как основные для данного числа долей
  List<Rhythm> basicRhythms;

  PredefinedRhythms() {
    all = List<List<Rhythm>>(12);
    for (int i = 0; i < 12; i++) {
      all[i] = [];
    }

    List<List<Rhythm>> simple = RhythmsByBeatN().rhythms;

    ///Соберем все ритмы
    ///
    ///Добавляем сначала простые ритмы
    for (int i = 0; i < 12; i++) {
      all[i] += simple[i];
    }

    ///Добавляем ритмы, где только первый бит сильный
    for (int i = 3; i < 12; i++) {
      all[i].add(Rhythm.onlyFirst(i + 1));
    }

    ///Добавляем модные
    List<List<Rhythm>> fancy = FancyRhythms().fancyRhythms;
    for (int i = 0; i < 12; i++) {
      all[i] += fancy[i];
    }

    ///Теперь соберем начальные
    basicRhythms = List<Rhythm>(12);
    for (int i = 0; i < 12; i++) {
      basicRhythms[i] = all[i][0];
    }
  }
}
