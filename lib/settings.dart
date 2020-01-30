import 'package:flutter/material.dart';

class SettingsWidget extends StatelessWidget
{
  final int animationType;
  final bool useKnob;
  final List<String> animations = [
    'Голова набок через раз',
    'Голова набок через два',
    'Голова набок',
    'Прифигевшие',
    'Прифигевшие набок',
  ];

  SettingsWidget({
    this.animationType,
    this.useKnob,
  });

  @override
  Widget build(BuildContext context)
  {
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
              final List<int> res = [value, useKnob ? 1 : 0];
              Navigator.pop(context, res);
            },
          )
        )
        ..add(
          new SwitchListTile(
            title: Text('Новый ручкан'),
            value: useKnob,
            onChanged: (bool value) {
              //setState(() { _character = value; });
              final List<int> res = [animationType, value ? 1 : 0];
              Navigator.pop(context, res);
            },
        )),

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
