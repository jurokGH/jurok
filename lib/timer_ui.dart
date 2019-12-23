import 'package:flutter/material.dart';
import 'dart:async';

class TimerWidget extends StatefulWidget
{
  final bool active;
  final double borderRadius;
  final double borderWidth;
  final double opacity;
  final Color color;
  final TextStyle textStyle;

  //final ValueChanged<int> onChanged;

  TimerWidget({//this.onChanged,
    this.active = false,
    this.borderWidth = 0,
    this.borderRadius = 0,
    this.opacity = 0,
    this.color = Colors.white,
    this.textStyle});

  @override
  State<StatefulWidget> createState() {
    return TimerState();
  }
}

class TimerState extends State<TimerWidget>
{
  // Timer for elapsed playing time
  Timer _timer;
  // Elapsed playing time in seconds
  int _time = 0;
  // String to display as a timer
  String _sTime;

  TimerState()
  {
    _sTime = _time2string(_time);
  }

  bool isActive()
  {
    return _timer != null && _timer.isActive;
  }

  void start()
  {
    _time = 0;
    _sTime = _time2string(_time);
    Duration duration = new Duration(milliseconds: 1000);
    _timer = new Timer.periodic(duration, _handleTimer);
  }

  void stop()
  {
    _timer?.cancel();
  }

  void toggleAnimation()
  {
    if (widget.active)
    {
      if (!isActive())
        start();
    }
    else
    {
      if (isActive())
        stop();
    }
  }

  @override
  Widget build(BuildContext context)
  {
    final Color borderColor = Theme.of(context).accentColor.withOpacity(widget.opacity);
    //Colors.purpleAccent.withOpacity(widget.opacity)
    print('Timer: ' + _sTime);
    toggleAnimation();

    return //FittedBox(
      //fit: BoxFit.scaleDown,
      //child:
/*
      DecoratedBox(
      //width:80,
      //height:30,
      decoration: BoxDecoration(
        color: widget.color.withOpacity(widget.opacity),
        //shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: widget.borderWidth),
        borderRadius: BorderRadius.circular(widget.borderRadius),
      ),
      //margin: EdgeInsets.all(16),
      child:
*/
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Text(_sTime,
          style: widget.textStyle,
        )
      )
    //)
    ;
  }

  TextBox _calcLastLineEnd(BuildContext context, BoxConstraints constraints)
  {
    final textSpan = TextSpan(text: _sTime, style: widget.textStyle);
    final richTextWidget = Text.rich(textSpan).build(context) as RichText;
    final renderObject = richTextWidget.createRenderObject(context);
    renderObject.layout(constraints);
    final lastBox = renderObject
      .getBoxesForSelection(TextSelection(
      baseOffset: 0, extentOffset: textSpan.toPlainText().length))
      .last;
    return lastBox;
  }

  void _handleTimer(Timer timer)
  {
    setState(()
    {
      _time = timer.tick;
      _sTime = _time2string(_time);
    });
  }

  /// Build time string in format 00:00
  /// time in seconds
  String _time2string(int seconds)
  {
    if (seconds < 0)
      seconds = 0;
    if (seconds >= 60000)
      seconds %= 60000;
    return (seconds ~/ 60).toString().padLeft(2, '0') + ':' + (seconds % 60).toString().padLeft(2, '0');
  }
}
