import 'package:flutter/material.dart';

class Settings
{
  int animationType;
  int soundScheme;
  bool useKnob;

  Settings({this.animationType, this.soundScheme, this.useKnob});
}

/*
class TempoDef
{
  String name;
  int tempo;
  int minTempo;
  int maxTempo;

  TempoDef([name, minTempo, maxTempo, tempo])
  {
    this.name = name;
    this.minTempo = minTempo;
    this.maxTempo = maxTempo;
    this.tempo = tempo == null ? minTempo : tempo;
  }
}
*/

class SettingsWidget extends StatelessWidget
{
  final Settings settings;
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
    this.settings,
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
            groupValue: settings.animationType,
            onChanged: (int value) {
              //setState(() { _character = value; });
              //final List<int> res = [value, settings.useKnob ? 1 : 0];
              settings.animationType = value;
              Navigator.pop(context, settings);
            },
          )
        )
        ..add(new Divider())
        ..add(
          new SwitchListTile(
            title: Text('Новый ручкан'),
            value: settings.useKnob,
            onChanged: (bool value) {
              //setState(() { _character = value; });
//              final List<int> res = [settings.animationType, value ? 1 : 0];
//              Navigator.pop(context, res);
              settings.useKnob = value;
              Navigator.pop(context, settings);
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
