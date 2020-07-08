///Подписываем и грузим
///
///

//после сливяния с заставкой и волатильными переменными в потоке.
//

//import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as serv;
import 'package:flutter/widgets.dart';
//import 'package:owlenome/GoAroundWheel.dart';
import 'package:owlenome/MetreBar_ui.dart';
import 'package:owlenome/Skin4Accents.dart';
import 'package:owlenome/subbeat-eq_ui.dart';
import 'package:owlenome/volume_uiTmp.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
//import 'package:wheel_chooser/wheel_chooser.dart';
//import 'package:flutter_xlider/flutter_xlider.dart';
import 'package:owlenome/TwoWheels.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:owlenome/prosody.dart';
import 'package:owlenome/rhythms.dart';

import 'package:owlenome/util.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:utf/utf.dart';
import 'PlatformSvc.dart';
import 'BarBracket.dart';
import 'SkinRot.dart';
import 'accentbar-ui.dart';
import 'arrow.dart';
import 'help.dart';
import 'metronome_state.dart';
import 'metre.dart';
import 'beat_metre.dart';
import 'beat_sound.dart';
import 'OwlGrid.dart';
import 'OwlGridRot.dart';
import 'Metre_ui.dart';
import 'Subbeat_ui.dart';
import 'TempoList_ui.dart';
import 'volume_ui.dart';
//import 'settings.dart';
import 'settings_plywood.dart';
import 'knob.dart';
import 'KnobTuned.dart';
//import 'KnobResizable.dart';

import 'UserPrefs.dart';
import 'NoteTempo.dart';
import 'NoteWidget.dart';

import 'package:google_fonts/google_fonts.dart';

//ToDo: DC means Double Check

///!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
/// UI Сontrol widgets can be found by comment tag: ///widget
///

///>>>>>> JG!
/// UI global constants
/// Theme primary color
final Color _cPrimaryColor = Colors.grey;

/// Theme accent color
final Color _cAccentColor = Colors.blueGrey;

/// Text color
final Color _cTextColor = Colors.white;

/// UI Controls color and opacity
final Color _cCtrlColor = Colors.grey;
final double _cCtrlOpacity = 0;

/// Common 'white' color
final Color _cWhiteColor = Colors.white;

/// Metre bar regular metre color
const Color _clrRegularBar = Colors.white70; // Color(0xB3FFFFFF)
/// Metre bar irregular metre color
const Color _clrIrregularBar = Color(0xB3FFECB3); // Colors.amber[100];
/// Metre control irregular metre color
const Color _clrIrregularMetre = Color(0xFFFFA000); // Colors.amber[600];
/// Tempo List text color
final Color _cTempoList = Colors.white;

/// 48 - minimum recommended target size of 7mm regardless of what screen they are displayed on
/// ISH:  Я нашел это в этой книге по дизайну ( Revista Lennken) в главе 7 Metrics.
///Что такое размер плоского объекта в мм - не очень понятно.
///Вряд ли речь про квадратный мм))) Меньшая сторона? Большая сторона?
///
///Из "официального"
///https://flutter.dev/docs/development/ui/layout/responsive
///- см. ссылки там, в частности:
///  "In responsive UI we don’t use hard-coded values for dimension and positions."  !!!
///
/// Вывод я сделал такой: нужно брать переменные значения и держать в голове наименьшую раскладку.
/// Для неё проверяются полученные жесткие значения на предмет ограничения 7mm, чтобы оно не значило
///
const double cMinTapSize = 48;
const double cBarHeightVert = 0.28;
const double cBarHeightHorz = 0.2;

/// Beat count min/max
const int _cMinBeatCount = 1;
const int _cMaxBeatCount = 12;

/// Max beat subdivision
const int _cMaxSubBeatCount = 8;

/// Note value min/max
const int _cMinNoteValue = 2;
const int _cMaxNoteValue = 16;
const int _cIniNoteValue = 4;

/// Initial metre (beat, note) index from _metreList
/// !!!ATTENTION!!! Make it compatible with next subbeat/accent lists
///
/// ISH: я упихал всю ритмовую механику в отдельный класс с предустановлеными
/// ритмами - см. rhythms.dart
///
/// Теперь начальный ритм выбирается через initRhythm
const int _cIniActiveMetre = 1; //3
/// Initial subbeats
const List<int> _cIniSubBeats = [
  //1, 1, 1,
  1, 1, 1, 1, 1, 1,

  //1,3,1,3,1,1, 1,3,1,3,3,3  // Fancy; Bolero; needs accents
  //2, 2, 4, 2, 4, 2,  // Fancy
  //2,2,4,2,4,2,6,1,
  //1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
];

/// Initial accents
const List<int> _cIniAccents = [
  //1, 0, 0,
  2, 0, 0, 1, 0, 0,

  //2, 0, 1, 0,
  //2, 0, 1, 0, 1, 0, 2, 0, 1, 0, 1, 0,  //Bolero
];

const int _initBeatCount = 3;

///Тут живёт список всех предустановленных ритмов (это список списков
///all, по долям  [важно: индекс от 0 до 11]),
///а также список initRhythms из базовых ритмов для каждой доли
final PredefinedRhythms _predefinedRhythms = PredefinedRhythms();

///список всех предустановленных ритмов (это список списков
///all, по долям  [важно: индекс от 0 до 11]),
final List<List<Rhythm>> _allPredefinedRhythms = _predefinedRhythms.all;

/// список из базовых ритмов для каждой доли
final List<Rhythm> _basicRhythms = _predefinedRhythms.basicRhythms;

/// список из базовых ритмов для каждой доли
final Rhythm initRhythm = _basicRhythms[_initBeatCount - 1];

///Ритмы пользователя по числу долей (от нуля)
List<UserRhythm> userRhythms;

///Числа долей, уменьшенное на  1, которое редактировали последней раз. -1 - не редактировали
///Редактирование - изменение акцентов или поддолей одной из сов (//ToDo: а правильно ли это?
///
/// Таким образом,  последний редактировавшийся ритм - это
/// userRhythms[_lastEditedBeatIndex]
int _lastEditedBeatIndex;
//List<int> _lastEditedInBeat = List<int>.filled(12, -1);
int _lastEditedInThisBeat = -1;

///это непонятно. В какой системе координат?
//List<int> _lastShownInBeat=List<int>.filled(12,-1);

///Когда последний раз мы показывали данное число бит   (-1),
///был ли ритм пользовательским?
List<bool> _lastShownWasUsers = List<bool>.filled(12, false);

List<Rhythm> _rhythmsToScroll = _allPredefinedRhythms[_initBeatCount - 1];

/// Min tempo
const int _cMinTempo = 1;

/// Absolute max tempo. Больше него не ставим, даже если позволяет сочетание схемы и метра.
/// 999 обусловлено местом под 3 цифры на виджетах
const int _cMaxTempo = 999; //500-5000
/// Initial tempo
const int _cIniTempo =
    90; //проверка латенси//120; //121 - идеально для долгого теста, показывает, правильно ли ловит микросекунды
const int _cTempoKnobTurns = 2;
const double _cTempoKnobAngle = 160;
const double _cTempoKnobSweepAngle = 3 * 360.0 + 2 * _cTempoKnobAngle;

/// Debug on different devices/resolutions
final bool _debugDevices = false;

///<<<<<< JG!

final String _cAppName = "Owlenome";
final String _cAppTitle = "Owlenome";

void main() {
  /* //ToDo: что-то такое надо сделать с лицензией. Гугл, и фонта для ПАУЗ
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('google_fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['google_fonts'], license);
  });
  */

  WidgetsFlutterBinding.ensureInitialized(); //ToDo: залочил портрет пока
  serv.SystemChrome.setPreferredOrientations(
      [serv.DeviceOrientation.portraitUp]).then((_) {
    if (_debugDevices) {
      return runApp(
        DevicePreview(
            builder: (context) => ChangeNotifierProvider(
                //create: (_) => new MetronomeState(_cIniSubBeats, _cIniAccents),
                create: (_) => new MetronomeState(initRhythm),
                child: App())
            //new App()
            ),
        //..devices.addAll();
      );
    }

    return runApp(ChangeNotifierProvider(
        //create: (_) => new MetronomeState(_cIniSubBeats, _cIniAccents),
        create: (_) => new MetronomeState(initRhythm),
        child: App()));
  });
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: _debugDevices ? DevicePreview.of(context).locale : null,
      builder: _debugDevices ? DevicePreview.appBuilder : null,
      title: _cAppName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: _cPrimaryColor,
        accentColor: _cAccentColor,
        iconTheme: IconThemeData(color: _cTextColor),
        buttonTheme: ButtonThemeData(
          //minWidth: 150,
          buttonColor: _cCtrlColor.withOpacity(_cCtrlOpacity),
          colorScheme: ColorScheme.light(),
          textTheme: ButtonTextTheme.primary,
        ),
        //fontFamily: 'RobotoMono',
      ),
      home: HomePage(title: _cAppTitle),
    );
  }
}

class HomePage extends StatefulWidget {
  HomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _HomePageState createState() => _HomePageState();
}

