import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:metaphor_beta/Model/NotfiicationUser.dart';
import 'package:metaphor_beta/const.dart';
import 'package:metaphor_beta/my_colors.dart';
import 'package:metaphor_beta/tablayouts/tablayout.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:photo_view/photo_view.dart';
import 'package:metaphor_beta/tablayouts/chat/chat_animations/screen_wrapper.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatelessWidget {
  /* final String peerId;
  final String peerAvatar;
  final String name;
  final String avatarUrl;
  final String userId;*/

  ///Getting User and Peer Details
  ///If user came from Application Chat We are using userDocument and peerDocument
  ///If user came from Notification We are using userDocument and notificationUser

  final DocumentSnapshot userDocument;
  final DocumentSnapshot peerDocument;
  final NotificationUser notificationUser;
  final int type;

  /* Chat(
      {Key key,
      @required this.userId,
      @required this.peerId,
      @required this.peerAvatar,
      @required this.name,
      @required this.avatarUrl})
      : super(key: key);*/

  ChatPage(
      {Key key,
      @required this.userDocument,
      @required this.peerDocument,
      @required this.notificationUser,
      @required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: true,
      bottom: true,
      child: new Scaffold(
        /// Creating AppBar with Car Name
        backgroundColor: new Color.fromRGBO(29, 23, 58, 0.85),
        appBar: new AppBar(
          backgroundColor: Colors.red,
          centerTitle: false,
          title: Row(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: new CircleAvatar(
                  foregroundColor: Theme.of(context).primaryColor,
                  backgroundColor: colors[3 % colors.length],
                  child: Text(
                    type == 1 || type == 0
                        ? peerDocument["name"]?.substring(0, 2)
                        : notificationUser.peerName?.substring(0, 2),
                    style: TextStyle(color: Colors.white),
                  ),
                  /*backgroundImage: ((type == 1 || type == 0) &&
                              peerDocument["profileImage"] != null &&
                              peerDocument["profileImage"]
                                  .toString()
                                  .isNotEmpty) ||
                          (type == 3 &&
                              notificationUser.peerProfilePic != null &&
                              notificationUser.peerProfilePic.isNotEmpty)
                      ? new NetworkImage(type == 1 || type == 0
                          ? peerDocument["profileImage"]
                          : notificationUser.peerProfilePic)
                      : CircleAvatar(
                          backgroundColor: colors[2 % colors.length],
                          child: ,
                        ),*/
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: new Text(
                      type == 1 || type == 0
                          ? peerDocument["name"]
                          : notificationUser.peerName,
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  StreamBuilder<QuerySnapshot>(
                      stream: Firestore.instance
                          .collection('users')
                          .where('ID',
                              isEqualTo: type == 1 || type == 0
                                  ? peerDocument.data["ID"]
                                  : notificationUser.peerId)
                          .snapshots(),
                      builder: (context, snapshot) {
                        return Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: new Text(
                            snapshot.hasData && snapshot.data != null
                                ? snapshot.data.documents[0]['isOnline'] ==
                                        "Online"
                                    ? "Online"
                                    : snapshot.data.documents[0]['isOnline'] ==
                                            "isTyping"
                                        ? snapshot.data.documents[0]
                                                    ['chatWith'] ==
                                                userDocument.data["ID"]
                                            ? "is Typing..."
                                            : "Online"
                                        : showLastSeen(snapshot
                                            .data.documents[0]['isOnline'])
                                : "",
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.0),
                          ),
                        );
                      }),
                ],
              )
            ],
          ),
        ),

        /// Chat Screen

        body: Container(
          decoration: new BoxDecoration(
              image: new DecorationImage(
                  image: new AssetImage('images/particles_dark.gif'),
                  fit: BoxFit.cover)),
          child: new ChatScreen(
            userDocument: userDocument,
            userId: userDocument["ID"],
            userName: userDocument["name"],
            userAvatar: userDocument["profileImage"],
            userToken: userDocument["device_token"],
            peerId: type == 1 || type == 0
                ? peerDocument["ID"]
                : notificationUser.peerId,
            peerName: type == 1 || type == 0
                ? peerDocument["name"]
                : notificationUser.peerName,
            peerAvatar: type == 1 || type == 0
                ? peerDocument["profileImage"]
                : notificationUser.peerProfilePic,
            peerDeviceToken: type == 1 || type == 0
                ? peerDocument["device_token"]
                : notificationUser.peerDeviceToken,
            peerDeviceType: type == 3
                ? notificationUser.peerDeviceType
                : peerDocument["user_device_type"],
            type: type,
          ),
        ),
      ),
    );
  }

  /// The last day of a given month
  DateTime lastDayOfMonth(DateTime month) {
    var beginningNextMonth = (month.month < 12)
        ? new DateTime(month.year, month.month + 1, 1)
        : new DateTime(month.year + 1, 1, 1);
    return beginningNextMonth.subtract(new Duration(days: 1));
  }

  /// Get months between two dates

  int monthsBetweenDates(DateTime startDate, DateTime endDate) {
    /* Calendar start = Calendar.getInstance();
    start.setTime(startDate);

    Calendar end = Calendar.getInstance();
    end.setTime(endDate);
*/
    int monthsBetween = 0;
    int dateDiff = endDate
        .difference(startDate)
        .inDays; //end.get(Calendar.DAY_OF_MONTH) - start.get(Calendar.DAY_OF_MONTH);

    if (dateDiff < 0) {
      /*int borrrow = end.getActualMaximum(Calendar.DAY_OF_MONTH);
      dateDiff = (end.get(Calendar.DAY_OF_MONTH) + borrrow) - start.get(Calendar.DAY_OF_MONTH);*/

      int borrrow = lastDayOfMonth(endDate).day;

      dateDiff = endDate.day + borrrow - startDate.day;
      monthsBetween--;

      if (dateDiff > 0) {
        monthsBetween++;
      }
    } else {
      monthsBetween++;
    }
    //monthsBetween += end.get(Calendar.MONTH) - start.get(Calendar.MONTH);
    //monthsBetween += (end.get(Calendar.YEAR) - start.get(Calendar.YEAR)) * 12;

    monthsBetween += endDate.month - startDate.month;
    monthsBetween += (endDate.year - startDate.year) * 12;
    return monthsBetween;
  }

  String showLastSeen(String userStatus) {
    if (userStatus != "Online") {
      String todayDateText,
          yesterdayDateText,
          twodayDateText,
          threedayDateText,
          fourdayDateText,
          fivedayDateText,
          sixdayDateText,
          weekDateText;

      String showDateTime = "";

      todayDateText = DateFormat("dd-MM-yyyy")
          .format(DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch))
          .toString();

      yesterdayDateText = DateFormat("dd-MM-yyyy").format(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day - 1));

      twodayDateText = DateFormat("dd-MM-yyyy").format(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day - 2));

      threedayDateText = DateFormat("dd-MM-yyyy").format(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day - 3));

      fourdayDateText = DateFormat("dd-MM-yyyy").format(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day - 4));
      fivedayDateText = DateFormat("dd-MM-yyyy").format(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day - 5));
      sixdayDateText = DateFormat("dd-MM-yyyy").format(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day - 6));
      weekDateText = DateFormat("dd-MM-yyyy").format(DateTime(
          DateTime.now().year, DateTime.now().month, DateTime.now().day - 7));

      int dayCount = DateTime.now()
          .difference(
              DateTime.fromMillisecondsSinceEpoch(int.parse(userStatus)))
          .inDays;

      //long dayCount = diff / (24 * 60 * 60 * 1000);
      int week = (dayCount / 7).round();
      int month = 0;

      month = monthsBetweenDates(
          DateTime.fromMillisecondsSinceEpoch(
              DateTime.now().millisecondsSinceEpoch),
          DateTime.fromMillisecondsSinceEpoch(int.parse(userStatus)));

      if (dayCount >= 7) {
        if (week >= 4) {
          if (month >= 12) {
            showDateTime = "year ago";
          } else {
            if (month == 1) {
              showDateTime = " $month month ago";
            } else {
              showDateTime = "$month months ago";
            }
          }
        } else {
          if (week == 1) {
            showDateTime = "$week week ago";
          } else {
            showDateTime = "$week weeks ago";
          }
        }
      } else {
        String apiDateText = DateFormat("dd-MM-yyyy")
            .format(DateTime.fromMillisecondsSinceEpoch(int.parse(userStatus)))
            .toString();

        if (apiDateText == todayDateText) {
          int hourOfDay =
              DateTime.fromMillisecondsSinceEpoch(int.parse(userStatus)).hour;

          int minute =
              DateTime.fromMillisecondsSinceEpoch(int.parse(userStatus)).minute;

          bool isPM = (hourOfDay >= 12);

          String hourOfDayString =
              ((hourOfDay == 12 || hourOfDay == 0) ? 12 : hourOfDay % 12)
                  .toString()
                  .padLeft(2, '0');
          showDateTime =
              "last seen today at $hourOfDayString:${minute.toString().padLeft(2, '0')} ${isPM ? "pm" : "am"}";
        } else if (apiDateText == yesterdayDateText) {
          showDateTime = "Yesterday";
        } else if (apiDateText == twodayDateText) {
          showDateTime = "2 days ago";
        } else if (apiDateText == threedayDateText) {
          showDateTime = "3 days ago";
        } else if (apiDateText == fourdayDateText) {
          showDateTime = "4 days ago";
        } else if (apiDateText == fivedayDateText) {
          showDateTime = "5 days ago";
        } else if (apiDateText == sixdayDateText) {
          showDateTime = "6 days ago";
        } else if (apiDateText == weekDateText) {
          showDateTime = "1 week ago";
        }
      }
      return showDateTime;
    }
  }
}

