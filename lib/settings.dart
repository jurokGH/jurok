import 'package:flutter/material.dart';

class SettingsWidget extends StatelessWidget
{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: FractionallySizedBox(
          alignment: Alignment.center,
          widthFactor: 0.5,
          heightFactor: 0.1,
          child: RaisedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text('Close')
          )
        )
      )
    );
  }
}