/// /////////////////////////////////////////////////////////////////////////

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin<HomePage> {
  // for showSnackBar to run
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Configuration constants
  bool _useNewKnob = true;
  bool _showKnobDialText = false;
  bool _showNoteTempo = true;
  bool _showVersion = true;

  static const int minBeatCount = _cMinBeatCount;
  static const int maxBeatCount = _cMaxBeatCount;
  static const int maxSubBeatCount = _cMaxSubBeatCount;
  static const int minNoteValue = _cMinNoteValue;
  static const int maxNoteValue = _cMaxNoteValue;
  static const int minTempo = _cMinTempo;

  ///Некий абсолютный максимум скорости. Больше него не ставим, даже если
  /// позволяет сочетание схемы и метра.
  static const int maxTempo = _cMaxTempo;

  /// Flutter-Java connection channel
  //PlatformSvc _channel = new PlatformSvc();
  PlatformSvc
      _channel; // = new PlatformSvc(onStartSound, onSyncSound, onLimitTempo);

  ///>>>>>> JG!
  /// UI parameters
  ///
  /// All UI text parameters
  Color _primaryColor = _cPrimaryColor;
  Color _accentColor = _cAccentColor;
  Color _textColor = _cTextColor;
  Color _ctrlColor = _cCtrlColor;
  TextStyle _textStyle;
  double _textSize = 28;

  // TODO Remove?
  int _animationType = 0;

  ///ISH:  Zebra must by quarantined.
  ///

  /// Controls border parameters
  double _borderRadius = 12;
  double _borderWidth = 3;
  double _smallBtnSize0 = 24;

  /// Size of small buttons
  double _smallBtnSize = 24;
  Offset _paddingBtn = new Offset(8, 8); //Size(24, 36);
  /// Controls opacity
  double _opacity = _cCtrlOpacity; // Control's opacity
  /// Standart padding
  Offset _padding = new Offset(4, 4); //Size(24, 36);

  /// Show advertising box
  bool _showAds = false;
  final List<double> _heightAds = [50, 32];

  ///Reserved  area in the bottom of the screen in the portrait mode (percents of the screen height).
  double reservedHeightBottom = 0;

  ///Put 100 and shrink everything to the singularity with the scrollbar! (see bOuterSpaceScrollDebug)
  final double maxReservedHeightBottom = 75.0;

  ///ISH: The following is for the reservation on the bottom of the screen in the portrait mode for a scrollbar
  ///dynamically changing reservedHeightBottom.
  /// One can use it to get an impression of how everything looks on other phones,
  /// or to chase theoretical zebras, or try to tap small controls.
  bool bOuterSpaceScrollDebug = false;

  ///Выделяет области контейнеров. Возможна зебра (толщина  границы - 1).
  bool bBoxContainer = false;

  // bool bShowBoundariesDebug=true;

  ///Константа для привязки к Витиному телефону.
  final double pixelWidth = 432;

  ///<<<<<< JG!

  /// Overall screen size
  Size _screenSize;

  /// Size of square owl's area
  double _sideSquare;
  double _squareX = 1.0;
  double _squareY = 0.85;
  Size _sizeCtrls;
  double _sizeCtrlsShortest;

  BeatMetre _beat; //TODO vs MetronomeState // = new BeatMetre();
  BeatSound _soundConfig = new BeatSound();

  /// Initial note value (denominator)

  int _noteValue = _cIniNoteValue;

  static final int _initScrollBarPosition = 0;
  int _scrollBarPosition = _initScrollBarPosition;

  ///not used in alfa-omega:
  /// Partly-sorted metre list to switch between metres
  /// Includes predefined ('standard') metres
  /// Initially filled with predefined ('standard') metres
  /// User defined metre is inserted into this list in its sorted position
  List<MetreBar> _metreList = [
    MetreBar(6, 8),
    MetreBar(9, 8),
    MetreBar(12, 16),
    // 'Unsorted' metres go in the end
    //MetreBar(5, 8),  // 3+2/8
    MetreBar(12, 16), // Bolero
    MetreBar(2, 4),
    MetreBar(3, 4),
    MetreBar(4, 4),
  ];

  /// Index of current active metre
  int _activeMetre = _cIniActiveMetre;

  /// Index of current user defined metre
  /// -1 - if there are no  user metre
  int _userMetre = -1;

  ///TODO: MetreBar problem
  MetreBar get activeMetre => _metreList[_activeMetre];

  double _volume = 100;
  bool _mute = false;
  int _tempoBpm = _cIniTempo;

  /// Переменная, ограничивающся максимальную скорость при данной музыкальной схеме и метре
  int _tempoBpmMax = maxTempo;

  /// Shows weather to update MetreWidget (if true)
  bool _updateMetreWheels = false;

  /// Shows weather to update MetreBarWidget (if true)
  bool _updateMetreBar = false;

  /// Playing state flag
  bool _playing;

  /// Keep screen on while playing (if true)
  bool _screenOn = true;

  //OwlSkinRot _skin;
  OwlSkin4Acc _skin;
  UserPrefs _userPrefs = new UserPrefs();

  /// Пение рокочущих сов
  /// ToDo: Сколько всего их, какие у них имена, иконки и может что еще
  /// Active sound scheme can be stored and set up on app init
  int _activeSoundScheme = 0;
  List<String> _soundSchemes = [];

  String _version = '';

  /// Animation
  bool redraw = false;
  bool hideCtrls = false;
  AnimationController _controller;
  Animation<double> _animation;
  Animation<Offset> _animationPos;
  Animation<Offset> _animationNeg;
  Animation<Offset> _animationDown;
  int _period = 10; // 1000; //ToDo: why?

  //IS: KnobTuned constants
  double _sensitivity = 2;
  double _innerRadius =
      0.00000000001; //Мега-супер! //Еще лучше -  наименьшее положительное число:)
  //0.0015*_pushDilationFactor; // Супер!
  //0.15*_pushDilationFactor;// Дрянной эффект

  ///Время на растягивание кноба, мс; пока сделано криво (нужно нормальную анимацию).
  final int _timeToDilation = 200;

  ///Во сколько раз увеличивается кноб
  static double _pushDilationFactor = 2.5;
  double _outerRadius = _pushDilationFactor *
      2; //ToDo: скоординировать ли с pushFactor? Сделаю побольше, иначе кажется неприятный эффект с
  //с потерей угла
  static const double initKnobAngle = 0;
  KnobValue _knobValue;

  ///Установка микса. Todo
  static const int _initMixType = 1;

  int _mixingType = _initMixType;

  /// /////////////////////////////////////////////////////////////////////////

  _HomePageState();

  @override
  void initState() {
    super.initState();

    /// Init channel callback from hardware Java code
    _channel = new PlatformSvc(onStartSound, onSyncSound, onLimitTempo);
    _channel.getVersion().then((String version) {
      setState(() {
        _version = version;
      });
    });

    /// Get sound schemes (async) and set active scheme
    _channel
        .getSoundSchemes(_activeSoundScheme)
        .then((List<String> soundSchemes) {
      _soundSchemes = soundSchemes;
      if (_soundSchemes.isEmpty)
        _activeSoundScheme = -1;
      else if (_activeSoundScheme == -1)
        _activeSoundScheme = 0; // Set default 0 scheme
    });

    _channel.setMix(_initMixType).then((int result) {
      if (result >= 0)
        _mixingType = _initMixType;
      else {
        //todo:
        _mixingType = _initMixType;
      }
    });

    //_skin = new OwlSkinRot(_animationType);
    _skin = new OwlSkin4Acc();
    _skin.init().then((_) {
      /*
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        //
        ///Hint//ToDo: тут этому вообще место? - UPD: Тут тоже не прокатило. Убрал.
        ///Не прорисовывалось при первом запуске (на чистый телефон) при AlertDialog (?!) //ToDo
        ///см. https://stackoverflow.com/questions/49466556/flutter-run-method-on-widget-build-complete/54553143#54553143
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            final double wd = _screenSize.width * 0.8;
            final TextStyle textStyle =
                TextStyle(fontSize: wd / 18, color: Colors.black);
            //GoogleFonts.roboto(fontSize: wd / 18, color: Colors.black);//ToDo:
            //Кажется, шрифты не прогружаются на этом этапе. По крайней мере,
            //установив первый раз на "чистый" телефон, я получил пустой диалог.
            final TextStyle textStyleEmph = textStyle.copyWith(
                fontWeight: FontWeight.w600,
                fontSize: textStyle.fontSize * 1.2);
            final Widget message = GestureDetector(
              onTap: () {
                //setState(() {}); //ToDo: Why?
                Navigator.of(context).pop();
              },
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: wd * 0.05,
                ),
                child: RichText(
                  textAlign: TextAlign.left,
                  textScaleFactor: 1,
                  text: TextSpan(
                    style: textStyle,
                    children: [
                      TextSpan(
                          text:
                              'Tap the play button first.\nThen tap/swipe/rotate anything.\n\n'),
                      TextSpan(
                          text:
                              'This is the best way to see what this app can do.'),
                    ],
                  ),
                ),
              ),
            );
            return SimpleDialog(
              backgroundColor: Colors.amber[50].withOpacity(0.75),
              elevation: 10.3,
              title: Text(
                "Hint 1 of 1:",
                style: textStyleEmph.copyWith(color: Colors.indigo),
                textScaleFactor: 1,
              ),
              children: <Widget>[message],
              //content: message,
            );
          },
        );
      });*/
      setState(() {});
    });

    /// Init animation
    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    );
    _animationPos =
        new Tween<Offset>(begin: Offset.zero, end: const Offset(2, 0))
            .chain(CurveTween(curve: Curves.easeIn))
            .animate(_controller);
    _animationNeg =
        new Tween<Offset>(begin: Offset.zero, end: const Offset(-2, 0))
            .chain(CurveTween(curve: Curves.easeIn))
            .animate(_controller);
    _animationDown =
        new Tween<Offset>(begin: Offset.zero, end: const Offset(0, 3))
            .chain(CurveTween(curve: Curves.easeIn))
            .animate(_controller);
    //_animation = new Tween<double>(begin: 1, end: 0).animate(_controller);
    //_animation = new Tween<double> CurvedAnimation(parent: _controller, curve: Curves.linear);

    _knobValue = KnobValue(
      pushed: false,
      absoluteAngle: initKnobAngle,
      value: _tempoBpm.toDouble(),
      tapAngle: null,
      //deltaAngle:0,
    );

    _playing = false;

    _beat = Provider.of<MetronomeState>(context, listen: false).beatMetre;
    //TODO insertMetre(_beat.beatCount, _cIniNoteValue);

    _channel.setBeat(
        _beat.beatCount,
        _beat.subBeatCount,
        _tempoBpm,
        _activeSoundScheme,
        _beat.subBeats,
        Prosody.reverseAccents(_beat.accents, _beat.maxAccent));

    //Пользовательские ритмы
    userRhythms = List<UserRhythm>.generate(12, (n) => UserRhythm([], []));
    _lastEditedBeatIndex = -1;

    ///ToDo: приветственная речь. Видимо, нужно только самый первый раз показывать.
    ///Выясним, была ли уже подсказка
    _loadHintStatus();

    /*
    /// не прорисовываются совы еще в этот момент
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          setState(() {          });//ToDo:
          final double wd = _screenSize.width * 0.8;
          final TextStyle textStyle =
              TextStyle(fontSize: wd / 18, color: Colors.black);
          //GoogleFonts.roboto(fontSize: wd / 18, color: Colors.black);//ToDo:
          //Кажется, шрифты не прогружаются на этом этапе. По крайней мере,
          //установив первый раз на "чистый" телефон, я получил пустой диалог.
          final TextStyle textStyleEmph = textStyle.copyWith(
              fontWeight: FontWeight.w600, fontSize: textStyle.fontSize * 1.2);
          final Widget message = RichText(
            textAlign: TextAlign.left,
            textScaleFactor: 1,
            text: TextSpan(
              style: textStyle,
              children: [
                TextSpan(
                    text:
                        'Tap the the play button first.\nThen tap/swipe/rotate anything.\n\n'),
                TextSpan(
                    text: 'This is the best way to see what this app can do.'),
              ],
            ),
          );
          return AlertDialog(
            backgroundColor: Colors.amber[50].withOpacity(0.75),
            elevation: 10.3,
            title: Text(
              "Hint 1 of 1:",
              style: textStyleEmph.copyWith(color: Colors.indigo),
              textScaleFactor: 1,
            ),
            content: message,
          );
        },
      );
    });*/
  }

  ///Флаги для подсказки

  /*
  ///Юзер умеет менять виджеты на ходу
  bool _bUserIsBrave = false;*/

  int _stopPressedCount = 0;

  ///Подсказака была показана когда-то, или не нужна
  bool _bHintWasAlreadyShownOrUserIsBrave = false;

  final String hintFieldName = 'hintFlag';
  _loadHintStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _bHintWasAlreadyShownOrUserIsBrave =
        (prefs.getBool(hintFieldName) ?? false);
  }

  _setHintStatusToTrue() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool(hintFieldName, true);
    _bHintWasAlreadyShownOrUserIsBrave = true;
  }

  @override
  void dispose() {
    //_userPrefs.store(_beat.subBeatCount, _tempoBpm, _activeMetre, _activeSoundScheme, _volume, userRhythms);
    //ToDo: пока убрал -  Failed to send request: {"jsonrpc":"2.0","id":"3979","method":"getMemoryUsage","params":{"isolateId":"isolates/3936973363009903"}}
    //(но может потому, что тел отключился)
    _controller.dispose();
    super.dispose();
  }

  /// /////////////////////////////////////////////////////////////////////////

  void initUserPrefs(bool b) {
    onMetreBarChanged(_userPrefs.activeMetre);
    _setVolume(_userPrefs.volume);
    _activeSoundScheme = _userPrefs.activeSoundScheme;

    /// Get sound schemes (async) and set active scheme
    _channel
        .getSoundSchemes(_activeSoundScheme)
        .then((List<String> soundSchemes) {
      _soundSchemes = soundSchemes;
      if (_soundSchemes.isEmpty)
        _activeSoundScheme = -1;
      else if (_activeSoundScheme == -1)
        _activeSoundScheme = 0; // Set default 0 scheme
    });

    _beat = Provider.of<MetronomeState>(context, listen: false).beatMetre;
    _beat.subBeatCount = _userPrefs.subbeats;

    _channel.setBeat(
        _beat.beatCount,
        _beat.subBeatCount,
        _tempoBpm,
        _activeSoundScheme,
        _beat.subBeats,
        Prosody.reverseAccents(_beat.accents, _beat.maxAccent));

    //Пользовательские ритмы
    userRhythms =
        _userPrefs.userRhythms == null || _userPrefs.userRhythms.length == 0
            ? List<UserRhythm>.generate(12, (n) => UserRhythm([], []))
            : _userPrefs.userRhythms;
    //_lastEditedBeatIndex = -1;

    setState(() {});
  }

  /// /////////////////////////////////////////////////////////////////////////
  /// Platform sound code handlers
  ///

  /// Called from platform sound code after sound warmup finished
  void onStartSound(int initTime) {
    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.startAfterWarm(initTime, _tempoBpm);

    // Start graphics animation
    _playing = true;
    //TODO _setBeat(); //Даёт отвратительный эффект при старт - доп. щелк
    setState(() {});
  }

  /// Called from platform sound code after sound warmup finished
  void onSyncSound(int newTime, int tempoBpm, int startTime) {
    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.sync(newTime, tempoBpm, startTime);
  }

  /// Called from platform sound code when max tempo limited
  void onLimitTempo(int limitTempo) {
    if (limitTempo > maxTempo) limitTempo = maxTempo;
    //TODO IS (Elsa): what if limitTempo<minTempo?
    if (limitTempo < minTempo) limitTempo = minTempo;
    //TODO Check out setState and UI refreshing
    if (limitTempo != _tempoBpmMax)
      setState(() {
        _tempoBpmMax = limitTempo;
        if (_tempoBpm > _tempoBpmMax) _tempoBpm = _tempoBpmMax;
      });
  }

  void _hintDialog() => showDialog(
        context: context,
        builder: (BuildContext context) {
          final double wd = _screenSize.width * 0.8;
          final TextStyle textStyle =
              //TextStyle(fontSize: wd / 18, color: Colors.black);
              GoogleFonts.roboto(fontSize: wd / 19, color: Colors.black);
          final TextStyle textStyleEmph = textStyle.copyWith(
              fontWeight: FontWeight.w600, fontSize: textStyle.fontSize * 1.2);
          final Widget message = GestureDetector(
            onTap: () {
              //setState(() {}); //ToDo: Why?
              Navigator.of(context).pop();
            },
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wd * 0.05,
              ),
              child: RichText(
                textAlign: TextAlign.left,
                textScaleFactor: 1,
                text: TextSpan(
                  style: textStyle,
                  children: [
                    TextSpan(
                        text:
                            'Try to tap, swipe, or rotate everything while the metronome is playing.\n\n'),
                    TextSpan(
                        text:
                            'This is the best way to see (and to hear) how everything works.'),
                  ],
                ),
              ),
            ),
          );
          return AlertDialog(
            backgroundColor: Colors.amber[50].withOpacity(0.75),
            elevation: 10.3,
            title: GestureDetector(
              onTap: () {
                //setState(() {}); //ToDo: Why?
                Navigator.of(context).pop();
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Flexible(
                    flex: 5,
                    child: Image.asset('images/owl3-3-3.png', fit: BoxFit.fill),
                  ),
                  Flexible(
                    flex: 20,
                    child: Text(
                      //"Hint 1 of 1:",
                      "Only one hint:",
                      style: textStyleEmph.copyWith(color: Colors.indigo),
                      textScaleFactor: 1,
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ),
            //children: <Widget>[message],
            content: message,
          );
        },
      );

  /// Start/Stop play handler
  void _play() {
    //_subbeatWidth = _subbeatWidth == 0 ? 60 : 0;

    if (!_playing && hideCtrls) _controller.forward();

    _channel
        .togglePlay(_tempoBpm, _beat.beatCount, _screenOn)
        .then((int result) {
      if (result != 0)
        setState(() {
          // TODO
          //IS: TEST
          Provider.of<MetronomeState>(context, listen: false).reset();
          //_tempoBpm = realTempo;
        });
    });

    if (_playing) {
      _playing = false;
      if (hideCtrls) _controller.reverse();

      _stopPressedCount++;
      if ((_stopPressedCount == 2) && !_bHintWasAlreadyShownOrUserIsBrave) {
        _userIsBrave();
        _hintDialog();
      }

      setState(() {}); // Stops OwlGridState::AnimationController
    }
    //TODO setState(() {});
  }

  /// Set new tempo to platform sound code
  void _setTempo(int tempo) {
    if (_tempoBpm != tempo) {
      _tempoBpm = tempo;
      if (_playing) _channel.setTempo(_tempoBpm);
      setState(() {}); //ToDo: в такой последовательности?
      //_userPrefs.store(_beat.subBeatCount, _tempoBpm, _activeMetre, _activeSoundScheme, _volume, userRhythms);
      //ToDo: пока убрал
    }
  }

  void _setVolume(double value) {
    if (value < 0) value = 0;
    if (value > 100) value = 100;
    setState(() {
      _mute = value == 0;
      _volume = value; //.round();
    });
    _channel.setVolume(_volume.round());
  }

  void _changeVolumeBy(int delta) {
    setState(() {
      _volume += delta;
      if (_volume < 0) _volume = 0;
      if (_volume > 100) _volume = 100;
      _mute = _volume == 0;
      _channel.setVolume(_volume.round());
    });
  }

  /// /////////////////////////////////////////////////////////////////////////
  /// assistants for UI notification handlers
  ///

  ///Запасаем пользовательский ритм для данного числа долей.
  ///После этого помещаем его в общий список
  void storeUserRhythm() {
    userRhythms[_beat.beatCount - 1] =
        UserRhythm(_beat.subBeats, _beat.accents);
    _lastEditedBeatIndex = _beat.beatCount - 1;
    int positionToInsert = _scrollBarPosition;

    ///EXPERIMENT, todo
    int pos = userRhythms[_beat.beatCount - 1]
        .isInTheList(_allPredefinedRhythms[_beat.beatCount - 1]);
    if (pos >= 0) {
      //Нашли и фактически удаляем из списка
      userRhythms[_beat.beatCount - 1].bDefined = false;
      //_lastShownWasUsers[_beat.beatCount - 1]=false; это в Make
      _lastEditedInThisBeat = -1; //потеряли? насовсем?//pos;
      positionToInsert = pos;
    } else {
      userRhythms[_beat.beatCount - 1].inheritName();
      _lastEditedInThisBeat = positionToInsert;
    }
    makeRhythmsForScroll(positionToInsert, positionToInsert);
    debugPrint("new rhythm was stored in " + _beat.beatCount.toString());
  }

  ///Из пользовательского и предустановленных создаем то, что крутится.
  ///Вызывается  при любом изменении ритма, который мы рисуем и играем
  ///scrollBarPosition - что показываем в строке акцентов
  ///insertUserAtPosition - куда положим пользовательский ритм.
  ///
  /// ToDo: всегда сопровождается созданием beat (e.g. beat = BeatMetre(userRhythms[beatIndex]);)
  /// отправкой его в состояние метронома,  отправкой его в яву
  /// и заканчивается setState. Надо причесывать...
  /// АККУРАТНО! storeUserRhythm собирает ритм из beat, эта же процедура задаёт
  /// beat. Всё это надо аккуратно оформить.
  ///
  void makeRhythmsForScroll(int scrollBarPosition, int insertUserAtPosition) {
    int beat = _beat.beatCount;
    _rhythmsToScroll =
        List.from(_allPredefinedRhythms[beat - 1], growable: true);
    //int length=_rhythmsToScroll.length;
    if (userRhythms[beat - 1].bDefined)
      _rhythmsToScroll.insert(insertUserAtPosition, userRhythms[beat - 1]);
    _lastShownWasUsers[beat - 1] =
        (insertUserAtPosition == scrollBarPosition) &&
            (userRhythms[beat - 1].bDefined);
    _scrollBarPosition = scrollBarPosition;
  }

  void _userIsBrave() {
    //_bUserIsBrave = true;
    if (!_bHintWasAlreadyShownOrUserIsBrave) _setHintStatusToTrue();
  }

  /// /////////////////////////////////////////////////////////////////////////
  /// UI notification handlers
  ///

  ///Крутим строку акцентов
  void _onScrollRhythms(int position) {
    if (_playing) _userIsBrave();

    if (position != _scrollBarPosition) {
      _scrollBarPosition = position;
      _beat = BeatMetre(_rhythmsToScroll[_scrollBarPosition]);
      _lastShownWasUsers[_beat.beatCount - 1] =
          (_scrollBarPosition == _lastEditedInThisBeat);

      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      Provider.of<MetronomeState>(context, listen: false).beatMetre =
          _beat; // TODO Need???
      _channel.setBeat(
          _beat.beatCount,
          _beat.subBeatCount,
          _tempoBpm,
          _activeSoundScheme,
          _beat.subBeats,
          Prosody.reverseAccents(_beat.accents, _beat.maxAccent));
      debugPrint('onScroll');
      setState(() {
        // _updateMetreBar = true;
      }); //TODO ListWheelScrollView redraws 1 excess time after wheeling
    }
  }

  /// Из списка. Число бит (-1); позиция в predefined, или же пользовательский
  void onRhythmSelectedFromList(int beatIndex, int position, bool bUsers) {
    if (_playing) _userIsBrave();

    if (!(false)) //ToDo:(проверяем, что надо менять что-то)
    {
      int oldBeat = _beat.beatCount;
      if (bUsers) {
        _beat = BeatMetre(userRhythms[beatIndex]);
        makeRhythmsForScroll(0, 0);
      } else {
        _beat = BeatMetre(_allPredefinedRhythms[beatIndex][position]);
        makeRhythmsForScroll(
            position, position + 1); //пользовательский - следующим
      }
      if (oldBeat != _beat.beatCount) _lastEditedInThisBeat = -1;
      Provider.of<MetronomeState>(context, listen: false).beatMetre =
          _beat; // TODO Need???
      _channel.setBeat(
          _beat.beatCount,
          _beat.subBeatCount,
          _tempoBpm,
          _activeSoundScheme,
          _beat.subBeats,
          Prosody.reverseAccents(_beat.accents, _beat.maxAccent));
      print('_onBeatChanged2');
      setState(() {
        _updateMetreWheels = true;
        //_updateMetreBar = true;
      });
    }
    //ToDo: _userPrefs.store(_beat.subBeatCount, _tempoBpm, _activeMetre, _activeSoundScheme, _volume, userRhythms);
    //пока убрал
  }

  ///Изменяем число нот
  void _onBeatChanged(int beats) {
    if (_playing) _userIsBrave();

    print('_onBeatChanged');
    if (_beat.beatCount != beats)

    ///Проверить не так надо? //ToDo
    {
      _lastEditedInThisBeat = -1;
      if ((beats - 1 == _lastEditedBeatIndex) &&
          _lastShownWasUsers[_lastEditedBeatIndex]) {
        ///Решается тонкий философский вопрос, результат
        ///недельных рассуждений.
        ///
        ///Что делать, если пользователь редактировал-редактировал,
        ///а потом колесо дернул? Дернул, вернул назад - а всё пропало!
        ///
        ///Чтобы его не расстраивать, мы ему возвращаем его последнюю редакцию -
        ///она важнее стандартных размеров. Но чтобы не было путаницы.
        ///мы напишем в строке названий ритмов, что это редактированный.
        _beat = BeatMetre(userRhythms[beats - 1]);

        makeRhythmsForScroll(0, 0);
      } else {
        ///Второй сложный вопрос: при выборе размера, что нам делать с поддолями?
        ///Пока я их все игнорирую...//ToDo: хорошо ли это?
        _beat = BeatMetre(_basicRhythms[beats - 1]);
        makeRhythmsForScroll(0, 1);
        //Третий вопрос из той же серии: Встать на позицию, которую показывали последний раз?
        //Ой ли? А пользователь с ума не сойдет?
        //
        //Общая проблема: Что лучше? Пользователю возвращать его выбор,
        //или наоборот, всегда подсовывать что-то стандартное?
        ///Видимо, лучше давать то, что он последний раз смотрел, но при этом сделать
        ///очень простой soft reset.ToDo:
        //
        //Дальше, куда пользовательский вставлять? 1 - на второе место.
      }

      //_beat.beatCount = beats;

      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      Provider.of<MetronomeState>(context, listen: false).beatMetre =
          _beat; // TODO Need???
      _channel.setBeat(
          _beat.beatCount,
          _beat.subBeatCount,
          _tempoBpm,
          _activeSoundScheme,
          _beat.subBeats,
          Prosody.reverseAccents(_beat.accents, _beat.maxAccent));
      print('_onBeatChanged2');
      setState(() {
        _scrollBarController.jumpToItem(_scrollBarPosition);

        ///Если раскрутить эти колёса одновременно, можно уронить
        ///приложение.

        // _updateMetreBar = true;
      });
    }
  }

  ///Изменяем число нот, не глядя на пользовательские ритмы и
  ///выбирая первый базовый
  void _onUltimateJump(int beatsToSet) {
    if (_playing) _userIsBrave();

    _lastEditedInThisBeat = -1;
    print('_onJump');
    _beat = BeatMetre(_basicRhythms[beatsToSet - 1]);
    Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;
    makeRhythmsForScroll(0, 1); //пользовательский - сразу за стандартным
    _channel.setBeat(
        _beat.beatCount,
        _beat.subBeatCount,
        _tempoBpm,
        _activeSoundScheme,
        _beat.subBeats,
        Prosody.reverseAccents(_beat.accents, _beat.maxAccent));
    print('-pmuJ');

    setState(() {
      _updateMetreWheels = true; //Todo:?
      ///Это нужно, если остаётся старая механика, где
      ///FixedExtentScrollController пересоздаётся внутри state.
      ///Другое решение - сделать их внешними. Кажется,
      ///это решение может быть более надежно.
    });
  }

  void onAllSubbeatsChanged(int subbeatCount) {
    if (_playing) _userIsBrave();

    //TODO
    _beat.subBeatCount = subbeatCount; //nextSubbeat(_beat.subBeatCount);
    //TODO Provider.of<MetronomeState>(context, listen: false).reset();
    //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need??? - вроде нет, не пересоздавали

    storeUserRhythm();

    _channel.setBeat(
        _beat.beatCount,
        _beat.subBeatCount,
        _tempoBpm,
        _activeSoundScheme,
        _beat.subBeats,
        Prosody.reverseAccents(_beat.accents, _beat.maxAccent));
    setState(() {});
  }

  void onOwlSubbeatsChanged(int id, int subCount) {
    if (_playing) _userIsBrave();

    assert(id < _beat.subBeats.length);
    _beat.subBeats[id] = subCount;

    ///ToDo: вот эту рутину ниже нужно куда-нибудь утащить...
    ///Ставить в виджет - не хочется (типа, виджет обрабатывает нам данные...)
    ///Видимо,   надо сделать subBeats как свойство, и проверять там.
    if (_beat.subBeatsEqualAndExist()) _beat.subBeatCount = _beat.subBeats[0];

    storeUserRhythm();

    //TODO Provider.of<MetronomeState>(context, listen: false).reset();
    //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
    _channel.setBeat(
        _beat.beatCount,
        _beat.subBeatCount,
        _tempoBpm,
        _activeSoundScheme,
        _beat.subBeats,
        Prosody.reverseAccents(_beat.accents, _beat.maxAccent));
    setState(() {});
  }

  void onAccentChanged(int id, int accent) {
    if (_playing) _userIsBrave();

    assert(id < _beat.subBeats.length);

    //_beat.setAccent(id, accent);
    _beat.setAccent(id, accent);
    //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???

    storeUserRhythm();

    _channel.setBeat(
        _beat.beatCount,
        _beat.subBeatCount,
        _tempoBpm,
        _activeSoundScheme,
        _beat.subBeats,
        Prosody.reverseAccents(_beat.accents, _beat.maxAccent));

    setState(() {});
  }

  ///Изменяем значение ноты (знаменатель)
  void _onNoteChanged(int noteValue) {
    //_noteValue = noteValue;  // Does not affect sound
    //bool changed = insertMetre(_beat.beatCount, noteValue);
    bool changed = (_noteValue != noteValue);
    if (changed) {
      print('_onNoteChanged');
      setState(() {
        _noteValue = noteValue;
        // _updateMetreBar = changed;
      });
    }
  }

  /*
  ///Изменились числитель и знаменатель? Временно не использую
  void onMetreChanged(int beats, int noteValue) {
    //_noteValue = noteValue;  // Does not affect sound
    // Change active metre at first
    //insertMetre(beats, noteValue);
    if (_beat.beatCount != beats) {
      _beat.beatCount = beats;
      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
      _channel.setBeat(
          _beat.beatCount,
          _beat.subBeatCount,
          _tempoBpm,
          _activeSoundScheme,
          _beat.subBeats,
          Prosody.reverseAccents(activeMetre.accents));
    }

    print('onMetreChanged');
    setState(() {
      _updateMetre = true;
    });
  }
   */

  ///(обработчик старой строки акцентов)
  void onMetreBarChanged(int index) {
    _activeMetre = index;
    int beats = _metreList[index].beats;
    if (_beat.beatCount != beats ||
        !equalLists(_metreList[index].accents, _metreList[index].accents)) {
      _beat.beatCount = beats;
      //_beat.accents = _metreList[index].accents;
      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
      _channel.setBeat(
          _beat.beatCount,
          _beat.subBeatCount,
          _tempoBpm,
          _activeSoundScheme,
          _beat.subBeats,
          Prosody.reverseAccents(_metreList[index].accents, _beat.maxAccent));
    }
    //_noteValue = _metreList[index].note;  // Does not affect sound
    print('onMetreBarChanged');
    setState(() {
      _updateMetreWheels = true;
    });
  }

  /// /////////////////////////////////////////////////////////////////////////
  /// >>>>>>>> Widget section
  ///

  ///widget Main screen
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
//    mediaQueryData.devicePixelRatio = 1.0,
//    mediaQueryData.textScaleFactor = 1.0,
//    mediaQueryData.padding = EdgeInsets.zero,
//    mediaQueryData.viewInsets = EdgeInsets.zero,
//    mediaQueryData.systemGestureInsets = EdgeInsets.zero,
//    mediaQueryData.viewPadding = EdgeInsets.zero,
//    mediaQueryData.disableAnimations = false,
//    mediaQueryData.boldText = false,
    _screenSize = mediaQueryData.size;
    _sideSquare = _screenSize.shortestSide;

    print(
        'mediaQueryData ${mediaQueryData.padding} - ${mediaQueryData.viewInsets} - ${mediaQueryData.viewPadding}');

    if (_screenSize.width > _screenSize.height)
      _sizeCtrls =
          new Size(_screenSize.width - _sideSquare, _screenSize.height);
    else
      _sizeCtrls =
          new Size(_screenSize.width, _screenSize.height - _sideSquare);
    _sizeCtrlsShortest = _sizeCtrls.shortestSide;

    //Theme.of(context).materialTapTargetSize;

    //debugPrint(        'screenSize $_screenSize - ${mediaQueryData.devicePixelRatio} - ${1 / _screenSize.aspectRatio} - $_sideSquare');

    if (_textStyle == null)
      _textStyle = Theme.of(context)
          .textTheme
          .headline4
          .copyWith(color: _textColor, /*fontSize: _textSize, */ height: 1);

    if (_screenSize.width <= 0 || _screenSize.height <= 0) //TODO
      return Container();
    else
      return Scaffold(
        key: _scaffoldKey, // for showSnackBar to run
        backgroundColor: Colors
            .deepPurple, //Color.fromARGB(0xFF, 0x45, 0x1A, 0x24),  //TODO: need?
        //appBar: AppBar(title: Text(widget.title),),
        body: SafeArea(
          child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
            final Orientation orientation = MediaQuery.of(context).orientation;
            final bool portrait = orientation == Orientation.portrait;
            final Size ourAreaSize =
                Size(constraints.maxWidth, constraints.maxHeight);
            if (!portrait) _sideSquare -= mediaQueryData.padding.vertical;

            return orientationBuilder(context, orientation, ourAreaSize);
          }),
        ),
      );
  }

  Widget orientationBuilder(
      BuildContext context, Orientation orientation, Size ourAreaSize) {
    // debugPrint("total area accessible for us :  $ourAreaSize");

    //_showAds = false;
    final bool portrait = orientation == Orientation.portrait;

    final double aspect = 1 / _screenSize.aspectRatio;
    final double aspectCtrls = (_showAds
            ? _sizeCtrls.height - _heightAds[portrait ? 0 : 1]
            : _sizeCtrls.height) /
        _sizeCtrls.width;
    //debugPrint("aspect $aspect - $aspectCtrls");
    final double wScale = aspectCtrls > 1.5 ? _squareX : 1;
    final double hScale = aspectCtrls < 0.9 ? _squareY : 1;
    final Size sizeOwlenome = new Size(
        portrait ? _sideSquare : wScale * _sideSquare,
        portrait
            ? hScale * _sideSquare
            : _sideSquare - (_showAds ? _heightAds[1] : 0));
    //_sideSquare);

    _smallBtnSize = Theme.of(context).buttonTheme.height;
    _smallBtnSize0 = 1.2 * Theme.of(context).buttonTheme.height; //1.2
    double btnPadding = 0.2 * Theme.of(context).buttonTheme.height;
    _paddingBtn = new Offset(btnPadding, btnPadding);

    double _barHeight =
        (portrait ? cBarHeightVert : cBarHeightHorz) * _sizeCtrls.height;
    if (_barHeight < cMinTapSize) _barHeight = cMinTapSize;
    final Size metreBarSize = new Size(_sizeCtrls.width, _barHeight);

    // Vertical/portrait
    if (true /*portrait todo*/) {
      return PortraitU(ourAreaSize);

      /// Owl square and controls
      final List<Widget> innerUI = <Widget>[
        _buildOwlenome(portrait, sizeOwlenome),
        _buildBar(portrait, metreBarSize),
        _buildControls(portrait, metreBarSize.height),
      ];

      if (_showAds) innerUI.add(_buildAds(portrait));

      return Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            image: AssetImage('images/BackgV.jpg'),
            fit: BoxFit.cover,
          )),
          child: Stack(children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: innerUI,
            ),
            Positioned(
                left: _paddingBtn.dx,
                bottom:
                    _showAds ? _heightAds[0] + _paddingBtn.dy : _paddingBtn.dy,
                child: _buildVolumeBtn(
                    _smallBtnSize, //0.05 * _sizeCtrlsShortest
                    _sizeCtrlsShortest)),

            /// Git revision number
            _showVersion
                ? Align(
                    alignment: Alignment.topLeft,
                    child: Text(_version,
                        style: Theme.of(context)
                            .textTheme
                            .bodyText1
                            .copyWith(color: Colors.white)))
                : Container(),
          ]));
    } else // Horizontal/landscape
    {
      //TODO _showAds = true;
      /// Owl square and controls
      final Widget innerUI = new Row(children: <Widget>[
        _buildOwlenome(portrait, sizeOwlenome),
        //Container(color: Colors.red, height: sizeOwlenome.height, width: sizeOwlenome.width),
        Expanded(
          child: Stack(
              //fit: StackFit.expand,
              children: <Widget>[
                //Positioned.fill(
                //child:
                Column(mainAxisSize: MainAxisSize.max,
                    //mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _buildBar(portrait, metreBarSize),
                      //Container(height: metreBarSize.height, width: metreBarSize.width),
                      _buildControls(portrait, metreBarSize.height),
                    ]
                    //),
                    //),
                    ),
                Positioned(
                    left: 0,
                    bottom: _paddingBtn.dy,
                    //bottom: _showAds ? _heightAds[1] + _paddingBtn.dy : _paddingBtn.dy,
                    child: _buildVolumeBtn(
                        _smallBtnSize, //0.05 * _sizeCtrlsShortest
                        _sizeCtrlsShortest)),

                /// Git revision number
                _showVersion
                    ? Align(
                        alignment: Alignment.topRight,
                        child: Text(_version,
                            style: Theme.of(context)
                                .textTheme
                                .bodyText1
                                .copyWith(color: Colors.white)))
                    : Container(),
              ]),
        ),
      ]);

      final Widget fullUI = !_showAds
          ? innerUI
          : new Column(
              //mainAxisSize: MainAxisSize.max,
              children: <Widget>[
                  Expanded(
                    child: innerUI,
                  ),
                  _buildAds(portrait),
                ]);

      return Container(
          decoration: BoxDecoration(
              image: DecorationImage(
            image: AssetImage('images/BackgH.jpg'),
            fit: BoxFit.cover,
          )),
          child: fullUI);
    }
  }

  ///ISH: My portrait layout; use bOuterSpaceScrollDebug to play with different ratios (within one phone).
  ///This consists of the metronome itself, plus any other stuff (perhaps something else, if we need it once ); it is only
  ///our area, in particular the app bar is not here.
  ///If bOuterSpaceScrollDebug, the area of metronome will be controlled by a scroll.
  Widget PortraitU(Size ourAreaSize) {
    ///Резервируем снизу место, units; например,  для рекламы, или любых иных целей.
    final double bottomReserved = bOuterSpaceScrollDebug
        ? reservedHeightBottom * 0.01 * ourAreaSize.height
        : (_showAds ? _heightAds[0] : 0);

    return Container(
      //Фактическая область, доступная для приложения (метроном вместе с рекламой или чем-то еще)
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage('images/backg.png'),
        fit: BoxFit.cover,
      )),
      child: Stack(
        children: <Widget>[
          MetronomeArea(
              Size(ourAreaSize.width, ourAreaSize.height - bottomReserved)),
          /*   Positioned(
              //ToDo: MOVE
              left: _paddingBtn.dx,
              bottom:
                  _showAds ? _heightAds[0] + _paddingBtn.dy : _paddingBtn.dy,
              child: _buildVolumeBtn(
                  _smallBtnSize, //0.05 * _sizeCtrlsShortest
                  _sizeCtrlsShortest)),
*/
          /// Git revision number
          _showVersion
              ? Align(
                  alignment: Alignment.topLeft,
                  child: Text(_version,
                      style: Theme.of(context)
                          .textTheme
                          .bodyText1
                          .copyWith(color: Colors.white)))
              : Container(),
          _showAds
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: _buildAds(true),
                )
              : Container(),

          ///Scroll for testing layouts
          bOuterSpaceScrollDebug
              ? Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                      //padding: EdgeInsets.all(_heightAds[0] * 0.1),
                      /*
                      decoration: BoxDecoration(
                        //color: Colors.grey.withOpacity(0.5),
                        border: Border.all(
                          color: Colors.green, //
                        ),
                      ),*/
                      height: _heightAds[0] / 2,
                      width: ourAreaSize.width,
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: Slider(
                                value: reservedHeightBottom,
                                activeColor: Colors.yellowAccent,
                                onChanged: (double newVal) {
                                  setState(() {
                                    reservedHeightBottom = newVal;
                                  });
                                },
                                min: 0,
                                max: maxReservedHeightBottom),
                          ),
                          Expanded(
                              flex: 1,
                              child: Text(
                                "Height:  " +
                                    (ourAreaSize.height - bottomReserved)
                                        .toStringAsFixed(1),
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: _screenSize.width / 20,
                                ),
                                textScaleFactor: 1,
                              )),
                        ],
                      )),
                )
              : Container(),
          bOuterSpaceScrollDebug
              ? Positioned(
                  left: 0,
                  top: ourAreaSize.height - bottomReserved,
                  child: Container(
                    width: _screenSize.width,
                    height: 1,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.red,
                      ),
                    ),
                  ))
              : Container(),
        ],
      ),
    );
  }

  ///widget Square section with metronome itself
  Widget _buildOwlenome(bool portrait, Size size) {
    if (!_skin.isInit || size.isEmpty)
      return Container(
        //color: Colors.orange,
        width: size.width,
        height: size.height,
      );

    //TODO MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    print('_buildOwlenome $size');

    // TODO VG
    final double paddingX = _beat.beatCount == 3 || _beat.beatCount == 4
        ? 10
        : 0; //0.03 * _widthSquare : 0;
    final double paddingY = _beat.beatCount > 4 ? 0.02 * _sideSquare : 0;
    final EdgeInsets padding = portrait
        ? new EdgeInsets.only(bottom: paddingY, left: paddingX, right: paddingX)
        : new EdgeInsets.only(
            bottom: paddingY, left: paddingX, right: paddingX);
    final Offset spacing = new Offset(10, 0);

    ///widget Owls
    final Widget wixOwls1 = new OwlGrid(
      playing: _playing,
      beat: _beat,
      activeBeat: -1, //state.activeBeat,
      activeSubbeat: -1, //state.activeSubbeat,
      noteValue: activeMetre.note,
      accents: activeMetre.accents,
      maxAccent: activeMetre.maxAccent,
      animationType: _animationType,
      onChanged: onOwlSubbeatsChanged,
      onAccentChanged: onAccentChanged,
    );

    final Widget wixOwls = new OwlGridRot(
      playing: _playing,
      beat: _beat,
      activeBeat: -1, //state.activeBeat,
      activeSubbeat: -1, //state.activeSubbeat,
      noteValue: activeMetre.note,
      accents: activeMetre.accents,
      maxAccent: activeMetre.maxAccent,
      spacing: spacing,
      padding: padding,
      skin: _skin,
      size: size,
      onChanged: onOwlSubbeatsChanged,
      onAccentChanged: onAccentChanged,
    );

    /// Do not use padding here!
    return Container(
        width: size.width,
        height: size.height,

        ///widget Background
/*
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_primaryColor, _accentColor])
       // image: DecorationImage(
        //  image: AssetImage('images/Backg-Up-1.jpg'),
         // fit: BoxFit.cover
       // )
      ),
*/
        child: wixOwls);
  }

  ///widget Metre-bar section
  Widget _buildBar(bool portrait, Size size) {
    final double horzSpace = portrait ? 16 : 16;

    final double paddingY = portrait ? 0 : 0.1 * _sideSquare;
    final double btnPadding = 0.2 * Theme.of(context).buttonTheme.height;
    final Size metreSize =
        Size((portrait ? 0.25 : 0.25) * size.width, size.height);
    double itemExtent = 0.5 * metreSize.width; //44,

    print('metreSize $metreSize - $itemExtent');
    //itemExtent = 44;
    final Size barSize =
        Size((portrait ? 0.70 : 0.70) * size.width, 0.5 * size.height);
    final Size listTempoSize =
        new Size((portrait ? 0.88 : 0.88) * barSize.width, barSize.height);
    final Size noteTempoSize =
        new Size(0.12 * barSize.width, 0.9 * barSize.height);
    //final Size subbeatSize = Size(0.2 * _sizeCtrls.width, 1.25 * barSize.height);
//    final Size subbeatSize = new Size(barSize.height, barSize.height);
    //0.02 * _sizeCtrls.width,
    final Size bracketSize =
        new Size(3.2 * btnPadding, 0.16 * _sizeCtrls.height);

    print('Font ${_textStyle.fontSize}');

    List<Widget> children = new List<Widget>();

    final Widget barSpacer = new Container(
      width: btnPadding,
    );

    bool updateMetre = _updateMetreWheels;
    _updateMetreWheels = false;

    final MetreWidget metre = new MetreWidget(
      update: updateMetre,
      beats: _beat.beatCount,
      minBeats: minBeatCount,
      maxBeats: maxBeatCount,
      note: activeMetre.note,
      minNote: minNoteValue,
      maxNote: maxNoteValue,
      width: metreSize.width,
      height: metreSize.height,
      itemExtent: itemExtent,
      color: Colors.deepPurple,
      textStyle: _textStyle,
      textStyleSelected: _textStyle.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: _textStyle.fontSize + 2,
          height: 1,
          color: activeMetre.regularAccent ? _cWhiteColor : _clrIrregularMetre),
      onBeatChanged: _onBeatChanged,
      onNoteChanged: _onNoteChanged,
    );

