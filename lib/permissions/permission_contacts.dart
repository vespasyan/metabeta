import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:metaphor_beta/welcome_screen/welcomeScreen.dart';

/*class MyPermissions extends StatelessWidget{

  final DocumentSnapshot userDocument;

  MyPermissions({this.userDocument});

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return MaterialApp(
      home: new PermissionContact(),
    );
  }
}*/

class PermissionContact extends StatefulWidget{


  final DocumentSnapshot userDocument;

  PermissionContact({this.userDocument});

  @override
  _PermissionContactState createState() => new _PermissionContactState();
}

class _PermissionContactState extends State<PermissionContact>{

  PermissionStatus _status = PermissionStatus.unknown;

  @override
  void initState() {
    super.initState();
    PermissionHandler().checkPermissionStatus(PermissionGroup.contacts)
        .then(_updateStatus);
    _finishTask();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Scaffold(
      backgroundColor: Colors.blue[200],
      appBar: new AppBar(
        title: Text('Permissions'),
        backgroundColor: Colors.red,
        leading: Icon(Icons.perm_identity),
      ),
      body: SafeArea(
          child: Container(
            decoration: new BoxDecoration(
                color: Color.fromRGBO(0, 22, 58, 1.0),
                image: new DecorationImage(image: new AssetImage('images/club_2.jpg'),
                    fit: BoxFit.cover)
            ),
            padding: EdgeInsets.fromLTRB(30, 0, 30, 0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                //new Padding(padding: EdgeInsets.fromLTRB(150, 20, 10, 10)),
                new Text('You must activate contacts permission to use the app',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 20,
                      fontWeight: FontWeight.bold
                  ),),
                new Text('$_status', style: new TextStyle(
                  color: getPermissionColor(),
                ),),
                new RaisedButton(
                  textColor: Colors.indigo,

                  child: Text('Ask Permission'),
                  onPressed: _askPermission,
                )],
            ),
          )
      ),
    );
  }

  Color getPermissionColor() {
    switch (_status) {
      case PermissionStatus.denied:
        return Colors.red;
      case PermissionStatus.granted:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }


  FutureOr _updateStatus(PermissionStatus value) {
    if( value != _status){
      setState(() {
        _status = value;
        _finishTask();
      });
    }
  }

  FutureOr _askPermission() {
    return PermissionHandler().requestPermissions([PermissionGroup.contacts])
        .then(_onStatusRequest);
  }

  FutureOr _onStatusRequest(Map<PermissionGroup, PermissionStatus> statuses) {
    final status =statuses[PermissionGroup.contacts];
    return _updateStatus(status);
  }

  void _finishTask() async{
      if(_status == PermissionStatus.granted){
        Navigator.of(context).pushReplacement(CupertinoPageRoute(
          builder: (context) => WelcomeScreen(userDocument: widget.userDocument,),
        ));
      }
  }
}



