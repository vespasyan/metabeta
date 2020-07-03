import 'dart:async';
import 'dart:math';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:metaphor_beta/UserListWidget.dart';
import 'chat_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:metaphor_beta/constants/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:metaphor_beta/my_colors.dart';
import 'package:flutter_sms/flutter_sms.dart';

class Chatlayout extends StatefulWidget {


  final DocumentSnapshot userDocument;

  Chatlayout ({this.userDocument});


  @override
  ChatlayoutState createState() {
    return new ChatlayoutState();
  }
}

class ChatlayoutState extends State<Chatlayout> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Iterable<Contact> _contacts;

  bool _isCreatingLink = false;

  String _linkMessage = "";

  @override
  void initState() {
    super.initState();

    initDynamicLinks();
    _createDynamicLink(true);

    refreshContacts();

  }


  void initDynamicLinks() async {
    final PendingDynamicLinkData data = await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {
      Navigator.pushNamed(context, deepLink.path);
    }

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
          final Uri deepLink = dynamicLink?.link;

          if (deepLink != null) {
            Navigator.pushNamed(context, deepLink.path);
          }
        },
        onError: (OnLinkErrorException e) async {
          print('onLinkError');
          print(e.message);
        }
    );
  }


  //Connect your phone

  Future<void> _createDynamicLink(bool short) async {
    setState(() {
      _isCreatingLink = true;
    });


    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://flutterchatapp.page.link',
      link: Uri.parse('https://metaphor.chat'),
      androidParameters: AndroidParameters(
        packageName: 'tech.metaphor.flutterchatapp',
        minimumVersion: 0,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        bundleId: 'tech.metaphor.metaphorLast',
        minimumVersion: '0',
      ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
    } else {
      url = await parameters.buildUrl();
    }

    setState(() {
      _linkMessage = url.toString();
      _isCreatingLink = false;
    });
  }


  refreshContacts() async {
    var contacts = await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      _contacts = contacts;
    });
  }


  @override
  Widget build(BuildContext context) {
    Contact con;
    Random random;
    return Scaffold(
      backgroundColor: Color.fromRGBO(29, 23, 58, 1.0),
      //appBar: AppBar(title: Text('Contacts Plugin Example')),
      floatingActionButton: InkWell(
        splashColor: Colors.green[800],
          child: Icon(Icons.add_circle, color: Colors.blue[600], size: 40,),
          onTap : () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => UserListWidget(contacts: _contacts,dynamicLink: _linkMessage,)));

            /*Navigator.of(context).pushNamed("/add").then((_) {
              refreshContacts();
            });*/
          }),
      body:
      SafeArea(
        child: Container(
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          decoration: new BoxDecoration(
            image: new DecorationImage(
                image: new AssetImage('images/navy_blue_1.jpg'),
                fit: BoxFit.cover),),
          child:_contacts != null
              ? ListView.builder(
            itemCount: _contacts?.length ?? 0,
            itemBuilder: (BuildContext context, int index) {
              Contact c = _contacts?.elementAt(index);
              return Row(
                children: <Widget>[
                  Expanded(
                      child: Card(
                        color: Color.fromRGBO(55, 105, 205, 0.25),
                        //semanticContainer: true,
                        shape: StadiumBorder(side: BorderSide(
                          width: 1.0,
                          color: Color(0xff002251),
                          style: BorderStyle.solid,)
                        ),
                        elevation: 5.0,
                        margin: EdgeInsets.only(bottom: 15.0),
                        child: ListTile(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (BuildContext context) =>
                                    Chat(peerId: null, peerAvatar: null, userName: c)));
                          },
                          leading: (c.avatar != null && c.avatar.length > 0)
                              ? CircleAvatar(backgroundImage: MemoryImage(c.avatar),
                              backgroundColor: colors[random.nextInt(4)])
                              : CircleAvatar(
                            backgroundColor: colors[index % colors.length],
                            child: Text(c.displayName.length > 1
                                ? c.displayName?.substring(0, 2)
                                : ""),
                          ),
                          title: Text(c.displayName ?? "", style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),

                          dense: false,
                          trailing: _checkColorGrey(),
                          enabled: true,
                          onLongPress: _checkContactStatus,

                        ),
                      )
                  ),
                ],
              );
            },
          )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }



  Widget _checkColorGrey(){
    return Container(
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Color(0xFF7991b8),
      ),
    );
  }

  Widget _checkColorGreen(){
    return Container(
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Color(0xFF7991b8),
      ),
    );
  }

   _checkContactStatus()async{
    FirebaseAuth.instance.currentUser().then((user){
      if(user==null) {
        _checkColorGrey();
      }
      else{
        _checkColorGreen();
      }
    });
  }

  void _sendSMS(String message, Iterable<String> recipents) async {
    String _result = await FlutterSms
        .sendSMS(message: message, recipients: recipents)
        .catchError((onError) {
      print(onError);
    });
    print(_result);
  }

  saveUserToPreferences(String userId, String userName, String pushId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(USER_ID, userId);
    prefs.setString(PUSH_ID, pushId);
    prefs.setString(USER_NAME, userName);
  }

  void updateFcmToken() async{
    var currentUser = await _firebaseAuth.currentUser();
    if(currentUser != null){
      var token = await _firebaseMessaging.getToken();
      print(token);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.setString(PUSH_ID, token);

      Firestore.instance
          .collection('Users')
          .reference()
          .document(currentUser.uid)
          .collection('Messages')
          .toString()
          .trim();

    }
  }
}