/*    final Widget accentMetre = new AccentMetreWidget(
      beats: _beat.beatCount,
      noteValue: _noteValue,
      accents: _beat.accents,
      pivoVodochka: _beat.pivoVodochka, //?
      size: barSize,
      //color: _beat.regular ? _cWhiteColor : Colors.orangeAccent,
      onChanged: onMetreChanged,
      onOptionChanged: (bool pivoVodochka) {
        _beat.setAccentOption(pivoVodochka);
        setState(() {});
      },
    );*/

    bool updateMetreBar = _updateMetreBar;
    _updateMetreBar = false;

    final Widget metreBar = new MetreBarWidget(
      update: updateMetreBar,
      metres: _metreList,
      activeMetre: _activeMetre,
      size: barSize,
      color: _clrRegularBar,
      colorIrregular: _clrIrregularBar, // Currently switched off
      noteColor: Colors.black,
      onSelectedChanged: onMetreBarChanged,
      onOptionChanged: (bool pivoVodochka) {
        //_beat.setAccentOption(pivoVodochka);
        if (activeMetre.setAccentOption(pivoVodochka ? 0 : 1)) {
          setState(() {});
        }
      },
      onResetMetre: () {
        activeMetre.setRegularAccent();
        //_beat.setRegularAccent();
        setState(() {
          _updateMetreBar = true;
        });
      },
    );

    ///widget Tempo list
    final Widget listTempo = new Container(
        //color: Colors.orange,
        //width: 80,
        height: listTempoSize.height,
        padding: EdgeInsets.only(
            top: 0.0 * _sizeCtrls.height, bottom: 0.0 * _sizeCtrls.height),
        //padding: EdgeInsets.only(top: 0.025 * _sizeCtrls.height, bottom: 0.025 * _sizeCtrls.height),
        child: TempoListWidget(
            //TODO Limit
            tempo: _tempoBpm,
            maxTempo: _tempoBpmMax,
            width: listTempoSize.width,
            textStyle: Theme.of(context)
                .textTheme
                .headline4
                .copyWith(color: _cTempoList, height: 1), //TODO
            //.copyWith(color: _cTempoList, fontSize: 0.07 * _sizeCtrls.height, height: 1),//TODO
            onChanged: _setTempo));
