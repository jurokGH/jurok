import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'metronome_state.dart';
import 'beat_metre.dart';
import 'owl_grid.dart';
import 'knob.dart';
import 'metre_ui.dart';
import 'subbeat_ui.dart';
import 'tempo_ui.dart';
import 'timer_ui.dart';
import 'settings.dart';
import 'Melody.dart';
import 'BipPauseCycle.dart';
import 'AccentBeat.dart';

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
final Color _cTextColor = Colors.black;
/// UI Controls color and opacity
final Color _cCtrlColor = Colors.grey;
final double _cCtrlOpacity = 0;
///<<<<<< JG!

final String _cAppName = "Owlenome";
final String _cAppTitle = "Owlenome";

void main()
{
  return runApp(ChangeNotifierProvider(
      create: (_) => new MetronomeState(), child: App()));
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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
  static const int initBeatCount = 4;
  static const int minBeatCount = 2;
  static const int maxBeatCount = 12;
  static const int maxSubBeatCount = 8;
  static const int minNoteValue = 2;
  static const int maxNoteValue = 32;
  static const int minTempo = 6;
  static const int maxTempo = 250; //ToDo: ask Java what is maximal speed according to the music scheme

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

  /// Controls border parameters
  double _borderRadius = 12;
  double _borderWidth = 3;
  /// Controls opacity
  double _opacity = _cCtrlOpacity;  // Control's opacity
  /// Standart padding
  Offset _padding = new Offset(4, 4);//Size(24, 36);
  ///<<<<<< JG!

  /// Size of square owl's area
  double _widthSquare;
  /// Overall screen size
  Size _screenSize;

  BeatMetre _beat = new BeatMetre();
  BeatSound _soundConfig = new BeatSound();

  // Metre denominator
  int _noteValue = 4;
  //int _beatCount = 4;  // _metreBeats
  //int _subBeatCount = 1;
  /// Current playing beat
  int _activeBeat = 0;
  /// Current playing subbeat of current beat
  int _activeSubbeat = 0;
  /// Melody parameters
  double _quortaInMSec = 20;
  int _bars = 1;
  //int _numerator = 1;

  int _volume = 50;
  bool _mute = false;
  int _tempoBpm = 60;
  //MelodyMeter _melodyMeter;
  int _counter = 0;

  // Native hardware audio parameters
  int nativeSampleRate = 0;
  int nativeBuffer = 0;
  int latencyUntested = 0;

  int latency = 0;
  int warmupFrames = 0;
  String _infoMsg = '';

  Melody melody;
  //BipPauseCycle bipPauseCycle;

  /// Пение рокочущих сов
  /// Сколько схем:
  ///ToDo: Сколько всего их, какие у них имена, иконки и может что еще -
  ///как мы это согласовываем? Пока - руками.
  final int _soundSchemeCount = 4;
  int _activeSoundScheme = 0;

  // true - redraw UI with Flutter's AnimationController at 60 fps
  bool animate60fps = true;
  bool redraw = false;
  AnimationController _controller;
  int _period = 60000;
  bool _playing;

  int _timeTick = 0;
  double prevTime = 0;

  @override
  void initState() {
    super.initState();

    // Channel callback from hardware Java code
    _channel.setMethodCallHandler(_handleMsg);
    // Query native hardware audio parameters
    _getAudioParams();

    _controller = new AnimationController(
      vsync: this,
      duration: new Duration(milliseconds: _period),
    );
    /*
    ..addListener(() {
      if (redraw)
        //setState((){
          redraw = false;
          //_time = _controller.value;
        //});
    });
*/

    _beat.beatCount = initBeatCount;

    _playing = false;
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

  void _play()
  {
    if (_playing)
    {
      _togglePlay();
      //_playing = !_playing;
      _playing = false;
      if (animate60fps)
        _controller.stop();
      /// Stops OwlGridState::AnimationController
      setState(() {});
    }
    else
    {
      prevTime = 0;
      _timeTick = 0;
      //TODO _timer.reset();

      _setBeat();
      _togglePlay();
    }
/*
    _playing = !_playing;
    if (_playing)
      _controller.repeat();
    else
      _controller.stop();
*/
  }

  // Start graphics animation
  void _start(int param)
  {
    /*
    if (_mode)
      barrelOrgan?.play();
    else
      ;//metronome1?.play();
     */

    if (animate60fps)
    {
      DateTime.now();

      _controller.reset();
      _controller.forward();
    }
    _playing = true;
    setState(() {});
    //_knob.pressed = true;
  }

  void onMetreChanged(int beats, int note)
  {
    if (_beat.beatCount != beats)
    {
      _beat.beatCount = beats;
      //_activeBeat %= _beat.beatCount;
      _activeBeat = _activeSubbeat = 0;
      Provider.of<MetronomeState>(context, listen: false).reset();
      if (_playing)
        _setBeat();
    }
    if (_noteValue != note)
    {
      _noteValue = note;
      if (_playing)
        _setTempo(0);
    }
    setState(() {});
  }

  void onSubbeatChanged(int subbeatCount)
  {
    //_beat.subBeatCount = _beat.subBeatCount < maxSubBeatCount ? _beat.subBeatCount + 1 : 1;
    _beat.subBeatCount = subbeatCount;//nextSubbeat(_beat.subBeatCount);
    _activeBeat = _activeSubbeat = 0;
    Provider.of<MetronomeState>(context, listen: false).reset();
    if (_playing)
      _setBeat();
    setState(() {});
  }

  void onOwlChanged(int id, int subCount)
  {
    assert(id < _beat.subBeats.length);
    //TODO
    _beat.subBeats[id] = subCount;
    _activeBeat = _activeSubbeat = 0;
    Provider.of<MetronomeState>(context, listen: false).reset();
    if (_playing)
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
    _widthSquare = _screenSize.width > _screenSize.height ? _screenSize.height : _screenSize.width;
    print('screenSize $_screenSize - ${mediaQueryData.devicePixelRatio}');

    if (_textStyle == null)
      _textStyle = Theme.of(context).textTheme.display1
        .copyWith(color: _textColor, fontSize: _textSize, height: 1);

    return Scaffold(
      key: _scaffoldKey,  // for showSnackBar to run
      backgroundColor: Color.fromARGB(0xFF, 0x45, 0x1A, 0x24),  //TODO: need?
      //appBar: AppBar(title: Text(widget.title),),
      body: Center(
        child: OrientationBuilder(
          builder: (context, orientation) {
            bool portrait = orientation == Orientation.portrait;

            /// Owl square and controls
            List<Widget> innerUI = <Widget>[
              _buildOwlenome(portrait, false),
              _buildControls(portrait, false)
            ];

            return portrait ?
              // Vertical/portrait
              Column(children: innerUI,
                mainAxisAlignment: MainAxisAlignment.start) :
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
    return _buildPlate(
      MetreWidget(
        beats: _beat.beatCount,
        minBeats: minBeatCount,
        maxBeats: maxBeatCount,
        note: _noteValue,
        minNote: minNoteValue,
        maxNote: maxNoteValue,
        color: _textColor,
        textStyle: textStyle,
        onChanged: onMetreChanged
      )
    );
  }

  ///widget Subbeat
  Widget _buildSubbeat(TextStyle textStyle)
  {
    return _buildPlate(
      SubbeatWidget(
        subbeatCount: _beat.subBeatCount,
        noteValue: _noteValue,
        color: _textColor,
        textStyle: textStyle,
        onChanged: onSubbeatChanged,
      ),
    );
  }

  ///widget Volume
  Widget _builVolume()
  {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          _volume.toString(),
          style: _textStyle,
        ),
        ///widget Volume slider
        Slider(
          min: 0.0,
          max: 100.0,
          value: _volume.toDouble(),
          onChanged: (double value) {
            setState(() {
              _volume = value.round();
              _mute = _volume == 0;
              _setVolume(_volume);
            });
          }
        ),
        ///widget Mute button
        Container(
          decoration: BoxDecoration(
            color: _ctrlColor.withOpacity(_opacity),
            //shape: BoxShape.circle,
            border: Border.all(color: _accentColor.withOpacity(_opacity), width: _borderWidth),
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          //margin: EdgeInsets.all(16),
          child: IconButton(
            iconSize: 24,
            padding: const EdgeInsets.all(0),
            icon: Icon(
              _mute ? Icons.volume_mute : Icons.volume_up,
              //size: 24,
              semanticLabel: 'Mute volume',
            ),
            onPressed: () {
              setState(() {
                _mute = !_mute;
                _setVolume(_mute ? 0 : _volume);
              });
            },
            tooltip: 'Mute volume',
          ),
        ),
        ///widget Settings
        IconButton(
          iconSize: 24,
          icon: Icon(Icons.settings,),
          color: _textColor.withOpacity(_opacity),
          onPressed: () {
            setState(() {
              _activeSoundScheme = (_activeSoundScheme + 1) % _soundSchemeCount;
            });
            _setMusicScheme(_activeSoundScheme);

            //Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsWidget()));
            //Navigator.of(context).push(_createSettings());
          },
        )
      ]
    );
  }

  Widget _buildOneButton(String text, int delta)
  {
    return RaisedButton(
      // Can use instead: Icon(Icons.exposure_neg_1, semanticLabel: 'Reduce tempo by one', size: 36.0, color: Colors.white)
      child: Text(text,
        style: _textStyle,
        textScaleFactor: 2.0,),
      //padding: EdgeInsets.all(4),
      shape: CircleBorder(
        //borderRadius: new BorderRadius.circular(18.0),
        side: BorderSide(color: _ctrlColor, width: _borderWidth)
      ),
      onPressed: () {
        setState(() {
          _tempoBpm += delta;
          if (_tempoBpm < minTempo)
            _tempoBpm = minTempo;
          if (_tempoBpm > maxTempo)
            _tempoBpm = maxTempo;
          if (_playing)
            _setTempo(0.0);
        });
      },
    );
  }

  ///widget Square section with metronome itself
  Widget _buildOwlenome(bool portrait, showControls)
  {
    List<Widget> children = <Widget>[
      ///widget Owls
      Expanded(
        child: OwlGrid(
          playing: _playing,
          beat: _beat,
          activeBeat: _activeBeat,
          activeSubbeat: _activeSubbeat,
          noteValue: _noteValue,
          //width: _widthSquare,
          //childSize: childSize,
          onChanged: onOwlChanged,
        )
      ),
    ];

    //>>>>>>>>TODO: remove later if don't need
    /// Row with Metre and Subbeat controls
    if (showControls)
      children.add(Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ///widget Metre
          Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: _buildMetre(_textStyle),
            ),
          ),
          ///widget Subbeat widget
          Flexible(
            child: _buildSubbeat(_textStyle),
          ),
        ]
      ));
    //<<<<<<<<

    //VG TODO
    double paddingX = _beat.beatCount == 3 || _beat.beatCount == 4 ?
      0.03 * _widthSquare : 0;
    double paddingY = _beat.beatCount > 4 ? 0.05 * _widthSquare : 0;

    return Container(
      width: _widthSquare,
      height: _widthSquare,
      padding: portrait ? EdgeInsets.only(top: paddingY, left: paddingX, right: paddingX) :
        EdgeInsets.only(top: paddingY, left: paddingX, right: paddingX),
      ///widget Background
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      )
    );
  }

  // Remaining section with controls
  Widget _buildControls(bool portrait, bool showVolume)
  {
    final TextStyle textStyleTimer = _textStyle.copyWith(fontSize: 20);

    final double horzSpace = portrait ? 16 : 16;
    List<Widget> children = new List<Widget>();

    double paddingY = portrait ? 0 : 0.1 * _widthSquare;

    if (!showVolume)  //TODO: remove
      children.add(Padding(
        padding: EdgeInsets.only(top: paddingY, left: _padding.dx, right: _padding.dx),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ///widget Metre
            //Flexible(mainAxisAlignment: MainAxisAlignment.start, child:
            _buildMetre(_textStyle),
            //),
            ///widget Timer
            portrait ?
            TimerWidget(
              active: _playing,
              opacity: _opacity,
              color: _ctrlColor,
              borderWidth: _borderWidth,
              borderRadius: _borderRadius,
              textStyle: textStyleTimer,
            )
            :
            Container(width: 0, height: 0),
            ///widget Subbeat widget
            //Flexible(child:
            _buildSubbeat(_textStyle),
            //)
          ])
        )
      );

    ///widget Tempo knob control
    Widget wixKnob = new Knob(
      value: _tempoBpm.toDouble(),
      min: minTempo.toDouble(),
      max: maxTempo.toDouble(),
      size: 0.36 * _widthSquare,
      color: _textColor.withOpacity(0.5),
      textStyle: _textStyle,
      onPressed: _play,
      onChanged: (double value) {
        setState(() {
          _tempoBpm = value.round();
          //_tempoList.setTempo(_tempoBpm);
          if (_playing)
            _setTempo(0.0);
        });
      },
    );

    List<Widget> tempoControls = new List<Widget>();
    if (portrait)
    {
      ///widget Tempo down (-1) button
      tempoControls.add(_buildOneButton('-', -1));
      ///widget Tempo knob control
      tempoControls.add(wixKnob);
      ///widget Tempo up (+1) button
      tempoControls.add(_buildOneButton('+', 1));
    }
    else
    {
      ///widget Tempo knob control
      tempoControls.add(wixKnob);
      ///widget Tempo up/down (+1/-1) buttons
      tempoControls.add(
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          //mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _buildOneButton('+', 1),
            _buildOneButton('-', -1),
          ]
        )
      );
    }

    List<Widget> otherChildren = <Widget>[
      Expanded(child:
        Row(
          mainAxisAlignment: portrait ?
            MainAxisAlignment.spaceEvenly : MainAxisAlignment.end,
          //crossAxisAlignment: CrossAxisAlignment.end,
          //mainAxisSize: MainAxisSize.min,
          children: tempoControls
        ),
      ),

        Stack(
          alignment: AlignmentDirectional.center,
          children: <Widget>[
            ///widget Tempo list
            //Center(child:
              _buildPlate(TempoWidget(
                tempo: _tempoBpm,
                textStyle: _textStyle,
                onChanged: (int tempo) {
                  if (_tempoBpm != tempo)
                    setState(() {
                      _tempoBpm = tempo;
                      if (_playing)
                        _setTempo(0.0);
                    });
                  }
                ),
                padding: _padding,
              //),
            ),
            Align(
              alignment: Alignment.centerRight,
              //padding: EdgeInsets.only(right: _padding.dx),
              ///widget Settings
              child: IconButton(
                iconSize: 32,
                //padding: EdgeInsets.all(_padding.dx),
                icon: Icon(Icons.settings,),
                color: portrait ? _accentColor : _primaryColor,
                onPressed: () {
                  setState(() {
                    _activeSoundScheme = (_activeSoundScheme + 1) % _soundSchemeCount;
                  });
                  _setMusicScheme(_activeSoundScheme);

                  //Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsWidget()));
                  //Navigator.of(context).push(_createSettings());
                },
              )
            )
          ]
        )
      ];

    children.addAll(otherChildren);

    ///widget Volume
    if (showVolume)
      children.add(_builVolume());

    // Fill up the remaining screen as the last widget in column/row
    return Expanded(
      child: Container(
        /// Background
        decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: portrait ? Alignment.bottomCenter : Alignment.topCenter,
                end: portrait ? Alignment.topCenter : Alignment.bottomCenter,
                colors: [_primaryColor, _accentColor])
        ),
        //Padding(
        //  padding: const EdgeInsets.all(8.0),
        //  child:
        //child: IntrinsicHeight(

        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: children,
        )
      )
    );
  }

  /// <<<<<<<< Widget section
  /// /////////////////////////////////////////////////////////////////////////
  /// Flutter-Java inter operation
  ///

  Future<dynamic> _handleMsg(MethodCall call) async
  {
    if (call.method == 'warmedUp')
    {
      warmupFrames = call.arguments;
      _start(call.arguments);
    }
    else if (call.method == 'timeFrame')
    {
      int beatOrder = call.arguments['note'];
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

      _timeTick++;
      if (!animate60fps)
        ;//VG0 setState(() {});

      print('NOTECOUNT $beatOrder - $offset - $cycle - $_timeTick - $_activeBeat - $_activeSubbeat');
      Provider.of<MetronomeState>(context, listen: false).setActiveState(_activeBeat, _activeSubbeat);
      redraw = true;

      /*
      int writtenFrames = call.arguments;

      double msecTime = (writtenFrames - warmupFrames) * 1000 / nativeSampleRate;
      //metronome1?.setFrame(writtenFrames - warmupFrames);

      double period = 60000 / (_tempoBpm * _subBeatCount);

      print('writtenFrames: $writtenFrames - $warmupFrames - $msecTime - $prevTime - $period');

      if (msecTime - prevTime > 0.8 * period)
      {
        int ticks = (msecTime - prevTime) ~/ period;
        _timeTick += ticks;
        prevTime = msecTime;

        print('_timeTick: $_timeTick');

        setState(()
        {
          //_timeTick++;

          _activeBeat = (_timeTick ~/ _subBeatCount);
          if (_beatCount == 1 && _subBeatCount == 1)
            _activeBeat %= 2;
          else
            _activeBeat %= _beatCount;
          _activeSubbeat = _timeTick % _subBeatCount;
          _timeSec = (60 * _timeTick) ~/ (_tempoBpm * _subBeatCount);
        });
      }
      print('timer $_timeTick - $_timeSec');
        */
    }
    return new Future.value('');
  }

  Future<void> _togglePlay() async
  {
    Tempo tempo = new Tempo(beatsPerMinute: _tempoBpm.toInt() ~/ _beat.beatCount, denominator: _noteValue);

/*
    if (melody == null)
    {
      melody = new BeatMelody(nativeSampleRate, _quortaInMSec, _bars, _beat.beatCount);
      //bipPauseCycle = melody.cycle;
      int realBpM = melody.cycle.setTempo(tempo, _bars);
      double dur = melody.cycle.tempoToCycleDuration(tempo, _bars, nativeSampleRate);

      AccentBeat melody1 = new AccentBeat(nativeSampleRate, _quortaInMSec,
        _beat,
        0.001 * _soundConfig.beatFreq, _soundConfig.beatDuration,
        0.001 * _soundConfig.accentFreq, _soundConfig.accentDuration,
        _bars, 1);

      //print("realBPM - duration: $realBpM, $dur");
      //metronome1?.setCycle(melody.cycle, latency);
      //metronome1?.setTempo(_tempoBpm, nativeSampleRate, _noteValue, dur);
    }
*/

    List<BipAndPause> bipsAndPauses = new List<BipAndPause>();
    try
    {
      final Map<String, int> args =
      <String, int>{
        'tempo' : _tempoBpm, 'note' : _noteValue,
        'quorta': _quortaInMSec.toInt(),
        'numerator': _beat.beatCount,
        'mod': _activeSoundScheme,
      };
      final bool result = await _channel.invokeMethod('start', args);
/*
      final List result = await _channel.invokeMethod('start', args);
      if (result.length > 0)
      {
        //result.length ~/ 2);
        for (int i = 0; i < result.length; i += 2)
        {
          bipsAndPauses.add(new BipAndPause(result[i].toInt(), result[i+1]));

          //print("$i : ${result[i].toInt()} - ${result[i+1]}");
        }
        //bipPauseCycle = new BipPauseCycle.fromMelody(nativeSampleRate, bipsAndPauses, _numerator);

        //msg = 'Cycle length: ${result.length % 2}';
        //bipPauseCycle = melody.cycle;//bipPauseCycle0;

        //int realBpM = bipPauseCycle.setTempo(tempo, _bars);
        //print("realBPM: $_tempoBpm, $realBpM");
      }
 */
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed to start playing';
    }
  }

  Future<void> _playSing() async
  {
    //melody = new SingSingMelody(nativeSampleRate, 30);
  }

  /// Send beat music to Java sound player
  Future<void> _setBeat() async
  {
    melody = new AccentBeat(nativeSampleRate, _quortaInMSec,
      _beat,
      0.001 * _soundConfig.beatFreq, _soundConfig.beatDuration,
      0.001 * _soundConfig.accentFreq, _soundConfig.accentDuration,
      _bars, 1);

    //Tempo tempo = new Tempo(beatsPerMinute: _subBeatCount * _tempoBpm.toInt(), denominator: _noteValue);
    //List<BipAndPause> bipsAndPauses = new List<BipAndPause>();
    try
    {
      //IS:
      final List<int> config = [
        _beat.beatCount,
        _beat.accent,
        _beat.subBeatCount,
        _soundConfig.beatFreq,
        _soundConfig.beatDuration,
        _soundConfig.accentFreq,
        _soundConfig.accentDuration,
        _bars,
        _beat.beatCount,
        _quortaInMSec.toInt()
      ];

      final Map<String, List<int>> args =
        <String, List<int>>{'config': config, 'subBeats': _beat.subBeats};

      final List result = await _channel.invokeMethod('setBeat', args);
      if (result.length == 0)
      {
        _infoMsg = 'Failed setting beat';
        print(_infoMsg);
      }
    }
    on PlatformException
    {
      _infoMsg = 'Exception: Failed setting beat';
    }
  }

  /// Send music tempo to Java sound player
  Future<void> _setTempo(double tempo) async
  {
    //int iTempo = (tempo + 0.5).toInt();
    //int i_tempoBpm = _tempoBpm;
    Tempo tempo = new Tempo(beatsPerMinute: _tempoBpm ~/ _beat.beatCount, denominator: _noteValue);
    try
    {
      final Map<String, int> args =
      <String, int>{
        'tempo' : _tempoBpm,
        'note' : _noteValue
      };
      final int result = await _channel.invokeMethod('setTempo', args);
      //assert(result == 1);
      if (result != 1)
      {
        _infoMsg = 'Failed setting tempo';
        print(_infoMsg);
      }
      else
        _infoMsg = 'Tempo: $_tempoBpm';
    } on PlatformException {
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
        print(_infoMsg);
      }
    } on PlatformException {
      _infoMsg = 'Exception: Failed setting volume';
    }
  }


  /// /ToDo: IS:   musicScheme to set
  Future<void> _setMusicScheme(int musicScheme) async {
    try {
      final int result =
      await _channel.invokeMethod('setMusicScheme', {'mod': musicScheme});
      //assert(result == 1);
      if (result != 1) {
        _infoMsg = 'Failed setting  music scheme, lay-la,la-la-la-lay-la-la...';
        print(_infoMsg);
      }
    } on PlatformException {
      _infoMsg = 'Exception: Failed setting  music scheme';
    }
  }

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

    print(_infoMsg);
    setState(() {});  // Update UI
  }


  // Settings boilerplate
  Route _createSettings()
  {
    return MaterialPageRoute(builder: (context) => SettingsWidget());
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


///VG: Don't delete
/*
  _scaffoldKey.currentState.showSnackBar(SnackBar(
    content: Text('Minus one'),
    duration: Duration(milliseconds: 250)));

  IconButton(
    iconSize: 36,
    icon: Icon(
      Icons.exposure_neg_1,
      //color: Colors.deepPurple,
      //size: 36.0,
      semanticLabel: 'Reduce tempo by one',
    ),
    onPressed: () {
      setState(() {
        _tempoBpm -= 10;
      });
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('Minus one'),
        duration: Duration(milliseconds: 250)));
    },
    tooltip: 'Reduce tempo',
  ),

  DropdownButton<int>(
    value: _subBeatCount,
    style: textStyle,
    icon: Icon(
      Icons.arrow_drop_down,
      color: Colors.white,
      size: 24.0,
      semanticLabel: 'Choose beat subdivision',
    ),
    //isDense: true,
    onChanged: (int value) {
      setState(() {
        if (value != null) {
          _subBeatCount = value;
          if (_playing)
            _setTempo(0.0);
        }
      });
    },
    items: <int>[1, 2, 3, 4, 5, 6]
      .map<DropdownMenuItem<int>>((int value) {
      return DropdownMenuItem<int>(
        value: value,
        child: Text(value.toString(),
        style: TextStyle(color: Colors.black)));
    }).toList()
  ),

  DropdownButton<int>(
    value: _subBeatCount,
    style: textStyle,
    icon: Icon(
      Icons.arrow_drop_down,
      color: Colors.white,
      size: 24.0,
      semanticLabel: 'Choose beat subdivision',
    ),
    //isDense: true,
    onChanged: (int value) {
      setState(() {
        if (value != null) {
          _subBeatCount = value;
          if (_playing)
            _setTempo(0.0);
        }
      });
    },
    items: <int>[1, 2, 3, 4, 5, 6]
      .map<DropdownMenuItem<int>>((int value) {
      return DropdownMenuItem<int>(
        value: value,
        child: Text(value.toString(),
        style: TextStyle(color: Colors.black)));
    }).toList()
  ),

  ButtonTheme(
    minWidth: 150,
    buttonColor: Colors.purple.withOpacity(_opacity),
    colorScheme: ColorScheme.light(),
    child: RaisedButton(
      textColor: Colors.white,
      padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      child: Text(isTicking() ? 'Pause' : 'Start',
        style: textStyle),
      shape: RoundedRectangleBorder(
        borderRadius: new BorderRadius.circular(16.0),
        side: BorderSide(color: Colors.purpleAccent.withOpacity(_opacity), width: 2)
      ),
      onPressed: _play,
    )
  )
*/
