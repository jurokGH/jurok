import 'package:flutter/material.dart';
import 'dart:async';
//import 'rollout_btn.dart';

enum RolloutDirection
{
  left, right, up, down
}
enum BtnStatus
{
  Closed, Open, Animating
}

///widget Volume

class VolumeButton extends StatefulWidget
{
  final double value;
  final double min;
  final double max;
  final bool mute;
  final ValueChanged<double> onChanged;
  final double diameter;
  final double height;

  final Color color;
  final TextStyle textStyle;
  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  final bool enableFeedback;

  /// In milliseconds
  final int msec;
  ///TODO Need? Idle time in milliseconds
  //final int idleTime;
  final RolloutDirection direction;
  //final VoidCallback onLongPress;

  VolumeButton({
    @required this.value,
    this.min = 0,
    this.max = 100,
    this.mute = false,
    @required this.onChanged,
    //@required this.onLongPress,
    this.diameter,
    this.height,
    this.color = Colors.white,
    this.textStyle,
    this.enableFeedback = true,
    this.direction = RolloutDirection.up,
    this.msec = 100,
    //this.idleTime = 2000,
  });

  @override
  State<StatefulWidget> createState() => VolumeState();
}

class VolumeState extends State<VolumeButton> with SingleTickerProviderStateMixin
{
  bool _mute = false;
  double _value;

  AnimationController controller;
  Animation<double> _animScale;
  Animation<double> _animPos;
  Animation<Offset> _animOffset;
  BtnStatus _status = BtnStatus.Closed;
  final int _idleTime = 2000;  // in milliseconds
  Duration _duration;
  Timer _timer;

  VolumeState();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    _duration = new Duration(milliseconds: _idleTime);
    controller = new AnimationController(duration: new Duration(milliseconds: widget.msec), vsync: this)
      ..addStatusListener((AnimationStatus status){
        if (status == AnimationStatus.completed)
          _status = BtnStatus.Open;
        else if (status == AnimationStatus.dismissed)
          _status = BtnStatus.Closed;
        else
          _status = BtnStatus.Animating;
      })
    ..addStatusListener(onStatusListener);

    _animScale = new Tween(begin: 0.2, end: 1.0)
      .animate(controller)
      ..addListener(() {
        setState(() {
        });
      });
    _animPos = new Tween(begin: 0.0, end: 100.0)
      .animate(controller)
      ..addListener(() {
        setState(() {
        });
      });

