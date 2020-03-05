import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:owlenome/accent_metre_ui.dart';
import 'package:owlenome/prosody.dart';
import 'package:owlenome/util.dart';
import 'package:provider/provider.dart';
import 'package:wheel_chooser/wheel_chooser.dart';
import 'package:device_preview/device_preview.dart';
//import 'package:flutter_xlider/flutter_xlider.dart';

import 'BarBracket.dart';
import 'arrow.dart';
import 'metronome_state.dart';
import 'beat_metre.dart';
import 'beat_sound.dart';
import 'owl_grid.dart';
import 'metre_ui.dart';
import 'subbeat_ui.dart';
import 'TempoListWidget.dart';
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

final Color _cWhiteColor = Colors.white;
const Color _clrRegularBar = Colors.white70;  // Color(0xB3FFFFFF)
const Color _clrIrregularBar = Color(0xB3FFECB3);  // Colors.amber[100];
const Color _clrIrregularMetre = Color(0xFFFFA000);  // Colors.amber[600];

const int _cMinBeatCount = 2;
const int _cMaxBeatCount = 12;
const int _cMaxSubBeatCount = 8;
const int _cMinNoteValue = 2;
const int _cMaxNoteValue = 16;
const int _cMinTempo = 1;
///Некий абсолютный максимум скорости. Больше него не ставим, даже если
/// позволяет сочетание схемы и метра.
const int _cMaxTempo = 1000;  //500-5000
const int _cIniTempo = 121;  //121 - идеально для долгого теста, показывает, правильно ли ловит микросекунды
const int _cTempoKnobTurns = 2;
const double _cTempoKnobAngle = 160;

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
          create: (_) => new MetronomeState(),
          child: App()
        )
        //new App()
      ),
        //..devices.addAll();
    );
  }

  return runApp(
    ChangeNotifierProvider(
      create: (_) => new MetronomeState(),
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

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin<HomePage>
{
  // for showSnackBar to run
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Configuration constants
  bool _useNewKnob = false;
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
  static const MethodChannel _channel =
    MethodChannel('samples.flutter.io/owlenome');

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

  int _animationType = 0;

  /// Controls border parameters
  double _borderRadius = 12;
  double _borderWidth = 3;
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

  BeatMetre _beat = new BeatMetre();
  BeatSound _soundConfig = new BeatSound();

  // Metre denominator
  int _noteValue = 4;
  //int _beatCount = 4;  // _metreBeats
  //int _subBeatCount = 1;
  /// Current playing beat
  int _activeBeat = -1;
  /// Current playing subbeat of current beat
  int _activeSubbeat = -1;
  /* /// Melody parameters
  double _quortaInMSec = 20;
  int _bars = 1;
  //int _numerator = 1;*/

  double _volume = 100;
  bool _mute = false;
  int _tempoBpm = _cIniTempo;
  //BipAndPouseCycle
  ///Переменная, ограничивающся максимальную скорость при данной музыкальной схеме и
  ///метре
  int _tempoBpmMax = maxTempo;
  //MelodyMeter _melodyMeter;
  int _counter = 0;

  /*
  // Native hardware audio parameters
  int nativeSampleRate = 0;
  int nativeBuffer = 0;
  int latencyUntested = 0;
   */

  /*
  int latency = 0;
  int warmupFrames = 0;*/
  String _infoMsg = '';
  bool _screenOn = true;

  //Melody melody;
  //BipPauseCycle bipPauseCycle;

  /// Пение рокочущих сов
  ///ToDo: Сколько всего их, какие у них имена, иконки и может что еще -
  int _activeSoundScheme = 0;//IS: Why?!
  List<String> _soundSchemes = [];

  bool redraw = false;
  bool hideCtrls = false;
  AnimationController _controller;
  Animation<double> _animation;
  Animation<Offset> _animationPos;
  Animation<Offset> _animationNeg;
  Animation<Offset> _animationDown;
  int _period = 1000;
  bool _playing;

  //IS: my knob constants
  double _sensitivity = 2;
  double _innerRadius = 0.1;
  double _outerRadius = 2;
  //double _knobSize = 150;
  static const double initKnobAngle = 0;

  KnobValue _knobValue;
  bool _updateMetre = false;

  _HomePageState();

  @override
  void initState()
  {
    super.initState();

    _knobValue = KnobValue(
      absoluteAngle: initKnobAngle,
      value: _tempoBpm.toDouble(),
      tapAngle: null,
      //deltaAngle:0,
    );

    // Channel callback from hardware Java code
    _channel.setMethodCallHandler(_handleMsg);
    // Query native hardware audio parameters
    //_getAudioParams();

    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    );
    _animationPos = new Tween<Offset>(begin: Offset.zero, end: const Offset(2, 0)).chain(CurveTween(curve: Curves.easeIn)).animate(_controller);
    _animationNeg = new Tween<Offset>(begin: Offset.zero, end: const Offset(-2, 0)).chain(CurveTween(curve: Curves.easeIn)).animate(_controller);
    _animationDown = new Tween<Offset>(begin: Offset.zero, end: const Offset(0, 3)).chain(CurveTween(curve: Curves.easeIn)).animate(_controller);
    //_animation = new Tween<double>(begin: 1, end: 0).animate(_controller);
    //_animation = new Tween<double> CurvedAnimation(parent: _controller, curve: Curves.linear);

    _getMusicSchemes();
//    debugPrint('!!!!!!!!!!!!!_getMusicSchemes_getMusicSchemes');
//    debugPrint('${_activeSoundScheme} - ${_soundSchemes.length}');

    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    state.beatMetre = _beat;
    _playing = false;
    _setBeat();

    //TODO Remove
    _setMusicScheme(_activeSoundScheme);
  }

  @override
  void dispose()
  {
    _controller.dispose();
    super.dispose();
  }

  bool isTicking()
  {
    return _playing;
  }

  // Start/Stop play handler
  void _play()
  {
    //_subbeatWidth = _subbeatWidth == 0 ? 60 : 0;

    if (_playing)
    {
      _togglePlay();
      _playing = false;
      if (hideCtrls)
        _controller.reverse();
      /// Stops OwlGridState::AnimationController
      setState(() {});
    }
    else
    {
      if (hideCtrls)
        _controller.forward();
      _togglePlay();
      //TODO setState(() {});
    }
  }

  // Start animation of graphics
  void _start()
  {
    _playing = true;
    //TODO _setBeat(); //Даёт отвратительный эффект при старт - доп. щелк
    setState(() {});
  }

  void _onBeatChanged(int beats)
  {
    if (_beat.beatCount != beats)
    {
      _beat.beatCount = beats;
      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      _setBeat();
      print('_onBeatChanged');
      setState(() {});  //TODO ListWheelScrollView redraws 1 excess time after wheeling
    }
  }

  void _onNoteChanged(int noteValue)
  {
    _noteValue = noteValue;  // Does not affect sound
    print('_onNoteChanged');
    setState(() {});  //TODO ListWheelScrollView redraws 1 excess time after wheeling
  }

  void onMetreChanged(int beats, int noteValue)
  {
    if (_beat.beatCount != beats)
    {
      _beat.beatCount = beats;
      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      _setBeat();
    }
    _noteValue = noteValue;  // Does not affect sound
    print('onMetreChanged');
    setState(() { _updateMetre = true; });
  }

  void onSubbeatChanged(int subbeatCount)
  {
    //TODO
    _beat.subBeatCount = subbeatCount;//nextSubbeat(_beat.subBeatCount);
    //TODO Provider.of<MetronomeState>(context, listen: false).reset();
    _setBeat();
    setState(() {});
  }

  void onOwlChanged(int id, int subCount)
  {
    assert(id < _beat.subBeats.length);
    _beat.subBeats[id] = subCount;
    //TODO Provider.of<MetronomeState>(context, listen: false).reset();
    _setBeat();
    setState(() {});
  }

  void onAccentChanged(int id)
  {
    assert(id < _beat.subBeats.length);
    _beat.accentUp(id);
    _setBeat();
    setState(() {});
  }

  /// /////////////////////////////////////////////////////////////////////////
  /// >>>>>>>> Widget section
  ///

  ///widget Main screen
  @override
  Widget build(BuildContext context) {
    final MediaQueryData mediaQueryData = MediaQuery.of(context);
    _screenSize = mediaQueryData.size;
    _sideSquare = _screenSize.shortestSide;

    if (_screenSize.width > _screenSize.height)
      _sizeCtrls = new Size(_screenSize.width - _sideSquare, _screenSize.height);
    else
      _sizeCtrls = new Size(_screenSize.width, _screenSize.height - _sideSquare);
    _sizeCtrlsShortest = _sizeCtrls.shortestSide;

    debugPrint('screenSize $_screenSize - ${mediaQueryData.devicePixelRatio} - ${1 / _screenSize.aspectRatio}');

    if (_textStyle == null)
      _textStyle = Theme.of(context).textTheme.display1
          .copyWith(color: _textColor, /*fontSize: _textSize, */height: 1);

/*
    MediaQuery.of(context).removePadding(
      removeTop: true,
      removeLeft: true,
      removeRight: true,
    ).padding
*/

    if (_screenSize.width <= 0 || _screenSize.height <= 0)  //TODO
      return Container();
    else
      return Scaffold(
        key: _scaffoldKey,  // for showSnackBar to run
        backgroundColor: Colors.deepPurple, //Color.fromARGB(0xFF, 0x45, 0x1A, 0x24),  //TODO: need?
        //appBar: AppBar(title: Text(widget.title),),
        body: SafeArea(
          child: OrientationBuilder(
            builder: orientationBuilder
          ),
        ),
      );
  }

  Widget orientationBuilder(BuildContext context, Orientation orientation)
  {
    final bool portrait = orientation == Orientation.portrait;
    final double aspect = 1 / _screenSize.aspectRatio;
    final double aspectCtrls = (_showAds ? _sizeCtrls.height - _heightAds[portrait ? 0 : 1] :
      _sizeCtrls.height) / _sizeCtrls.width;
    debugPrint("aspect $aspect - $aspectCtrls");
    final double wScale = aspectCtrls > 1.5 ? _squareX : 1;
    final double hScale = aspectCtrls < 0.9 ? _squareY : 1;
    final Size sizeOwlenome = new Size(
      portrait ? _sideSquare : wScale * _sideSquare,
      portrait ? hScale * _sideSquare : _sideSquare - _heightAds[1]);

    // Vertical/portrait
    if (portrait) {
      /// Owl square and controls
      final List<Widget> innerUI = <Widget>[
        _buildOwlenome(portrait, sizeOwlenome),
        _buildBar(portrait),
        _buildControls(portrait),
      ];

      if (_showAds)
        innerUI.add(_buildAds(portrait));

      return Container(
          decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/Backg-1.jpg'),
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
                  left: 0,
                  bottom: _showAds ? _heightAds[0] + 10 : 10,
                  child: _buildVolumeBtn(
                    Theme.of(context).buttonTheme.height,//0.05 * _sizeCtrlsShortest
                    _sizeCtrlsShortest)
                )
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
          Expanded(child:
          Stack(
            //fit: StackFit.expand,
            children: <Widget>[
              //Positioned.fill(
                //child:
                Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _buildBar(portrait),
                    _buildControls(portrait),
                  ]
                //),
                //),
              ),
              Positioned(
                left: 0,
                bottom: _showAds ? _heightAds[1] + 10 : 10,
                child: _buildVolumeBtn(
                  Theme.of(context).buttonTheme.height,//0.05 * _sizeCtrlsShortest
                  _sizeCtrlsShortest)
              )
            ]
          ),
          ),
        ]
      );

      if (_showAds)
      {
        return Column(
            children: <Widget>[
              innerUI,
              _buildAds(portrait),
            ]
        );
      }
      else
      {
        return innerUI;
      }
    }
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

    return new MetreWidget(
      update: update,
      beats: _beat.beatCount,
      minBeats: minBeatCount,
      maxBeats: maxBeatCount,
      note: _noteValue,
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
        color: _beat.regular ? _cWhiteColor : _clrIrregularMetre
      ),
      onBeatChanged: _onBeatChanged,
      onNoteChanged: _onNoteChanged,
    );
  }

  ///widget Subbeat
  Widget _buildSubbeat(TextStyle textStyle)
  {
    return Center(child:
      _buildPlate(
      SubbeatWidget(
        subbeatCount: _beat.subBeatCount,
        noteValue: _noteValue,
        color: _textColor,
        textStyle: textStyle,
        size: new Size(0.18 * _sizeCtrls.width, 0.24 * _sizeCtrls.height),
        onChanged: onSubbeatChanged,
      ),
      //padding: const Offset(8, 0),
    ));
  }

  void _changeVolume(double value)
  {
    if (value < 0)
      value = 0;
    if (value > 100)
      value = 100;
    setState(() {
      _mute = value == 0;
      _volume = value;//.round();
    });
    _setVolume(_volume.round());
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
      _setVolume(_volume.round());
    });
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

  Widget _buildPlayBtn(bool portrait)
  {
    return new MaterialButton(
      minWidth: (portrait ? 0.25 : 0.2) * _sizeCtrlsShortest,
      //iconSize: 0.4 * _sizeCtrls.height,
      /*
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(width: 2, color: Colors.purple.withOpacity(0.8)),
      ),
      padding: EdgeInsets.all(8),//_padding.dx),
*/
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      padding: EdgeInsets.all(18),//_padding.dx),
      //child: tempo,
      child: Icon(_playing ? Icons.pause : Icons.play_arrow,
        size: 0.125 * _sizeCtrls.width),
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
        //Icon(Icons.music_note, size: 24, color: _cWhiteColor),
        Text(strScheme,
          style: Theme.of(context).textTheme.headline
            .copyWith(fontWeight: FontWeight.bold, color: Colors.amberAccent), //fontSize: 28
          //          style: Theme.of(context).textTheme.display1
          //            .copyWith(fontWeight: FontWeight.bold, color: _cWhiteColor), //fontSize: 28
        ),
      ]
    );

    final Widget icon1 = new Text(strScheme,
      style: Theme.of(context).textTheme.display1
        .copyWith(fontWeight: FontWeight.bold, color: _cWhiteColor), //fontSize: 28
    );
    final Widget icon2 = new Row(
      children: <Widget>[
        Icon(Icons.music_note, size: 24, color: _cWhiteColor),
        Text(strScheme,
          style: Theme.of(context).textTheme.title//headline
            .copyWith(fontWeight: FontWeight.bold, color: _cWhiteColor), //fontSize: 28
//          style: Theme.of(context).textTheme.display1
//            .copyWith(fontWeight: FontWeight.bold, color: _cWhiteColor), //fontSize: 28
        ),
      ]
    );