class ChatScreen extends StatefulWidget with WidgetsBindingObserver {
  final DocumentSnapshot userDocument;

  final String userId;
  final String userName;
  final String userAvatar;
  final String userToken;

  final String peerId;
  final String peerName;
  final String peerAvatar;
  final String peerDeviceToken;
  final String peerDeviceType;
  final int type;

  ChatScreen(
      {Key key,
      @required this.userDocument,
      @required this.userId,
      @required this.userName,
      @required this.userAvatar,
      @required this.userToken,
      @required this.peerId,
      @required this.peerName,
      @required this.peerAvatar,
      @required this.peerDeviceToken,
      @required this.peerDeviceType,
      @required this.type})
      : super(key: key);

  @override
  State createState() => new ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  //String id;

  var listMessage;

  /// List of  Messages
  String groupChatId;

  /// Creating Group ID like if 43 chating to 46 -> 43_46 like wise..
  SharedPreferences prefs;

  var platform =
      const MethodChannel('com.metaphor.flutterchatapp/platform_channel');

  File imageFile;

  /// Sending Image File
  bool isLoading;

  /// Loaded or not

  String imageUrl;

  /// Load image from url

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();
  final FocusNode focusNodeType = new FocusNode();
  bool isShowSticker;

  Animation<double> _animation;
  AnimationController _animationController;


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
            .document(widget.userId.toString())
            .delete();

