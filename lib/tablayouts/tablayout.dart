import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity/connectivity.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metaphor_beta/ChatListPage.dart';
import 'package:metaphor_beta/ChatPage.dart';
import 'package:metaphor_beta/Model/NotfiicationUser.dart';
import 'package:metaphor_beta/const.dart';
import 'package:metaphor_beta/tablayouts/call/call_layout.dart';
import 'package:metaphor_beta/tablayouts/chat/chat_layout.dart';
import 'search_layout.dart';
import 'package:contacts_service/contacts_service.dart';

class TabLayouts extends StatefulWidget {
  final cameras;
  final DocumentSnapshot userDocument;

  final bool inApp;

  const TabLayouts({Key key, this.cameras, this.userDocument, this.inApp})
      : super(key: key);

  //TabLayouts(this.cameras);

  @override
  _TabLayoutsState createState() => new _TabLayoutsState();
}

class _TabLayoutsState extends State<TabLayouts>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  TabController _tabController;
  final TextEditingController _filter = new TextEditingController();
  var contacts = ContactsService.getContacts(withThumbnails: false);
  Contact _contacts;

  String _connectionStatus = 'Unknown';
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult> _connectivitySubscription;

  /// platform to execute native platform

  static const platform =
      const MethodChannel('com.metaphor.flutterchatapp/platform_channel');

  /// Get intentData for android user

  String intentData = "false";

  NotificationUser notificationUserInApp;

  void updateDeviceToken() async {
    await Firestore.instance
        .collection('users')
        .document(widget.userDocument.documentID)
        .updateData({
      'device_token': Constants.deviceToken,
      'user_device_type': Platform.isIOS ? "I" : "A"
    });
  }

  @override
  void initState() {
    super.initState();

    updateDeviceToken();

    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);

    initDynamicLinks();
    Firestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userDocument['email'])
        .getDocuments()
        .then((userDoc) {
      Firestore.instance
          .collection('users')
          .document(userDoc.documents[0].documentID)
          .updateData({'isOnline': "Online"});
    });

    WidgetsBinding.instance.addObserver(this);
    platform.setMethodCallHandler(_handleMethod);


    _tabController = new TabController(vsync: this, initialIndex: 0, length: 2);

    if (!Constants.inApp) {
      getIntent();
    }
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initConnectivity() async {
    ConnectivityResult result;
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      result = await _connectivity.checkConnectivity();
    } on PlatformException catch (e) {
      print(e.toString());
    }

    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) {
      return;
    }
    _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(ConnectivityResult result) async {

    print("Connected Status ${result.toString()}" );




    switch (result) {
      case ConnectivityResult.wifi:
        Firestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.userDocument['email'])
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({
            'isConnected': "true"
          });
        });

        Constants.isConnected = "true";

          setState(() => _connectionStatus = result.toString());
        break;
      case ConnectivityResult.mobile:

        Firestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.userDocument['email'])
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({
            'isConnected': "true"
          });
        });

        Constants.isConnected = "true";
        setState(() => _connectionStatus = result.toString());
        break;
      case ConnectivityResult.none:

        Firestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.userDocument['email'])
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({
            'isConnected': "false"
          });
        });
        Constants.isConnected = "false";
        setState(() => _connectionStatus = result.toString());
        break;
      default:
        setState(() => _connectionStatus = 'Failed to get connectivity.');
        break;
    }
  }


  void initDynamicLinks() async {
    final PendingDynamicLinkData data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri deepLink = data?.link;

    if (deepLink != null) {}

    FirebaseDynamicLinks.instance.onLink(
        onSuccess: (PendingDynamicLinkData dynamicLink) async {
      final Uri deepLink = dynamicLink?.link;

      if (deepLink != null) {
        Firestore.instance
            .collection('users')
            .where('deepLink', isEqualTo: widget.userDocument.data['deepLink'])
            .getDocuments()
            .then((userDoc) {
          if (userDoc != null && userDoc.documents.length > 0) {
            if (userDoc.documents[0] != null) {


              Firestore.instance
                  .collection('users')
                  .where('ID',
                  isEqualTo: widget
                      .userDocument
                      .data["ID"])
                  .getDocuments()
                  .then((userDocF) async {
                await Firestore.instance
                    .collection('users')
                    .document(userDocF
                    .documents[0]
                    .documentID)
                    .updateData({
                  'chatWith': userDoc.documents[0]
                      .data["ID"]
                });
              });


              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => ChatPage(
                          userDocument: widget.userDocument,
                          peerDocument: userDoc.documents[0],
                          type: 0,
                        )),
              );
            }
          }
        });
      }
    }, onError: (OnLinkErrorException e) async {
      print('onLinkError');
      print(e.message);
    });
  }

  @override
  Future didChangeAppLifecycleState(AppLifecycleState state) async {
    // TODO: implement didChangeAppLifecycleState
    print('state = $state');

    var userNot = widget.userDocument;

    if (state == AppLifecycleState.inactive) {
      if (userNot != null) {
        await Firestore.instance
            .collection('users')
            .where('email', isEqualTo: widget.userDocument['email'])
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({
            'isOnline': DateTime.now().millisecondsSinceEpoch.toString()
          });
        });

        await Firestore.instance
            .collection('CurrentlyActiveUser')
            .document(userNot['ID'].toString())
            .delete();

        await Firestore.instance
            .collection('ChatBadge')
            .document(userNot['ID'].toString())
            .collection(userNot['ID'].toString())
            .document(userNot['ID'].toString())
            .delete();
      }
    } else if (state == AppLifecycleState.resumed) {
      /*if (user != null) {
        if (user.status == Status.Authenticated) {
          await Firestore.instance
              .collection('ChatBadge')
              .document(user.userDocument['ID'].toString())
              .collection(user.userDocument['ID'].toString())
              .document(user.userDocument['ID'].toString())
              .delete();
        }
      }*/

      Firestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userDocument['email'])
          .getDocuments()
          .then((userDoc) {
        Firestore.instance
            .collection('users')
            .document(userDoc.documents[0].documentID)
            .updateData({'isOnline': "Online"});
      });

      print("Resume INAPP ${widget.inApp}");

      if (notificationUserInApp != null) {
        getInAppIntent();
      } else {
        if (!Constants.inApp) {
          getIntent();
        }
      }
    } else if (state == AppLifecycleState.suspending) {
      if (userNot != null) {
        await Firestore.instance
            .collection('CurrentlyActiveUser')
            .document(userNot['ID'].toString())
            .delete();
        await Firestore.instance
            .collection('ChatBadge')
            .document(userNot['ID'].toString())
            .collection(userNot['ID'].toString())
            .document(userNot['ID'].toString())
            .delete();
      }
    }
  }

  /// Get Intent data on Notification click

  Future getIntent() async {
    var getData = await platform.invokeMethod("getIntent");
    print("getData $getData");
    if (getData != null) {
      intentData = getData;
      print("intentData $intentData");

      if (intentData != "false" && intentData.length > 0 && intentData.isNotEmpty) {
        final jsonResponse = json.decode(intentData);
        NotificationUser notificationUser =
            new NotificationUser.fromJson(jsonResponse);

        var userNoti = widget.userDocument;

        if (userNoti != null) {

          Firestore.instance
              .collection('users')
              .where('ID',
              isEqualTo: widget
                  .userDocument
                  .data["ID"])
              .getDocuments()
              .then((userDocF) async {
            await Firestore.instance
                .collection('users')
                .document(userDocF
                .documents[0]
                .documentID)
                .updateData({
              'chatWith': notificationUser.peerId
            });
          });

          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ChatPage(
                      userDocument: userNoti,
                      notificationUser: notificationUser,
                      type: 3,
                    )),
          );
        }
      }
    }
  }

  /// Get InApp Notification Intent Data

  Future getInAppIntent() async {
    var userNoti = widget.userDocument;

    if (userNoti != null) {
      NotificationUser tempNoti = notificationUserInApp;
      notificationUserInApp = null;
      Constants.inApp = true;
      if (tempNoti.peerName.isNotEmpty && tempNoti.peerName.length > 0) {

        Firestore.instance
            .collection('users')
            .where('ID',
            isEqualTo: widget
                .userDocument
                .data["ID"])
            .getDocuments()
            .then((userDocF) async {
          await Firestore.instance
              .collection('users')
              .document(userDocF
              .documents[0]
              .documentID)
              .updateData({
            'chatWith': tempNoti.peerId
          });
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatPage(
              userDocument: userNoti,
              notificationUser: tempNoti,
              type: 3,
            ),
          ),
        );
      }
    }
  }


  /// Handle Native call made from native platforms [Communicate with Native to Flutter Application]


  Future<dynamic> _handleMethod(MethodCall call) async {
    switch (call.method) {
      case "notification":
        print("Call Back ${call.arguments}");
        if (call.arguments != null) {
          final jsonResponse = json.decode(call.arguments);
          notificationUserInApp = new NotificationUser.fromJson(jsonResponse);
          Constants.inApp = false;
          //if (Platform.isIOS) {
            getInAppIntent();
          //}
        }
    }
  }


  Future<bool> onBackPress() {
    exit(0);
    return Future.value(false);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: new Scaffold(
        resizeToAvoidBottomPadding: false,
        appBar: new AppBar(
          centerTitle: true,
          backgroundColor: Colors.red[800],
          title: new Text("Metaphor"),
          elevation: 0.7,
          bottom: new TabBar(
            controller: _tabController,
            indicatorColor: Colors.blue,
            tabs: <Widget>[
              //new Tab(icon: new Icon(Icons.camera_alt)),
              new Tab(text: "CHATS"),
              //new Tab(text: "STATUS"),
              new Tab(text: "CALLS"),
            ],
          ),
          /*
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch(context: context, delegate: SearchContacts());
              },
            ),
            new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5.0),
            ),
            new Icon(Icons.more_vert)
          ],
          */
        ),
        /*
        drawer: Drawer(
          child: Container(
            decoration: new BoxDecoration(
              color: Color.fromRGBO(10, 15, 45, 1),
            ),
          ),
        ),
        */
        body: new TabBarView(
          controller: _tabController,
          children: <Widget>[
            //new Chatlayout(),

            ChatListPage(
              userDocument: widget.userDocument,
            ),
            //new StatusScreen(),
            new Callslayout(),
            //new CameraScreen(widget.cameras)
          ],
        ),
      ),
    );
  }

}