//FlatButton
    return new RawMaterialButton(
      //iconSize: 40,
      //minWidth: 40,
      padding: EdgeInsets.all(4),
      //icon: Icon(Icons.check_box_outline_blank,),
      child: imageIndex == 3 ? icon3 : icon,
      //shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      constraints: BoxConstraints(minWidth: sizeButton, minHeight: sizeButton),//36.0
      //textTheme: ButtonTextTheme.primary,
      //textColor: _cWhiteColor,
      //color: _cWhiteColor,
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: !_playing,
      onPressed: () {
        if (_soundSchemes != null && _soundSchemes.length > 0)
        {
          _activeSoundScheme = (_activeSoundScheme + 1) % _soundSchemes.length;
          _setMusicScheme(_activeSoundScheme);
          setState(() {}); //TODO move to _setMusicScheme?
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
      onChanged: _changeVolume,
/*
      onLongPress: () {
        setState(() {
          _mute = !_mute;
        });
      },
*/
      diameter: size,
      height: height,
      color: _cWhiteColor,
      enableFeedback: !_playing,
    );
  }

  ///widget Settings
  Widget _buildSettingsBtn(double size)
  {
    return new IconButton(
      iconSize: size,
      padding: EdgeInsets.all(4),
      icon: Icon(Icons.settings,),
      color: _cWhiteColor.withOpacity(0.8),
      enableFeedback: !_playing,
      onPressed: () {
        _showSettings(context);
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

  ///widget Square section with metronome itself
  Widget _buildOwlenome(bool portrait, Size size)
  {
    ///widget Owls
    final Widget wixOwls = OwlGrid(
      playing: _playing,
      beat: _beat,
      activeBeat: _activeBeat,  //TODO Move to _beat??
      activeSubbeat: _activeSubbeat,
      noteValue: _noteValue,
      accents: _beat.accents,
      //width: _widthSquare,
      //childSize: childSize,
      animationType: _animationType,
      onChanged: onOwlChanged,
      onAccentChanged: onAccentChanged,
/*
      onCountChanged: (int count) {
        if (count > maxBeatCount)
          count = minBeatCount;
        if (count < minBeatCount)
          count = maxBeatCount;
        onMetreChanged(count, _noteValue);
      }
*/
    );

    //VG TODO
    final double paddingX = _beat.beatCount == 3 || _beat.beatCount == 4 ? 10 : 0;
      //0.03 * _widthSquare : 0;
    final double paddingY = _beat.beatCount > 4 ? 0.02 * _sideSquare : 0;

    return Container(
      width: size.width,
      height: size.height,
      padding: portrait ? EdgeInsets.only(bottom: paddingY, left: paddingX, right: paddingX) :
        EdgeInsets.only(bottom: paddingY, left: paddingX, right: paddingX),
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
  Widget _buildBar(bool portrait)
  {
    final double horzSpace = portrait ? 16 : 16;
    List<Widget> children = new List<Widget>();

    double paddingY = portrait ? 0 : 0.1 * _sideSquare;
    double width = portrait ? _sideSquare : _screenSize.width - _sideSquare;

    bool update = _updateMetre;
    _updateMetre = false;

    final MetreWidget metre = new MetreWidget(
      update: update,
      beats: _beat.beatCount,
      minBeats: minBeatCount,
      maxBeats: maxBeatCount,
      note: _noteValue,
      minNote: minNoteValue,
      maxNote: maxNoteValue,
      width: 0.3 * _sizeCtrls.width,
      height: 0.32 * _sizeCtrls.height,
      itemExtent: 44,
      color: Colors.deepPurple,
      textStyle: _textStyle,
      textStyleSelected: _textStyle.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: _textStyle.fontSize + 2,
          height: 1,
          color: _beat.regular ? _cWhiteColor : _clrIrregularMetre
      ),
      onBeatChanged: _onBeatChanged,
      onNoteChanged: _onNoteChanged,
    );

    final NoteTempoWidget noteTempo = new NoteTempoWidget(
      tempo: _tempoBpm,
      noteValue: _noteValue,
      color: Colors.black,
      size: new Size(18, 36),
      textStyle: TextStyle(fontSize: 16, color: Colors.black),
    );

    final Size barSize = Size((portrait ? 0.5 : 0.4) * _sizeCtrls.width, 0.14 * _sizeCtrls.height);
    final Widget accentMetre = new AccentMetreWidget(
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
    );

    ///widget Tempo list
    final Widget listTempo = new Container(
      //color: Colors.orange,
        //width: 80,
        height: 0.12 * _sizeCtrls.height,
        padding: EdgeInsets.only(top: 0.0 * _sizeCtrls.height, bottom: 0.0 * _sizeCtrls.height),
      //padding: EdgeInsets.only(top: 0.025 * _sizeCtrls.height, bottom: 0.025 * _sizeCtrls.height),
      child:
      TempoListWidget(//TODO Limit
        tempo: _tempoBpm,
        width: (portrait ? 0.5 : 0.3) * _sizeCtrls.width,
        textStyle: Theme.of(context).textTheme.display1
          .copyWith(color: Colors.black, fontSize: 0.09 * _sizeCtrls.height, height: 1),//TODO
        onChanged: (int tempo) {
          if (_tempoBpm != tempo)
          {
            _tempoBpm = tempo;
            if (_playing)
              _setTempo(_tempoBpm);
            setState(() {});
          }
        }
      ));

    final Widget btnSubbeat = new SubbeatWidget(
      subbeatCount: _beat.subBeatCount,
      noteValue: _noteValue,
      color: _textColor,
      textStyle: _textStyle,
      size: new Size(0.10 * _sizeCtrls.width, 0.28 * _sizeCtrls.height),
      //size: new Size(0.10 * _sizeCtrls.width, 0.28 * _sizeCtrls.height),
      onChanged: onSubbeatChanged,
    );

    double btnPadding = 0.2 * Theme.of(context).buttonTheme.height;
    //0.02 * _sizeCtrls.width,
    final Size bracketSize = new Size(3.2 * btnPadding, 0.19 * _sizeCtrls.height);
    final Widget barSpacer = new Container(width: btnPadding,);

    if (portrait)
    {
    ///widget Metre row
    final Widget rowBar = new Padding(
      padding: EdgeInsets.zero, //only(top: paddingY, left: _padding.dx, right: _padding.dx),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          barSpacer,
          metre,  ///widget Metre
          barSpacer,

          Flexible(
            //fit: FlexFit.tight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  color: _beat.regular ? _clrRegularBar : _clrIrregularBar,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: btnPadding),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                      //Container(width: 0.02 * _sizeCtrls.width,),
                        BarBracketWidget(
                          direction: BarBracketDirection.left,
                          color: Colors.black,
                          size: bracketSize,
                        ),
                        ///widget Subbeat widget
                        //Flexible(child:
                        Padding(
                          padding: EdgeInsets.only(bottom: 0.05 * _sizeCtrls.height),//20
                          child: accentMetre
                        ),
                        BarBracketWidget(
                          direction: BarBracketDirection.right,
                          color: Colors.black,
                          size: bracketSize
                        ),
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
                      noteTempo,
                      Expanded(child:
  //                        ClipRect(child:
                        listTempo,
                      ),
                    ]
                  ),
                )
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ///widget Metre
          _buildMetre(0.22 * _sizeCtrls.width, 0.32 * _sizeCtrls.height, _textStyle),
          Container(width: btnPadding,),

          Expanded(child:
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
            Container(
            color: _beat.regular ? _clrRegularBar : _clrIrregularBar,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(width: btnPadding,),
                  ///widget Subbeat widget
                  /////TODO !!!
                  //Flexible(child:
                  Padding(
                    padding: EdgeInsets.only(bottom: 0.05 * _sizeCtrls.height),//20
                    child: accentMetre
                  ),
                ]
              ),
            ),

            Row(
              //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  noteTempo,
                  //Expanded(child:
//                        ClipRect(child:
                  //TODO !!! listTempo,
                  //),
                ]
              ),
            ]
          ),
          ),
          //btnSubbeat,
          //listTempo,
          //accentMetre,
          //btnSubbeat,
        ]
      );

      return rowBar;
    }
  }

  // Remaining section with controls
  Widget _layoutControls(BuildContext context, BoxConstraints constraints, bool portrait)
  {
    double minSquare = constraints.maxWidth > constraints.maxHeight ? constraints.maxHeight : constraints.maxWidth;
    print("minSquare");
    print(constraints);

    final TextStyle textStyleTimer = _textStyle.copyWith(fontSize: 20);

    final double horzSpace = portrait ? 16 : 16;
    double paddingY = portrait ? 0 : 0.1 * _sideSquare;
    double width = portrait ? _sideSquare : _screenSize.width - _sideSquare;

    ///widget Tempo list
    final Widget listTempo = new Row(
      mainAxisAlignment: MainAxisAlignment.center,
      //Padding( padding: EdgeInsets.zero, child:
      children: <Widget>[
        //_buildPlate(TempoWidget(
        Padding(
          padding: EdgeInsets.only(top: 0.025 * _sizeCtrls.height, bottom: 0.025 * _sizeCtrls.height),
          child:
          TempoListWidget(//TODO Limit
            tempo: _tempoBpm,
            textStyle: Theme.of(context).textTheme.display1
              .copyWith(color: _cWhiteColor, fontSize: 0.09 * _sizeCtrls.height, height: 1),//TODO
            onChanged: (int tempo) {
              if (_tempoBpm != tempo)
              {
                _tempoBpm = tempo;
                if (_playing)
                  _setTempo(_tempoBpm);
                setState(() {});
              }
            }
          )),
      ]
    );

    final ScrollController scrollCtrl = new FixedExtentScrollController(initialItem: _tempoBpm - minTempo);
    Widget picker = new CupertinoPicker.builder(
      diameterRatio: 1.1,
      backgroundColor: Colors.grey.withOpacity(0),
      //squeeze: 1.9,
      //offAxisFraction: 10,
      //        const double _kDefaultDiameterRatio = 1.07;
      //      const double _kDefaultPerspective = 0.003;
      //      const double _kSqueeze = 1.45;
      useMagnifier: true,
      magnification: 1.5,
      itemExtent: 36,
      scrollController: scrollCtrl,
      onSelectedItemChanged: (int index) {
        _tempoBpm = minTempo + index;
        //_tempoList.setTempo(_tempoBpm);
        if (_playing)
          _setTempo(_tempoBpm);
        else
          setState(() {});
      },
      itemBuilder: (BuildContext context, int index) =>
        Text((index + minTempo).toString(),
          style: TextStyle(color: _cWhiteColor, fontSize: 36, height: 1)
        ),
      childCount: maxTempo - minTempo + 1,
      /*
    this.diameterRatio = _kDefaultDiameterRatio,
    this.backgroundColor = _kDefaultBackground,
    this.offAxisFraction = 0.0,
    this.useMagnifier = false,
    this.magnification = 1.0,
    this.scrollController,
    this.squeeze = _kSqueeze,
    @required this.itemExtent,
    @required this.onSelectedItemChanged,
    @required IndexedWidgetBuilder itemBuilder,
    int childCount,
*/
    );

    Widget wheelTempo =
    new Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x40202020), Colors.deepPurple[600]])
      ),
      width: 0.2 * _sizeCtrls.width, //80,
      height: 0.35 * _sizeCtrls.height, //100,
      child: WheelChooser.integer(
        selectTextStyle: Theme.of(context).textTheme.display1
          .copyWith(color: _cWhiteColor, fontSize: 24, fontWeight: FontWeight.bold, height: 1),
        unSelectTextStyle: Theme.of(context).textTheme.display1
          .copyWith(color: Colors.white70, fontSize: 24, height: 1),
        magnification: 1,
        itemSize: 48,
        //perspective: 0.01,
        //listWidth: 100,
        squeeze: 1,
        horizontal: false,
        minValue: minTempo,
        maxValue: maxTempo,
        initValue: _tempoBpm,
        step: 1,
        onValueChanged: (dynamic value) {
          _tempoBpm = value.round();
          //_tempoList.setTempo(_tempoBpm);
          if (_playing)
            _setTempo(_tempoBpm);
          //else
          setState(() {});
        },
      )
    );

    Widget cupWheelTempo = new SizedBox(
      //fit: BoxFit.fill,
      width: 0.2 * _sizeCtrls.width, //80,
      height: 0.35 * _sizeCtrls.height, //100,
      child: picker,
    );

    /*
    children.add(Row(
      mainAxisAlignment: portrait ?
      MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
      //crossAxisAlignment: CrossAxisAlignment.end,
      //mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        wixKnob
      ]
    ));
*/
    /*
    children.add(Row(
      mainAxisAlignment: portrait ?
      MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
      //crossAxisAlignment: CrossAxisAlignment.end,
      //mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        wixKnob
      ]
    ));
*/
    Widget tempo = Text(_tempoBpm.toString(),
      style: Theme.of(context).textTheme.display3
        .copyWith(
        color: ((_tempoBpm> minTempo)&&(_tempoBpm<_tempoBpmMax))?_cWhiteColor : Colors.amberAccent, //TODO
        fontSize: 0.10 * _sizeCtrls.height,
        height: 1));


    ///widget Tempo knob control
    final Widget knobTempo = new Knob(
      value: _tempoBpm.toDouble(),
      min: minTempo.toDouble(),
      max: maxTempo.toDouble(),
      minAngle: -_cTempoKnobAngle,
      maxAngle: _cTempoKnobAngle,
      turnCount: _cTempoKnobTurns,
      sweepAngle: _cTempoKnobTurns * 360.0 + 2 * _cTempoKnobAngle,
      dialDivisions: 12,
      limit: _tempoBpmMax.toDouble(),
      radiusButton: 0.1,
      radiusDial: 0.8,
      //radius: 0.7 * _sizeCtrlsShortest,
      radius: 0.9 * minSquare,
      debug: false,
      showIcon: false,
      color: _cWhiteColor.withOpacity(0.8),
      textStyle: _textStyle.copyWith(fontSize: 0.2 * _sizeCtrls.height,
        color: Colors.white, height: 1),
      onPressed: () {},//_play,
      onChanged: (double value) {
        _tempoBpm = value.round();
        //_tempoList.setTempo(_tempoBpm);
        if (_playing)
          _setTempo(_tempoBpm);//ToDo: в такой последовательности?
        //else
        setState(() {});
      },
    );

    _knobValue.value = _tempoBpm.toDouble();
    Widget knobTempoNew = new KnobTuned(
      knobValue: _knobValue,
      minValue: minTempo.toDouble(),
      maxValue: _tempoBpmMax.toDouble(),
      sensitivity: _sensitivity,
      onChanged: (KnobValue newVal) {
        _tempoBpm = newVal.value.round();
        _knobValue = newVal;
        if (_playing)
          _setTempo(_tempoBpm);
        setState(() {});
      },
      diameter: 0.65 * _sizeCtrls.height,//0.43
      innerRadius: _innerRadius,
      outerRadius: _outerRadius,
      textStyle: _textStyle.copyWith(fontSize: 0.2 * _sizeCtrls.height, color: Colors.white),
    );

    final Widget btnSubbeat = new SubbeatWidget(
      subbeatCount: _beat.subBeatCount,
      noteValue: _noteValue,
      color: _textColor,
      textStyle: _textStyle,
      size: new Size(0.10 * _sizeCtrls.width, (portrait ? 0.25 : 0.2) * _sizeCtrlsShortest,),
      //size: new Size(0.10 * _sizeCtrls.width, 0.28 * _sizeCtrls.height),
      onChanged: onSubbeatChanged,
    );

    // On app startup: _soundSchemes == null
    final Widget buttonsLeft = new Column(
      //      mainAxisAlignment: portrait ?
      //        MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        btnSubbeat,
        //Container(height: 0.1 * _sizeCtrls.height),
        //_buildVolumeBtn(), //TODO SizedOverflowBox
        Container(
          width: 24,
          height: 0.2 * _sizeCtrls.height,
        ),
      ]
    );

    final Widget buttonsRight = new Column(
      //      mainAxisAlignment: portrait ?
      //        MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          _buildPlayBtn(portrait),
          //Container(height: 0.1 * _sizeCtrls.height),
          Wrap(
            children: <Widget>[
              _buildSoundBtn(Theme.of(context).buttonTheme.height),
              _buildSettingsBtn(Theme.of(context).buttonTheme.height),
            ]
          ),
          //_buildVolumeBtn(), //TODO SizedOverflowBox
          //_buildSettingsBtn(),
/*
          Container(
            width: 24,
            height: 0.2 * _sizeCtrls.height,
          ),
*/
        ]
    );

    final Widget stack = new Stack(
      alignment: Alignment.bottomCenter,
      //fit: StackFit.passthrough,
      children: <Widget>[
        Column(
          children: <Widget>[
            //rowMetre,

            Stack(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    //rowTempo,
                    //wixTempoWheel,
                    //wixKnob,
                  ]
                ),
                //rowButtons,
                /*
                    Positioned(
                      right: 0,
                      width: 0.5 * _sizeCtrls.width,
                      child: listTempo
                    ),
*/
              ]),
          ]
        ),
        //rowButtons,
      ]
    );

    final Widget rowButtons = new Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        buttonsLeft,
        (_useNewKnob ? knobTempoNew : knobTempo),
        //Container(width: 0.0 * _sizeCtrls.width,),
        buttonsRight,
      ]
    );

    double btnPadding = 0.2 * Theme.of(context).buttonTheme.height;

    // Fill up the remaining screen as the last widget in column/row
    return Stack(
      children: <Widget>[
        Positioned(
          left: btnPadding,
          top: btnPadding,
          child: btnSubbeat,
        ),
        Positioned(
          bottom: 10,
          left: 0,
          child:
            Container(
              width: 88,
              height: Theme.of(context).buttonTheme.height,
            ),
        ),
        Center(
          child: (_useNewKnob ? knobTempoNew : knobTempo),
        ),
        Positioned(
          right: btnPadding,
          top: btnPadding,
          child: _buildPlayBtn(portrait),
        ),
        Positioned(
          right: btnPadding,
          bottom: btnPadding,
          child: Row(
            children: <Widget>[
              _buildSoundBtn(Theme.of(context).buttonTheme.height),
              Container(width: btnPadding),
              _buildSettingsBtn(Theme.of(context).buttonTheme.height),
            ]
          ),
        ),
      ]
    );
  }

  Widget _buildControls(bool portrait)
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
            return _layoutControls(context, constraints, portrait);
          },
        ),
      //child: rowButtons
    );
  }

  /// <<<<<<<< Widget section
  /// /////////////////////////////////////////////////////////////////////////
  /// Flutter-Java inter operation
  ///

  Future<dynamic> _handleMsg(MethodCall call) async
  {
    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);

    if  (call.method == 'warm')
    {
      debugPrint('START-STABLE');
      //int warmupFrames = call.arguments;
      int initTime=call.arguments;
      debugPrint('Time in Flutter of stable time (mcs) $initTime');
      state.startAfterWarm(initTime,_tempoBpm);
      _start();
    }
    else if (call.method == 'Cauchy') {
      //IS:Устанавливаем время начала первого бипа и темп
      int bpmToSet = call.arguments['bpm'];
      int timeOfAFirstToSet = call.arguments['nt']; //новое время
      int newSpeedStarts = call.arguments['dt']; //время, когда менять время
      state.sync(timeOfAFirstToSet, bpmToSet, newSpeedStarts);

      /*
      //test:
      int timeNow = DateTime
          .now()
          .microsecondsSinceEpoch;
      int timeNowRem = timeNow % 1000000000;

      int dtime = (timeNow - timeOfAFirstToSet) ~/ 1000;
       */

      //debugPrint('MsgTest:  BPM in Flutter $bpmToSet\n');
      //debugPrint('MsgTest:  Time now mCs mod 10^9  in Flutter $timeNowRem');
      //debugPrint('MsgTest:  d-from-frst in Flutter $dtime\n');

      /*int newBPMMax=call.arguments['maxBpm'];
      if (_tempoBpmMax!=newBPMMax) {
        setState(() { _tempoBpmMax = newBPMMax; });
        /*
        _tempoBpmMax = newBPMMax;
        setState(() {}); //IS: VS, Витя, это правильно так делать?
         */
      }*/
    }
    /*
    else if (call.method == 'sync')
    {
      int index = call.arguments['index'];
      int beatIndex = call.arguments['beat'];
      int subbeatIndex = call.arguments['sub'];
      int offset = call.arguments['offset'];
      int cycle = call.arguments['cycle'];
      int time = call.arguments['time'];

      //debugPrint('SYNC $index - $offset - $time');

      //warmupFrames = call.arguments;
      //state.sync(index, 1e-6 * offset, beatIndex, subbeatIndex, time);
    }*/
    /*IS: Obsolete:
    else if (call.method == 'timeFrame')
    {
      int beatOrder = call.arguments['index'];
      int offset = call.arguments['offset'];
      int cycle = call.arguments['cycle'];

      List<int> pair = _beat.beatPair(beatOrder);

      //beatOrder += _timeTick;
      //_activeBeat =  beatOrder ~/ _subBeatCount;
      if (_beat.beatCount == 1 && _beat.subBeatCount == 1)
        //_activeBeat %= 2;
        _activeBeat = (_activeBeat + 1) % 2;
      else
        _activeBeat = pair[0];
      _activeSubbeat = pair[1];

      //_timeTick++;

      //debugPrint('NOTECOUNT $beatOrder - $offset - $cycle - $_timeTick - $_activeBeat - $_activeSubbeat');
      //state.setActiveState(_activeBeat, _activeSubbeat);
      redraw = true;
    }*/
    return new Future.value('');
  }

  Future<void> _togglePlay() async
  {
    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    //state.setTempo(_tempoBpm/*, _noteValue*/);

    //List<BipAndPause> bipsAndPauses = new List<BipAndPause>();
    try
    {
      final Map<String, int> args =
      <String, int>{
        'tempo': _tempoBpm,
        'screen': _screenOn ? 1 : 0,
        //'note': _beat.beatCount,//_noteValue,//IS: VS, Полагаю, beatCount тут - опечатка. В любом случае, это больше не нужно.
        //'quorta': _quortaInMSec.toInt(),
        'numerator': _beat.beatCount,
      };
      final int res =  await _channel.invokeMethod('start', args);
      if (res == 0)
      {
        _infoMsg = 'Failed starting/stopping';
        debugPrint(_infoMsg);
      }
      else
      {
        setState(() {
          state.reset();//IS: TEST
          //_tempoBpm = realTempo;
        });
      }
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed to start playing';
    }
  }

  /// Send beat music to Java sound player and state.beatMetre
  Future<void> _setBeat() async
  {
    MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    /*
    state.melody = new AccentBeat(nativeSampleRate, _quortaInMSec,
      _beat,
      0.001 * _soundConfig.beatFreq, _soundConfig.beatDuration,
      0.001 * _soundConfig.accentFreq, _soundConfig.accentDuration,
      _bars, 1);
     */
    state.beatMetre = _beat;

    //Tempo tempo = new Tempo(beatsPerMinute: _subBeatCount * _tempoBpm.toInt(), denominator: _noteValue);
    //List<BipAndPause> bipsAndPauses = new List<BipAndPause>();
    try
    {
      //IS:
      final List<int> config = [
        _beat.beatCount,
        _beat.subBeatCount,
        _activeSoundScheme,
        _tempoBpm,
        _beat.beatCount,//_noteValue
//        _soundConfig.beatFreq,
//        _soundConfig.beatDuration,
//        _soundConfig.accentFreq,
//        _soundConfig.accentDuration,
//        _bars,
//        _beat.beatCount,
//        _quortaInMSec.toInt(),
      ];

      final Map<String, List<int>> args = <String, List<int>>{
        'config': config,
        'subBeats': _beat.subBeats,
        'accents': Prosody.reverseAccents(_beat.accents),
      };

      final int limitTempo = await _channel.invokeMethod('setBeat', args);

      if (limitTempo == 0)
      {
        _infoMsg = 'Failed setting beat';
        debugPrint(_infoMsg);
      }
      else if (limitTempo == -1){
        // - это значит что мы первый раз посылали beat,
        //и схема (нужная для получения скорости, для которой нужен beat) еще не определена.
      }
      else
      {
        onMaxTempoRecieved(limitTempo);
      }
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed setting beat';
    }
  }

  ///Рутина, которую нужно проделать при получении нового максимально темпа
  void onMaxTempoRecieved(int limitTempo)
  {
    if (limitTempo > maxTempo)
      limitTempo = maxTempo;
    //TODO IS (Elsa): what if limitTempo<minTempo?
    if (limitTempo < minTempo)
      limitTempo = minTempo;
    if (limitTempo != _tempoBpmMax)
      setState(() {
        _tempoBpmMax = limitTempo;
        if (_tempoBpm > _tempoBpmMax)
          _tempoBpm = _tempoBpmMax;
      });
  }

  /// Send music tempo to Java sound player
  Future<void> _setTempo(int tempo) async
  {
    // MetronomeState state = Provider.of<MetronomeState>(context, listen: false);
    //state.setTempo(_tempoBpm/*, _noteValue*/);//IS: Почему сначала меняется tempo у состояния?

    //В любом случае, новый темп для анимации устанавливать рано -
    //Ява начнет играть с данным темпом не сразу.
    //Есом мы раньше явы поменяем BPM в state,
    //и, кроме того, не учтем, что изменилось время начального бипа
    //(то, которое мы бы имели, играя с данным темпом),
    //то у нас разойдутся звук и анимация
    //("путешествия в прошлое").
    try
    {
      final Map<String, int> args =
      <String, int>{
        'tempo' : _tempoBpm,
        //'note' : _beat.beatCount,//_noteValue IS: Это ява не использует.
      };
      //Нам не нужно ниже переопределять мак. темп,
      //ява сама пришлёт, когда установит
      //_channel.invokeMethod('setTempo', args);

      final int res = await _channel.invokeMethod('setTempo', args);
      //assert(result == 1);
      if (res == 0)
      {
        _infoMsg = 'Failed setting tempo';
        debugPrint(_infoMsg);
      }
      else
      { //темп придёт позже, когда ява узнает время его начала
        /*
        setState(() {
          /*_tempoBpmMax = limitTempo;
          if (_tempoBpm > _tempoBpmMax)
            _tempoBpm = _tempoBpmMax;*/
        });*/
      }
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed setting tempo';
    }
    //metroAudio.reSetTempo(progress + minimal_tempoBpm);
    //tempo.beatsPerMinute = BPMfromSeekBar;
    //realBPM = singSingSing.setTempo(tempo);

    //barrelOrgan.reSetAngles(cycle);
    //this.bipPauseCycle=cycle;
    //setAngles();

    /*
    if (_mode)
      barrelOrgan?.setTempo(i_tempoBpm, _noteValue);
    else
    {
      if (melody != null)
      {
        int realBpM = melody.cycle.setTempo(tempo, _bars);
        double dur = melody.cycle.tempoToCycleDuration(
          tempo, _bars, nativeSampleRate);
        //metronome1?.setCycle(melody.cycle, latency);
        metronome1?.setTempo(_tempoBpm, nativeSampleRate, _noteValue, dur);
      }
    }
     */
  }

  /// Send music volume to Java sound player
  Future<void> _setVolume(int volume) async
  {
    try
    {
      final int result = await _channel.invokeMethod('setVolume', {'volume' : volume});
      //assert(result == 1);
      if (result != 1)
      {
        _infoMsg = 'Failed setting volume';
        debugPrint(_infoMsg);
      }
    } on PlatformException {
      _infoMsg = 'Exception: Failed setting volume';
    }
  }

  /// Send sound scheme number to Java sound player
  Future<void> _setMusicScheme(int musicScheme) async
  {
    try
    {
      final int limitTempo = await _channel.invokeMethod('setScheme', {'scheme': musicScheme});
      if (limitTempo <=0) {
        _infoMsg = 'Failed setting  music scheme, lay-la,la-la-la-lay-lay-la-la-la...';
        debugPrint(_infoMsg);
      }
      else
      {
//        debugPrint('###############_setMusicSchemes_SetMusicSchemes');
//        debugPrint('${_activeSoundScheme} - ${_soundSchemes.length}');

        onMaxTempoRecieved(limitTempo);
        /*
        setState(() {
          _tempoBpmMax = limitTempo;
          if (_tempoBpm > _tempoBpmMax)
            _tempoBpm = _tempoBpmMax;
        });*/
      }
    } on PlatformException {
      _infoMsg = 'Exception: Failed setting  music scheme';
    }
  }

  Future<void> _getMusicSchemes() async
  {
    try
    {
      List<dynamic> result = await _channel.invokeMethod('getSchemes');
//      debugPrint('??????????????_getMusicSchemes_getMusicSchemes');
//      debugPrint('${result.length} - ${_soundSchemes.length}');
      if (result.length > 0)
      {
        _soundSchemes = new List<String>();
        for (int i = 0; i < result.length; i++)
          _soundSchemes.add(result[i]);

        bool doSet = _activeSoundScheme < 0;  // 1st run on app startup
        if (_activeSoundScheme >= _soundSchemes.length)
          _activeSoundScheme = 0;

//TODO Need at 1st ? No, Include to getSchemes call
        // if (doSet)
//          _setMusicScheme(_activeSoundScheme);
      }
      else
        debugPrint('Error: Sound scheme not found');
    } on PlatformException {
      _infoMsg = 'Exception: Failed getting music schemes';
    }
  }

  /*
  Future<void> _getAudioParams() async {
    try {
      final Map<String, dynamic> result =
          await _channel.invokeMapMethod('getAudioParams');
      if (result != null) {
        nativeSampleRate = result['nativeSampleRate'];
        nativeBuffer = result['nativeBuffer'];
        latencyUntested = result['latencyUntested'];
        _infoMsg = 'Native audio params: $nativeSampleRate - $nativeBuffer - $latencyUntested';
      }
      else
        _infoMsg = 'Failed to get audio params';
    }
    on PlatformException
    {
      _infoMsg = 'Failed to get audio params';
    }

    debugPrint(_infoMsg);
    setState(() {});  // Update UI
  }*/

  // Settings boilerplate
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
        _setMusicScheme(_activeSoundScheme);//TODO move to _setMusicScheme?
      }
      setState(() {
        _animationType = res.animationType;
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
}
