import 'package:flutter/material.dart';

class HelpWidget extends StatelessWidget
{
  HelpWidget();

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      //appBar: AppBar(title: Text('Help')),
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(  // TODO Decide if need
          child: SingleChildScrollView(
            //child: Image.asset('images/help.jpg',fit: BoxFit.contain)
              child: Image.asset('images/help.png',fit: BoxFit.contain)
          ),
        ),
      ),
    );
  }
}