/*
    final Widget btnSubbeat = new SubbeatWidget(
      subbeatCount: _beat.subBeatCount,
      noteValue: activeMetre.note,
      color: _textColor,
      textStyle: _textStyle,
      size: subbeatSize,
      onChanged: onSubbeatChanged,
    );
*/

    final NoteTempoWidget noteTempo = new NoteTempoWidget(
      tempo: _tempoBpm,
      noteValue: activeMetre.note,
      color: Colors.white,
      size: noteTempoSize,
      textStyle: TextStyle(fontSize: 20, color: Colors.white),
    );

    if (portrait) {
      ///widget Metre row
      final Widget rowBar = new Padding(
          padding: EdgeInsets
              .zero, //only(top: paddingY, left: _padding.dx, right: _padding.dx),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                barSpacer,
                //Flexible(
                //flex: 25,
                //child:
                metre,

                ///widget Metre
                //),
                barSpacer,

                Expanded(
                  //flex: 75,
                  //fit: FlexFit.tight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        color: activeMetre.regularAccent
                            ? _clrRegularBar
                            : _clrIrregularBar,
                        child: Padding(
                          padding: EdgeInsets
                              .zero, //symmetric(horizontal: 0.5 * btnPadding),
                          child: Row(
                              //mainAxisSize: MainAxisSize.max,
                              mainAxisAlignment: MainAxisAlignment
                                  .center, //spaceBetween, for brackets
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                //Container(width: 0.02 * _sizeCtrls.width,),
//                        BarBracketWidget(
//                          direction: BarBracketDirection.left,
//                          color: Colors.black,
//                          size: bracketSize,
//                        ),
                                ///widget Subbeat widget
                                // Remove Flexible for BarBracketWidget usage here
                                Flexible(
                                  child: Padding(
                                      padding: EdgeInsets.only(
                                          top:
                                              2), //(bottom: 0.05 * _sizeCtrls.height),//20
                                      child: metreBar),
                                ),
//                        BarBracketWidget(
//                          direction: BarBracketDirection.right,
//                          color: Colors.black,
//                          size: bracketSize
//                        ),
                              ]),
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        color: Colors.deepPurple.withOpacity(0.8),
                        child: Row(
                            //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              _showNoteTempo ? noteTempo : Container(),

                              ///widget Note=tempo
                              Expanded(
                                child:
                                    //                        ClipRect(child:
                                    listTempo,

                                ///widget Tempo list
                              ),
                            ]),
                      ),
                    ],
                  ),
                ),
                //btnSubbeat,
                barSpacer,
              ]));

