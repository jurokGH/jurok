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

class VolumeButtonTmp extends StatefulWidget
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

  VolumeButtonTmp({
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

class VolumeState extends State<VolumeButtonTmp> with SingleTickerProviderStateMixin
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

          RotatedBox(
            quarterTurns: -1,
            child:
            SizedBox(
                width: 0.7 / 0.88 * widget.height,//0.42
                child:
                Slider(
                    min: widget.min,
                    max: widget.max,
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
        ]
    );


    Widget button = new RawMaterialButton(
      child: Icon(_mute ? Icons.volume_off : Icons.volume_up,
        size: widget.diameter,//36,
        color: widget.color,
        semanticLabel: 'Mute volume',
      ),
      //shape: CircleBorder(side: BorderSide(width: 2, color: widget.color)),
      constraints: BoxConstraints(
        minWidth: widget.diameter,
        minHeight: widget.diameter,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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

    return Container(
        child: Stack(
            alignment: align,
            //fit: StackFit.expand,
            //overflow: Overflow.visible,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.circular(0.5 * widget.diameter),
                child: SlideTransition(
                  position: _animOffset,
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
              ),
              button,
            ]
        ));
  }
}
