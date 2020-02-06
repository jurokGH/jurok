import 'package:flutter/material.dart';

class Settings
{
  int animationType;
  int activeScheme;
  final List<String> soundSchemes;
  bool useKnob;

  Settings({this.animationType, this.activeScheme, this.soundSchemes, this.useKnob});
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
  final List<String> animations = [
    'Голова набок через раз',
    'Голова набок через два',
    'Голова набок',
    'Прифигевшие',
    'Прифигевшие набок',
  ];

  SettingsWidget({
    this.settings,
  });

  @override
  Widget build(BuildContext context)
  {
    //List<Widget> radioSoundSchemes = new List<Widget>();

    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: ListView(
        children: List<Widget>.generate(settings.soundSchemes.length, (int index) =>
          //RadioListTile<SingingCharacter>(
          new RadioListTile<int>(
            value: index,
            title: Text(settings.soundSchemes[index]),
            groupValue: settings.activeScheme,
            onChanged: (int value) {
              //setState(() { _character = value; });
              settings.activeScheme = value;
              Navigator.pop(context, settings);
            },
          )
        )
        ..add(new Divider())
        ..add(new ListTile(
          //leading: icon,
          title: Text('Animation type'),
          //dense: true,
        ))
        ..addAll(List<Widget>.generate(5, (int index) =>
            //RadioListTile<SingingCharacter>(
            new RadioListTile<int>(
              title: Text(animations[index]),
              value: index,
              groupValue: settings.animationType,
              onChanged: (int value) {
                //setState(() { _character = value; });
                settings.animationType = value;
                Navigator.pop(context, settings);
              },
            )
          )
        )
        ..add(new Divider())
        ..add(new ListTile(
          //leading: icon,
          title: Text('Other options'),
          //dense: true,
        ))
        ..add(
          new SwitchListTile(
            title: Text('Новый ручкан'),
            value: settings.useKnob,
            onChanged: (bool value) {
              //setState(() { _character = value; });
              settings.useKnob = value;
              Navigator.pop(context, settings);
            },
        ))
        ..add(new Divider())
        ..add(new AboutListTile()),

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