//            AnimatedOpacity(
//              duration: new Duration(seconds: 1),
//              opacity: _subbeatWidth,
//              child: _buildSubbeat(_textStyle),
//            )
//            AnimatedContainer(
//              duration: new Duration(seconds: 1),
//              width: _subbeatWidth,
//              child:
//            _buildSubbeat(_textStyle),
//            )

      return rowBar;
    } else {
      ///widget Metre row
      final Widget rowBar = Row(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center, // start,
          children: <Widget>[
            ///widget Metre
            metre,
            barSpacer,

            Flexible(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      color: activeMetre.regularAccent
                          ? _clrRegularBar
                          : _clrIrregularBar,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: <Widget>[
                            ///widget Subbeat widget
                            /////TODO !!!
                            //Flexible(child:
                            Padding(
                                padding: EdgeInsets
                                    .zero, //EdgeInsets.only(bottom: 0.05 * size.height),//20
                                child: metreBar),
                          ]),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 4),
                      color: Colors.deepPurple.withOpacity(0.8),
                      child: Row(
                          //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            _showNoteTempo ? noteTempo : Container(),

                            ///widget Note=tempo
                            Expanded(
                              child:
//                        ClipRect(child:
                                  listTempo,
                            ),
                          ]),
                    ),
                  ]),
            ),
            //btnSubbeat,
            //listTempo,
            //accentMetre,
          ]);

      return rowBar;
    }
  }

  Widget borderedContainer(Size size) {
    return Container(
      width: size.width,
      height: size.height,
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        border: Border.all(
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildControls(bool portrait, double barHeight) {
    // Fill up the remaining screen as the last widget in column/row
    return
        //Container(
        //        width: _sizeCtrls.width,
        //        height: _sizeCtrls.height - 24,
        //  padding: const EdgeInsets.all(8.0),
        /// Background
        /*
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: portrait ? Alignment.bottomCenter : Alignment.topCenter,
                end: portrait ? Alignment.topCenter : Alignment.bottomCenter,
                colors: [_primaryColor, _accentColor])
        ),
      */
        Expanded(
      child: //TODO Without Expanded in portrait mode: constraints.height == infinity
          LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return _layoutControls(context, constraints, portrait, barHeight);
          //return Placeholder(fallbackWidth: constraints.maxWidth, fallbackHeight: constraints.maxHeight, color: Colors.red);
        },
      ),
      //child: rowButtons
    );
  }

  BoxDecoration decorDebug(Color color) {
    return BoxDecoration(
      //style: bDecoration? BorderStyle.solid: BorderStyle.none,
      // color: color.withOpacity(0.5),
      border: bBoxContainer
          ? Border.all(
              color: color,
            )
          : null,
    );
  }

  // Remaining section with controls
  Widget _layoutControls(BuildContext context, BoxConstraints constraints,
      bool portrait, double barHeight) {
    double minSquare = constraints.maxWidth > constraints.maxHeight
        ? constraints.maxHeight
        : constraints.maxWidth;
    print("minSquare $constraints - $barHeight");

    final TextStyle textStyleTimer = _textStyle.copyWith(fontSize: 20);

    final double horzSpace = portrait ? 16 : 16;
    double paddingY = portrait ? 0 : 0.1 * _sideSquare;
    double width = portrait ? _sideSquare : _screenSize.width - _sideSquare;

    // 48 - minimum recommended target size of 7mm regardless of what screen they are displayed on
    // 48 <= buttonSize <= 1.5 * 48
    final double playBtnSize = barHeight > 1.5 * cMinTapSize
        ? 1.5 * cMinTapSize
        : (barHeight < cMinTapSize ? cMinTapSize : barHeight);
    final Size subbeatSize = new Size(playBtnSize, playBtnSize);
    final double dist0 = _paddingBtn.dx;
    final Offset sidePadding = _paddingBtn;
    final Offset knobPadding = _paddingBtn; //const Offset(0, 0);
    //sidePadding = const Offset(0, 0);
    //knobPadding = const Offset(0, 0);
    //dist0 = 0;
    final List<double> res = knobRadius(
        constraints.maxWidth,
        constraints.maxHeight,
        0.5 * playBtnSize,
        sidePadding,
        knobPadding,
        dist0,
        _smallBtnSize0);
    final double diameter = 2 * res[0];
    _smallBtnSize = 2 * res[1] < _smallBtnSize0 ? 2 * res[1] : _smallBtnSize0;
    _smallBtnSize = 2 * res[1];

    //_smallBtnSize = _smallBtnSize0;
    //if (diameter == minSquare - 2 * knobPadding.dy)

    //print('${constraints.maxWidth} - ${constraints.maxHeight} - $diameter');

    //diameter = 2 * 143.76;
    //diameter = constraints.maxHeight - 20;
    //radius: 0.9 * minSquare,
    //Size subbeatSize = new Size(0.2 * _sizeCtrls.width, (portrait ? 0.3 : 0.2) * _sizeCtrlsShortest);

    ///widget Tempo knob control
    final Widget knobTempo = new Knob(
      value: _tempoBpm.toDouble(),
      min: minTempo.toDouble(),
      max: maxTempo.toDouble(),
      minAngle: -_cTempoKnobAngle,
      maxAngle: _cTempoKnobAngle,
      turnCount: _cTempoKnobTurns,
      sweepAngle: _cTempoKnobSweepAngle,
      dialDivisions: 12,
      limit: _tempoBpmMax.toDouble(),
      radiusButton: 0.1,
      radiusDial: 0.8,
      diameter: diameter,
      firmKnob: false,
      debug: false,
      showIcon: false,
      showDialText: _showKnobDialText,
      color: _cWhiteColor.withOpacity(0.8),
      colorOutLimit: _clrIrregularMetre,
      textStyle: _textStyle.copyWith(
          fontSize: 0.15 * _sizeCtrls.height, //0.2
          //fontWeight: FontWeight.bold,
          color: Colors.white,
          height: 1),
      onPressed: () {}, //_play,
      onChanged: (double value) {
        _setTempo(value.round());
      },
    );

    _knobValue.value = _tempoBpm.toDouble();
    Widget knobTempoNew = KnobTuned(
      knobValue: _knobValue,
      minValue: minTempo.toDouble(),
      maxValue: _tempoBpmMax.toDouble(),
      sensitivity: _sensitivity,
      onChanged: (KnobValue newVal) {
        _knobValue = newVal;
        _setTempo(newVal.value.round());
        //_tempoBpm = newVal.value.round();
        //if (_playing)
        //_setTempo(_tempoBpm);
        setState(() {});
      },
      diameter: diameter,
      //diameter: 0.65 * _sizeCtrls.height,//0.43
      innerRadius: _innerRadius,
      outerRadius: _outerRadius,
      textStyle: _textStyle.copyWith(
          fontSize: 0.2 * _sizeCtrls.height, color: Colors.white),
      timeToDilation: _timeToDilation,
    );

    final Widget btnSubbeat = new Tooltip(
      message: 'Press to divide beats to equal sub-beats',
      child: SubbeatWidget(
        subbeatCount: _beat.subBeatCount,
        noteValue: activeMetre.note,
        color: _textColor,
        textStyle: _textStyle,
        size: subbeatSize,
        onChanged: onAllSubbeatsChanged,
      ),
    );

    // On app startup: _soundSchemes == null

    final Widget buttonsRight = new Column(
        //      mainAxisAlignment: portrait ?
        //        MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildPlayBtn(playBtnSize, portrait),
          //Container(height: 0.1 * _sizeCtrls.height),
          Wrap(children: <Widget>[
            _buildSoundBtn(_smallBtnSize),
            _buildSettingsBtn(_smallBtnSize),
          ]),
          //_buildVolumeBtn(), //TODO SizedOverflowBox
          //_buildSettingsBtn(),
        ]);

    // Fill up the remaining screen as the last widget in column/row
    return Stack(children: <Widget>[
      Positioned(
        bottom: knobPadding.dy,
        left: 0.5 * (constraints.maxWidth - diameter),
        child: (_useNewKnob ? knobTempoNew : knobTempo),
      ),
      Positioned(
        left: _paddingBtn.dx,
        top: _paddingBtn.dy,
        //child: Container(),
        child: btnSubbeat,
      ),
//        Container(),
      Positioned(
        bottom: _paddingBtn.dx,
        left: _paddingBtn.dy,
        child: Row(children: <Widget>[
          Container(
            width: _smallBtnSize,
            height: _smallBtnSize,
          ),
          Container(width: _paddingBtn.dx),
          _buildSoundBtn(_smallBtnSize),
        ]),
      ),
      Positioned(
        right: _paddingBtn.dx,
        top: _paddingBtn.dy,
        child: _buildPlayBtn(playBtnSize, portrait),
      ),
      Positioned(
        right: _paddingBtn.dx,
        bottom: _paddingBtn.dy,
        child: Row(children: <Widget>[
          _buildHelpBtn(_smallBtnSize),
          Container(width: _paddingBtn.dx),
          _buildSettingsBtn(_smallBtnSize),
        ]),
      ),
    ]);
  }

  Widget _buildPlayBtn(double diameter, bool portrait) {
    final Widget icon =
        Icon(_playing ? Icons.pause : Icons.play_arrow, size: 1 * diameter);
    final Widget icon1 = Stack(alignment: Alignment.center, children: <Widget>[
      Image.asset('images/owl-btn.png', height: diameter, fit: BoxFit.contain),
      icon,
    ]);

    return new RawMaterialButton(
      //FlatButton
      //padding: EdgeInsets.all(18),//_padding.dx),
      child: icon,
      fillColor: Colors.deepPurple
          .withOpacity(0.5), //portrait ? _accentColor : _primaryColor,
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      constraints: BoxConstraints(
        minWidth: diameter,
        minHeight: diameter,
        //maxWidth: 200,
        //maxHeight: 200,
      ),
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: false,
      onPressed: _play,
    );

    return new MaterialButton(
        minWidth: (portrait ? 0.25 : 0.2) * _sizeCtrlsShortest,
        //iconSize: 0.4 * _sizeCtrls.height,
//      shape: RoundedRectangleBorder(
//        borderRadius: BorderRadius.circular(16),
//        side: BorderSide(width: 2, color: Colors.purple.withOpacity(0.8)),),
        shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
        padding: EdgeInsets.all(18), //_padding.dx),
        //child: tempo,
        child: Icon(_playing ? Icons.pause : Icons.play_arrow, size: diameter),
        color: Colors.deepPurple
            .withOpacity(0.5), //portrait ? _accentColor : _primaryColor,
        enableFeedback: false,
        onPressed: _play);
    /*
    Widget btnPlay = new IconButton(
      iconSize: 0.4 * _sizeCtrls.height,
      padding: EdgeInsets.all(0),//_padding.dx),
      icon: tempo,
      //icon: Icon(_playing ? Icons.pause_circle_outline : Icons.play_circle_outline,),
      color: _cWhiteColor, //portrait ? _accentColor : _primaryColor,
      enableFeedback: false,
      onPressed: _play
    );
*/
  }

  Widget _buildSoundBtn(double size) {
    int soundScheme = _activeSoundScheme;
    final int imageIndex = soundScheme < 3 ? soundScheme : 3;
    final String schemeName = 'images/sound' + imageIndex.toString() + '.png';

//    final String strScheme = _soundSchemes != null && _activeSoundScheme < _soundSchemes.length ?
//      _soundSchemes[_activeSoundScheme] : '';
    final String strScheme = (soundScheme + 1).toString();
    final double sizeButton = size;

    final Widget icon = new Image.asset(
      schemeName,
      width: sizeButton,
      height: sizeButton,
      fit: BoxFit.contain,
    );
    final Widget icon3 =
        new Stack(alignment: AlignmentDirectional.center, children: <Widget>[
      Image.asset(
        schemeName,
        width: sizeButton,
        height: sizeButton,
        fit: BoxFit.contain,
      ),
      Text(
        strScheme,
        style: Theme.of(context).textTheme.headline5.copyWith(
            fontSize: 0.9 * size,
            fontWeight: FontWeight.bold,
            color: Colors.white), //fontSize: 28
      ),
    ]);

    final Widget icon2 = new Row(children: <Widget>[
      Icon(Icons.music_note, size: 0.5 * sizeButton, color: _cWhiteColor),
      Text(
        strScheme,
        style: Theme.of(context).textTheme.headline5.copyWith(
            fontSize: 0.5 * size,
            fontWeight: FontWeight.bold,
            color: Colors.white), //fontSize: 28
      ),
    ]);

    return new RawMaterialButton(
      //FlatButton
      //padding: EdgeInsets.all(10),
      child: imageIndex == 3 ? icon2 : icon,
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      constraints: BoxConstraints(
        minWidth: sizeButton,
        minHeight: sizeButton,
        //maxWidth: sizeButton,
        //maxHeight: sizeButton,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: !_playing,
      onPressed: () {
        if (_soundSchemes?.length > 0) {
          _activeSoundScheme = (_activeSoundScheme + 1) % _soundSchemes.length;
          // setState() is called in onLimitTempo() call
          _channel.setSoundScheme(_activeSoundScheme).then((int result) {
            setState(() {});
          });
        }
      },
    );
  }

  Widget _buildVolumeBtn(double size, double height) {
    return new VolumeButton(
      value: _volume,
      min: 0,
      max: 100,
      //mute = false,
      msec: 250,
      onChanged: _setVolume,
//      onLongPress: () {setState(() {
//          _mute = !_mute;
//        });},
      diameter: size,
      height: height,
      color: _cWhiteColor,
      enableFeedback: !_playing,
    );
  }

  ///widget Settings
  Widget _buildSettingsBtn(double size) {
    return new RawMaterialButton(
      //FlatButton
      //padding: EdgeInsets.all(18),//_padding.dx),
      //padding: EdgeInsets.zero,
      child: Icon(Icons.settings, size: 1.0 * size),
      //fillColor: Colors.deepPurple.withOpacity(0.5), //portrait ? _accentColor : _primaryColor,
      //color: _cWhiteColor.withOpacity(0.8),
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
        //maxWidth: 200,
        //maxHeight: 200,
      ),
      materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap, // Make button of exact size
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: !_playing,
      onPressed: () {
        _showSettings(context);
      },
    );

    return new IconButton(
      iconSize: size,
      padding: EdgeInsets.all(0),
      icon: Icon(
        Icons.settings,
      ),
      color: _cWhiteColor.withOpacity(0.8),
      enableFeedback: !_playing,
      onPressed: () {
        _showSettings(context);
      },
    );
  }

  ///widget Settings
  Widget _buildHelpBtn(double size) {
    return new RawMaterialButton(
      child: Icon(Icons.help_outline, size: size),
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      materialTapTargetSize:
          MaterialTapTargetSize.shrinkWrap, // Make button of exact size
      enableFeedback: !_playing,
      onPressed: () {
        _showHelp(context);
      },
    );
  }

  Widget _buildAds(bool portrait) {
    return Container(
      height: portrait ? _heightAds[0] : _heightAds[1],
      color: Colors.grey[400],
      child: Image.asset('images/Ad-1.png',
          //height: portrait ? 50 : 32,
          fit: BoxFit.contain),
    );
  }

  /// <<<<<<<< Widget section
  /// /////////////////////////////////////////////////////////////////////////

  /// Show settings
  void _showSettings(BuildContext context) async {
    final Settings settings = new Settings(
      //animationType: _animationType,
      mixingType: _mixingType,
      activeScheme: _activeSoundScheme,
      soundSchemes: _soundSchemes,
      //useKnob: _useNewKnob,
    );

    final Settings res = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SettingsWidget(settings: settings)));
    //Navigator.of(context).push(_createSettings());

    if (res != null) {
      if (res.activeScheme != _activeSoundScheme &&
          _soundSchemes != null &&
          res.activeScheme < _soundSchemes.length) {
        _activeSoundScheme = res.activeScheme;
        _channel.setSoundScheme(_activeSoundScheme).then((int result) {
          setState(() {});
        });
      }
      if (res.mixingType != _mixingType) {
        _channel.setMix(res.mixingType).then((int result) {
          if (result >= 0) _mixingType = res.mixingType;
          debugPrint('_mixingType: ${_mixingType}');
          setState(() {});
        });
      }
      setState(() {
        //ToDo: не два ли раза?
        //_animationType = res.animationType;
        //_skin.animationType = _animationType;
        //_useNewKnob = res.useKnob;
      });
    }
    /*
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => SettingsWidget(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        var curveTween = CurveTween(curve: Curves.easeOut);
        var begin = Offset(0, 1);
        var end = Offset.zero;
        var tween = Tween(begin: begin, end: end).chain(curveTween);
        var offsetAnimation = animation.drive(tween);
        return SlideTransition(
          position: offsetAnimation,
          child: child
        );
      }
    );
   */
  }

  void _showHelp(BuildContext context) async {
    await Navigator.push(
        context, MaterialPageRoute(builder: (context) => HelpWidget()));
  }

  ///widget Plate under controls
  Widget _buildPlate(Widget widget, {Offset padding = Offset.zero}) {
    return Container(
        decoration: BoxDecoration(
            color: _ctrlColor.withOpacity(_opacity),
            //shape: BoxShape.circle,
            border: Border.all(
                color: _accentColor.withOpacity(_opacity), width: _borderWidth),
            borderRadius: BorderRadius.circular(_borderRadius)),
        padding:
            EdgeInsets.symmetric(horizontal: padding.dx, vertical: padding.dy),
        //margin: const EdgeInsets.all(0),
        child: widget);
  }

  ///widget Metre
  Widget _buildMetre(double width, double height, TextStyle textStyle) {
//    selectTextStyle: Theme.of(context).textTheme.headline
//      .copyWith(color: _cWhiteColor, fontWeight: FontWeight.bold, height: 1),//16
//    unSelectTextStyle: Theme.of(context).textTheme.subhead
//      .copyWith(color: Colors.white70, height: 1),//16
    bool update = _updateMetreWheels;
    _updateMetreWheels = false;

    print('Font ${textStyle.fontSize}');

    return new MetreWidget(
      update: update,
      beats: _beat.beatCount,
      minBeats: minBeatCount,
      maxBeats: maxBeatCount,
      note: activeMetre.note,
      minNote: minNoteValue,
      maxNote: maxNoteValue,
      width: width,
      height: height,
      itemExtent: 44,
      color: Colors.deepPurple,
      textStyle: textStyle,
      textStyleSelected: textStyle.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: textStyle.fontSize + 2,
          height: 1,
          color: activeMetre.regularAccent ? _cWhiteColor : _clrIrregularMetre),
      onBeatChanged: _onBeatChanged,
      onNoteChanged: _onNoteChanged,
    );
  }

  //===================================================
  //
  // ISH: виджеты без hard-coded values

  ///ToDo: убрать
  static final int _initTest = 3;
  int _tmpTest = _initTest;
  final List<int> testList = List<int>.generate(10, (int x) => x * 10);
  final FixedExtentScrollController tempController1 =
      FixedExtentScrollController(initialItem: _initTest);
  final FixedExtentScrollController tempController2 =
      FixedExtentScrollController(initialItem: _initTest);

  Widget testWidget(Size size) {
    //double fontSizeTempo = size.width * 1 / 10;
    //TextStyle textStyle = GoogleFonts.roboto(fontSize: fontSizeTempo);

    //final double wd = _screenSize.width * 0.95;
    final double wd = size.width * 0.8;
    final double ht = wd;
    final TextStyle textStyle =
        GoogleFonts.roboto(fontSize: wd / 18, color: Colors.black);
    final TextStyle textStyleEmph = textStyle.copyWith(
        fontWeight: FontWeight.w600, fontSize: textStyle.fontSize * 1.2);

    final Widget messageUgly = Flexible(
        fit: FlexFit.tight,
        // width: wd,
        //height: ht,
        //color: Colors.amber[50].withOpacity(0.90),
        /*decoration: BoxDecoration(
         // color: Colors.amber[50],
          //color: Colors.amber[50].withOpacity(0.90),
        ),*/
        child: Container(
          padding: EdgeInsets.symmetric(
            vertical: wd * 0.05,
            horizontal: wd * 0.01,
          ),
          child: RichText(
              textAlign: TextAlign.left,
              textScaleFactor: 1,
              text: TextSpan(
                style: textStyle,
                children: [
                  TextSpan(text: "Hint 1 of 1:\n\n", style: textStyleEmph),
                  TextSpan(
                      text:
                          'Tap the the play button first.\nThen tap/swipe/rotate anything.\n\n'),
                  TextSpan(
                      text:
                          'This is the best way to see what this app can do.'),

                  /*

                    TextSpan(
                      text: "Dear very-very first user!\n\n",
                    ),
                    TextSpan(text: 'This is a metronome for kids.\n\n'),
                    TextSpan(
                        text:
                            'It visualizes rhythms with owls, because owls are awesome and we hope that kids will like them. \n\n'),
                    TextSpan(text: 'To see what this app does, just tap the '),
                    TextSpan(
                      text: 'play ',
                      style: textStyleEmph,
                    ),
                    TextSpan(text: 'button and then tap/swipe '),
                    TextSpan(text: 'anything else', style: textStyleEmph),
                    TextSpan(text: ':  you will hear (and see) the result.\n\n'),
                    TextSpan(
                        text: 'In our team we have an artist, a programmer, and a mathematician... but we are not musicians. ' +
                            'We would be really happy to hear what you think about our experiment, especially about ' +
                            'its \'musical\'  components '
                                'like the quality of sound ' +
                            'or correctness of note grouping.\n\n'),
                    TextSpan(
                        text:
                            'And of course, we are worried how clear and easy to use these owls are. '+
                                 'What do you think?'+
                                '\n\n'),
                    TextSpan(
                        text:
                            'Well, any of your comment would be of paramount importance for us!\n\n' +
                                '- OwlTeam'),

                     */
                ],
              )),
        ));

    //return message;

    return RawMaterialButton(
      child: Text(
        "TEST MESSAGE",
        style: textStyle.copyWith(color: Colors.blue),
      ),
      onPressed: () {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            var message = RichText(
              textAlign: TextAlign.left,
              textScaleFactor: 1,
              text: TextSpan(
                style: textStyle,
                children: [
                  TextSpan(
                      text:
                          'Tap the the play button first.\nThen tap/swipe/rotate anything.\n\n'),
                  TextSpan(
                      text:
                          'This is the best way to see what this app can do.'),
                ],
              ),
            );
            return AlertDialog(
              backgroundColor: Colors.amber[50].withOpacity(0.75),
              elevation: 10.3,
              title: Text(
                "Hint 1 of 1:",
                style: textStyleEmph.copyWith(color: Colors.indigo),
                textScaleFactor: 1,
              ),
              content: message,
            );
          },
        );
      },
    );

