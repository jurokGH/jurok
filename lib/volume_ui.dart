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
  final double radius;
  final double height;

  final Color color;
  final TextStyle textStyle;
  /// Whether detected gestures should provide acoustic and/or haptic feedback.
  final bool enableFeedback;

  final int msec;
  final RolloutDirection direction;
  final VoidCallback onLongPress;

  VolumeButton({
    @required this.value,
    this.min = 0,
    this.max = 100,
    this.mute = false,
    @required this.onChanged,
    @required this.onLongPress,
    this.radius,
    this.height,
    this.color = Colors.white,
    this.textStyle,
    this.enableFeedback = true,
    this.direction = RolloutDirection.up,
    this.msec = 100,
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
  Timer _timer;
  int _timeOut = 1000;  // milliseconds

  VolumeState();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    controller = new AnimationController(duration: new Duration(milliseconds: widget.msec), vsync: this)
      ..addStatusListener((AnimationStatus status){
        if (status == AnimationStatus.completed)
          _status = BtnStatus.Open;
        else if (status == AnimationStatus.dismissed)
          _status = BtnStatus.Closed;
        else
          _status = BtnStatus.Animating;
      });

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

  void _onTimer()
  {
    if (_status == BtnStatus.Open)
      controller.reverse().orCancel;
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
      controller.reverse().orCancel;
  }

  @override
  Widget build(BuildContext context)
  {
    if (!_mute)
      _value = widget.value;

    Widget rollup = new Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        /*
        IconButton(
          iconSize: 30,
          padding: const EdgeInsets.all(0),
          icon: Icon(Icons.volume_up,),
          color: _cWhiteColor,
          enableFeedback: widget.enableFeedback,
          onPressed: () { _changeVolume(10); },
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
              onChanged: (double value) {
                setState(() {
                  _mute = value == widget.min;
                });
                widget.onChanged(value);
              },
              onChangeEnd: (double value) {

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
          onPressed: () { _changeVolume(-10); },
        ),
*/
      ]
    );

/*
    return RolloutBtn(
      child: button,
      rollout: rollup,
      radius: widget.radius,
      height: widget.height,
      msec: 200,
      onLongPress: () {
        setState(() {
          _mute = !_mute;
        });
        widget.onChanged(_mute ? widget.min : widget.value);
      },
    );
*/

    /*
    FloatingActionButton(
      backgroundColor: Colors.blue,
      onPressed: _handleOpenClose,
      child: Icon(Icons.add)
    ),
*/
    Widget button = new MaterialButton(
      //iconSize: 40,
      child: Icon(_mute ? Icons.volume_off : Icons.volume_up,
        size: 36,
        color: widget.color,
        semanticLabel: 'Mute volume',
      ),
      shape: CircleBorder(side: BorderSide(width: 2, color: widget.color)),
      padding: EdgeInsets.all(4),
      textTheme: ButtonTextTheme.primary,
      //tooltip: _soundSchemes[_activeSoundScheme],
      enableFeedback: widget.enableFeedback,
      onLongPress: () {
        setState(() {
          _mute = !_mute;
        });
        widget.onChanged(_mute ? widget.min : _value);
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

    return UnconstrainedBox(
      alignment: align,
      //      minWidth: 2 * widget.radius,
      //      minHeight: widget.height,
      //      maxWidth: 2 * widget.radius,
      //      maxHeight: widget.height,
      child: Stack(
        alignment: align,
        //overflow: Overflow.clip,
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
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
                  width: 2 * widget.radius,
                  height: widget.height,
                  //color: Colors.red,
                  decoration: BoxDecoration(
                    color: Colors.deepPurple.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(widget.radius),
                  ),
                  child: rollup,
                  //Icon(Icons.add_circle)


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
/*
Widget _builVolume1()
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
        iconSize: 18,
        icon: Icon(Icons.settings,),
        color: _textColor.withOpacity(_opacity),
        onPressed: () {
          setState(() {
            /* _activeSoundScheme = (_activeSoundScheme + 1) % _soundSchemeCount;
                _setMusicScheme(_activeSoundScheme);*/
          });
          //_setMusicScheme(_activeSoundScheme); IS: here or above??

          //Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsWidget()));
          //Navigator.of(context).push(_createSettings());
        },
      )
    ]
  );
}
*/
