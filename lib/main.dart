import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:owlenome/MetreBar_ui.dart';
import 'package:provider/provider.dart';
import 'package:device_preview/device_preview.dart';
//import 'package:wheel_chooser/wheel_chooser.dart';
//import 'package:flutter_xlider/flutter_xlider.dart';

import 'package:owlenome/prosody.dart';
import 'package:owlenome/util.dart';
import 'PlatformSvc.dart';
import 'BarBracket.dart';
import 'SkinRot.dart';
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
import 'settings.dart';
import 'knob.dart';
import 'KnobTuned.dart';
import 'timer_ui.dart';
import 'NoteTempo.dart';

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
const Color _clrRegularBar = Colors.white70;  // Color(0xB3FFFFFF)
/// Metre bar irregular metre color
const Color _clrIrregularBar = Color(0xB3FFECB3);  // Colors.amber[100];
/// Metre control irregular metre color
const Color _clrIrregularMetre = Color(0xFFFFA000);  // Colors.amber[600];
/// Tempo List text color
final Color _cTempoList = Colors.white;

/// 48 - minimum recommended target size of 7mm regardless of what screen they are displayed on
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
//const int _cIniNoteValue = 4;

/// Initial metre (beat, note) index from _metreList
/// !!!ATTENTION!!! Make it compatible with next subbeat/accent lists
const int _cIniActiveMetre = 1;//3
/// Initial subbeats
const List<int> _cIniSubBeats = [
  1, 1, 1,
  //1, 1, 1, 1, 1, 1,

  //1,3,1,3,1,1, 1,3,1,3,3,3  // Fancy; Bolero; needs accents
  //2, 2, 4, 2, 4, 2,  // Fancy
  //2,2,4,2,4,2,6,1,
  //1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
];
/// Initial accents
const List<int> _cIniAccents = [
  1, 0, 0,
  //2, 0, 0, 1, 0, 0,

  //2, 0, 1, 0,
  //2, 0, 1, 0, 1, 0, 2, 0, 1, 0, 1, 0,  //Bolero
  //ToDo: fancy Bolero ;
];

/// Min tempo
const int _cMinTempo = 1;
/// Absolute max tempo. Больше него не ставим, даже если позволяет сочетание схемы и метра.
const int _cMaxTempo = 1000;  //500-5000
/// Initial tempo
const int _cIniTempo = 120;  //121 - идеально для долгого теста, показывает, правильно ли ловит микросекунды
const int _cTempoKnobTurns = 2;
const double _cTempoKnobAngle = 160;
const double _cTempoKnobSweepAngle = 3 * 360.0 + 2 * _cTempoKnobAngle;

/// Debug on different devices/resolutions
final bool _debugDevices = false;
///<<<<<< JG!

final String _cAppName = "Owlenome";
final String _cAppTitle = "Owlenome";