/*
    return Container(
        width: size.width / 2,
        height: size.height,
        decoration: BoxDecoration(
            image: DecorationImage(
          image: AssetImage('images/wh23meter.png'),
          fit: BoxFit.fill,
        )),
        child: RawMaterialButton(
          child: Text("Press", style: textStyle),
          onPressed: () {
            showDialog(
              context: context,
              builder: (BuildContext context) => Dialog(
                  child: Stack(
                children: <Widget>[
                  Text("ZZs", style: textStyle),
                  Text("PrAAs", style: textStyle),
                ],
                //...bottom card part,
                //...top circlular image part,
              )),
            );
          },
        ));
    */
  }

  ///Скролл темпов.
  ///
  ///Витин скролл темпов, завернутый в LayoutBuilder, чтобы знать собственную ширину,
  ///и чуть ужатый по горизонтали, чтобы текст попадал в область, определенную Юриной картинкой
  Widget _tempoListFinallyGotLaid(TextStyle textStyle, double horShrink) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double width = constraints.maxWidth * horShrink;
      return Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          //decoration: decorTmp(Colors.black),
          width: width,
          child: TempoListWidget(
            //TODO Limit
            tempo: _tempoBpm,
            maxTempo: _tempoBpmMax,
            width: width,
            textStyle: textStyle,
            onChanged: _setTempo,
            bReactOnTap: false,

            ///ВАЖНО!
            ///Поскольку Витя считает, что перемотка по кругу - плохо,
            ///то необходимо убрать переход по тапу.
            ///Иначе получается очень неудобная ситуация:
            ///с  тапом по максимальному попадаем в 1, и снова по кругу...
            ///При втором промахивании пользователь в бешенстве и удаляет приложение.
          ),
        ),
      );
    });
  }

  ///Область метронома: совы и контролы
  Widget MetronomeArea(Size allowedSize) {
    //Область нашего метронома, всего вместе
    double totalWidth = allowedSize.width;
    double totalHeight = allowedSize.height;
    if ((totalWidth == 0) || (totalHeight == 0)) return Container();

    ///Это худшая из реальных (насколько я проверил отношения сторон на имеющихся телефонах) ситуаций.
    ///Обыкновенно пространства больше, чем мы предусматриваем в этом, худшем, случае, и
    ///мы адаптируемся, разреживая строки. //ToDo
    ///Если же его меньше (в каких-то квадратных уродах, скажем), то мы "вписываемся" в него искусственно - идеально не будет,
    ///но работать будет.
    ///
    /// Такое решение: на Юрином телефоне будет чуть всё сжато по горизонтали (это даже хорошо,
    /// поскольку слева плохо крутятся колёса). Его значение с рекламой - это 458/320, 1,43125
    /// На Pixel с рекламой - ~1.83
    ///
    /// Беру золотую середину - 1.6?
    final double minimalRatio = 1.5;

    final bool bDecreaseWidth = (totalHeight / totalWidth < minimalRatio);

    if (bDecreaseWidth) //Ужимаемся, если совсем плохо всё. Не должно случится на извествных телефонах.
      totalWidth = totalHeight / minimalRatio;

    ///Разбиваем на три области
    final double c1 = 0.85;
    final double c3 = 0.35;
    final double c2 = minimalRatio - (c1 + c3);

    /*final int nOfSpacec=5;
    final double spaceC=max(0,totalHeight/totalWidth-1)/nOfSpacec;*/

    double shadowOffset = totalWidth * 0.03; //TODO: запасти место под тень
    //(пока она едет зайцем).
    //А то разрушится трёхмернось.

    bool bTest = false;
    //bTest = true; //ToDo hide
    final List<Widget> metrMainAreas = <Widget>[
      _AreaOfOwls(true, Size(totalWidth * c1, totalWidth * c1)),
      //!bTest
      true
          ? _knobAndStartArea(true, Size(totalWidth, totalWidth * c2))
          : testWidget(Size(totalWidth, totalWidth * c2)),
      !bTest
          // (true)
          ? _rowControlsArea(true, Size(totalWidth, totalWidth * c3))
          : testWidget(Size(totalWidth, totalWidth * c3)),
    ];

    Widget metronome = Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
            width: totalWidth,
            height: totalHeight,
            child: Stack(
              children: <Widget>[
                bOuterSpaceScrollDebug
                    ? Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.black,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Text("virtual bootom of the phone",
                              textScaleFactor: 1,
                              style: TextStyle(
                                fontSize: 12 * totalWidth / pixelWidth,
                                color: Colors.yellowAccent,
                              )),
                        ),
                      )
                    : Container(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: metrMainAreas,
                ),
                /*Positioned(
                  //ToDo: кнопку перенсти, где ей и место
                  left: _paddingBtn.dx,
                  bottom: _showAds
                      ? _heightAds[0] + _paddingBtn.dy
                      : _paddingBtn.dy,
                  child: _buildVolumeBtn(
                      _smallBtnSize, //0.05 * _sizeCtrlsShortest
                      _sizeCtrlsShortest),
                ),
                */
              ],
            )));
    return metronome;
  }

  ///widget Metre-bar section
  Widget _knobAndStartArea(bool portrait, Size size) {
    final double useOfHeight = 0.95;

    final double knobDiameter = size.height * useOfHeight;

    ///Центр старта
    final double startDiameter = size.height * useOfHeight * 0.8 * 0.85;
    final double statrCenterX = size.width * 2.25 / 16 * 0.85;
    final double statrCenterY = size.height * useOfHeight / 2;

    ///Область служебных кнопок
    double rightArea = 0.08 * size.width;
    final double inkWellBetweenPaddingFact = 0.1;
    final double h = size.height *
        useOfHeight; //возмодно, нужно подровняь: size.height*useOfHeight
    ///Нужно, чтобы поместилось 3 кнопки и два паддинга:
    final double d = h / (3 + 2 * inkWellBetweenPaddingFact);
    if (rightArea > d) rightArea = d;
    //double inkWellBetweenPadding = inkWellBetweenPaddingFact * h;

    ///Центр кноба
    final double knobCenterX = 2 * statrCenterX +
        ((size.width - statrCenterX - startDiameter - rightArea) / 2) * 0.92;
    final double knobCenterY = statrCenterY;
    //knobDiameter /        2; //Фактически, выравниванием сверху - хотим быть поближе к совам
    //и подальше от остальных контролов

    ///Кнопки темпа
    final double tempoButtonsSize = knobDiameter / 2.5;
    //double fontSizeButtons = tempoButtonsSize / 2.3;
    /*
    TextStyle _textStyleButtons = //To Do: fix font; fix font size (obsolete)
        Theme.of(context) //ISH: Не знаю, зачем это. Следую Витиной практике
            .textTheme
            .headline4
            .copyWith(color: Colors.black, fontSize: fontSizeButtons);*/

    ///Отсутупы от центра кноба
    final double tempoButtonDeltaX =
        (knobDiameter + tempoButtonsSize) / 2 * 0.95 * 1.1;
    final double tempoButtonDeltaY =
        (knobDiameter - tempoButtonsSize) / 2 * 0.99;

    final double textOuterSizeY = knobDiameter * _pushDilationFactor / 1.2 / 2;
    final double textOuterSizeX = knobDiameter * _pushDilationFactor * 1.2 / 2;
    final double textOuterDY = knobDiameter * _pushDilationFactor * 0.02;

    final double knobFontSize = 0.3 * knobDiameter;
    final double knobFontSizeBig = knobFontSize * _pushDilationFactor;

    ///Кнопка хелп:
    final double helpCenterX = size.width * 0.88;
    final double helpCenterY = statrCenterY;
    final double helpDiam = (startDiameter + tempoButtonsSize) / 2;

    final Color tempoColor = (_tempoBpm <= minTempo ||
            _tempoBpm >= _tempoBpmMax)
        ? Colors.red
        : Colors
            .black; //Todo - В коробке с текстом над кнобом. И проверить там арифметику (она работает, но не доказывалась)

    final TextStyle knobTextStyle = GoogleFonts.roboto(
      fontSize: knobFontSize,
      color: tempoColor,
      //fontStyle: FontStyle.italic,
    );

    return Container(
      width: size.width,
      height: size.height,
      decoration: decorDebug(Colors.black),
      //color: Colors.black,
      child: Stack(
        overflow: Overflow.visible,
        fit: StackFit.expand,
        children: [
          /*Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ///ToDo
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: useOfHeight * size.width / 3,
                decoration: decorTmp(Colors.red),
                height: knobDiameter,
                //child: _buildPlayBtn1(size.height * useOfHeight),
              ),
              Container(
                width: useOfHeight * size.width / 3,
                height: knobDiameter,
                decoration: decorTmp(Colors.red),
              ),
              Container(
                  width: useOfHeight * size.width / 5,
                  height: knobDiameter,
                  decoration: decorTmp(Colors.red),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOneButton(
                                  "+1", 1, tempoButtonsSize, _textStyleButtons),
                              //Container(width: tempoButtonsSize/5),
                              _buildOneButton(
                                  "+5", 5, tempoButtonsSize, _textStyleButtons),
                            ]),
                        //Container(width: tempoButtonsSize/3),
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildOneButton("-1", -1, tempoButtonsSize,
                                  _textStyleButtons),
                              _buildOneButton("-5", -5, tempoButtonsSize,
                                  _textStyleButtons),
                            ])
                      ])),
            ],
          ),*/
          Positioned.fromRect(
            //Start-Stop bn
            rect: Rect.fromCenter(
                center: Offset(statrCenterX, statrCenterY),
                width: startDiameter,
                height: startDiameter),
            child: _buildPlayBtn1(startDiameter),
          ),
          Positioned.fromRect(
            //button
            rect: Rect.fromCenter(
                center: Offset(knobCenterX - tempoButtonDeltaX,
                    knobCenterY - tempoButtonDeltaY),
                width: tempoButtonsSize,
                height: tempoButtonsSize),
            child: _buildOneButton(
                "-1", -1, tempoButtonsSize /*, _textStyleButtons*/),
          ),
          Positioned.fromRect(
            //button
            rect: Rect.fromCenter(
                center: Offset(knobCenterX - tempoButtonDeltaX,
                    knobCenterY + tempoButtonDeltaY),
                width: tempoButtonsSize,
                height: tempoButtonsSize),
            child: _buildOneButton(
                "-5", -5, tempoButtonsSize /*, _textStyleButtons*/),
          ),
          Positioned.fromRect(
            //button
            rect: Rect.fromCenter(
                center: Offset(knobCenterX + tempoButtonDeltaX,
                    knobCenterY - tempoButtonDeltaY),
                width: tempoButtonsSize,
                height: tempoButtonsSize),
            child: _buildOneButton(
                "+1", 1, tempoButtonsSize /*, _textStyleButtons*/),
          ),
          Positioned.fromRect(
            //button
            rect: Rect.fromCenter(
                center: Offset(knobCenterX + tempoButtonDeltaX,
                    knobCenterY + tempoButtonDeltaY),
                width: tempoButtonsSize,
                height: tempoButtonsSize),
            child: _buildOneButton(
                "+5", 5, tempoButtonsSize /*, _textStyleButtons*/),
          ),
          Positioned.fromRect(
            ///Help
            //button
            rect: Rect.fromCenter(
                center: Offset(helpCenterX, helpCenterY),
                width: helpDiam,
                height: helpDiam),
            child: _buildHelpBtnU(),
          ),

          /*
          //Очередная неудачная попытка примотать Витину кнопку звука в данном месте
          Positioned.fromRect(
            rect: Rect.fromCenter(
                center: Offset(size.width-rightArea/2,
                    rightArea/2),
                width: rightArea,
                height: rightArea),
            child:
            OverflowBox(
              alignment: Alignment.center,
              minWidth: 50,
              minHeight: 50,
              maxWidth:  rightArea,
              maxHeight: double.infinity,
              child:  //Container(width:rightArea, height:rightArea, color: Colors.green),
               //_buildVolumeBtnU(),
                  //bottom: _showAds ? _heightAds[1] + _paddingBtn.dy : _paddingBtn.dy,
               _buildVolumeBtn(
                      _smallBtnSize, //0.05 * _sizeCtrlsShortest
                      _sizeCtrlsShortest),
            )
          ),
*/

          Align(
            //Служебные кнопки
            alignment: Alignment.topRight,
            child: Container(
              width: rightArea,
              height: size.height * useOfHeight,
              decoration: decorDebug(Colors.blue),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  //mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: rightArea, height: rightArea,
                      child: _buildVolumeBtnU(),
                      //decoration: decorTmp(Colors.green),
                    ),
                    Container(
                      // child: _buildHelpBtnU(),
                      width: rightArea, height: rightArea,
                      //padding: EdgeInsets.only(top: inkWellBetweenPadding),
                      //decoration: decorTmp(Colors.white),
                    ),
                    Container(
                      child: _buildSettingsBtnU(),
                      width: rightArea, height: rightArea,
                      //padding: EdgeInsets.only(bottom: inkWellBetweenPadding),
                      //decoration: decorTmp(Colors.blue),
                    ),
                  ]),
            ),
          ),
          Positioned.fromRect(
            //Knob
            ///Дальнейшее: коробка кноба выравнена по Stack (иначе не получается его нажимать, или же он обсекается)
            rect: Rect.fromCenter(
                center: Offset(knobCenterX, knobCenterY),
                width: knobDiameter,
                height: knobDiameter),
            child: knobInBox(knobDiameter, knobTextStyle),
          ),
          Positioned.fromRect(
            //Большие цифры
            ///Дальнейшее: коробка кноба выравнена по Stack (иначе не получается его нажимать, или же он обсекается)
            rect: Rect.fromCenter(
                center: Offset(
                    knobCenterX,
                    knobCenterY -
                        knobDiameter * _pushDilationFactor / 2 -
                        textOuterSizeY / 2),
                width: textOuterSizeX,
                height: textOuterSizeY),
            child: SizedOverflowBox(
              alignment: Alignment.center,
              size: Size(textOuterSizeX, textOuterSizeY),
              child: _knobValue.pushed
                  ? Container(
                      width: textOuterSizeX,
                      height: textOuterSizeY,
                      decoration: new BoxDecoration(
                        color: Colors.amber[50].withOpacity(0.75),
                        borderRadius: new BorderRadius.all(
                            Radius.elliptical(textOuterSizeX, textOuterSizeY)),
                      ),
                      child: Align(
                        alignment: Alignment.center,
                        child: Text(
                          _knobValue.value.toInt().toString(),
                          style:
                              knobTextStyle.copyWith(fontSize: knobFontSizeBig),
                          textScaleFactor: 1,
                        ),
                      ),
                    )
                  : Container(),
            ),
          ),

          /*
        Positioned.fill(
          ///Дальнейшее: коробка кноба выравняна по Stack (иначе не получается его нажимать, или же он обсецается)
          ///Сам он в центре относительно неё.
          ///Теперь мы её двигаем (законно ли это - непонятно...)
          //left: -100,
          //top: size.height/2,
          //top: -(size.height - knobDiameter) / 2,

          ///Выравнивае по верху
          //child: Container(color:Colors.green, width:50, height:50,),
          child: knobInBox(knobDiameter),
          /*
            child: Container(
              width: size.width * 2 / 3,
              height: size.height,
              child: knobInBox(knobDiameter),
            ),
             */
        ),

         */
        ],
      ),
    );
  }

  Widget knobInBox(double knobDiameter, TextStyle knobTextStyle) {
    _knobValue.value = _tempoBpm.toDouble();
    //final double fontSize = !_knobValue.pushed? basicFontSize: basicFontSize*_pushFactor;
    return OverflowBox(
      alignment: Alignment.center,
      minWidth: knobDiameter,
      minHeight: knobDiameter,
      maxWidth: knobDiameter * _pushDilationFactor, //double.infinity,
      maxHeight: knobDiameter * _pushDilationFactor, //double.infinity,
      //child:Container(width: size.height/2 , height: size.height*2,decoration: decorTmp(Colors.yellow),),
      child: KnobTuned(
        pushFactor: _pushDilationFactor,
        knobValue: _knobValue,
        minValue: minTempo.toDouble(),
        maxValue: _tempoBpmMax.toDouble(),
        sensitivity: _sensitivity,
        diameter: knobDiameter,
        innerRadius: _innerRadius,
        outerRadius: _outerRadius,
        textStyle: knobTextStyle,
        timeToDilation:
            _timeToDilation, //TODO: UNTESTED//Сделано предварительно
        showText: true,
        onChanged: (KnobValue newVal) {
          _knobValue = newVal;
          _setTempo(newVal.value.round());
          //_tempoBpm = newVal.value.round();
          //if (_playing)
          //_setTempo(_tempoBpm);
          setState(() {}); //ToDo: ???? DC
        },
      ),
    );
  }

  Widget signatureRaw(TextStyle textStyle, double totalWidht) {
    final int leftFlex = 7;
    final int meterWheelsFlex = 12;
    final int meterFlex = 25;
    final int rightFlex = 12;
    final int total = leftFlex + meterWheelsFlex + meterFlex + rightFlex;
    double globalYPadding = totalWidht * 0.005;
    double localXPadding = totalWidht * 0.01;
    double meterYPaddyng = totalWidht * 0.007;
    return Container(
        padding: EdgeInsets.symmetric(vertical: globalYPadding),
        // decoration: decorTmp(Colors.blue),
        child: Row(children: [
          Expanded(
            //Звуковая схема
            flex: leftFlex,
            child: Container(
              padding: EdgeInsets.only(right: localXPadding),
              decoration: decorDebug(Colors.blue),
              child: wSchemeBn(
                  textStyle, totalWidht /*totalWidht*leftFlex/total*/),
            ),
          ),
          Expanded(
            //Колонка колёс метра
            flex: meterWheelsFlex,
            child: Container(child: wMetreWheels()),
          ),
          Expanded(
            //Строка акцентов
            flex: meterFlex,
            child: Container(
              padding: EdgeInsets.only(
                  right: localXPadding,
                  left: localXPadding,
                  top: meterYPaddyng,
                  bottom: meterYPaddyng),
              decoration: decorDebug(Colors.yellow),
              child: wMetreBar(),
            ),
          ),
          //Spacer(flex:1),
          Expanded(
            //Колонка справа (ритмы и регулятор-сова)
            flex: rightFlex,
            child: Container(
              child: Column(
                //crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    //ритмы
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                        //image: AssetImage('images/but-rhythms.png'),
                        //ToDo: Юрик,
                        //одень это по-человечески (это прыг на стандартный размер)
                        image: AssetImage('images/but123short.png'),
                        //image: AssetImage('images/but-note-1.png'),
                        //image: AssetImage('images/ictempo.png'),
                        fit: BoxFit.fill,
                      )),
                      //decoration: decorTmp(Colors.green),
                      child: wJumpToNextStandardBeat(), // rhythmPicker(),
                    ),
                  ),
                  /*Expanded(
                    //спайс
                    flex: 1,
                    child: Container(
                      decoration: decorDebug(Colors.green),
                    ),
                  ),
                  Expanded(
                    //сова-регулятор поддолей
                    //Звуковая схема
                    flex: 7,
                    child: Container(
                      decoration: BoxDecoration(
                          image: DecorationImage(
                        image: AssetImage('images/but123short.png'),
                        //image: AssetImage('images/but-note-1.png'),
                        //image: AssetImage('images/ictempo.png'),
                        fit: BoxFit.fill,
                      )),
                      //decoration: decorTmp(Colors.green),
                      child: btnSubBeatU(),
                    ),
                  ),
                  */
                ],
              ),
            ),
          ),
        ]));
  }

  ///Прыгаем к следующему стандартному размеру.
  Widget wJumpToNextStandardBeat() {
    int nextBeat() {
      int lng = Prosody.standardBeatNth.length;
      int indToJump = 0; //Ищем следующий размер
      if ((Prosody.standardBeatNth[0] <= _beat.beatCount) &&
          (_beat.beatCount < Prosody.standardBeatNth[lng - 1])) {
        do {
          indToJump++;
        } while (Prosody.standardBeatNth[indToJump] <= _beat.beatCount);
      } // не изящно получилось
      return Prosody.standardBeatNth[indToJump];
    }

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        Size size = Size(constraints.maxWidth, constraints.maxHeight);
        TextStyle textStyle = GoogleFonts.roboto(
            fontSize: size.width * 0.2, fontWeight: FontWeight.bold);

        //onChanged: onSubbeatChanged,

        return Container(
          child: GestureDetector(
            onTap: () {
              _onUltimateJump(nextBeat());
            },
            child: Align(
              alignment: Alignment.center,
              child: Text(
                'Go to\n ${nextBeat()}/${_noteValue}',
                style: textStyle,
                maxLines: 2,
                textScaleFactor: 1,
              ),
            ),
          ),
        );
      },
    );
  }

  /*
  ///Выбора списков в данном метре. Мозголомство для юзера. Запрятано. (Недосогласовано (кажется) со строкой акцентов)
  Widget rhythmPicker() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      Size size = Size(constraints.maxWidth, constraints.maxHeight);

      return rhythmPickerInside(size);
    });
  }

  Widget rhythmPickerInside(Size size) {
    TextStyle textStyle = GoogleFonts.roboto(
      fontSize: size.width / 7,
      color: Colors.black,
      fontStyle: FontStyle.italic,
    );

    List<Rhythm> rhythms =
        List<Rhythm>.from(_allPredefinedRhythms[_beat.beatCount - 1]);
    UserRhythm userRhythm = userRhythms[_beat.beatCount - 1];
    if (userRhythm.bDefined) {
      rhythms.add(userRhythm);
    }

    final List<PopupMenuItem<int>> items = [];
    for (int i = 0; i < rhythms.length; i++) {
      String name = !rhythms[i].bStandard
          ? rhythms[i].name
          : _beat.beatCount.toString() + "/" + _noteValue.toString();

      items.add(
        PopupMenuItem(
          value: i,
          child: Text(name, textScaleFactor: 1, style: textStyle),
        ),
      );
    }

    return PopupMenuButton<int>(
      //ToDo: мерзейший клик
      onSelected: (value) {
        //TODO: jumpToNextStandard
        /*//Если выбран пользовательский ритм, то запасаем, какой был последний
        // - Не, путано.
        if ((userRhythm.bDefined)&&(value==rhythms.length-1)){
          lastEdited=value;
        }
        */
      },
      child: Container(
        width: size.width,
        height: size.height,
        child: Align(
          alignment: Alignment.center,
          child: Text(
            "more in " + _beat.beatCount.toString(),
            style: textStyle,
            textScaleFactor: 1,
          ),
        ),
      ),
      itemBuilder: (context) => items,
    );
  }
  */

  Widget btnSubBeatU() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      Size size = Size(constraints.maxWidth, constraints.maxHeight);

      /*
      TextStyle textStyle =
          Theme.of(context) //ISH: Не знаю, зачем это. Следую Витиной практике
              .textTheme
              .headline4;*/

      TextStyle textStyle = GoogleFonts.roboto();

      //onChanged: onSubbeatChanged,

      return Container(
        child: SubbeatEqWidget(
          subbeatCount: _beat.subBeatCount,
          subbeatCountMax: 4,
          noteValue: _noteValue,
          noteColor: Colors.black,
          textStyle: textStyle,
          size: size,
          allEqual: _beat.subBeatsEqualAndExist(),
          onChanged: onAllSubbeatsChanged,
        ),
      );
    });
  }

  ///+- tempo buttons
  Widget _buildOneButton(
      String text, int delta, double sqsize /*, TextStyle textStyle*/) {
    final String s1 = (delta > 0) ? 'plus' : 'minus';
    final String s2 = (delta.abs() > 1) ? '5' : '1';
    final Widget icon = new Image.asset(
      //"images/butowl4.png",
      //"images/button.png",
      //'images/button12.png',
      'images/' + s1 + s2 + '.png',
      width: sqsize,
      height: sqsize,
      fit: BoxFit.contain,
    );

    return InkWell(
      child: Stack(
          alignment: Alignment.center, //ToDo:без текста теперь Stack не нужен?
          children: [
            icon,
            /*Text(
          text,
          textScaleFactor: 1,
          style: textStyle,
        ),*/
          ]),
      enableFeedback: false, //!_playing,
      onTap: () {
        int newTempo = _tempoBpm + delta;

        ///ToDo: Untested
        if (newTempo < minTempo) newTempo = minTempo;
        if (newTempo > _tempoBpmMax) newTempo = _tempoBpmMax;

        ///ToDo:
        ///- нажатие на кнопку должны останавливать вращение "grave ..."; аналогично -
        ///нужно проверить остальные сочетания.
        ///- нужно проверить билды у кноба и остальных темпо-виджетов
        ///- setState в них и в setTempo кажутся излишними
        _knobValue.absoluteAngle +=
            (newTempo - _tempoBpm) * _sensitivity / sensitivityToAngle;

        _setTempo(newTempo);

        ///ToDo: DC
        /*
        if (_playing)
          _setTempo(
              _tempoBpm);  */
        setState(() {});
      },
    );
  }

  ///
  /// Масштабируемый виджет "Нота = темп";   убрана проблема с налезанием хвоста на равенство
  ///
  /// Выравнивается слева. Всё отрисованное (общая ширина, размер шрифта)  зависит от высоты  отведенной  области.
  /// В частности, размер шрифта зависит от высоты.
  ///
  /// Чтобы этот виджет отцентрировать (если вдруг захотим), нужно будет померять реальное отношение отрисованного к высоте
  /// (но длина текста может меняться в зависимости от значения темпа, так что надо аккуратно)
  Widget noteAndTempo(TextStyle textStyle) {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final double noteH = constraints.maxHeight;
      final Size noteSize = Size(noteH * 0.3, noteH);
      final Color col = Colors.white;

      //Отрисовка ноты отпределяется её высотой, привязываемся к ней
      return Align(
          //Чтобы можно было сделать меньше, чем доступная область, заворачиваем в Align (см. документацию)
          child: Row(
        //mainAxisAlignment: MainAxisAlignment.
        //crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(width: noteSize.width * 0.5),
          Container(
              height: noteSize.height,
              width: noteSize.width,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: noteSize.height * 0.08),
                child: NoteWidget(
                  subDiv: 1,
                  denominator: _noteValue,
                  active: -1,
                  accents: [],
                  showAccent: false,
                  showTuplet: false,
                  coverWidth: true,
                  colorPast: col,
                  colorNow: col,
                  colorFuture: col,
                  colorInner: col,
                ),
              )),
          Container(
              //Размер хвостика нотки не должен цеплять равенство
              //ToDo: а пробел поставить в след. виджете? - не выходит
              width: noteSize.width * 1.2),
          Align(
              alignment: Alignment.center,
              child: Text(
                "= " + _tempoBpm.toString(),
                style: textStyle.copyWith(
                    /*fontWeight: FontWeight.w800,*/ color: col),
                textScaleFactor: 1,
              )),
          //Размер хвостика нотки не должен цеплять равенство
        ],
      ));
    });
  }

  Widget _buildPlayBtn1(double diameter) {
    return InkWell(
      //ISH: I do not use  material button here
      //(it has some pudding requirements that I do not need)
      child: Image.asset(_playing ? 'images/icstop.png' : 'images/icplay.png',
          height: diameter, fit: BoxFit.contain),
      enableFeedback: false,
      onTap: _play,
    );
  }

  Widget tempoRow(TextStyle _textStyleTempoRow) {
    return Container(
      //decoration: decorTmp(Colors.yellow),
      child: Row(
        children: [
          Expanded(
            flex: 7,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('images/noteravno1.png'),
                fit: BoxFit.fill,
              )),
            ),
          ),
          Expanded(
            flex: 12,
            child: Container(
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('images/noteravno.png'),
                fit: BoxFit.fill,
              )),
              child: noteAndTempo(_textStyleTempoRow),
            ),
          ),
          Expanded(
              flex: 37,
              child: Container(
                decoration: BoxDecoration(
                    image: DecorationImage(
                  //image: AssetImage('images/but-note-1.png'),
                  //image: AssetImage('images/ictempo.png'),
                  //image: AssetImage('images/wh1.jpg'),
                  image: AssetImage('images/wh22.png'),
                  fit: BoxFit.fill,
                )),
                //decoration: decorTmp(Colors.green),
                child: _tempoListFinallyGotLaid(_textStyleTempoRow, 0.705),
              ))
        ],
      ),
    );
  }

  ///Звуковая схема
  Widget wSchemeBn(TextStyle textStyle, /*double totalWidth,*/ listWidth) {
    ///Полный бардак с listWidth и вокруг. Сделано на ходу. //ToDo
    final double shrinkForList = 0.9;
    final TextStyle listTextStyle =
        textStyle.copyWith(fontSize: textStyle.fontSize * shrinkForList);
    final TextStyle listTextStyleBold =
        listTextStyle.copyWith(fontWeight: FontWeight.bold);



    Stack stackedIcon(int soundScheme) {
      final int imageIndex = soundScheme < 4 ? soundScheme : 4;
      final String schemeName = 'images/ic' + imageIndex.toString() + '.png';
      final String strScheme = (soundScheme + 1).toString();
      final     Widget icon =Image.asset(
        schemeName,
        //width: sizeButton,
        // height: sizeButton,
        fit: BoxFit.contain,
      );
      return Stack(alignment: Alignment.center, children: [
        //decoration: decorTmp(Colors.green),
        icon,
        imageIndex == 4
            ? Text(
          strScheme,
          /*
              style: Theme.of(context).textTheme.headline5.copyWith(
                  fontSize: 0.4 * totalWidth,
                  fontWeight: FontWeight.bold,
                  color: Colors.black),*/
          style: textStyle,
          textScaleFactor: 1,
        )
            : Container(),
      ]);
    }


    //Базовый рабочий вариант для диалога. Однако он позволяет выбраь item лишь один раз и закрыть диалоговое окно -
    //само диалоговое окно не обновляется.
    //Чтобы диалог обновлялся сам при выборе нового item, необходимо оформить виджеты-элементы как класс и
    //завернуть выбор в  StatefulBuilder.
    List<Widget> musicList = [];
    for (int j = 0; j < _soundSchemes.length; j++) {
      int i = j %
          _soundSchemes.length; //Отладочное, чтобы проверить на многих списках
      if (i==6) //TODO : заплатка в спешке
        musicList.add(Padding(
        padding: EdgeInsets.only(
          //    vertical: totalWidth * shrinkForList * 0.1
            top: listWidth * 0.03,
          bottom: listWidth * 0.01,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            "Experimental:",
            style: textStyle.copyWith(
                fontSize: textStyle.fontSize * 1.1),
          ),
        ),
      ),);

      musicList.add(
        Container(
          //decoration: decorTmp(Colors.yellow),
          padding: EdgeInsets.symmetric(
              vertical: listWidth * shrinkForList / 100,
              horizontal: listWidth * (1 - shrinkForList) / 4),
          child: GestureDetector(
            onTap: () {
              _activeSoundScheme = i;
              _channel.setSoundScheme(_activeSoundScheme).then((int result) {
                setState(() {}); //ToDo: Why? Double Check
                Navigator.of(context).pop();
              });
            },
            child: Container(
              width: shrinkForList * listWidth,
              height: shrinkForList * listWidth / 7,
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('images/but123short.png'),
                //ToDo: Юрик, кажется but123short тут смотрится сморчково. Или строчково. Ты посмотри.
                //image: AssetImage('images/but-note-1.png'),
                //image: AssetImage('images/ictempo.png'),
                fit: BoxFit.fill,
              )),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  children: <Widget>[
                    stackedIcon(i),
                    Text(
                      _soundSchemes[i],
                      style: (i == _activeSoundScheme)
                          ? listTextStyleBold
                          : listTextStyle,
                      textScaleFactor: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    final Scrollbar listInScroll = Scrollbar(
      child: ListView(
        children: musicList,
      ),
    );




    return Container(
      //width: totalWidth,
      //decoration: decorTmp(Colors.yellow),
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage('images/but1452long.png'),
        fit: BoxFit.fill,
      )),
      child: RawMaterialButton(
        enableFeedback: false, //!_playing,
        onPressed: () {
          //По тапу вытаскиваем список для выбора схемы
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.amber[50],
                  elevation: 10.3,
                  child: Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                      image: AssetImage('images/back-v4.jpg'),
                      //ToDo Юрик, тут подложка для списка муз. схем
                      fit: BoxFit.cover,
                    )),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              //    vertical: totalWidth * shrinkForList * 0.1
                              vertical: listWidth * 0.1),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              "Pairs of sounds:",
                              style: textStyle.copyWith(
                                  fontSize: textStyle.fontSize * 1.3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: listInScroll,
                          /*child: Scrollbar(
                            child: ListView(
                              children: musicList,
                            ),
                          ),*/
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
        child: Align(
          //То, что рисуется в строке
          alignment: Alignment.center,
          child:  stackedIcon(_activeSoundScheme),
        ),
      ),
    );
  }

  Widget _rowControlsArea(bool portrait, Size size) {
    double fontSizeTempo = size.width *
        0.3 /
        6; //ToDo: to make the widget more flexible,  the constant should be one of c_i-s constatns
    double fontSizeMusicScheme = fontSizeTempo * 1.5;

    TextStyle _textStyleTempoRow = GoogleFonts.roboto(fontSize: fontSizeTempo);

    TextStyle _textStyleSchemeRow =
        GoogleFonts.roboto(fontSize: fontSizeMusicScheme * 0.68);

    ///Паддинг большой плашки контролов относительно краев экраан

    ///Параметры модели figma - вся ширина экрана и ширина плашки
    final double modelWidth = 640;
    final double plashkaWidth = 617;

    ///ToDo: Юра

    final double leftRightPadding =
        size.width * (modelWidth - plashkaWidth) / modelWidth / 2;

    ///Shadow плашки. //ToDo: Юра.
    ///
    /// Параметры модели:
    /// box-shadow: 8px 8px 32px rgba(0, 0, 0, 0.75);
    ///
    double shrinkShad = size.width / modelWidth;
    final Color shadCol = Color.fromRGBO(0, 0, 0, 0.75);
    final double shadX = 8 * shrinkShad;
    final double shadY =
        8 * shrinkShad; //не совсем корректно относительно тени по y?
    final double shadRad = 32 * shrinkShad;

    return Container(
      width: size.width,
      height: size.height,
      padding: EdgeInsets.symmetric(horizontal: leftRightPadding),
      child: Container(
        decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: shadCol,
                offset: Offset(shadX, shadY),
                //spreadRadius: ??
                blurRadius: shadRad,
              ),
            ],
            image: DecorationImage(
              image: AssetImage('images/bigplashka.png'),
              //image: AssetImage('images/but-note-1.png'),
              //image: AssetImage('images/ictempo.png'),
              fit: BoxFit.fill,
            )),
        child: Column(
          //mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Flexible(
              flex: 10,
              fit: FlexFit.tight,
              child: tempoRow(_textStyleTempoRow),
            ),
            Flexible(
              flex: 20,
              fit: FlexFit.tight,
              child: signatureRaw(_textStyleSchemeRow, size.width),
            ),
            Flexible(
              flex: 7,
              fit: FlexFit.tight,
              child: musicSchemeRaw(_textStyleSchemeRow, size.width),
            ),
            //auxRaw//ToDo: добавим в конец схем
          ],
        ),
      ),
    );
  }

  Widget musicSchemeRaw(TextStyle textStyle, double totalWidth) {
    final int left = 14;
    final int padding = 1;
    final int right = 100;
    //final int total = left + padding + right;
    final int total = right;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        /*Expanded(
          flex: left,
          child: musicSchemeListW(
              textStyle, totalWidth * left / total, 0.85 * totalWidth),
        ),
        Expanded(
          flex: padding,
          child: Container(
            decoration: decorDebug(Colors.green),
          ),
        ),*/
        Expanded(
          flex: right,
          child: rhythmNameW(textStyle, totalWidth * right / total),
        ),
      ],
    );
  }

  ///
  /// Рисует тапабельную строку с ритмом.
  ///
  Widget rhythmNameW(TextStyle textStyle, double totalWidth) {
    //double inkWellBetweenPadding = totalWidth * 0.01;

    double shrinkForList = 0.9;
    TextStyle listTextStyle = textStyle.copyWith(
        fontSize: textStyle.fontSize * shrinkForList * 0.9 /*ToDo*/);
    TextStyle listTextStyleBold =
        listTextStyle.copyWith(fontWeight: FontWeight.bold);

    Widget itemOfList(Rhythm rhythm, int beatIndex, int position) {
      return Container(
        padding: EdgeInsets.symmetric(
            vertical: totalWidth * shrinkForList / 150,
            horizontal: totalWidth * (1 - shrinkForList) / 3),
        child: GestureDetector(
          onTap: () {
            onRhythmSelectedFromList(beatIndex, position, (position < 0));
            /*//ToDo: experiment
            if (rhythm.bSubBeatDependent)
              onEverythingChanged(rhythm);
            else
              onEverythingChanged(Rhythm(
                  name: rhythm.name,
                  subBeats:  _beat.subBeats,
                  accents: rhythm.accents)
              );*/
            setState(() {}); //ToDo: Why?
            Navigator.of(context).pop();
          },
          child: Container(
            width: shrinkForList * totalWidth,
            height: shrinkForList * totalWidth / 8,
            decoration: BoxDecoration(
                image: DecorationImage(
              image: AssetImage('images/but1452long.png'),
              fit: BoxFit.fill,
            )),
            child: Align(
              alignment: Alignment.center,
              child: Text(
                rhythm.name,
                style: listTextStyle,
                /*
                style: //ToDo
                    ? listTextStyleBold
                    : listTextStyle, */
                textScaleFactor: 1,
              ),
            ),
          ),
        ),
      );
    }

    List<Widget> rhythmListW = [];

    for (int j = 0; j < maxBeatCount; j++) {
      rhythmListW.add(
        Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            'In ${j + 1} beat' + ((j == 0) ? '' : 's') + ':',
            style: textStyle,
          ),
        ),
      );
      for (int i = 0; i < _allPredefinedRhythms[j].length; i++) {
        rhythmListW.add(itemOfList(_allPredefinedRhythms[j][i], j, i));
      }
      UserRhythm userRhythm = userRhythms[j];
      if (userRhythm.bDefined) {
        rhythmListW.add(itemOfList(userRhythm, j, -1));
      }
      if (j < maxBeatCount - 1)
        rhythmListW.add(
          Padding(
              padding: EdgeInsets.symmetric(
            vertical: totalWidth * shrinkForList / 50,
          )),
        );
    }

    final Scrollbar listInScroll = Scrollbar(
      child: ListView(
        children: rhythmListW,
      ),
    );

    return Container(
      width: totalWidth,
      //decoration: decorTmp(Colors.yellow),
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage('images/but1452long.png'),
        //image: AssetImage('images/but-note-1.png'),
        //image: AssetImage('images/ictempo.png'),
        fit: BoxFit.fill,
      )),
      child: RawMaterialButton(
        enableFeedback: false, //!_playing,
        onPressed: () {
          //По тапу вытаскиваем список для выбора схемы
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.amber[50],
                  elevation: 10.3,
                  child: Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                      image: AssetImage(
                          'images/back-v4.jpg'), //ToDo Юрик, тут подложка для списка ритмов
                      fit: BoxFit.cover,
                    )),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: totalWidth * shrinkForList / 25),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              "Rhythms",
                              style: textStyle.copyWith(
                                  fontSize: textStyle.fontSize * 1.1),
                            ),
                          ),
                        ),
                        Expanded(
                          child: listInScroll,
                          /*child: Scrollbar(
                            child: ListView(
                              children: musicList,
                            ),
                          ),*/
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
        child: Align(
          //То, что рисуется в строке
          alignment: Alignment.center,
          child: Text(
            _rhythmsToScroll[_scrollBarPosition].name,
            //_beat.name,
            style: textStyle,
            textScaleFactor: 1,
          ),
        ),
      ),
    );
  }

  ///
  /// Рисует тапабельную строку с музыкальной схемой. По тапу выдаётся диалог
  ///
  Widget musicSchemeListW(TextStyle textStyle, double totalWidth, listWidth) {
    //double inkWellBetweenPadding = totalWidth * 0.01;

    double shrinkForList = 0.9;
    TextStyle listTextStyle =
        textStyle.copyWith(fontSize: textStyle.fontSize * shrinkForList);
    TextStyle listTextStyleBold =
        listTextStyle.copyWith(fontWeight: FontWeight.bold);

    //Базовый рабочий вариант для диалога. Однако он позволяет выбраь item лишь один раз и закрыть диалоговое окно -
    //само диалоговое окно не обновляется.
    //Чтобы диалог обновлялся сам при выборе нового item, необходимо оформить виджеты-элементы как класс и
    //завернуть выбор в  StatefulBuilder.
    List<Widget> musicList = [];
    for (int j = 0; j < _soundSchemes.length; j++) {
      int i = j %
          _soundSchemes.length; //Отладочное, чтобы проверить на многих списках
      musicList.add(
        Container(
          //decoration: decorTmp(Colors.yellow),
          padding: EdgeInsets.symmetric(
              vertical: listWidth * shrinkForList / 100,
              horizontal: listWidth * (1 - shrinkForList) / 4),
          child: GestureDetector(
            onTap: () {
              _activeSoundScheme = i;
              _channel.setSoundScheme(_activeSoundScheme).then((int result) {
                setState(() {}); //ToDo: Why? Double Check
                Navigator.of(context).pop();
              });
            },
            child: Container(
              width: shrinkForList * listWidth,
              height: shrinkForList * listWidth / 7,
              decoration: BoxDecoration(
                  image: DecorationImage(
                image: AssetImage('images/but1452long.png'),
                //image: AssetImage('images/but-note-1.png'),
                //image: AssetImage('images/ictempo.png'),
                fit: BoxFit.fill,
              )),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  _soundSchemes[i],
                  style: (i == _activeSoundScheme)
                      ? listTextStyleBold
                      : listTextStyle,
                  textScaleFactor: 1,
                ),
              ),
            ),
          ),
        ),
      );
    }

    final Scrollbar listInScroll = Scrollbar(
      child: ListView(
        children: musicList,
      ),
    );

    //ToDo: Jump to item

    return Container(
      width: totalWidth,
      //decoration: decorTmp(Colors.yellow),
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage('images/but1452long.png'),
        fit: BoxFit.fill,
      )),
      child: RawMaterialButton(
        enableFeedback: false, //!_playing,
        onPressed: () {
          //По тапу вытаскиваем список для выбора схемы
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return Dialog(
                  backgroundColor: Colors.amber[50],
                  elevation: 10.3,
                  child: Container(
                    decoration: BoxDecoration(
                        image: DecorationImage(
                      image: AssetImage(
                          'images/back-v4.jpg'), //ToDo Юрик, тут подложка для списка муз. схем
                      fit: BoxFit.cover,
                    )),
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: totalWidth * shrinkForList * 0.1),
                          child: Align(
                            alignment: Alignment.bottomCenter,
                            child: Text(
                              "Pairs of sounds:",
                              style: textStyle.copyWith(
                                  fontSize: textStyle.fontSize * 1.3),
                            ),
                          ),
                        ),
                        Expanded(
                          child: listInScroll,
                          /*child: Scrollbar(
                            child: ListView(
                              children: musicList,
                            ),
                          ),*/
                        ),
                      ],
                    ),
                  ),
                );
              });
        },
        child: Align(
          //То, что рисуется в строке
          alignment: Alignment.center,
          child: Text(
            "...",
            /*_soundSchemes != null && _activeSoundScheme < _soundSchemes.length
                ? _soundSchemes[_activeSoundScheme]
                : "[no sound sheme loaded]",*/
            style: textStyle,
            textScaleFactor: 1,
          ),
        ),
      ),
    );

    /*//Список, котороый позволяет менять схему не останавливаясь и не закрываясь.
    // Для этого он должен обновляться на ходу
    //В том, что ниже,  что-то не верно с обновлением состояния...
    return Container(
      width: totalWidth,
      //decoration: decorTmp(Colors.yellow),
      decoration: BoxDecoration(
          image: DecorationImage(
        image: AssetImage('images/ic3.png'),
        //image: AssetImage('images/but-note-1.png'),
        //image: AssetImage('images/ictempo.png'),
        fit: BoxFit.fill,
      )),
      child: RawMaterialButton(
        enableFeedback: !_playing,
        onPressed: () { //По тапу вытаскиваем список для выбора схемы
          showDialog(
              context: context,
              builder: (BuildContext context) {
                return StatefulBuilder(builder: (context, setState) { //Эта приблуда нужна, чтобы список обновлялся
                  List<Widget> musicList = [];
                  for (int i = 0; i < _soundSchemes.length; i++) {
                    musicList.add(
                      Container(
                        //decoration: decorTmp(Colors.yellow),
                        padding: EdgeInsets.symmetric(
                            vertical: totalWidth * shrinkForList / 50,
                            horizontal: totalWidth * (1 - shrinkForList) / 4),
                        child: GestureDetector(
                          onTap: () {
                            _activeSoundScheme = i;
                            setState(() {});
                            _channel
                                .setSoundScheme(_activeSoundScheme)
                                .then((int result) {
                               //ToDo: Why?
                              //Navigator.of(context).pop();
                            });
                            if (!_playing) Navigator.of(context).pop();
                          },
                          child: Container(
                            width: shrinkForList * totalWidth,
                            decoration: BoxDecoration(
                                image: DecorationImage(
                              image: AssetImage('images/ic3.png'),
                              //image: AssetImage('images/but-note-1.png'),
                              //image: AssetImage('images/ictempo.png'),
                              fit: BoxFit.fill,
                            )),
                            child: Align(
                              alignment: Alignment.center,
                              child: Text(
                                _soundSchemes[i],
                                style: (i == _activeSoundScheme)
                                    ? listTextStyleBold
                                    : listTextStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }
                  return SimpleDialog(
                    backgroundColor: Colors.amber[50],
                    elevation: 10.3,
                    // title: const Text("Instruments"),
                    children:
                        musicList, //Чтобы обновить состояние, нужно переделать musicList
                    //через класс, или же впихивать его прямо сюда.
                    //см https://stackoverflow.com/questions/51962272/how-to-refresh-an-alertdialog-in-flutter
                    //Пока впихнул сюда.
                  );
                });
              });
        },
        child: Align( //То, что рисуется в строке
          alignment: Alignment.center,
          child: Text(
            _soundSchemes != null && _activeSoundScheme < _soundSchemes.length
                ? _soundSchemes[_activeSoundScheme]
                : "[no sound sheme loaded]",
            style: textStyle,
          ),
        ),
      ),
    );
     */
  }

  ///Витины колёса метра, завернутые во внешний размер
  Widget wMetreWheels() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      Size meterSize = Size(constraints.maxWidth, constraints.maxHeight);
      double itemExtent = 0.5 * meterSize.width; //44,
      final bool updateMetre = _updateMetreWheels; //ISH: не уверен, что это
      _updateMetreWheels = false;

      double meterTextSize = meterSize.height / 2.6;
      TextStyle meterTextStyle = GoogleFonts.roboto(
        fontSize: meterTextSize,
        fontWeight: FontWeight.w800,
      );
      return //Container();
          TwoWheels(
        //MetreWidget(
        update: updateMetre, //ToDo: А в других вроде не нужно такой штуки....
        beats:
            _beat.beatCount, //А, разобрался. Надо было всегда перерисовывать,
        //когда значение меняется. Не нужно никаких update, кажется
        minBeats: minBeatCount,
        maxBeats: maxBeatCount,
        note: _noteValue,
        minNote: minNoteValue,
        maxNote: maxNoteValue,
        width: meterSize.width,
        height: meterSize.height,
        //itemExtent: itemExtent,
        color: Colors.deepPurple,
        textStyle: meterTextStyle,
        //textStyleSelected: meterTextStyle,
        onBeatChanged: _onBeatChanged,
        onNoteChanged: _onNoteChanged,
      );
    });
  }

  Widget rhythmDrawW(Size size, BeatMetre beatMetre, int noteValue) {
    //final MetreBar metreBar = widget.metres[widget.activeMetre];
    final int beats = beatMetre.beatCount;
    // Simple metre array
    final List<int> subMetres = Prosody.groupNotes(beatMetre.accents);
    //Prosody.getSimpleMetres(beats, false);
    final List<int> accents = beatMetre.accents;

    final List<Widget> notes = new List<Widget>();

    final Size bracketSize = new Size(3.0 * size.width / 30, size.height);

    notes.add(new BarBracketWidget(
        direction: BarBracketDirection.left,
        color: Colors.black,
        size: bracketSize));

    int j = 0; // Simple metre 1st note index
    for (int i = 0; i < subMetres.length; i++) {
      // Build note with subbeats
      final List<int> accents1 = accents.sublist(j, j + subMetres[i]);
      j += subMetres[i];

      //TODO Width
      double width =
          (size.width - 3 * bracketSize.width) * subMetres[i] / beats;
      //width = (widget.size.width) * metres[i] / beats;

      //print('metreBuilder:width $width');
      //print('widget.accents $index - $i - ${metres[i]} - ${metreBar.note}');
      //print(accents1);

      final Widget wix = new NoteWidget(
        subDiv: subMetres[i],
        denominator: noteValue,
        active: -2,
        colorPast: Colors.black, //ToDo
        colorNow: Colors.black,
        colorFuture: Colors.black,
        colorInner: Colors.black,
        accents: accents1,
        maxAccentCount: 3,
        coverWidth: beats > 5, // true,
        showTuplet: false,
        showAccent: true,
        size: new Size(width, size.height),
      );
      notes.add(wix);
    }

    // Add right bracket
    notes.add(new BarBracketWidget(
        direction: BarBracketDirection.right,
        color: Colors.black,
        size: bracketSize));
    return new Container(
      //color: Colors.blue,
      width: size.width,
      height: size.height,
      alignment: Alignment.center,
      child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, children: notes),
    );
  }

  final FixedExtentScrollController _scrollBarController =
      FixedExtentScrollController(initialItem: _initScrollBarPosition);

  Widget wMetreBar() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      Size metreBarSize = Size(constraints.maxWidth, constraints.maxHeight);
      return AccentBarWidget(
        rhythms: _rhythmsToScroll,
        size: metreBarSize,
        position: _scrollBarPosition,
        onChanged: _onScrollRhythms,
        noteValue: _noteValue,
        bReactOnTap: true,
        //Тап перестаёт иногда работать. Мой косяк? Или же
        // https://github.com/flutter/flutter/issues/38803//ToDo
        maxAccent: _beat.maxAccent,
        scrollController: _scrollBarController,
      );
    });
  }

  ///widget Settings
  Widget _buildHelpBtnU() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double size = constraints.maxHeight < constraints.maxWidth
          ? constraints.maxHeight
          : constraints.maxWidth;
      return InkWell(
        //child: Icon(Icons.help_outline, size: size),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.asset(
              "images/round-btn.png",
              width: size,
              height: size,
              fit: BoxFit.contain,
            ),
            Text(
              '?',
              textScaleFactor: 1,
              style: GoogleFonts.roboto(
                  fontSize: 0.6 * size,
                  color: Colors.black,
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
        enableFeedback: false, //!_playing,
        onTap: () {
          _showHelp(context);
        },
      );
    });
  }

  ///widget Settings
  Widget _buildSettingsBtnU() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double size = constraints.maxHeight < constraints.maxWidth
          ? constraints.maxHeight
          : constraints.maxWidth;
      return new InkWell(
        child: Icon(Icons.settings, size: size),
        //tooltip: _soundSchemes[_activeSoundScheme],
        enableFeedback: false, // !_playing,
        onTap: () {
          _showSettings(context);
        },
      );
    });
  }

  Widget _buildVolumeBtnU() {
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      double diam = constraints.maxHeight < constraints.maxWidth
          ? constraints.maxHeight
          : constraints.maxWidth;

      return RawMaterialButton(
        enableFeedback: false,
        onPressed: () {
          _setVolume(_mute ? 100 : 0);
        },
        child: _mute
            ? Icon(Icons.volume_off, size: diam)
            : Icon(Icons.volume_up, size: diam),
        //tooltip: _soundSchemes[_activeSoundScheme],
      );
    });
  }

  ///widget Square section with metronome itself. ToDo
  Widget _AreaOfOwls(bool portrait, Size size) {
    //return BorderedContainer(size);

    if (!_skin.isInit || size.isEmpty)
      return Container(
        width: size.width,
        height: size.height,
      );

    //TODO MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    print('_buildOwlenome $size');

    final double paddingX = _beat.beatCount == 3 || _beat.beatCount == 4
        ? 0 //ToDo
        : 0;
    final double paddingY = _beat.beatCount > 4 ? 0 : 0;
    final Offset spacing = new Offset(0, 0);

    final Widget wixOwls = new OwlGridRot(
      playing: _playing,
      beat: _beat,
      activeBeat: -1, //state.activeBeat,
      activeSubbeat: -1, //state.activeSubbeat,
      noteValue: _noteValue,
      accents: _beat.accents,
      maxAccent: _beat.maxAccent,
      //spacing: spacing,
      //padding: padding,
      padding: // EdgeInsets.symmetric(horizontal: size.width*0.15),
          EdgeInsets.only(
              bottom: size.height * 0.10, top: size.height * 0.005), //ToDo:
      //Совы разложено учень неэкономно. Нужно править.
      //EdgeInsets.zero, //ToDo: определить сообразно общей ситуации извне
      skin: _skin,
      size: size,
      onChanged: onOwlSubbeatsChanged,
      onAccentChanged: onAccentChanged,
    );

    final sizeOfSubbeatNm = Size(size.width * 0.4, size.height * 0.10);
    return Stack(
      // fit: StackFit.expand,
      children: [
        Container(width: size.width, height: size.height, child: wixOwls),
        Positioned.fromRect(
          /*rect: Rect.fromPoints(
             Offset(size.width, size.height),
             Offset(size.width-sizeOfSubbeatNm.width, size.height-sizeOfSubbeatNm.height),
           ), */
          rect: Rect.fromCenter(
            center: Offset(
              size.width / 2,
              size.height -
                  sizeOfSubbeatNm.height / 2 -
                  sizeOfSubbeatNm.height * 0.2,
            ),
            width: sizeOfSubbeatNm.width,
            height: sizeOfSubbeatNm.height,
          ),
          child: _beat.beatCount > 1
              ? Container(
                  /*decoration: BoxDecoration(
                    image: DecorationImage(
                      //image:   AssetImage('images/but-note-2.png'),
                      //image:     AssetImage('images/but-note-1.png'),
                      image: AssetImage('images/but123short.png'), //ToDo: Юрик,
                      //одень это по-человечески (это регулятор подбит)
                      fit: BoxFit.fill,
                    ),
                  ),*/
                  child: SubbeatEqWidget(
                    subbeatCount: _beat.subBeatCount,
                    subbeatCountMax: 4,
                    noteValue: _noteValue,
                    noteColor: Colors.black,
                    textStyle: GoogleFonts.roboto(),
                    size: sizeOfSubbeatNm,
                    allEqual: _beat.subBeatsEqualAndExist(),
                    onChanged: onAllSubbeatsChanged,
                  ),
                )
              : Container(),
        ),
      ],
    );
  }
}