        await Firestore.instance
            .collection('ChatBadge')
            .document(widget.userId.toString())
            .collection(widget.userId.toString())
            .document(widget.userId.toString())
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

      await Firestore.instance
          .collection('users')
          .where('email', isEqualTo: widget.userDocument['email'])
          .getDocuments()
          .then((userDoc) {
        Firestore.instance
            .collection('users')
            .document(userDoc.documents[0].documentID)
            .updateData({'isOnline': "Online"});
      });

    } else if (state == AppLifecycleState.suspending) {
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
            .document(widget.userId.toString())
            .delete();
        await Firestore.instance
            .collection('ChatBadge')
            .document(widget.userId.toString())
            .collection(widget.userId.toString())
            .document(widget.userId.toString())
            .delete();
      }
    }
  }


  @override
  void initState() {
    super.initState();

    groupChatId = '';

    isLoading = false;
    isShowSticker = false;
    imageUrl = '';
    WidgetsBinding.instance.addObserver(this);
    readLocal();
    Firestore.instance
        .collection('CurrentlyActiveUser')
        .document(widget.userId.toString())
        .collection(widget.userId.toString())
        .document(widget.peerId.toString())
        .setData({
      'ID': widget.peerId,
    });

    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
        vsync: this,
        duration: Duration(
            seconds:
            2)); //specify the duration for the animation & include `this` for the vsyc
    _animation = Tween<double>(begin: 1.0, end: 2).animate(
        _animationController); //use Tween animation here, to animate between the values of 1.0 & 2.5.

    _animation.addListener(() {
      //here, a listener that rebuilds our widget tree when animation.value changes
      setState(() {});
    });

    _animation.addStatusListener((status) {
      //AnimationStatus gives the current status of our animation, we want to go back to its previous state after completing its animation
      _animationController.isCompleted;
      if (status == AnimationStatus.completed) {
        //reverse the animation back here if its completed
        _animationController.reverse();
      }
    });
  }

  @override
  Future dispose() async {
    super.dispose();
    print("ChatPage Dispose");
    await Firestore.instance
        .collection('CurrentlyActiveUser')
        .document(widget.userId.toString())
        .collection(widget.userId.toString())
        .document(widget.peerId.toString())
        .delete();
  }

  /// Generating Group ID from userId and peerID

  readLocal() async {
    prefs = await SharedPreferences.getInstance();

    //id = prefs.getString('id') ?? '2';
    if (widget.userId.hashCode <= widget.peerId.hashCode) {
      groupChatId = '${widget.userId}-${widget.peerId}';
    } else {
      groupChatId = '${widget.peerId}-${widget.userId}';
    }
    setState(() {});
  }

  /// Get Image from firebase to load

  Future getImage() async {
    imageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if (imageFile != null) {
      setState(() {
        isLoading = true;
      });
      uploadFile();
    }
  }

  Future getSticker() async {
    // Hide keyboard when sticker appear
    focusNode.unfocus();
    setState(() {
      isShowSticker = !isShowSticker;
    });
  }

  /// Upload Image to Firebase

  Future uploadFile() async {
    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    StorageReference reference = FirebaseStorage.instance.ref().child(fileName);
    StorageUploadTask uploadTask = reference.putFile(imageFile);
    StorageTaskSnapshot storageTaskSnapshot = await uploadTask.onComplete;
    storageTaskSnapshot.ref.getDownloadURL().then((downloadUrl) {
      imageUrl = downloadUrl;
      setState(() {
        isLoading = false;
        onSendMessage(imageUrl, 1);
      });
    }, onError: (err) {
      setState(() {
        isLoading = false;
      });
      //Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  /// Send Message to other user

  Future onSendMessage(String content, int type) async {
    // type: 0 = text, 1 = image, 2 = sticker
    /*if (type != 0) {
      content = "Image";
    }*/

    if (Constants.isConnected == "true") {
      if (content.trim() != '') {
        textEditingController.clear();

        //var  chatID = Firestore.instance.collection('ChatList').document(id.toString()).collection(id.toString()).document(peerId.toString());

        Firestore.instance
            .collection('users')
            .where('ID', isEqualTo: widget.peerId.toString())
            .getDocuments()
            .then((userDoc) {
          if (userDoc.documents[0].data["isConnected"] == "true") {
            processToSend(content, type, "true");
          } else {
            processToSend(content, type, "false");
          }
        });
      } else {
        Fluttertoast.showToast(msg: 'Please enter message to send!');
      }
    } else {
      Fluttertoast.showToast(msg: 'Please connect to Internet!');
    }
  }

  processToSend(String content, int type, String isConnected) {
    var documentReference = Firestore.instance
        .collection('messages')
        .document(groupChatId)
        .collection(groupChatId)
        .document(DateTime.now().millisecondsSinceEpoch.toString());

    Firestore.instance.runTransaction((transaction) async {
      await transaction.set(
        documentReference,
        {
          'idFrom': widget.userId,
          'idTo': widget.peerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'content': content,
          'isRead': isConnected == "false" ? "0" : "1",
          'type': type
        },
      );
    });

    addUserToChatList(
        content, DateTime.now().millisecondsSinceEpoch.toString(), type);

    /*final QuerySnapshot currentActiveUsers = await */
    Firestore.instance
        .collection('CurrentlyActiveUser')
        .document(widget.peerId.toString())
        .collection(widget.peerId.toString())
        //.where("ID", isEqualTo: widget.userId)
        .getDocuments()
        .then((currentActive) async {
      if (currentActive.documents != null) {
        if (currentActive.documents.length > 0) {
          if (currentActive.documents[0]["ID"].toString() != widget.userId) {
            print("Current ${currentActive.documents[0]["ID"]}");

            String userDeviceType = Platform.isAndroid ? "A" : "I";

            String notificationContent = "";

            if (type == 1) {
              notificationContent = "Image";
            } else if (type == 2) {
              notificationContent = "Sticker";
            } else {
              notificationContent = content;
            }

            Firestore.instance
                .collection('ChatBadge')
                .document(widget.peerId.toString())
                .collection(widget.peerId.toString())
                .getDocuments()
                .then((snap) {
              if (snap.documents != null) {
                if (snap.documents.length > 0) {
                  int oldBadge = snap.documents[0]['Badge'];
                  createNotification(
                      oldBadge + 1, notificationContent, userDeviceType);
                } else {
                  createNotification(1, notificationContent, userDeviceType);
                }
              } else {
                createNotification(1, notificationContent, userDeviceType);
              }
            });
          }
        } else {
          String userDeviceType = Platform.isAndroid ? "A" : "I";

          String notificationContent = "";

          if (type == 1) {
            notificationContent = "Image";
          } else if (type == 2) {
            notificationContent = "Sticker";
          } else {
            notificationContent = content;
          }

          Firestore.instance
              .collection('ChatBadge')
              .document(widget.peerId.toString())
              .collection(widget.peerId.toString())
              .getDocuments()
              .then((snap) {
            if (snap.documents != null) {
              if (snap.documents.length > 0) {
                int oldBadge = snap.documents[0]['Badge'];

                createNotification(
                    oldBadge + 1, notificationContent, userDeviceType);
              } else {
                createNotification(1, notificationContent, userDeviceType);
              }
            } else {
              createNotification(1, notificationContent, userDeviceType);
            }
          });
        }
      } else {
        String userDeviceType = Platform.isAndroid ? "A" : "I";

        String notificationContent = "";

        if (type == 1) {
          notificationContent = "Image";
        } else if (type == 2) {
          notificationContent = "Sticker";
        } else {
          notificationContent = content;
        }

        Firestore.instance
            .collection('ChatBadge')
            .document(widget.peerId.toString())
            .collection(widget.peerId.toString())
            .getDocuments()
            .then((snap) {
          if (snap.documents != null) {
            if (snap.documents.length > 0) {
              int oldBadge = snap.documents[0]['Badge'];

              createNotification(
                  oldBadge + 1, notificationContent, userDeviceType);
            } else {
              createNotification(1, notificationContent, userDeviceType);
            }
          } else {
            createNotification(1, notificationContent, userDeviceType);
          }
        });
      }
    }).catchError((onError) {
      print("Erro $onError");
    });

    listScrollController.animateTo(0.0,
        duration: Duration(milliseconds: 300), curve: Curves.easeOut);
  }

  /// Add user to chat list to show in ChatList page

  Future<void> addUserToChatList(
      String content, String timestamp, int type) async {
    if (type == 1) {
      content = "Image";
    }
    if (type == 2) {
      content = "Sticker";
    }

    try {
      Firestore.instance
          .collection('ChatList')
          .document(widget.userId.toString())
          .collection(widget.userId.toString())
          .document(widget.peerId.toString())
          .setData({
        'ID': widget.peerId,
        'name': widget.peerName,
        'content': content,
        'timestamp': timestamp,
        'profileImage': widget.peerAvatar,
        'deviceToken': widget.peerDeviceToken,
        'user_device_type': widget.peerDeviceType,
      });
      Firestore.instance
          .collection('ChatList')
          .document(widget.peerId.toString())
          .collection(widget.peerId.toString())
          .document(widget.userId.toString())
          .setData({
        'ID': widget.userId,
        'name': widget.userName,
        'content': content,
        'timestamp': timestamp,
        'profileImage': widget.userAvatar,
        'deviceToken': widget.userToken,
        'user_device_type': Platform.isAndroid ? "A" : "I"
      });
    } catch (e) {}
  }

  /// Build Message Widget for User and Peer User
  Widget myPlaceHolder(context, url){
    return Container(
      child: CircularProgressIndicator(
        valueColor:
        AlwaysStoppedAnimation<Color>(themeColor),
      ),
      width: 200.0,
      height: 200.0,
      padding: EdgeInsets.all(70.0),
      decoration: BoxDecoration(
        color: greyColor2,
        borderRadius: BorderRadius.all(
          Radius.circular(8.0),
        ),
      ),
    );
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    CachedNetworkImage networkImage =
                    new CachedNetworkImage(imageUrl: document['content']);
    if (document['idFrom'] == widget.userId) {
      // Right (my message)
      return Row(
        children: <Widget>[
          document['type'] == 0
              // Text
              ? Container(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Flexible(
                        child: Linkify(
                          text: document['content'],
                            style:
                            TextStyle(color: Colors.white70, fontSize: 16.0),
                          onOpen: _onOpen,
                          humanize: true,
                        ),
                        flex: 11,
                        fit: FlexFit.tight,
                      ),
                      /*
                      Flexible(
                          flex: 1,
                          fit: FlexFit.loose,
                          child: Ink(
                            child: Icon(
                              Icons.mail,
                              size: 8,
                              color: document["isRead"] == "2"
                                  ? Colors.green
                                  : document["isRead"] == "1"
                                      ? Colors.yellow
                                      : Colors.red,
                            ),
                          )),
                      */
                      Padding(padding: EdgeInsets.only(right: 2.0)),
                      Flexible(
                        flex: 3,
                        fit: FlexFit.loose,
                        child: Text(
                          DateFormat('dd MMM kk:mm').format(
                              DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(document['timestamp']))),
                          style: TextStyle(
                              color: document["isRead"] == "2"
                                  ? Colors.green
                                  : document["isRead"] == "1"
                                  ? Colors.yellow
                                  : Colors.red,
                              fontSize: 7.0,
                              fontWeight: FontWeight.bold),
                        ),
                      )
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 5.0, 10.0),
                  width: 235.0,
                  decoration: BoxDecoration(
                      color: new Color.fromRGBO(87, 112, 170, 0.6),
                      borderRadius: BorderRadius.circular(18.0)),
                  margin: EdgeInsets.only(
                      bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                      right: 10.0),
                )
              : document['type'] == 1
                  // Image
                  ? Container(
            //alignment: FractionalOffset.bottomLeft,
            decoration: BoxDecoration(),
            height: 200.0,
            width: 200.0,
            child: Stack(
              //crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Container(
                  decoration: BoxDecoration(),
                  height: 200.0,
                  width: 200.0,
                  child: Material(
                    child: InkWell(
                      onTap: (){
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FullScreenWrapper(
                              imageProvider: CachedNetworkImageProvider(
                                networkImage.imageUrl,
                              ),
                              //const AssetImage("assets/large-image.jpg"),
                              initialScale: PhotoViewComputedScale.contained * 0.7,
                              minScale: PhotoViewComputedScale.contained * 0.5,
                              maxScale: PhotoViewComputedScale.covered,
                            ),
                          ),
                        );
                      },

                      child: PhotoView(
                        imageProvider: CachedNetworkImageProvider(networkImage.imageUrl),//NetworkImage(networkImage.imageUrl),
                        initialScale: PhotoViewComputedScale.covered * 1,
                      ),
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(8.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                ),
                new Positioned(
                  height: 15,
                  width: 55,
                  left: 140,
                  top: 185,

                  //color: Colors.white70,
                  //padding: EdgeInsets.all(2.0),
                  //alignment: FractionalOffset.bottomRight,
                  child: new Container(
                    alignment: FractionalOffset.center,
                    color: Colors.blue.withOpacity(0.1),
                    child: new Text(
                      DateFormat('dd MMM kk:mm').format(
                          DateTime.fromMillisecondsSinceEpoch(
                              int.parse(document['timestamp']))),
                      style: TextStyle(
                          color: document["isRead"] == "2"
                              ? Colors.green
                              : document["isRead"] == "1"
                              ? Colors.yellow
                              : Colors.red,
                          fontSize: 9,
                          fontFamily: 'Aharoni',
                          fontWeight: FontWeight.bold),
                    ),
                  )
                )
              ],
            ),
            margin: EdgeInsets.only(
                bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                right: 10.0),
          )
                  // Sticker
                  : Container(
                      padding: EdgeInsets.all(2.0),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.0),
                        borderRadius: BorderRadius.circular(10.0),

                      ),
                      height: 65,
                      width: 120,

                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Flexible(
                              fit: FlexFit.loose,
                              flex: 3,
                              child: Center(
                                  child: GestureDetector(
                                    onTap: () {
                                      _animationController.forward();
                                      //_animationController.animateBack(2.0);
                                      // tapping the button, starts the animation.
                                    },
                                    child: new Image.asset(
                                      'emoji/${document['content']}.png',
                                      width: 45.0 * _animation.value,
                                      height: 45.0 * _animation.value,
                                      //fit: BoxFit.cover,
                                    ),
                                  )
                              )
                          ),
                          //Padding(padding: EdgeInsets.only(right: 15)),
                          /*
                          Flexible(
                              flex: 1,
                              fit: FlexFit.tight,
                              child: Ink(
                                child: Icon(
                                  Icons.mail,
                                  size: 7,
                                  color: document["isRead"] == "2"
                                      ? Colors.green
                                      : document["isRead"] == "1"
                                          ? Colors.yellow
                                          : Colors.red,
                                ),
                              )),
                              */
                          //Padding(padding: EdgeInsets.symmetric(horizontal: 1.0)),
                          Flexible(
                            flex: 3,
                            fit: FlexFit.tight,
                            child: Text(
                              DateFormat('dd MMM kk:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(document['timestamp']))),
                              style: TextStyle(
                                  color: document["isRead"] == "2"
                                      ? Colors.green
                                      : document["isRead"] == "1"
                                      ? Colors.yellow
                                      : Colors.red,
                                  fontSize: 6.5,
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                        ],
                      ),
                      margin: EdgeInsets.only(
                          bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                          right: 5.0),
                    )
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      // Left (peer message)
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                document['type'] == 0
                    ? Container(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Flexible(
                              child: Linkify(
                                text: document['content'],
                                style:
                                TextStyle(color: Colors.white, fontSize: 16.0),
                                onOpen: _onOpen,
                                humanize: true,
                              ),
                              flex: 9,
                              fit: FlexFit.tight,
                            ),
                            Flexible(
                              child: Text(
                                DateFormat('dd MMM kk:mm').format(
                                    DateTime.fromMillisecondsSinceEpoch(
                                        int.parse(document['timestamp']))),
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 7.0,
                                    fontWeight: FontWeight.bold),
                              ),
                              flex: 3,
                              fit: FlexFit.loose,
                            )
                          ],
                        ),
                        padding: EdgeInsets.fromLTRB(15.0, 10.0, 0.0, 10.0),
                        width: 225.0,
                        decoration: BoxDecoration(
                            color: Color.fromRGBO(57, 173, 239, 0.85),
                            borderRadius: BorderRadius.circular(16.0)),
                        //margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 0.0),
                      )
                    : document['type'] == 1
                        ? Container(
                  //alignment: FractionalOffset.bottomLeft,
                  decoration: BoxDecoration(),
                  height: 200.0,
                  width: 200.0,
                  child: Stack(
                    //crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        decoration: BoxDecoration(),
                        height: 200.0,
                        width: 200.0,
                        child: Material(
                          child: InkWell(
                            onTap: (){
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => FullScreenWrapper(
                                    imageProvider: CachedNetworkImageProvider(
                                      networkImage.imageUrl,
                                    ),
                                    //const AssetImage("assets/large-image.jpg"),
                                    initialScale: PhotoViewComputedScale.contained * 0.7,
                                    minScale: PhotoViewComputedScale.contained * 0.5,
                                    maxScale: PhotoViewComputedScale.covered,
                                  ),
                                ),
                              );
                            },

                            child: PhotoView(
                              imageProvider: CachedNetworkImageProvider(networkImage.imageUrl),
                              initialScale: PhotoViewComputedScale.covered * 1,
                            ),
                          ),
                          borderRadius: BorderRadius.all(Radius.circular(8.0)),
                          clipBehavior: Clip.hardEdge,
                        ),
                      ),
                      new Positioned(
                          height: 15,
                          width: 55,
                          left: 140,
                          top: 185,

                          //color: Colors.white70,
                          //padding: EdgeInsets.all(2.0),
                          //alignment: FractionalOffset.bottomRight,
                          child: new Container(
                            alignment: FractionalOffset.center,
                            color: Colors.blue.withOpacity(0.1),
                            child: new Text(
                              DateFormat('dd MMM kk:mm').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      int.parse(document['timestamp']))),
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 9,
                                  fontFamily: 'Aharoni',
                                  fontWeight: FontWeight.bold),
                            ),
                          )
                      )
                    ],
                  ),
                  //margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 10.0),
                )
                        : Container(
                            padding: EdgeInsets.all(2.0),
                            decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10.0)),
                            width: 95,
                            height: 50,
                            //padding: EdgeInsets.only(left: 20.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: <Widget>[
                                Flexible(
                                  fit: FlexFit.tight,
                                  child: Center(
                                      child: GestureDetector(
                                        onTap: () {
                                          _animationController.forward();
                                          //_animationController.animateBack(2.0);
                                          // tapping the button, starts the animation.
                                        },
                                        child: new Image.asset(
                                          'emoji/${document['content']}.png',
                                          width: 45.0 * _animation.value,
                                          height: 45.0 * _animation.value,
                                          //fit: BoxFit.cover,
                                        ),
                                      )
                                  ),
                                  flex: 2,
                                ),
                                Flexible(
                                  child: Text(
                                    DateFormat('dd MMM kk:mm').format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            int.parse(document['timestamp']))),
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 7.0,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Tahoma'),
                                  ),
                                  flex: 2,
                                  fit: FlexFit.loose,
                                )
                              ],
                            ),
                            margin: EdgeInsets.only(
                                bottom: isLastMessageLeft(index) ? 20.0 : 10.0,
                                left: 20.0),
                          )
              ],
            ),

            // Time
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10.0),
      );
    }
  }

  /// Check message is First

  bool isFirstMessage(int index) {
    if (index > 0) {
      return true;
    } else {
      return false;
    }
  }

  /// Check message is Last for user

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] == widget.userId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  /// Check message is Last for other user

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1]['idFrom'] != widget.userId) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<void> _onOpen(LinkableElement link) async {
    if (await canLaunch(link.url)) {
      await launch(link.url);
    } else {
      throw 'Could not launch $link';
    }
  }

  /// onClick of back button

  Future<bool> onBackPress() async {
    /*if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {*/

    /// remove user from current active user

    await Firestore.instance
        .collection('CurrentlyActiveUser')
        .document(widget.userId.toString())
        .delete();

    if (widget.type == 3) {
      Constants.inApp = true;
      Firestore.instance
          .collection('CurrentlyActiveUser')
          .document(widget.userId.toString())
          .delete()
          .then((val) {
        Navigator.of(context).pushReplacement(CupertinoPageRoute(
            builder: (context) => TabLayouts(
                  userDocument: widget.userDocument,
                  inApp: true,
                )));
      });
    } else {
      Navigator.pop(context,false);
      //return Future.value(false);

    }
    //}


    return Future.value(false);


  }

  Widget buildSticker() {
    /** RESIZED ALL EMOJI 'S..............
        ............................... */
    return Container(
      decoration: new BoxDecoration(
        //border: new Border(top: new BorderSide(color: Color(0xFF5770aa).withOpacity(0.7), width: 0.0,)),
        color: Color(0xFF5770aa).withOpacity(0.0),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 10.0),
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.01),
                  onTap: () => onSendMessage('1f621', 2),
                  child: new Image.asset(
                    'emoji/1f621.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f642', 2),
                  child: new Image.asset(
                    'emoji/1f642.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.deepPurple.withOpacity(0.9),
                  onTap: () => onSendMessage('1f915', 2),
                  child: new Image.asset(
                    'emoji/1f915.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.red.withOpacity(0.8),
                  onTap: () => onSendMessage('1f607', 2),
                  child: new Image.asset(
                    'emoji/1f607.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.green.withOpacity(0.5),
                  onTap: () => onSendMessage('1f643', 2),
                  child: new Image.asset(
                    'emoji/1f643.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f609', 2),
                  child: new Image.asset(
                    'emoji/1f609.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f604', 2),
                  child: new Image.asset(
                    'emoji/1f604.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: <Widget>[
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f606', 2),
                  child: new Image.asset(
                    'emoji/1f606.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f605', 2),
                  child: new Image.asset(
                    'emoji/1f605.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f602', 2),
                  child: new Image.asset(
                    'emoji/1f602.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f923', 2),
                  child: new Image.asset(
                    'emoji/1f923.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: <Widget>[
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f60d', 2),
                  child: new Image.asset(
                    'emoji/1f60d.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f60b', 2),
                  child: new Image.asset(
                    'emoji/1f60b.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f61b', 2),
                  child: new Image.asset(
                    'emoji/1f61b.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f92a', 2),
                  child: new Image.asset(
                    'emoji/1f92a.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f9d0', 2),
                  child: new Image.asset(
                    'emoji/1f9d0.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f60e', 2),
                  child: new Image.asset(
                    'emoji/1f60e.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            ),
            Row(
              children: <Widget>[
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f60f', 2),
                  child: new Image.asset(
                    'emoji/1f60f.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f613', 2),
                  child: new Image.asset(
                    'emoji/1f613.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f914', 2),
                  child: new Image.asset(
                    'emoji/1f914.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
                InkWell(
                  //backgroundColor: Colors.blue.withOpacity(0.1),
                  onTap: () => onSendMessage('1f97a', 2),
                  child: new Image.asset(
                    'emoji/1f97a.png',
                    width: 40,
                    height: 40,
                    //fit: BoxFit.cover,
                  ),
                ),
              ],
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            )
          ],
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        ),
      ),
      padding: EdgeInsets.all(0),
      height: 150.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    focusNodeType.addListener(() {
      if (focusNodeType.hasFocus && textEditingController.text.isNotEmpty) {
        Firestore.instance
            .collection('users')
            .where('ID', isEqualTo: widget.userId)
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({'isOnline': "isTyping"});
        });
      } else {
        Firestore.instance
            .collection('users')
            .where('ID', isEqualTo: widget.userId)
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({'isOnline': "Online"});
        });
      }
    });

    void updateIsTyping() {
      if (focusNodeType.hasFocus && textEditingController.text.isNotEmpty) {
        Firestore.instance
            .collection('users')
            .where('ID', isEqualTo: widget.userId)
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({'isOnline': "isTyping"});
        });
      } else {
        Firestore.instance
            .collection('users')
            .where('ID', isEqualTo: widget.userId)
            .getDocuments()
            .then((userDoc) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({'isOnline': "Online"});
        });
      }
    }

    textEditingController.addListener(updateIsTyping);

    return WillPopScope(
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              // List of messages
              buildListMessage(),

              // Sticker
              (isShowSticker ? buildSticker() : Container()),

              // Input content
              buildInput(),
            ],
          ),

          // Loading
          buildLoading()
        ],
      ),
      onWillPop: onBackPress,
    );
  }

  /// Build Loading Circular

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
              child: Center(
                child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
              ),
              color: Colors.white.withOpacity(0.8),
            )
          : Container(),
    );
  }

  /// Bottom widget including send button, text area, attach image

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Container(
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15.0),
                color: Colors.red.withOpacity(0.9)),
            child: new Container(
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.add_a_photo),
                onPressed: getImage,
                color: Colors.white70,
              ),
            ),
          ), //Color(0xFF5770aa)
          Padding(
            padding: EdgeInsets.only(left: 5.0),
            child: new Container(
              height: 40,
              width: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30.0),
                color: Colors.yellow[700].withOpacity(0.8),
              ),
              margin: new EdgeInsets.symmetric(horizontal: 1.0),
              child: new IconButton(
                icon: new Icon(Icons.tag_faces, color: Colors.white70),
                onPressed: getSticker,
                color: Colors.white70,
              ),
            ),
          ),

          // Edit text
          Flexible(
            child: new Padding(
              padding: EdgeInsets.only(left: 5.0),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0),
                  color: Color(0xFF5770aa).withOpacity(0.7),
                ),
                padding: EdgeInsets.only(left: 5.0),
                child: TextField(
                  cursorColor: Color(0xFF5770aa).withOpacity(0.7),
                  cursorRadius: Radius.circular(2.0),
                  //cursorWidth: 3.0,
                  textCapitalization: TextCapitalization.sentences,
                  //textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 20.0,
                    fontWeight: FontWeight.w400,
                    //textBaseline: TextBaseline.ideographic
                  ),
                  focusNode: focusNodeType,
                  controller: textEditingController,
                  decoration: InputDecoration(
                    contentPadding: EdgeInsets.all(6),
                    border: InputBorder.none,
                    hasFloatingPlaceholder: true,
                    hintText: 'Type your message...',
                    //labelText: 'Enter your username',
                    //labelStyle: ,
                    hintStyle: TextStyle(
                        color: greyColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w100,
                        fontFamily: 'Arial'),
                  ),
                  //focusNode: focusNode,
                ),
              ),
            ),
          ),
          Padding(padding: EdgeInsets.only(left: 10.0)),

          // Button send message
          Container(
            height: 40,
            width: 55,
            child: new Container(
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25.0), color: Colors.red),
              margin: new EdgeInsets.symmetric(horizontal: 8.0),
              child: new IconButton(
                icon: new Icon(
                  Icons.send,
                  color: Colors.white,
                ),
                hoverColor: Colors.red,
                onPressed: () => onSendMessage(textEditingController.text.toString().trim(), 0),
                color: Colors.white70,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: 10.0),
          ),
        ],
      ),
      width: double.infinity,
      height: 60.0,
      decoration: new BoxDecoration(
          border: new Border(top: new BorderSide(width: 0)),
          color: Colors.transparent),
      padding: EdgeInsets.only(bottom: 5.0),
    );
  }

  /// Build List of messages

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(
              child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(themeColor)))
          : StreamBuilder(
              stream: Firestore.instance
                  .collection('messages')
                  .document(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  //.limit(40)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                      child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation<Color>(themeColor)));
                } else {
                  listMessage = snapshot.data.documents;

                  Firestore.instance
                      .collection('messages')
                      .document(groupChatId)
                      .collection(groupChatId)
                      .getDocuments()
                      .then((messageDoc) {
                    if (messageDoc.documents.length > 0) {
                      messageDoc.documents.forEach((msgDoc) {
                        if (msgDoc.data["idFrom"] != widget.userId) {
                          Firestore.instance
                              .collection('messages')
                              .document(groupChatId)
                              .collection(groupChatId)
                              .document(msgDoc.documentID)
                              .updateData({'isRead': "2"});
                        }
                      });
                    }
                  });

                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollController,
                  );
                }
              },
            ),
    );
  }

  /// Call send notification API [Firebase]

  Future<http.Response> createNotification(
      int oldBadge, String notificationContent, String userDeviceType) async {
    Firestore.instance
        .collection('ChatBadge')
        .document(widget.peerId.toString())
        .collection(widget.peerId.toString())
        .document(widget.peerId.toString())
        .setData({
      'ID': widget.peerId,
      'Badge': oldBadge,
    });

    String sendNoti;
    print("peer device token : ${widget.peerDeviceToken}");
    if (widget.peerDeviceType == "A") {
      print("Send Message Type : A ${widget.peerDeviceType}");
      sendNoti =
          "{\"to\":\"${widget.peerDeviceToken}\",\"priority\":\"high\",\"data\":{\"type\":\"100\",\"user_id\":\"${widget.userId}\",\"user_token\":\"${widget.userToken}\",\"user_name\":\"${widget.userName}\",\"user_pic\":\"${widget.userAvatar}\",\"user_device_type\":\"$userDeviceType\",\"msg\":\"$notificationContent\",\"time\":\"${DateTime.now().millisecondsSinceEpoch}\"}}";
    } else {
      print("Send Message Type : I ${widget.peerDeviceType}");
      sendNoti =
          "{\"to\":\"${widget.peerDeviceToken}\",\"data\":{\"type\":\"100\",\"user_id\":\"${widget.userId}\",\"user_token\":\"${widget.userToken}\",\"user_name\":\"${widget.userName}\",\"user_pic\":\"${widget.userAvatar}\",\"user_device_type\":\"$userDeviceType\",\"msg\":\"$notificationContent\",\"time\":\"${DateTime.now().millisecondsSinceEpoch}\"},\"notification\":{\"title\":\"${widget.userName}\",\"body\":\"$notificationContent\",\"user_id\":\"${widget.userId}\",\"user_token\":\"${widget.userToken}\",\"user_pic\":\"${widget.userAvatar}\",\"user_device_type\":\"$userDeviceType\",\"sound\":\"default\",\"badge\": \"1\"},\"priority\":\"high\"}";
    }
    print("Send Message  $sendNoti");


    final response = await http.post('https://fcm.googleapis.com/fcm/send',
        headers: {
          HttpHeaders.contentTypeHeader: 'application/json',
          HttpHeaders.authorizationHeader:
              "key=AAAAcn0Fevo:APA91bH8YBxU3w6gCv8l9fJCuTqPsYmcVkGnzFs2l1wtUDnDg5i-Ilwfff89CwnOgKPIJMPcuK6VR9Ep-JYKQWvytcVdnM_3-pESBr3OvWfwN5Rvf_T5LqyAuz90z5KBv0UURSgPofs_"
        },
        body: sendNoti);
    print("Notification Response");
    print(response.body.toString());
    return response;
  }
}
