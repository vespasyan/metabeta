import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:metaphor_beta/tablayouts/chat/chat_screen.dart';

class CallScreen extends StatefulWidget{
  @override
  _CallScreenState createState() => new _CallScreenState();

}

class _CallScreenState extends State<CallScreen>{
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(

      backgroundColor: Colors.amber,

      body: Stack(
        children: <Widget>[
          new Container(
            decoration: new BoxDecoration(
                image: new DecorationImage(
                    image: new AssetImage('images/tenor_16.gif'), fit: BoxFit.cover)
            ),
          ),
          new Container(
            width: 200.0,
            height: 300.0,

            decoration: new BoxDecoration(color: Color.fromRGBO(57, 143, 229, 0.75),borderRadius: BorderRadius.circular(18.0)),
            child: Center(
              child: Text('Note: at this time, you should use the version packages like me in pubspec.yaml, if you use the latest (like Google’s packages, they use AndroidX and will not compatible with the other packages like cached_network_image, flutter_toast… so the project can’t build success). More details at here: https://flutter.dev/docs/development/packages-and-plugins/androidx-compatibility#how-to-migrate-a-flutter-app-to-androidx',
                style: TextStyle(color: Colors.white70, fontSize: 20.0),),
            ),

          ),

          new Center(
            child: Container(
              width: 200,
              height: 100,
              decoration: new BoxDecoration(
                  color: new Color.fromRGBO(87, 112, 170, 0.6),
                  shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(18.0),
              ),
              child: Center(
                child: Text('ssdgfsgfdsdfgdfg', style: TextStyle(color: Colors.white70, fontSize: 20.0),),
              ),
            ),
          ),
        ],

      )
    );
  }

}