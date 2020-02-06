import 'dart:async';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:owlenome/accent_metre_ui.dart';
import 'package:owlenome/prosody.dart';
import 'package:provider/provider.dart';
import 'package:wheel_chooser/wheel_chooser.dart';
import 'package:device_preview/device_preview.dart';
//import 'package:flutter_xlider/flutter_xlider.dart';

import 'arrow.dart';
import 'metronome_state.dart';
import 'beat_metre.dart';
import 'beat_sound.dart';
import 'owl_grid.dart';
import 'metre_ui.dart';
import 'subbeat_ui.dart';
import 'tempo_ui.dart';
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

final bool usePlayButton = true;
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
  static const int minBeatCount = 2;
  static const int maxBeatCount = 12;
  static const int maxSubBeatCount = 8;
  static const int minNoteValue = 2;

  static const int maxNoteValue = 16;
  static const int minTempo = 1;
  ///Некий абсолютный максимум скорости. Больше него не ставим, даже если
  /// позволяет сочетание схемы и метра.
  static const int maxTempo = 500; //5000

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
  ///<<<<<< JG!

  /// Overall screen size
  Size _screenSize;
  /// Size of square owl's area
  double _sideSquare;
  double _squareX = 1.0;
  double _squareY = 0.85;
  Size _sizeCtrls;

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
  int _tempoBpm = 121;//121 - идеально для долгого теста, показывает, правильно ли ловит микросекунды
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
  double _innerRadius = 0.1;  //VG ??
  double _outerRadius = 2;
  //double _knobSize = 150;
  static const double initKnobAngle = 0;

  KnobValue _knobValue;

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

  void onMetreChanged(int beats, int note)
  {
    if (_beat.beatCount != beats)
    {
      _beat.beatCount = beats;
      //TODO Provider.of<MetronomeState>(context, listen: false).reset();
      _setBeat();
    }
    _noteValue = note;  // Does not affect sound
    setState(() {});
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
    MediaQueryData mediaQueryData = MediaQuery.of(context);
    _screenSize = mediaQueryData.size;
    _sideSquare = _screenSize.width > _screenSize.height ? _screenSize.height : _screenSize.width;

    if (_screenSize.width > _screenSize.height)
      _sizeCtrls = new Size(_screenSize.width - _sideSquare, _screenSize.height);
    else
      _sizeCtrls = new Size(_screenSize.width, _screenSize.height - _sideSquare);
    debugPrint('screenSize $_screenSize - ${mediaQueryData.devicePixelRatio}');

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
          builder: (context, orientation) {
            final bool portrait = orientation == Orientation.portrait;

            /// Owl square and controls
            final List<Widget> innerUI = <Widget>[
              _buildOwlenome(portrait, false),
              _buildBar(portrait),
              _buildControls(portrait),
            ];

            if (_showAds && portrait)
            {
              innerUI.add(_buildAds(portrait));
            }

            return portrait ?
              // Vertical/portrait
              Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('images/Backg-1.jpg'),
                    fit: BoxFit.cover,
                  )
                ),
                child:
              Column(children: innerUI,
                mainAxisAlignment: MainAxisAlignment.start)
              )
              :
              // Horizontal/landscape
              Row(children: innerUI,
                mainAxisAlignment: MainAxisAlignment.start);
          }
        )
      ),
    );
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
  Widget _buildMetre(TextStyle textStyle)
  {
    int noteValuePos = 0;
    for (int noteValue = _noteValue; noteValue > 2; noteValue ~/= 2)
      noteValuePos++;
    print('noteValuePos');
    print(noteValuePos);

    return //_buildPlate(
      Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Colors.white70, Colors.white70])
            ),
            width: 0.22 * _sizeCtrls.width,
            height: 0.16 * _sizeCtrls.height,
            child: WheelChooser.integer(
            selectTextStyle: Theme.of(context).textTheme.headline
              .copyWith(color: _cWhiteColor, fontWeight: FontWeight.bold, height: 1),//20
            unSelectTextStyle: Theme.of(context).textTheme.subhead
              .copyWith(color: Colors.white, height: 1),//16
            magnification: 1,
            //itemSize: 48,
            //perspective: 0.01,
            //listWidth: 100,
            squeeze: 1.6,
            horizontal: true,
            minValue: minBeatCount,
            maxValue: maxBeatCount,
            initValue: _beat.beatCount,
            //start: _beat.beatCount - ,
            step: 1,
            onValueChanged: (dynamic value) {
              int beats = value;
              if (_beat.beatCount != beats)
              {
                _beat.beatCount = beats;
                //_activeBeat %= _beat.beatCount;
                _activeBeat = _activeSubbeat = 0;
                //TODO Provider.of<MetronomeState>(context, listen: false).reset();
                //TODO if (_playing)
                  _setBeat();
                setState(() {});
              }
            },
          ),
        ),

      Container(
        //width: 0.3 * _sizeCtrls.height,
        height: 4,
      ),

      Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.white70, Colors.white70])
        ),
        width: 0.22 * _sizeCtrls.width,
        height: 0.16 * _sizeCtrls.height,
        child: WheelChooser(
          selectTextStyle: Theme.of(context).textTheme.headline
            .copyWith(color: _cWhiteColor, fontWeight: FontWeight.bold, height: 1),//16
          unSelectTextStyle: Theme.of(context).textTheme.subhead
            .copyWith(color: Colors.white70, height: 1),//16
          magnification: 1,
          //itemSize: 48,
          //perspective: 0.01,
          //listWidth: 100,
          squeeze: 1.6,
          horizontal: true,
          datas: ['2', '4', '8', '16'],
          startPosition: noteValuePos,
          onValueChanged: (dynamic value) {
            String sNote = value;
            int note = int.parse(sNote);
            if (_noteValue != note)
            {
              _noteValue = note;
              if (_playing)
                _setTempo(note);
              else //ToDo: нужно поменять ноты в строке размере
                setState(() {});
            }
          },
        ),
      ),
      ]
    );

    return _buildPlate(
      MetreWidget(
        beats: _beat.beatCount,
        minBeats: minBeatCount,
        maxBeats: maxBeatCount,
        note: _noteValue,
        minNote: minNoteValue,
        maxNote: maxNoteValue,
        color: _primaryColor,
        textStyle: textStyle,
        onChanged: onMetreChanged
      )
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

  Widget _buildPlayBtn()
  {
    return new MaterialButton(
      minWidth: 0.25 * _sizeCtrls.width,
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

  Widget _buildSoundBtn()
  {
    final String strScheme = _soundSchemes != null && _activeSoundScheme < _soundSchemes.length ?
      _soundSchemes[_activeSoundScheme] : '';

    return new MaterialButton(
      //iconSize: 40,
      padding: EdgeInsets.all(0),
      //icon: Icon(Icons.check_box_outline_blank,),
      child: Text((_activeSoundScheme + 1).toString(),
        style: Theme.of(context).textTheme.display1
          .copyWith(fontWeight: FontWeight.bold, color: _cWhiteColor),
        //                TextStyle(fontSize: 28,
        //                  fontWeight: FontWeight.bold,
        //                  color: _cWhiteColor
        //                )
      ),
      shape: CircleBorder(side: BorderSide(width: 2, color: _cWhiteColor)),
      //padding: EdgeInsets.all(0),
      textTheme: ButtonTextTheme.primary,
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

  Widget _buildVolumeBtn()
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
      radius: 0.08 * _sizeCtrls.height,
      height: 0.85 * _sizeCtrls.height,
      color: _cWhiteColor,
      enableFeedback: !_playing,
    );
  }

  ///widget Settings
  Widget _buildSettingsBtn()
  {
    return new IconButton(
      iconSize: 0.14 * _sizeCtrls.height,
      padding: EdgeInsets.all(0),
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
      height: portrait ? 50 : 32,
      color: Colors.grey[400],
      child: Image.asset('images/Ad-1.png',
        //height: portrait ? 50 : 32,
        fit: BoxFit.contain
      ),
    );
  }

  ///widget Square section with metronome itself
  Widget _buildOwlenome(bool portrait, bool showControls)
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
      onCountChanged: (int count) {
        if (count > maxBeatCount)
          count = minBeatCount;
        if (count < minBeatCount)
          count = maxBeatCount;
        onMetreChanged(count, _noteValue);
      }
    );

    //VG TODO
    final double paddingX = _beat.beatCount == 3 || _beat.beatCount == 4 ? 10 : 0;
      //0.03 * _widthSquare : 0;
    final double paddingY = 0;//_beat.beatCount > 4 ? 0.05 * _widthSquare : 0;

    return Container(
      width: _squareX * _sideSquare,
      height: _squareY * _sideSquare,
      padding: portrait ? EdgeInsets.only(top: paddingY, left: paddingX, right: paddingX) :
        EdgeInsets.only(top: paddingY, left: paddingX, right: paddingX),
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

    final NoteTempoWidget noteTempo = new NoteTempoWidget(
      tempo: _tempoBpm,
      noteValue: _noteValue,
      color: Colors.black,
      size: new Size(18, 36),
      textStyle: TextStyle(fontSize: 16, color: Colors.black),
    );

    ///widget Tempo list
    final Widget listTempo = new Padding(
      padding: EdgeInsets.only(top: 0.0 * _sizeCtrls.height, bottom: 0.0 * _sizeCtrls.height),
      //padding: EdgeInsets.only(top: 0.025 * _sizeCtrls.height, bottom: 0.025 * _sizeCtrls.height),
      child:
      TempoWidget(//TODO Limit
        tempo: _tempoBpm,
        textStyle: Theme.of(context).textTheme.display1
          .copyWith(color: Colors.black, fontSize: 0.09 * _sizeCtrls.height, height: 1),//TODO
        onChanged: (int tempo) {
          if (_tempoBpm != tempo)
          {
            _tempoBpm = tempo;
            if (_playing)
              _setTempo(tempo);
            setState(() {});
          }
        }
      ));

    ///widget Metre row
    final Widget rowBar = new Padding(
      padding: EdgeInsets.zero, //only(top: paddingY, left: _padding.dx, right: _padding.dx),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(width: 0.05 * _sizeCtrls.width,),

          ///widget Metre
          _buildMetre(_textStyle),
/*
          SizedBox(
            width: 0.3 * (_sizeCtrls.width - 2 * _padding.dx),
            child: _buildMetre(_textStyle)
          ),
*/
          Container(width: 0.02 * _sizeCtrls.width,),

          Flexible(child:
            Container(
              color: Colors.white70,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
/*
          SizedBox(
            width: 0.02 * _sizeCtrls.width,//10
            height: 0.14 * _sizeCtrls.height,
            child:
            ArrowWidget(direction: ArrowDirection.left,
              color: Colors.white.withOpacity(0.8),
              //color: Colors.deepPurpleAccent.withOpacity(0.75),
            ),
          ),
*/
          ///widget Subbeat widget
          //Flexible(child:
            Padding(
              padding: EdgeInsets.only(bottom: 0.05 * _sizeCtrls.height),//20
              child:
              AccentMetreWidget(
                beats: _beat.beatCount,
                noteValue: _noteValue,
                accents: _beat.accents,
                pivoVodochka: _beat.pivoVodochka, //?
                size: Size(0.5 * _sizeCtrls.width, 0.15 * _sizeCtrls.height),
                onChanged: onMetreChanged,
                onOptionChanged: (bool pivoVodochka) {
                  _beat.pivoVodochka = pivoVodochka;
                  setState(() {});
                },
              ),
            ),
                    ]),
/*
          SizedBox(
            width: 0.02 * _sizeCtrls.width,
            height: 0.14 * _sizeCtrls.height,
            child:
            ArrowWidget(direction: ArrowDirection.right,
              color: Colors.white.withOpacity(0.8),
              //color: Colors.deepPurpleAccent.withOpacity(0.75),
            ),
          ),
*/
                  Row(
                    //mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      noteTempo,
                      Expanded(child:
                        listTempo,
                      ),
                    ]
                  ),
                ]),
              )
            ),

            SubbeatWidget(
              subbeatCount: _beat.subBeatCount,
              noteValue: _noteValue,
              color: _textColor,
              textStyle: _textStyle,
              size: new Size(0.15 * _sizeCtrls.width, 0.3 * _sizeCtrls.height),
              onChanged: onSubbeatChanged,
            ),

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
          //)
        ])
      );

    return rowBar;
  }

  // Remaining section with controls
  Widget _buildControls(bool portrait)
  {
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
          TempoWidget(//TODO Limit
            tempo: _tempoBpm,
            textStyle: Theme.of(context).textTheme.display1
              .copyWith(color: _cWhiteColor, fontSize: 0.09 * _sizeCtrls.height, height: 1),//TODO
            onChanged: (int tempo) {
              if (_tempoBpm != tempo)
              {
                _tempoBpm = tempo;
                if (_playing)
                  _setTempo(tempo);
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
      scaleCount: 12,
      limit: _tempoBpmMax.toDouble(),
      buttonRadius: 0.1,
      outerRadius: 0.8,
      size: 0.65 * _sizeCtrls.height,
      debug: true,
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

    Widget btnPlay = _buildPlayBtn();

    // On app startup: _soundSchemes == null
    final Widget buttons = new Column(
      //      mainAxisAlignment: portrait ?
      //        MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
      //mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _buildSoundBtn(),
        //Container(height: 0.1 * _sizeCtrls.height),
        _buildVolumeBtn(),
        _buildSettingsBtn(),
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
        buttons,
        (_useNewKnob ? knobTempoNew : knobTempo),
        //Container(width: 0.0 * _sizeCtrls.width,),
        btnPlay,
      ]
    );

    // Fill up the remaining screen as the last widget in column/row
    return Expanded(
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
      child: rowButtons
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
      soundScheme: _activeSoundScheme,
      useKnob: _useNewKnob,
    );

    final Settings res = await Navigator.push(context,
      MaterialPageRoute(builder: (context) => SettingsWidget(
        animationType: _animationType,
        useKnob: _useNewKnob,
        settings: settings)));
    //Navigator.of(context).push(_createSettings());
      setState(() {
        if (res != null)
        {
          _animationType = res.animationType;
          _useNewKnob = res.useKnob;
        }
      });
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
