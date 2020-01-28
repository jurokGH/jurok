import 'dart:async';

import 'package:flutter/material.dart';

class RolloutBtn extends StatefulWidget
{
  final Widget child;
  final Widget rollout;
  final double radius;
  final double height;
  final int msec;
  final RolloutDirection direction;
  final VoidCallback onLongPress;

  RolloutBtn({this.child, this.rollout,
    this.radius = 20, this.height = 200,
    this.direction = RolloutDirection.up, this.msec = 100,
    this.onLongPress});

  @override
  State<StatefulWidget> createState() {
    return RolloutBtnState();
  }
}

enum RolloutDirection
{
  left, right, up, down
}
enum BtnStatus
{
  Closed, Open, Animating
}

class RolloutBtnState extends State<RolloutBtn> with SingleTickerProviderStateMixin
{
  AnimationController controller;
  Animation<double> _animScale;
  Animation<double> _animPos;
  Animation<Offset> _animOffset;
  BtnStatus _status = BtnStatus.Closed;
  Timer _timer;
  int _timeOut = 1000;  // milliseconds

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
/*
    FloatingActionButton(
      backgroundColor: Colors.blue,
      onPressed: _handleOpenClose,
      child: Icon(Icons.add)
    ),
*/
    FlatButton model = widget.child;

    Widget button = new FlatButton(
      //iconSize: 40,
      child: model.child,
      shape: model.shape,
      padding: model.padding,
      textTheme: model.textTheme,
      //tooltip: _soundSchemes[_activeSoundScheme],
      onLongPress: widget.onLongPress,
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

      // TODO: implement build
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
          child:
          SlideTransition(
            position: _animOffset,
            //          Positioned(
            //            //top: -100 + _animPos.value,
            //            bottom: _animPos.value,
            //            child:
            //            Transform(
            //              transform: Matrix4.diagonal3Values(1.0, _animScale.value, 1.0)
            //                ..setTranslationRaw(0.0, _animPos.value, 0.0),
            //scale: 1.0,//_animScale.value,
            child:
            Transform(
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
                child: widget.rollout,
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