    double x = 0;
    double y = 0;
    if (widget.direction == RolloutDirection.right)
      x = 1;
    else if (widget.direction == RolloutDirection.left)
      x = -1;
    if (widget.direction == RolloutDirection.up)
      y = 1;
    else if (widget.direction == RolloutDirection.down)
      y = -1;
    _animOffset = new Tween<Offset>(begin: Offset(x, y), end: Offset(0.0, 0.0))
      .animate(controller);
    //      ..addListener(() {
    //        setState(() {
    //        });
    //      });
  }

  void onStatusListener(AnimationStatus status)
  {
    if (status == AnimationStatus.completed)
      _timer = new Timer(_duration, _onTimer);
  }

  void _onTimer()
  {
    if (_status == BtnStatus.Open)
      controller.reverse().orCancel;
    _timer = null;
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleOpenClose()
  {
    if (_status == BtnStatus.Closed)
      controller.forward().orCancel;
    else if (_status == BtnStatus.Open)
    {
      _timer?.cancel();  // To prevent calling twice controller.reverse()
      controller.reverse().orCancel;
    }
  }

  @override
  Widget build(BuildContext context)
  {
    if (!_mute)
      _value = widget.value;

    Widget rollup = Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
/*
        IconButton(
          iconSize: 30,
          padding: const EdgeInsets.all(0),
          icon: Icon(Icons.volume_up,),
          color: widget.color,
          enableFeedback: widget.enableFeedback,
          onPressed: () {
            widget.onChanged(widget.value - 10);
            _timer?.cancel();
            _timer = new Timer(_duration, _onTimer);
          },
        ),
*/
        RotatedBox(
          quarterTurns: -1,
          child:
          SizedBox(
            width: 0.7 / 0.88 * widget.height,//0.42
            //height:  0.2 * _sizeCtrls.height,//0.42,
            child:
            Slider(
              min: widget.min,
              max: widget.max,
              //label: _volume.toString(),
              value: widget.value,
              onChangeStart: (double value) {
                _timer?.cancel();
              },
              onChanged: (double value) {
                setState(() {
                  _mute = value == widget.min;
                });
                widget.onChanged(value);
              },
              onChangeEnd: (double value) {
                _timer = new Timer(_duration, _onTimer);
              }
            )
          ),
        ),
        /*
        IconButton(
          iconSize: 30,
          padding: const EdgeInsets.all(0),
          icon: Icon(Icons.volume_down,),
          color: _cWhiteColor,
          enableFeedback: widget.enableFeedback,
          onPressed: () {
            _changeVolume(-10);
            _timer?.cancel();
            _timer = new Timer(_duration, _onTimer);
          },
        ),
*/
      ]
    );

    Widget rollup1 = Container(
      width: widget.diameter - 4,
      height: widget.height,
      color: Color(0x8080FF80),
    );

    Widget button1 = new MaterialButton(
      //iconSize: 40,
      child: Icon(_mute ? Icons.volume_off : Icons.volume_up,
        size: widget.diameter,//36,
        color: widget.color,
        semanticLabel: 'Mute volume',
      ),
      shape: CircleBorder(side: BorderSide(width: 2, color: widget.color)),
      padding: EdgeInsets.all(4),
      textTheme: ButtonTextTheme.primary,
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: widget.enableFeedback,
      onLongPress: () {
        _timer?.cancel();
        setState(() {
          _mute = !_mute;
        });
        widget.onChanged(_mute ? widget.min : _value);
        _timer = new Timer(_duration, _onTimer);
      },
      onPressed: _handleOpenClose,
        /*
      onPressed: () {
        setState(() {
          _mute = !_mute;
          _setVolume(_mute ? 0 : _volume);
        });
      },
*/
    );

    Widget button = new RawMaterialButton(  //FlatButton
      //padding: EdgeInsets.all(18),//_padding.dx),
      child: Icon(_mute ? Icons.volume_off : Icons.volume_up,
        size: widget.diameter,//36,
        color: widget.color,
        semanticLabel: 'Mute volume',
      ),
      //fillColor: Colors.deepPurple.withOpacity(0.5), //portrait ? _accentColor : _primaryColor,
      //color: _cWhiteColor.withOpacity(0.8),
      shape: CircleBorder(side: BorderSide(width: 2, color: widget.color)),
      constraints: BoxConstraints(
        minWidth: widget.diameter,
        minHeight: widget.diameter,
        //maxWidth: 200,
        //maxHeight: 200,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,  // Make button of exact diameter size
      //tooltip: _soundSchemes[_activeSoundScheme],
//      padding: EdgeInsets.all(4),
      //textTheme: ButtonTextTheme.primary,
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: widget.enableFeedback,
      onLongPress: () {
        _timer?.cancel();
        setState(() {
          _mute = !_mute;
        });
        widget.onChanged(_mute ? widget.min : _value);
        _timer = new Timer(_duration, _onTimer);
      },
      onPressed: _handleOpenClose,
      /*
      onPressed: () {
        setState(() {
          _mute = !_mute;
          _setVolume(_mute ? 0 : _volume);
        });
      },
*/
    );

    AlignmentDirectional align;
    switch (widget.direction)
    {
    case RolloutDirection.up:
      align = AlignmentDirectional.bottomCenter;
      break;
    case RolloutDirection.down:
      align = AlignmentDirectional.topCenter;
      break;
    case RolloutDirection.left:
      align = AlignmentDirectional.centerEnd;
      break;
    case RolloutDirection.right:
      align = AlignmentDirectional.centerStart;
      break;
    }

//    return SizedOverflowBox(
//      alignment: Alignment.bottomCenter,
//      size: new Size(2 * widget.radius, 2 * widget.radius),

//    return UnconstrainedBox(
//      alignment: align,

    return Container(
      //      minWidth: 2 * widget.radius,
      //minHeight: widget.height,
      //      maxWidth: 2 * widget.radius,
      //      maxHeight: widget.height,
      child: Stack(
        alignment: align,
        //fit: StackFit.expand,
        //overflow: Overflow.visible,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(0.5 * widget.diameter),
            child: SlideTransition(
              position: _animOffset,
//          Positioned(
//            //top: -100 + _animPos.value,
//            bottom: _animPos.value,
//            child:
//            Transform(
//              transform: Matrix4.diagonal3Values(1.0, _animScale.value, 1.0)
//                ..setTranslationRaw(0.0, _animPos.value, 0.0),
//scale: 1.0,//_animScale.value,
              child: Transform(
                transform: Matrix4.diagonal3Values(1.0, 1.0, 1.0),
                //                ..setTranslationRaw(0.0, _animPos.value, 0.0),
                child:
                  Container(
                  width: widget.diameter,
                  height: widget.height,
                  //color: Colors.red,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(0.5 * widget.diameter),
                  ),
                  child: rollup,
                ),
              ),
            ),
            //Icon(Icons.add_circle)
            /*OwlWidget
            RotatedBox(
              quarterTurns: 1,
              child: Slider.adaptive(
                min: 0.0,
                max: 100.0,
                value: 50.0,
                onChanged: (double value) {}
              )
            )
*/
          ),
          //  widget.child,
          button,
          /*
      IconButton(
        color: Colors.blue,
        icon: Icon(Icons.add),
        onPressed: _handleOpenClose,
      ),
      */
        ]
      ));
  }
}
