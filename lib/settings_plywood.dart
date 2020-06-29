import 'package:flutter/material.dart';

class Settings
{
  int mixingType;
  int activeScheme;
  final List<String> soundSchemes;
  //int animationType;
  //bool useKnob;

  Settings({this.mixingType, this.activeScheme, this.soundSchemes,});
}

class SettingsWidget extends StatelessWidget
{
  final Settings settings;
  /*
  final List<String> animations = [
    'Голова набок через раз',
    'Голова набок через два',
    'Голова набок',
    'Прифигевшие',
    'Прифигевшие набок',
  ];*/

  final List<String> mixingTypes = [
    'Half sum (energy saving)',
    'Hyperbolic Tangent',
    'Hyperbolic Tangent with amplifier  (louder)',
    'Experimental',
  ];

  SettingsWidget({
    this.settings,
  });

  @override
  Widget build(BuildContext context)
  {
    //List<Widget> radioSoundSchemes = new List<Widget>();
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: Center(
        child: ListView(
          children: List<Widget>.generate(1, (int index) =>
          //RadioListTile<SingingCharacter>(
          new ListTile(
            dense: true,
            //leading: icon,
            //title: Text('Animation type'),
            title: Text('Audio mixing type'),
            //dense: true,
          ))
            ..addAll(List<Widget>.generate(mixingTypes.length, (int index) =>
            //RadioListTile<SingingCharacter>(
            new RadioListTile<int>(
              dense: true,
              title: Text(mixingTypes[index]),
              value: index,
              groupValue: settings.mixingType,
              onChanged: (int value) {
                //setState(() { _character = value; });
                settings.mixingType = value;
                debugPrint("MixingTypeInSetChosen: ${value}");
                Navigator.pop(context, settings);
              },
            )
            )
            )
            /*
            ..add(new Divider(color: Colors.deepPurple))
            ..add(new ListTile(
              dense: true,
              //leading: icon,
              title: Text('Other options'),
              //dense: true,
            ))
            ..add(
                new SwitchListTile(
                  dense: true,
                  title: Text('New knob'),
                  value: settings.useKnob,
                  onChanged: (bool value) {
                    //setState(() { _character = value; });
                    settings.useKnob = value;
                    Navigator.pop(context, settings);
                  },
                ))
            */
            ..add(new Divider(color: Colors.deepPurple))
            ..add(new ListTile(
              dense: true,
              //leading: icon,
              title: Text('Sound'),
              //dense: true,
            ))
            ..addAll(List<Widget>.generate(settings.soundSchemes.length, (int index) =>
            new RadioListTile<int>(
              dense: true,
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
              ..add(new Divider(color: Colors.deepPurple))
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
      ),
    );
  }
}
