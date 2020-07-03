import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metaphor_beta/const.dart';
import 'package:metaphor_beta/welcome_screen/welcomeScreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metaphor_beta/authentication/auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(new MyMainScreen());

class MyMainScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metaphor',
      home: FirstScreen(
        title: 'Metaphor',
      ),
      debugShowCheckedModeBanner: false,
      theme:
          ThemeData(primarySwatch: Colors.red, fontFamily: 'Times New Roman'),
      routes: <String, WidgetBuilder>{
        '/WelcomeScreen': (BuildContext context) => new WelcomeScreen(),
        '/AuthScreen': (BuildContext context) => new AuthScreen()
      },
    );
  }
}

class FirstScreen extends StatefulWidget {
  final String title;

  const FirstScreen({Key key, this.title}) : super(key: key);

  @override
  State<StatefulWidget> createState() => new _FirstScreenState();
}

class _FirstScreenState extends State<FirstScreen> {
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          CircularProgressIndicator(),
          Center(
            child: Text(
              "Please wait\nwhile we are loading your preference",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.redAccent,fontSize: 16.0),
            ),
          ),
        ],
      ),
    );
  }

  checkForToken() {
    FirebaseAuth.instance.currentUser().then((user) {
      if (user == null) {
        //Fluttertoast.showToast(msg: "Not Logged In");
        Navigator.of(context).pushReplacementNamed("/AuthScreen");
      } else {
        //Navigator.of(context).pushReplacementNamed("/WelcomeScreen");

        //Fluttertoast.showToast(msg: "Logging you in please wait");
        print("Phone number ${user.phoneNumber}");
        Firestore.instance
            .collection('users')
            .where('email', isEqualTo: user.email)
            // .limit(1)
            .getDocuments()
            .then((userDoc) {
          //Fluttertoast.showToast(msg: "User found");
          if (userDoc != null && userDoc.documents.length > 0) {
            //Fluttertoast.showToast(msg: "User doc Length found");
            if (userDoc.documents[0] != null) {
              //Fluttertoast.showToast(msg: "User doc found");
              print("device token : ${Constants.deviceToken}");
              //Fluttertoast.showToast(msg: "Redirecting User");
              Navigator.of(context).pushReplacement(CupertinoPageRoute(
                builder: (context) =>
                    WelcomeScreen(userDocument: userDoc.documents[0]),
              ));
            }
          } else {
            //Fluttertoast.showToast(msg: "User not found");
            Navigator.of(context).pushReplacementNamed("/AuthScreen");
          }
        });
      }
    });
  }

  @override
  void initState() {
    super.initState();

    firebaseCloudMessaging_Listeners();
  }

  void firebaseCloudMessaging_Listeners() {
    if (Platform.isIOS) iOS_Permission();

    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print('on message $message');
      },
      onResume: (Map<String, dynamic> message) async {
        print('on resume $message');
      },
      onLaunch: (Map<String, dynamic> message) async {
        print('on launch $message');
      },
    );

    _firebaseMessaging.getToken().then((token) {
      print('Firebase Messaging Token : $token');

      Constants.deviceToken = token;
      //Fluttertoast.showToast(msg: "Token Found");
      checkForToken();
    });
  }

  void iOS_Permission() {
    _firebaseMessaging.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
  }
}