void main()
{
  if (_debugDevices)
  {
    return runApp(
      DevicePreview(builder: (context) =>
        ChangeNotifierProvider(
          create: (_) => new MetronomeState(_cIniSubBeats, _cIniAccents),
          child: App()
        )
        //new App()
      ),
        //..devices.addAll();
    );
  }

  return runApp(
    ChangeNotifierProvider(
      create: (_) => new MetronomeState(_cIniSubBeats, _cIniAccents),
      child: App()
    )
  );
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin<HomePage>
{
  // for showSnackBar to run
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Configuration constants
  bool _useNewKnob = false;
  bool _showKnobDialText = true;
  bool _showNoteTempo = true;
  bool _showVersion = true;

  //static const int initBeatCount = 4;//From beatMetre
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
  PlatformSvc _channel;// = new PlatformSvc(onStartSound, onSyncSound, onLimitTempo);

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

  /// Controls border parameters
  double _borderRadius = 12;
  double _borderWidth = 3;
  double _smallBtnSize0 = 24;
  /// Size of small buttons
  double _smallBtnSize = 24;
  Offset _paddingBtn = new Offset(8, 8);//Size(24, 36);
  /// Controls opacity
  double _opacity = _cCtrlOpacity;  // Control's opacity
  /// Standart padding
  Offset _padding = new Offset(4, 4);//Size(24, 36);

  /// Show advertising box
  bool _showAds = false;
  final List<double> _heightAds = [50, 32];
  ///<<<<<< JG!

  /// Overall screen size
  Size _screenSize;
  /// Size of square owl's area
  double _sideSquare;
  double _squareX = 1.0;
  double _squareY = 0.85;
  Size _sizeCtrls;
  double _sizeCtrlsShortest;

  BeatMetre _beat;//TODO vs MetronomeState // = new BeatMetre();
  BeatSound _soundConfig = new BeatSound();

  /// Initial note value (denominator)
  //final int _noteValue = _cIniNoteValue;

  /// Partly-sorted metre list to switch between metres
  /// Includes predefined ('standard') metres
  /// Initially filled with predefined ('standard') metres
  /// User defined metre is inserted into this list in its sorted position
  List<MetreBar> _metreList =
  [
    MetreBar(2, 2),
    MetreBar(3, 4),
    MetreBar(4, 4),
    MetreBar(6, 8),
    MetreBar(9, 8),
    MetreBar(12, 16),
    // 'Unsorted' metres go in the end
    //MetreBar(5, 8),  // 3+2/8
    MetreBar(12, 16),  // Bolero
  ];
  /// Index of current active metre
  int _activeMetre = _cIniActiveMetre;
  /// Index of current user defined metre
  /// -1 - if there are not user metre
  int _userMetre = -1;

  MetreBar get activeMetre => _metreList[_activeMetre];

  double _volume = 100;
  bool _mute = false;
  int _tempoBpm = _cIniTempo;
  /// Переменная, ограничивающся максимальную скорость при данной музыкальной схеме и метре
  int _tempoBpmMax = maxTempo;

  /// Shows weather to update MetreWidget (if true)
  bool _updateMetre = false;
  /// Shows weather to update MetreBarWidget (if true)
  bool _updateMetreBar = false;
  /// Playing state flag
  bool _playing;
  /// Keep screen on while playing (if true)
  bool _screenOn = true;

  OwlSkinRot _skin;

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
  int _period = 1000;

  //IS: my knob constants
  double _sensitivity = 2;
  double _innerRadius = 0.1;
  double _outerRadius = 2;
  //double _knobSize = 150;
  static const double initKnobAngle = 0;
  KnobValue _knobValue;

  /// /////////////////////////////////////////////////////////////////////////

  _HomePageState();

  @override
  void initState()
  {
    super.initState();
    /// Init channel callback from hardware Java code
    _channel = new PlatformSvc(onStartSound, onSyncSound, onLimitTempo);
    _channel.getVersion().then((String version) {
      setState(() { _version = version; });
    });
    /// Get sound schemes (async) and set active scheme
    _channel.getSoundSchemes(_activeSoundScheme).then((List<String> soundSchemes) {
      _soundSchemes = soundSchemes;
      if (_soundSchemes.isEmpty)
        _activeSoundScheme = -1;
      else if (_activeSoundScheme == -1)
        _activeSoundScheme = 0;  // Set default 0 scheme
    });

    _skin = new OwlSkinRot(_animationType);
    _skin.init().then((_) {
      setState(() {});
    });

    /// Init animation
    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    );
    _animationPos = new Tween<Offset>(begin: Offset.zero, end: const Offset(2, 0)).chain(CurveTween(curve: Curves.easeIn)).animate(_controller);
    _animationNeg = new Tween<Offset>(begin: Offset.zero, end: const Offset(-2, 0)).chain(CurveTween(curve: Curves.easeIn)).animate(_controller);
    _animationDown = new Tween<Offset>(begin: Offset.zero, end: const Offset(0, 3)).chain(CurveTween(curve: Curves.easeIn)).animate(_controller);
    //_animation = new Tween<double>(begin: 1, end: 0).animate(_controller);
    //_animation = new Tween<double> CurvedAnimation(parent: _controller, curve: Curves.linear);

    _knobValue = KnobValue(
      absoluteAngle: initKnobAngle,
      value: _tempoBpm.toDouble(),
      tapAngle: null,
      //deltaAngle:0,
    );

    _playing = false;

    _beat = Provider.of<MetronomeState>(context, listen: false).beatMetre;
    //TODO insertMetre(_beat.beatCount, _cIniNoteValue);

    _channel.setBeat(_beat.beatCount, _beat.subBeatCount, _tempoBpm,
      _activeSoundScheme, _beat.subBeats, Prosody.reverseAccents(activeMetre.accents));
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  /// /////////////////////////////////////////////////////////////////////////

  /// (Re)Insert metre (beast, note) into _sorted_ metre list
  bool insertMetre(int beats, int note)
  {
    bool activeChanged = true;
    print('insertMetre - $beats - $note');
    int index = metreIndex(_metreList, beats, note);
    if (index < _metreList.length &&
        beats == _metreList[index].beats && note == _metreList[index].note)
    {
      if (index == _activeMetre)
        activeChanged = false;
      _activeMetre = index;
      print('insertMetre_= - $index');
    }
    else
    {
      if (index == _userMetre)
      {
        print('insertMetre_user - $index');
        _metreList[_userMetre] = MetreBar(beats, note);
      }
      else
      {
        print('insertMetre_insert - $index');
        // Insert shifts right all elements including [index]
        _metreList.insert(index, MetreBar(beats, note));
        // Remove previous User Metre if existed
        if (_userMetre != -1)
        {
          print('insertMetre_remove - $index - ${_userMetre + (_userMetre >= index ? 1 : 0)}');
          _metreList.removeAt(_userMetre + (_userMetre >= index ? 1 : 0));
          // Correct new index after removing
          if (_userMetre < index)
            index--;
        }
      }
      _activeMetre = _userMetre = index;
    }
    print('insertMetre - $_activeMetre');
    return activeChanged;
  }

  /// /////////////////////////////////////////////////////////////////////////
  /// Platform sound code handlers
  ///

  /// Called from platform sound code after sound warmup finished
  void onStartSound(int initTime)
  {
    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.startAfterWarm(initTime, _tempoBpm);

    // Start graphics animation
    _playing = true;
    //TODO _setBeat(); //Даёт отвратительный эффект при старт - доп. щелк
    setState(() {});
  }

  /// Called from platform sound code after sound warmup finished
  void onSyncSound(int newTime, int tempoBpm, int startTime)
  {
    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.sync(newTime, tempoBpm, startTime);
  }

  /// Called from platform sound code when max tempo limited
  void onLimitTempo(int limitTempo)
  {
    if (limitTempo > maxTempo)
      limitTempo = maxTempo;
    //TODO IS (Elsa): what if limitTempo<minTempo?
    if (limitTempo < minTempo)
      limitTempo = minTempo;
    //TODO Check out setState and UI refreshing
    if (limitTempo != _tempoBpmMax)
      setState(() {
        _tempoBpmMax = limitTempo;
        if (_tempoBpm > _tempoBpmMax)
          _tempoBpm = _tempoBpmMax;
      });
  }

  /// Start/Stop play handler
  void _play()
  {
    //_subbeatWidth = _subbeatWidth == 0 ? 60 : 0;

    if (!_playing && hideCtrls)
      _controller.forward();

    _channel.togglePlay(_tempoBpm, _beat.beatCount, _screenOn).then((int result) {
      if (result != 0)
        setState(() {  // TODO
          //IS: TEST
          Provider.of<MetronomeState>(context, listen: false).reset();
          //_tempoBpm = realTempo;
        });
    });

    if (_playing)
    {
      _playing = false;
      if (hideCtrls)
        _controller.reverse();
      setState(() {});  // Stops OwlGridState::AnimationController
    }
    //TODO setState(() {});
  }

  /// Set new tempo to platform sound code
  void _setTempo(int tempo)
  {
    if (_tempoBpm != tempo)
    {
      _tempoBpm = tempo;
      if (_playing)
        _channel.setTempo(_tempoBpm);
      setState(() {}); //ToDo: в такой последовательности?
    }
  }

  void _setVolume(double value)
  {
    if (value < 0)
      value = 0;
    if (value > 100)
      value = 100;
    setState(() {
      _mute = value == 0;
      _volume = value;//.round();
    });
    _channel.setVolume(_volume.round());
  }

  void _changeVolumeBy(int delta)
  {
    setState(() {
      _volume += delta;
      if (_volume < 0)
        _volume = 0;
      if (_volume > 100)
        _volume = 100;
      _mute = _volume == 0;
      _channel.setVolume(_volume.round());
    });
  }

  /// /////////////////////////////////////////////////////////////////////////
  /// UI notification handlers
  ///

  void _onBeatChanged(int beats)
  {
    print('_onBeatChanged');
    if (_beat.beatCount != beats)
    {
      _beat.beatCount = beats;
      bool changed = insertMetre(beats, activeMetre.note);

      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
      _channel.setBeat(_beat.beatCount, _beat.subBeatCount, _tempoBpm,
        _activeSoundScheme, _beat.subBeats, Prosody.reverseAccents(activeMetre.accents));
      print('_onBeatChanged2');
      setState(() { _updateMetreBar = changed; });  //TODO ListWheelScrollView redraws 1 excess time after wheeling
    }
  }

  void _onNoteChanged(int noteValue)
  {
    //_noteValue = noteValue;  // Does not affect sound
    bool changed = insertMetre(_beat.beatCount, noteValue);

    print('_onNoteChanged');
    setState(() { _updateMetreBar = changed; });  //TODO ListWheelScrollView redraws 1 excess time after wheeling
  }

  void onMetreChanged(int beats, int noteValue)
  {
    //_noteValue = noteValue;  // Does not affect sound
    // Change active metre at first
    insertMetre(beats, noteValue);
    if (_beat.beatCount != beats)
    {
      _beat.beatCount = beats;
      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
      _channel.setBeat(_beat.beatCount, _beat.subBeatCount, _tempoBpm,
        _activeSoundScheme, _beat.subBeats, Prosody.reverseAccents(activeMetre.accents));
    }

    print('onMetreChanged');
    setState(() { _updateMetre = true; });
  }

  void onMetreBarChanged(int index)
  {
    _activeMetre = index;
    int beats = _metreList[index].beats;
    if (_beat.beatCount != beats || !equalLists(_metreList[index].accents, _metreList[index].accents))
    {
      _beat.beatCount = beats;
      //_beat.accents = _metreList[index].accents;
      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
      _channel.setBeat(_beat.beatCount, _beat.subBeatCount, _tempoBpm,
        _activeSoundScheme, _beat.subBeats, Prosody.reverseAccents(_metreList[index].accents));
    }
    //_noteValue = _metreList[index].note;  // Does not affect sound

    print('onMetreBarChanged');
    setState(() { _updateMetre = true; });
  }

  void onSubbeatChanged(int subbeatCount)
  {
    //TODO
    _beat.subBeatCount = subbeatCount;//nextSubbeat(_beat.subBeatCount);
    //TODO Provider.of<MetronomeState>(context, listen: false).reset();
    //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
    _channel.setBeat(_beat.beatCount, _beat.subBeatCount, _tempoBpm,
      _activeSoundScheme, _beat.subBeats, Prosody.reverseAccents(activeMetre.accents));
    setState(() {});
  }

  void onOwlChanged(int id, int subCount)
  {
    assert(id < _beat.subBeats.length);
    _beat.subBeats[id] = subCount;
    //TODO Provider.of<MetronomeState>(context, listen: false).reset();
    //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
    _channel.setBeat(_beat.beatCount, _beat.subBeatCount, _tempoBpm,
      _activeSoundScheme, _beat.subBeats, Prosody.reverseAccents(activeMetre.accents));
    setState(() {});
  }

  void onAccentChanged(int id, int accent)
  {
    assert(id < _beat.subBeats.length);
    //_beat.setAccent(id, accent);
    activeMetre.setAccent(id, accent);
    //Provider.of<MetronomeState>(context, listen: false).beatMetre = _beat;  // TODO Need???
    _channel.setBeat(_beat.beatCount, _beat.subBeatCount, _tempoBpm,
      _activeSoundScheme, _beat.subBeats, Prosody.reverseAccents(activeMetre.accents));
    setState(() {});
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

    print('mediaQueryData ${mediaQueryData.padding} - ${mediaQueryData.viewInsets} - ${mediaQueryData.viewPadding}');

    if (_screenSize.width > _screenSize.height)
      _sizeCtrls = new Size(_screenSize.width - _sideSquare, _screenSize.height);
    else
      _sizeCtrls = new Size(_screenSize.width, _screenSize.height - _sideSquare);
    _sizeCtrlsShortest = _sizeCtrls.shortestSide;

    //Theme.of(context).materialTapTargetSize;

    debugPrint('screenSize $_screenSize - ${mediaQueryData.devicePixelRatio} - ${1 / _screenSize.aspectRatio} - $_sideSquare');

    if (_textStyle == null)
      _textStyle = Theme.of(context).textTheme.display1
        .copyWith(color: _textColor, /*fontSize: _textSize, */height: 1);

    if (_screenSize.width <= 0 || _screenSize.height <= 0)  //TODO
      return Container();
    else
      return Scaffold(
        key: _scaffoldKey,  // for showSnackBar to run
        backgroundColor: Colors.deepPurple, //Color.fromARGB(0xFF, 0x45, 0x1A, 0x24),  //TODO: need?
        //appBar: AppBar(title: Text(widget.title),),
        body: SafeArea(
          child: OrientationBuilder(
            builder: (BuildContext context, Orientation orientation) {
              final bool portrait = orientation == Orientation.portrait;
              if (!portrait)
                _sideSquare -= mediaQueryData.padding.vertical;
              return orientationBuilder(context, orientation);
            }
          ),
        ),
      );
  }

  Widget orientationBuilder(BuildContext context, Orientation orientation)
  {
    //_showAds = false;
    final bool portrait = orientation == Orientation.portrait;

    final double aspect = 1 / _screenSize.aspectRatio;
    final double aspectCtrls = (_showAds ? _sizeCtrls.height - _heightAds[portrait ? 0 : 1] :
      _sizeCtrls.height) / _sizeCtrls.width;
    debugPrint("aspect $aspect - $aspectCtrls");
    final double wScale = aspectCtrls > 1.5 ? _squareX : 1;
    final double hScale = aspectCtrls < 0.9 ? _squareY : 1;
    final Size sizeOwlenome = new Size(
      portrait ? _sideSquare : wScale * _sideSquare,
      portrait ? hScale * _sideSquare : _sideSquare - (_showAds ? _heightAds[1] : 0));
      //_sideSquare);

    _smallBtnSize = Theme.of(context).buttonTheme.height;
    _smallBtnSize0 = 1.2 * Theme.of(context).buttonTheme.height;//1.2
    double btnPadding = 0.2 * Theme.of(context).buttonTheme.height;
    _paddingBtn = new Offset(btnPadding, btnPadding);

    double _barHeight = (portrait ? cBarHeightVert : cBarHeightHorz) * _sizeCtrls.height;
    if (_barHeight < cMinTapSize)
      _barHeight = cMinTapSize;
    final Size metreBarSize = new Size(_sizeCtrls.width, _barHeight);

    // Vertical/portrait
    if (portrait)
    {
      /// Owl square and controls
      final List<Widget> innerUI = <Widget>[
        _buildOwlenome(portrait, sizeOwlenome),
        _buildBar(portrait, metreBarSize),
        _buildControls(portrait, metreBarSize.height),
      ];

      if (_showAds)
        innerUI.add(_buildAds(portrait));

      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/BackgV.jpg'),
            fit: BoxFit.cover,
          )
        ),
        child: Stack(
          children: <Widget>[
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: innerUI,
            ),
            Positioned(
              left: _paddingBtn.dx,
              bottom: _showAds ? _heightAds[0] + _paddingBtn.dy : _paddingBtn.dy,
              child: _buildVolumeBtn(_smallBtnSize,//0.05 * _sizeCtrlsShortest
                _sizeCtrlsShortest)
            ),
            /// Git revision number
            _showVersion ? Align(
              alignment: Alignment.topLeft,
              child: Text(_version,
                style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white))
            )
            : Container(),
          ]
        )
      );
    }
    else  // Horizontal/landscape
    {
      //TODO _showAds = true;
      /// Owl square and controls
      final Widget innerUI = new Row(
        children: <Widget>[
          _buildOwlenome(portrait, sizeOwlenome),
          //Container(color: Colors.red, height: sizeOwlenome.height, width: sizeOwlenome.width),
          Expanded(child:
          Stack(
            //fit: StackFit.expand,
            children: <Widget>[
              //Positioned.fill(
                //child:
              Column(
                mainAxisSize: MainAxisSize.max,
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
                  _smallBtnSize,//0.05 * _sizeCtrlsShortest
                  _sizeCtrlsShortest)
              ),
              /// Git revision number
              _showVersion ? Align(
                alignment: Alignment.topRight,
                child: Text(_version,
                  style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white))
              )
              : Container(),
            ]
          ),
          ),
        ]
      );

      final Widget fullUI = !_showAds ? innerUI :
        new Column(
          //mainAxisSize: MainAxisSize.max,
          children: <Widget>[
            Expanded(child:
              innerUI,
            ),
            _buildAds(portrait),
          ]
        );

      return Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('images/BackgH.jpg'),
            fit: BoxFit.cover,
          )
        ),
        child: fullUI
      );
    }
  }

  ///widget Square section with metronome itself
  Widget _buildOwlenome(bool portrait, Size size)
  {
    if (!_skin.isInit || size.isEmpty)
      return Container(
        //color: Colors.orange,
        width: size.width,
        height: size.height,
      );

    //TODO MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    print('_buildOwlenome $size');

    // TODO VG
    final double paddingX = 0;//_beat.beatCount == 3 || _beat.beatCount == 4 ? 10 : 0;
    //0.03 * _widthSquare : 0;
    final double paddingY = _beat.beatCount > 4 ? 0.02 * _sideSquare : 0;
    final EdgeInsets padding = portrait ? new EdgeInsets.only(bottom: paddingY, left: paddingX, right: paddingX) :
      new EdgeInsets.only(bottom: paddingY, left: paddingX, right: paddingX);
    final Offset spacing = new Offset(10, 0);

    ///widget Owls
    final Widget wixOwls1 = new OwlGrid(
      playing: _playing,
      beat: _beat,
      activeBeat: -1,//state.activeBeat,
      activeSubbeat: -1,//state.activeSubbeat,
      noteValue: activeMetre.note,
      accents: activeMetre.accents,
      maxAccent: activeMetre.maxAccent,
      animationType: _animationType,
      onChanged: onOwlChanged,
      onAccentChanged: onAccentChanged,
    );

    final Widget wixOwls = new OwlGridRot(
      playing: _playing,
      beat: _beat,
      activeBeat: -1,//state.activeBeat,
      activeSubbeat: -1,//state.activeSubbeat,
      noteValue: activeMetre.note,
      accents: activeMetre.accents,
      maxAccent: activeMetre.maxAccent,
      spacing: spacing,
      padding: padding,
      skin: _skin,
      size: size,
      onChanged: onOwlChanged,
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
      child: wixOwls
    );
  }

  ///widget Metre-bar section
  Widget _buildBar(bool portrait, Size size)
  {
    final double horzSpace = portrait ? 16 : 16;

    final double paddingY = portrait ? 0 : 0.1 * _sideSquare;
    final double btnPadding = 0.2 * Theme.of(context).buttonTheme.height;
    final Size metreSize = Size((portrait ? 0.25 : 0.25) * size.width, size.height);
    double itemExtent = 0.5 * metreSize.width;//44,

    print('metreSize $metreSize - $itemExtent');
    //itemExtent = 44;
    final Size barSize = Size((portrait ? 0.70 : 0.70) * size.width, 0.5 * size.height);
    final Size listTempoSize = new Size((portrait ? 0.88 : 0.88) * barSize.width, barSize.height);
    final Size noteTempoSize = new Size(0.12 * barSize.width, 0.9 * barSize.height);
    //final Size subbeatSize = Size(0.2 * _sizeCtrls.width, 1.25 * barSize.height);
//    final Size subbeatSize = new Size(barSize.height, barSize.height);
    //0.02 * _sizeCtrls.width,
    final Size bracketSize = new Size(3.2 * btnPadding, 0.16 * _sizeCtrls.height);

    print('Font ${_textStyle.fontSize}');

    List<Widget> children = new List<Widget>();

    final Widget barSpacer = new Container(width: btnPadding,);

    bool updateMetre = _updateMetre;
    _updateMetre = false;

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
          color: activeMetre.regularAccent ? _cWhiteColor : _clrIrregularMetre
      ),
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
        if (activeMetre.setAccentOption(pivoVodochka ? 0 : 1))
        {
          setState(() {});
        }
      },
      onResetMetre: () {
        activeMetre.setRegularAccent();
        //_beat.setRegularAccent();
        setState(() { _updateMetreBar = true; });
      },
    );

    ///widget Tempo list
    final Widget listTempo = new Container(
      //color: Colors.orange,
        //width: 80,
        height: listTempoSize.height,
        padding: EdgeInsets.only(top: 0.0 * _sizeCtrls.height, bottom: 0.0 * _sizeCtrls.height),
      //padding: EdgeInsets.only(top: 0.025 * _sizeCtrls.height, bottom: 0.025 * _sizeCtrls.height),
      child:
      TempoListWidget(//TODO Limit
        tempo: _tempoBpm,
        width: listTempoSize.width,
        textStyle: Theme.of(context).textTheme.display1
          .copyWith(color: _cTempoList, height: 1),//TODO
          //.copyWith(color: _cTempoList, fontSize: 0.07 * _sizeCtrls.height, height: 1),//TODO
        onChanged: _setTempo
      )
    );
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

    if (portrait)
    {
    ///widget Metre row
    final Widget rowBar = new Padding(
      padding: EdgeInsets.zero, //only(top: paddingY, left: _padding.dx, right: _padding.dx),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          barSpacer,
          //Flexible(
            //flex: 25,
            //child:
            metre,  ///widget Metre
          //),
          barSpacer,

          Expanded(
            //flex: 75,
            //fit: FlexFit.tight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  color: activeMetre.regularAccent ? _clrRegularBar : _clrIrregularBar,
                  child: Padding(
                    padding: EdgeInsets.zero,//symmetric(horizontal: 0.5 * btnPadding),
                    child: Row(
                      //mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.center,  //spaceBetween, for brackets
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
                        Flexible(child:
                        Padding(
                          padding: EdgeInsets.only(top: 2),//(bottom: 0.05 * _sizeCtrls.height),//20
                          child: metreBar
                        ),
                        ),
//                        BarBracketWidget(
//                          direction: BarBracketDirection.right,
//                          color: Colors.black,
//                          size: bracketSize
//                        ),
                      ]
                    ),
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(top: 4),
                  color: Colors.deepPurple.withOpacity(0.8),
                  child: Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      _showNoteTempo ? noteTempo : Container(),  ///widget Note=tempo
                      Expanded(child:
  //                        ClipRect(child:
                        listTempo,  ///widget Tempo list
                      ),
                    ]
                  ),
                ),
              ],
              ),
            ),
            //btnSubbeat,
            barSpacer,
          ]
        )
    );

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
    }
    else
    {
      ///widget Metre row
      final Widget rowBar = Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center, // start,
        children: <Widget>[
          ///widget Metre
          metre,
          barSpacer,

          Flexible(child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
              color: activeMetre.regularAccent ? _clrRegularBar : _clrIrregularBar,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  ///widget Subbeat widget
                  /////TODO !!!
                  //Flexible(child:
                  Padding(
                    padding: EdgeInsets.zero,//EdgeInsets.only(bottom: 0.05 * size.height),//20
                    child: metreBar
                  ),
                ]
              ),
            ),

            Container(
              margin: EdgeInsets.only(top: 4),
              color: Colors.deepPurple.withOpacity(0.8),
              child: Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _showNoteTempo ? noteTempo : Container(),  ///widget Note=tempo
                  Expanded(child:
//                        ClipRect(child:
                  listTempo,
                  ),
                ]
              ),
            ),
            ]
          ),
          ),
          //btnSubbeat,
          //listTempo,
          //accentMetre,
        ]
      );

      return rowBar;
    }
  }

  Widget _buildControls(bool portrait, double barHeight)
  {
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
      Expanded(child:  //TODO Without Expanded in portrait mode: constraints.height == infinity
      LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return _layoutControls(context, constraints, portrait, barHeight);
          //return Placeholder(fallbackWidth: constraints.maxWidth, fallbackHeight: constraints.maxHeight, color: Colors.red);
        },
      ),
        //child: rowButtons
      );
  }

  // Remaining section with controls
  Widget _layoutControls(BuildContext context, BoxConstraints constraints, bool portrait, double barHeight)
  {
    double minSquare = constraints.maxWidth > constraints.maxHeight ? constraints.maxHeight : constraints.maxWidth;
    print("minSquare $constraints - $barHeight");

    final TextStyle textStyleTimer = _textStyle.copyWith(fontSize: 20);

    final double horzSpace = portrait ? 16 : 16;
    double paddingY = portrait ? 0 : 0.1 * _sideSquare;
    double width = portrait ? _sideSquare : _screenSize.width - _sideSquare;

    // 48 - minimum recommended target size of 7mm regardless of what screen they are displayed on
    // 48 <= buttonSize <= 1.5 * 48
    final double playBtnSize = barHeight > 1.5 * cMinTapSize ? 1.5 * cMinTapSize : (barHeight < cMinTapSize ? cMinTapSize : barHeight);
    final Size subbeatSize = new Size(playBtnSize, playBtnSize);
    final double dist0 = _paddingBtn.dx;
    final Offset sidePadding = _paddingBtn;
    final Offset knobPadding = _paddingBtn;//const Offset(0, 0);
    //sidePadding = const Offset(0, 0);
    //knobPadding = const Offset(0, 0);
    //dist0 = 0;
    final List<double> res = knobRadius(constraints.maxWidth, constraints.maxHeight,
        0.5 * playBtnSize, sidePadding, knobPadding, dist0, _smallBtnSize0);
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
      textStyle: _textStyle.copyWith(fontSize: 0.15 * _sizeCtrls.height,//0.2
        //fontWeight: FontWeight.bold,
        color: Colors.white, height: 1),
      onPressed: () {},//_play,
      onChanged: (double value) {
        _setTempo(value.round());
      },
    );

    _knobValue.value = _tempoBpm.toDouble();
    Widget knobTempoNew = new KnobTuned(
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
      textStyle: _textStyle.copyWith(fontSize: 0.2 * _sizeCtrls.height, color: Colors.white),
    );

    final Widget btnSubbeat = new SubbeatWidget(
      subbeatCount: _beat.subBeatCount,
      noteValue: activeMetre.note,
      color: _textColor,
      textStyle: _textStyle,
      size: subbeatSize,
      onChanged: onSubbeatChanged,
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
          Wrap(
            children: <Widget>[
              _buildSoundBtn(_smallBtnSize),
              _buildSettingsBtn(_smallBtnSize),
            ]
          ),
          //_buildVolumeBtn(), //TODO SizedOverflowBox
          //_buildSettingsBtn(),
        ]
    );

    // Fill up the remaining screen as the last widget in column/row
    return Stack(
      children: <Widget>[
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
          child: Row(
            children: <Widget>[
              Container(
                width: _smallBtnSize,
                height: _smallBtnSize,
              ),
            Container(width: _paddingBtn.dx),
              _buildSoundBtn(_smallBtnSize),
          ]
        ),
        ),
        Positioned(
          bottom: knobPadding.dy,
          left: 0.5 * (constraints.maxWidth - diameter),
          child: (_useNewKnob ? knobTempoNew : knobTempo),
        ),
        Positioned(
          right: _paddingBtn.dx,
          top: _paddingBtn.dy,
          child: _buildPlayBtn(playBtnSize, portrait),
        ),
        Positioned(
          right: _paddingBtn.dx,
          bottom: _paddingBtn.dy,
          child: Row(
            children: <Widget>[
              _buildHelpBtn(_smallBtnSize),
              Container(width: _paddingBtn.dx),
              _buildSettingsBtn(_smallBtnSize),
            ]
          ),
        ),
      ]
    );
  }

  Widget _buildPlayBtn(double diameter, bool portrait)
  {
    final Widget icon = Icon(_playing ? Icons.pause : Icons.play_arrow,
        size: 1 * diameter);
    final Widget icon1 = Stack(
      alignment: Alignment.center,
      children: <Widget>[
        Image.asset('images/owl-btn.png',
          height: diameter,
          fit: BoxFit.contain
        ),
        icon,
    ]);

    return new RawMaterialButton(  //FlatButton
      //padding: EdgeInsets.all(18),//_padding.dx),
      child: icon,
      fillColor: Colors.deepPurple.withOpacity(0.5), //portrait ? _accentColor : _primaryColor,
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
        padding: EdgeInsets.all(18),//_padding.dx),
        //child: tempo,
        child: Icon(_playing ? Icons.pause : Icons.play_arrow,
            size: diameter),
        color: Colors.deepPurple.withOpacity(0.5), //portrait ? _accentColor : _primaryColor,
        enableFeedback: false,
        onPressed: _play
    );
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

  Widget _buildSoundBtn(double size)
  {
    int soundScheme = _activeSoundScheme;
    final int imageIndex = soundScheme < 3 ? soundScheme : 3;
    final String schemeName = 'images/sound' + imageIndex.toString() + '.png';

//    final String strScheme = _soundSchemes != null && _activeSoundScheme < _soundSchemes.length ?
//      _soundSchemes[_activeSoundScheme] : '';
    final String strScheme = (soundScheme + 1).toString();
    final double sizeButton = size;

    final Widget icon = new Image.asset(schemeName,
      width: sizeButton,
      height: sizeButton,
      fit: BoxFit.contain,
    );
    final Widget icon3 = new Stack(
        alignment: AlignmentDirectional.center,
        children: <Widget>[
          Image.asset(schemeName,
            width: sizeButton,
            height: sizeButton,
            fit: BoxFit.contain,
          ),
          Text(strScheme,
            style: Theme.of(context).textTheme.headline
              .copyWith(fontSize: 0.9 * size,
                fontWeight: FontWeight.bold, color: Colors.white), //fontSize: 28
          ),
        ]
    );

    final Widget icon2 = new Row(
        children: <Widget>[
          Icon(Icons.music_note, size: 0.5 * sizeButton, color: _cWhiteColor),
          Text(strScheme,
            style: Theme.of(context).textTheme.headline
                .copyWith(fontSize: 0.5 * size,
                fontWeight: FontWeight.bold, color: Colors.white), //fontSize: 28
          ),
        ]
    );

    return new RawMaterialButton(  //FlatButton
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
        if (_soundSchemes?.length > 0)
        {
          _activeSoundScheme = (_activeSoundScheme + 1) % _soundSchemes.length;
          // setState() is called in onLimitTempo() call
          _channel.setSoundScheme(_activeSoundScheme)
            .then((int result) {
            setState(() {});
          });
        }
      },
    );
  }

  Widget _buildVolumeBtn(double size, double height)
  {
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
  Widget _buildSettingsBtn(double size)
  {
    return new RawMaterialButton(  //FlatButton
      //padding: EdgeInsets.all(18),//_padding.dx),
      //padding: EdgeInsets.zero,
      child: Icon(Icons.settings,
          size: 1.0 * size),
      //fillColor: Colors.deepPurple.withOpacity(0.5), //portrait ? _accentColor : _primaryColor,
      //color: _cWhiteColor.withOpacity(0.8),
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
        //maxWidth: 200,
        //maxHeight: 200,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,  // Make button of exact size
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: !_playing,
      onPressed: () {
        _showSettings(context);
      },
    );

    return new IconButton(
      iconSize: size,
      padding: EdgeInsets.all(0),
      icon: Icon(Icons.settings,),
      color: _cWhiteColor.withOpacity(0.8),
      enableFeedback: !_playing,
      onPressed: () {
        _showSettings(context);
      },
    );
  }

  ///widget Settings
  Widget _buildHelpBtn(double size)
  {
    return new RawMaterialButton(
      child: Icon(Icons.help_outline,
        size: size),
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      constraints: BoxConstraints(
        minWidth: size,
        minHeight: size,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,  // Make button of exact size
      enableFeedback: !_playing,
      onPressed: () {
        _showHelp(context);
      },
    );
  }

  Widget _buildAds(bool portrait)
  {
    return Container(
      height: portrait ? _heightAds[0] : _heightAds[1],
      color: Colors.grey[400],
      child: Image.asset('images/Ad-1.png',
        //height: portrait ? 50 : 32,
        fit: BoxFit.contain
      ),
    );
  }

  /// <<<<<<<< Widget section
  /// /////////////////////////////////////////////////////////////////////////

  /// Show settings
  void _showSettings(BuildContext context) async
  {
    final Settings settings = new Settings(
      animationType: _animationType,
      activeScheme: _activeSoundScheme,
      soundSchemes: _soundSchemes,
      useKnob: _useNewKnob,
    );

    final Settings res = await Navigator.push(context,
        MaterialPageRoute(builder: (context) => SettingsWidget(settings: settings)));
    //Navigator.of(context).push(_createSettings());

    if (res != null)
    {
      if (res.activeScheme != _activeSoundScheme && _soundSchemes != null && res.activeScheme < _soundSchemes.length)
      {
        _activeSoundScheme = res.activeScheme;
        _channel.setSoundScheme(_activeSoundScheme)
          .then((int result) {
            setState(() {});
        });
      }
      setState(() {
        _animationType = res.animationType;
        _skin.animationType = _animationType;
        _useNewKnob = res.useKnob;
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

  void _showHelp(BuildContext context) async
  {
    await Navigator.push(context,
      MaterialPageRoute(builder: (context) => HelpWidget()));
  }

  ///widget Plate under controls
  Widget _buildPlate(Widget widget, {Offset padding = Offset.zero})
  {
    return Container(
        decoration: BoxDecoration(
            color: _ctrlColor.withOpacity(_opacity),
            //shape: BoxShape.circle,
            border: Border.all(color: _accentColor.withOpacity(_opacity), width: _borderWidth),
            borderRadius: BorderRadius.circular(_borderRadius)
        ),
        padding: EdgeInsets.symmetric(horizontal: padding.dx, vertical: padding.dy),
        //margin: const EdgeInsets.all(0),
        child: widget
    );
  }

  ///widget Metre
  Widget _buildMetre(double width, double height, TextStyle textStyle)
  {
//    selectTextStyle: Theme.of(context).textTheme.headline
//      .copyWith(color: _cWhiteColor, fontWeight: FontWeight.bold, height: 1),//16
//    unSelectTextStyle: Theme.of(context).textTheme.subhead
//      .copyWith(color: Colors.white70, height: 1),//16
    bool update = _updateMetre;
    _updateMetre = false;

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
          color: activeMetre.regularAccent ? _cWhiteColor : _clrIrregularMetre
      ),
      onBeatChanged: _onBeatChanged,
      onNoteChanged: _onNoteChanged,
    );
  }

  ///+- tempo buttons
  Widget _buildOneButton(String text, int delta)
  {
    //return RaisedButton(//Эта хрень щелкает!
    return InkWell(
      // Can use instead: Icon(Icons.exposure_neg_1, semanticLabel: 'Reduce tempo by one', size: 36.0, color: Colors.white)
      child: Text(text,
        style: _textStyle,
        textScaleFactor: 1.2,),
      //padding: EdgeInsets.all(4),
      enableFeedback: !_playing,//Регулирует писк кнопки
      //shape: CircleBorder(
      customBorder: CircleBorder(
        //borderRadius: new BorderRadius.circular(18.0),
          side: BorderSide(color: _ctrlColor, width: _borderWidth)
      ),
      //onPressed: () {
      onTap: () {
        _tempoBpm += delta;
        if (_tempoBpm < minTempo)
          _tempoBpm = minTempo;
        if (_tempoBpm > _tempoBpmMax)
          _tempoBpm = _tempoBpmMax;
        if (_playing)
          _setTempo(_tempoBpm); //IS: Не уверен, в какой последовательности посылать
        //в яву и обновлять виджет
        setState(() {
        });
      },
    );
  }
}
