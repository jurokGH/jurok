
import 'package:owlenome/prosody.dart';

class Rhythm{

  static String sOnlyFist="Only first beat is strong";//ToDo
  static String sOneStrong="Strong";//ToDo
  static String sOneWeak="Weak";//ToDo


  //final
  String name;

  //final
  List<int> subBeats;
  //final
  List<int> accents;

  ///Сигнализирует, что нужно поменять подбиты;
  ///Нужно для красивых ритмов типа Болеро
  bool bSubBeatDependent=false;

  ///Стандартный ли размер? Введено, чтобы имя было вида m/n
  bool bStandard=false;

  Rhythm({this.name="", this.subBeats, this.accents, this.bSubBeatDependent=false});


  Rhythm.fromAccents(List<int> accents)
  {
    ///Переводим акценты в строку n1+n2+...
    ///Не очень понятно, как отображать их силу, и корректно ли так писать для
    ///ритма, начинающегося со слабой доли
    String accentsToName(List<int> beats){
      if (beats==null) return null;
      if (beats.length==0) return "";
      List<int> summands=[1];
      for(int i=1; i<beats.length; i++){
        if (beats[i]==0) summands[summands.length-1]++;
        else summands.add(1);
      }

      String res=summands[0].toString();
      for(int i=1; i<summands.length; i++){
        res+="+"+summands[i].toString();
      }
      return res;
    }

    name=accentsToName(accents);
    this.accents=accents;
    this.subBeats=List<int>.filled(accents.length,1);
  }

  Rhythm.onlyFirst(int nOfBeats){
    name=sOnlyFist;
    this.subBeats=List<int>.filled(nOfBeats,1);
    this.accents=List<int>.filled(nOfBeats,0);
    if (nOfBeats>0) accents[0]=1;
  }


  Rhythm.oneStrong(){
    name=sOneStrong;
    this.subBeats=[1];
    this.accents=[1];
  }

  Rhythm.oneWeak(){
    name=sOneWeak;
    this.subBeats=[1];
    this.accents=[0];
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

  Rhythm.bolero12(){
    name = "Bolero";
    bSubBeatDependent=true;
    subBeats=[1,3,1,3,1,1,1,3,1,3,3,3];
    accents=[2,0,1,0,1,0,2,0,1,0,1,0];
  }

  Rhythm.warmGun(){ //Draft; Beatles, Happiness is a warm gun
    name = "Happiness is a warm gun (draft)";
    bSubBeatDependent=true;
    accents=[2,0,0,1,0,0,2,0,1,0];
    subBeats=List<int>.filled(accents.length,1);
  }

  Rhythm.soca(){ //Draft; Soca
    name = "Soca (draft)";
    bSubBeatDependent=true;
    accents=[0,2,0,1,0,2,0,1];
    subBeats=[1,2,1,2,1,2,1,2];
  }


  Rhythm.tango(){ //Draft; tango; need pauses
    name = "Soca (draft)";
    bSubBeatDependent=true;
    accents=[1,0,0,0,2,0,0,0];
    subBeats=[1,1,1,2,1,1,1,2];
  }


  Rhythm.twoBubBum(){ //
    name = "crackle  (draft)";
    bSubBeatDependent=true;
    accents=[1,0];
    subBeats=[8,8];
  }

/*
  Rhythm.rumBaTMP(){ //Undested; Rumba
    name = "Rumbu (under constr)";
    bSubBeatDependent=true;
    accents=[zzzz];
    subBeats=[zzz];
  }*/
}

class UserRhythm extends Rhythm{
  bool bDefined=false;
  UserRhythm(List<int> subBeats,  List<int> accents):
        bDefined=(subBeats.length>0),
        super(
        bSubBeatDependent:true,
        name: "Last edited in "+subBeats.length.toString(),
        subBeats: subBeats,
        accents: accents,
      );
}

class FancyRhythms {

  ///Список по поддолям
  List<List<Rhythm>> fancyRhythms;


  FancyRhythms() {
    ///Добавляем подряд всё, что нам нравится
    List<Rhythm> fancy=[];

    //12 долей
    fancy.add(Rhythm.bolero12());


    ///drafts
    //10 долей
    fancy.add(Rhythm.warmGun());
    fancy.add(Rhythm.soca());
    fancy.add(Rhythm.tango());
    fancy.add(Rhythm.twoBubBum());




    fancyRhythms = List<List<Rhythm>>.generate(12,(n)=>[]);
    for(int i=0;i<fancy.length;i++){
      fancy[i].bSubBeatDependent=true;//на всякий случай, если забыли
      //сортируем по номерам
      fancyRhythms[fancy[i].subBeats.length-1].add(fancy[i]);
    }
  }
}



///Простая просодия - ритмы по числу долей
class RhythmsByBeatN {

  ///Список по поддолям
  List<List<Rhythm>> rhythms;

  /// стандартные размеры
  static List<int> standardBeatNth=[2,3,4,6,9,12];

  RhythmsByBeatN() {
    ///Добавляем подряд всё, что нам нравится
    List<Rhythm> simple=[];

    ///Ритмы из 1 бита
    simple+=[Rhythm.oneStrong(),Rhythm.oneWeak()];

    ///Остальные; если стандартное число бит - то добавляем один стандартный ритм;
    ///если нет - то пиво-водочка
    for(int i=1; i<12; i++){
      simple.add(Rhythm.fromAccents(Prosody.getAccents(i+1,true)));
      if (standardBeatNth.contains(i+1))//пометим его как стандартный
        simple.last.bStandard=true;
      else//нужно добавить ещё пива
        simple.add(Rhythm.fromAccents(Prosody.getAccents(i+1,false)));
    }

    ///теперь добавляем разбиения нестандартных долей, не попавшее в пиво-водочку
    ///ToDo
    simple.add(Rhythm.fromAccents([2, 0, 1, 0, 0, 1, 0])); //7 долей

    simple.add(Rhythm.fromAccents([2, 0, 0, 1, 0, 1, 0, 0])); //8 долей


    rhythms = List<List<Rhythm>>.generate(12,(n)=>[]);
    for(int i=0;i<simple.length;i++){
      simple[i].bSubBeatDependent=false;//на всякий случай, если забыли
      //сортируем по номерам
      rhythms[simple[i].subBeats.length-1].add(simple[i]);
    }
  }
}


class PredefinedRhythms{

  ///Список по числу долей
  List<List<Rhythm>> all;

  ///Это ритмы, которые предлагаются как основные для данного числа долей
  List<Rhythm> basicRhythms;

  PredefinedRhythms(){
    all= List<List<Rhythm>>(12);
    for(int i=0; i<12; i++) {all[i]=[];}




    List<List<Rhythm>> simple=RhythmsByBeatN().rhythms;

    ///Соберем все ритмы
    ///
    ///Добавляем сначала простые ритмы
    for(int i=0; i<12; i++){      all[i]+=simple[i];    }

    ///Добавляем ритмы, где только первый бит сильный
    for(int i=3; i<12; i++){ all[i].add(Rhythm.onlyFirst(i+1));}

    ///Добавляем модные
    List<List<Rhythm>> fancy=FancyRhythms().fancyRhythms;
    for(int i=0; i<12; i++){       all[i]+=fancy[i];    }

    ///Теперь соберем начальные
    basicRhythms=List<Rhythm>(12);
    for(int i=0; i<12; i++){       basicRhythms[i]=all[i][0];}
  }


}