import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'call_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metaphor_beta/constants/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metaphor_beta/webrtc/webrtc_main.dart';
import 'popup.dart';
import 'package:google_sign_in/google_sign_in.dart';

class Callslayout extends StatefulWidget {
  @override
  CallslayoutState createState() {
    return new CallslayoutState();
  }
}

class CallslayoutState extends State<Callslayout> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Iterable<Contact> _contacts;
  GoogleSignIn _googleSignIn = GoogleSignIn();
  GoogleSignInAccount _googleSignInAccount;

  ReturnPopup returnPopup = new ReturnPopup();

  @override
  void initState() {
    super.initState();
    refreshContacts();

    //updateFcmToken();
  }

  refreshContacts() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      var contacts = await ContactsService.getContacts();
      setState(() {
        _contacts = contacts;
      });
    } else {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await PermissionHandler()
        .checkPermissionStatus(PermissionGroup.contacts);
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler()
              .requestPermissions([PermissionGroup.contacts]);
      return permissionStatus[PermissionGroup.contacts] ??
          PermissionStatus.unknown;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw new PlatformException(
          code: "PERMISSION_DENIED",
          message: "Access to location data denied",
          details: null);
    } else if (permissionStatus == PermissionStatus.disabled) {
      throw new PlatformException(
          code: "PERMISSION_DISABLED",
          message: "Location data is not available on device",
          details: null);
    }
  }

  _handleSubmitted() {
    GoogleSignInAccount user = _googleSignIn.currentUser;
    return user.photoUrl;
  }

  @override
  Widget build(BuildContext context) {
    List<Color> colors = [
      Colors.red,
      Colors.blue[900],
      Colors.blue,
      Colors.green,
      Colors.deepOrange,
      Colors.green[700]
    ];
    Random random;
    const polo = 7;

    return Scaffold(
      backgroundColor: Color.fromRGBO(29, 23, 58, 1.0),
      //appBar: AppBar(title: Text('Contacts Plugin Example')),
      floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: () {
            Navigator.of(context).pushNamed("/add").then((_) {
              refreshContacts();
            });
          }),

      body: SafeArea(
        bottom: false,

        /*
      padding: EdgeInsets.only(left: 20.0),
      decoration: new BoxDecoration(
        image: new DecorationImage(
            image: new AssetImage('images/navy_blue_1.jpg'),
            fit: BoxFit.cover),),
      */
        child: Container(
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          decoration: new BoxDecoration(
            image: new DecorationImage(
                image: new AssetImage('images/navy_blue_4.jpg'),
                fit: BoxFit.cover),
          ),
          child: _contacts != null
              ? ListView.builder(
                  itemCount: _contacts?.length ?? 0,
                  itemBuilder: (BuildContext context, int index) {
                    Contact c = _contacts?.elementAt(index);
                    return Row(
                      children: <Widget>[
                        Expanded(
                            child: Card(
                          color: Color.fromRGBO(55, 105, 205, 0.15),
                          //semanticContainer: true,
                          shape: StadiumBorder(
                              side: BorderSide(
                            width: 1.0,
                            color: Color(0xff002251),
                            style: BorderStyle.solid,
                          )),
                          elevation: 5.0,
                          margin: EdgeInsets.only(bottom: 15.0),
                          /*
                      height: 75,
                      padding: EdgeInsets.all(10.0),
                      decoration: new BoxDecoration(
                          color: Color.fromRGBO(55, 100, 225, 0.2),
                        shape: BoxShape.rectangle,
                        borderRadius: new BorderRadius.circular(5.0),
                      ),
                      */
                          child: ListTile(
                            onTap: () {
                              returnPopup.information(context, 'Alert',
                                  'Call service is not available yet !!!');
                              //Navigator.of(context).push(MaterialPageRoute(
                              //  builder: (BuildContext context) =>
                              //    MyWebRtc()));
                            },
                            leading: CircleAvatar(
                              backgroundColor: colors[index % colors.length],
                              child: Text(c.displayName.length > 1
                                  ? c.displayName?.substring(0, 2)
                                  : ""),
                            ),
                            /*(c.avatar != null && c.avatar.length > 0)
                                  ? CircleAvatar(backgroundImage:
                              CachedNetworkImageProvider(
                                _googleSignInAccount.photoUrl
                              ),
                                  backgroundColor: colors[random.nextInt(4)])
                                  : CircleAvatar(
                                backgroundColor: colors[index % colors.length],
                                child: Text(c.displayName.length > 1
                                    ? c.displayName?.substring(0, 2)
                                    : ""),
                              ),*/
                            title: Text(c.displayName ?? "",
                                style: TextStyle(
                                  color: Color(0xFFa7adb7),
                                  fontWeight: FontWeight.bold,
                                )),
                            subtitle: Text(c.identifier ?? "",
                                style: TextStyle(
                                  color: Color(0xFFa7adb7),
                                  fontWeight: FontWeight.w100,
                                )),
                            dense: true,
                          ),
                        )),
                      ],
                    );
                  },
                )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }
}
