import 'package:flutter/material.dart';

class SettingsWidget extends StatelessWidget
{
  final int animationType;
  final List<String> animations = [
    'Голова набок через раз',
    'Голова набок через два',
    'Голова набок',
    'Прифигевшие',
    'Прифигевшие набок',
  ];

  SettingsWidget({
    this.animationType
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ListView(
        children: List<Widget>.generate(5, (int index) =>
          //RadioListTile<SingingCharacter>(
          new RadioListTile<int>(
            title: Text(animations[index]),
            value: index,//animationType == index ? 1 : 0,
            groupValue: animationType,
            onChanged: (int value) {
              //setState(() { _character = value; });
              Navigator.pop(context, value);
            },
          )
        ),

/*          CheckboxListTile(
            title: Text('Text'),
            value: true,
            onChanged: (bool value) {
            },
          ),
          ListTile(
            title: Text('text'),
            trailing: Checkbox(
              value: true,
              onChanged: (bool value) {
              },
          ),
          onTap: () {
            //setState(() {});
          },
          ),
          RaisedButton(
            onPressed: () {
              //Navigator.pop(context);
            },
          )
        ]
 */
        ),
      ),
    );
  }
}

/*
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
 */
