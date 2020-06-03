
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

  Rhythm({this.name="", this.subBeats, this.accents,this.bSubBeatDependent});



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

  Rhythm.fromAccents(List<int> accents)
  {
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

  Rhythm.bolero12(){
    name = "Bolero";
    bSubBeatDependent=true;
    subBeats=[1,3,1,3,1,1,1,3,1,3,3,3];
    accents=[2,0,1,0,1,0,2,0,1,0,1,0];
  }



}

class UserRhythm extends Rhythm{
  bool bDefined=false;
  UserRhythm(List<int> subBeats,  List<int> accents):
    bDefined=(subBeats.length>0),
        super(
        bSubBeatDependent:true,
        name: "Last edited",
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


    fancyRhythms = List<List<Rhythm>>.generate(12,(n)=>[]);
    for(int i=0;i<fancy.length;i++){
      fancy[i].bSubBeatDependent=true;//на всякий случай, если забыли
      //сортируем по номерам
      fancyRhythms[fancy[i].subBeats.length-1].add(fancy[i]);
    }
  }
}



///Простая просодия
class SimpleRhythms {

  ///Список по поддолям
  List<List<Rhythm>> simpleRhythms;

  /// стандартные размеры
  static List<int> standardBeatNth=[2,3,4,6,9,12];

  SimpleRhythms() {
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


    simpleRhythms = List<List<Rhythm>>.generate(12,(n)=>[]);
    for(int i=0;i<simple.length;i++){
      simple[i].bSubBeatDependent=false;//на всякий случай, если забыли
      //сортируем по номерам
      simpleRhythms[simple[i].subBeats.length-1].add(simple[i]);
    }
  }
}


class AllRhythms{

  ///Список по поддолям
  List<List<Rhythm>> rhythms;



  AllRhythms(){
    rhythms= List<List<Rhythm>>(12);
    for(int i=0; i<12; i++) {rhythms[i]=[];}

    ///Добавляем простые ритмы
    List<List<Rhythm>> simple=SimpleRhythms().simpleRhythms;
    for(int i=0; i<12; i++){      rhythms[i]+=simple[i];    }

    ///Добавляем ритмы, где только первый бит сильный
    for(int i=3; i<12; i++){ rhythms[i].add(Rhythm.onlyFirst(i+1));}

    ///Добавляем модные
    List<List<Rhythm>> fancy=FancyRhythms().fancyRhythms;
    for(int i=0; i<12; i++){       rhythms[i]+=fancy[i];    }

  }


}