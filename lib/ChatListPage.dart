import 'dart:async';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:metaphor_beta/ChatPage.dart';
import 'package:metaphor_beta/Model/CustomContact.dart';
import 'package:metaphor_beta/UserListWidget.dart';
import 'package:metaphor_beta/my_colors.dart';
import 'package:metaphor_beta/webrtc/call_sample/random_string.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;

class ChatListPage extends StatefulWidget {
  final DocumentSnapshot userDocument;

  ChatListPage({@required this.userDocument});

  @override
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  Iterable<Contact> _contacts;

  bool _isCreatingLink = false;

  String _linkMessage = "";

  bool chatFound = false;

  List<CustomContact> customContact = new List();

  @override
  void initState() {
    super.initState();

    _createDynamicLink(true);
    refreshContacts();


    if (widget.userDocument != null) {
      Firestore.instance
          .collection("ChatList")
          .document(widget.userDocument['ID'] /*"1"*/)
          .collection(widget.userDocument['ID'] /*"1"*/)
          .getDocuments()
          .then((snapshot) {
        if (snapshot.documents != null) {
          snapshot.documents.forEach((data) {
            print("Data ${data.documentID}");
            Firestore.instance
                .collection("users")
                .where('ID', isEqualTo: data.documentID)
                .getDocuments()
                .then((snap) {
              print(snap.documents[0]['device_token']);
              Firestore.instance
                  .collection("ChatList")
                  .document(widget.userDocument['ID'])
                  .collection(widget.userDocument['ID'])
                  .document(data.documentID)
                  .updateData({
                'deviceToken': snap.documents[0]['device_token'].toString(),
                'user_device_type':
                snap.documents[0]['user_device_type'].toString()
              }).then((val) {
                setState(() {
                  chatFound = true;
                });
              });
            });
          });
        } else {
          setState(() {
            chatFound = false;
          });
        }
      });

      if (widget.userDocument != null) {
        Firestore.instance
            .collection('ChatBadge')
            .document(widget.userDocument['ID'].toString())
            .collection(widget.userDocument['ID'].toString())
            .document(widget.userDocument['ID'].toString())
            .setData({
          'ID': widget.userDocument['ID'],
          'Badge': 0,
        });
      }
    } else {
      setState(() {
        chatFound = false;
      });
    }
  }

  //Connect your phone

  Future<void> _createDynamicLink(bool short) async {
    setState(() {
      _isCreatingLink = true;
    });

    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://flutterchatapp.page.link',
      link: Uri.parse('https://metaphor.chat/${randomString(6)}'),
      androidParameters: AndroidParameters(
        packageName: 'chat.metaphor.metaphor_beta',
        minimumVersion: 1,
      ),
      dynamicLinkParametersOptions: DynamicLinkParametersOptions(
        shortDynamicLinkPathLength: ShortDynamicLinkPathLength.short,
      ),
      iosParameters: IosParameters(
        bundleId: 'chat.metaphor.metaphorAlpha',
        minimumVersion: '1',
      ),
    );

    Uri url;
    if (short) {
      final ShortDynamicLink shortLink = await parameters.buildShortLink();
      url = shortLink.shortUrl;
    } else {
      url = await parameters.buildUrl();
    }

    Firestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.userDocument.data['email'])
        .getDocuments()
        .then((userDoc) {
      if (userDoc != null && userDoc.documents.length > 0) {
        if (userDoc.documents[0] != null) {
          Firestore.instance
              .collection('users')
              .document(userDoc.documents[0].documentID)
              .updateData({'deepLink': url.toString()}).then((val) {
            setState(() {
              _linkMessage = url.toString();
              _isCreatingLink = false;
            });
          });
        }
      }
    });
  }



  refreshContacts() async {
    var contacts = await ContactsService.getContacts(withThumbnails: false);
    setState(() {
      _contacts = contacts;

      _contacts.forEach((contact) {
        contact.phones.forEach((phone) {
          bool alreadyInList = false;

          if (!widget.userDocument.data['phone'].toString().contains(phone.value
              .toString()
              .trim()
              .replaceAll("-", "")
              .replaceAll("(", "")
              .replaceAll(")", "")
              .replaceAll(" ", ""))) {
            CustomContact customContactObj = new CustomContact(
                contact,
                phone.value
                    .toString()
                    .trim()
                    .replaceAll("-", "")
                    .replaceAll("(", "")
                    .replaceAll(")", "")
                    .replaceAll(" ", ""),
                false);
            customContact.forEach((contactObj) {
              if (contactObj.phoneNumber
                  .contains(customContactObj.phoneNumber)) {
                alreadyInList = true;
              }
            });
            if (!alreadyInList) {
              customContact.add(customContactObj);
            }
          }
        });
      });
    });
  }

  /// The last day of a given month
  static DateTime lastDayOfMonth(DateTime month) {
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

  @override
  Widget build(BuildContext context) {
    Random random;

    return Scaffold(
        backgroundColor: Color.fromRGBO(29, 23, 58, 1.0),
        //appBar: AppBar(title: Text('Contacts Plugin Example')),
        floatingActionButton: InkWell(
            splashColor: Colors.green[800],
            child: Icon(
              Icons.add_circle,
              color: Colors.blue[600],
              size: 40,
            ),
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) =>
                          UserListWidget(
                            userDocument: widget.userDocument,
                            contacts: _contacts,
                            dynamicLink: _linkMessage,
                            customContact: customContact,
                          )));

              /*Navigator.of(context).pushNamed("/add").then((_) {
              refreshContacts();
            });*/
            }),
        body: SafeArea(
          bottom: false,
          child: Container(
            padding: EdgeInsets.only(left: 10.0, right: 10.0, top: 10.0),
            decoration: new BoxDecoration(
              image: new DecorationImage(
                  image: new AssetImage('images/navy_blue_1.jpg'),
                  fit: BoxFit.fill),
            ),
            child: /* !chatFound
                ? Center(
                    child: Text(
                    "No Chats Found!",
                    style: TextStyle(color: Colors.white),
                  ))
                : */StreamBuilder<QuerySnapshot>(
                stream: Firestore.instance
                    .collection("ChatList")
                    .document(widget.userDocument['ID'])
                    .collection(widget.userDocument['ID'])
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return ListView.separated(
                        separatorBuilder: (context, i) =>
                            Divider(
                              height: 10.0,
                            ),
                        itemCount: snapshot.data.documents.length,
                        itemBuilder: (context, i) {
                          String name, profileImage, isOnline;

                          String todayDateText,
                              yesterdayDateText,
                              twodayDateText,
                              threedayDateText,
                              fourdayDateText,
                              fivedayDateText,
                              sixdayDateText,
                              weekDateText,
                              showDateTime;

                          todayDateText = DateFormat("dd-MM-yyyy")
                              .format(DateTime.fromMillisecondsSinceEpoch(
                              DateTime
                                  .now()
                                  .millisecondsSinceEpoch))
                              .toString();

                          yesterdayDateText = DateFormat("dd-MM-yyyy")
                              .format(DateTime(
                              DateTime
                                  .now()
                                  .year,
                              DateTime
                                  .now()
                                  .month,
                              DateTime
                                  .now()
                                  .day - 1));

                          twodayDateText = DateFormat("dd-MM-yyyy").format(
                              DateTime(
                                  DateTime
                                      .now()
                                      .year,
                                  DateTime
                                      .now()
                                      .month,
                                  DateTime
                                      .now()
                                      .day - 2));

                          threedayDateText = DateFormat("dd-MM-yyyy")
                              .format(DateTime(
                              DateTime
                                  .now()
                                  .year,
                              DateTime
                                  .now()
                                  .month,
                              DateTime
                                  .now()
                                  .day - 3));

                          fourdayDateText = DateFormat("dd-MM-yyyy").format(
                              DateTime(
                                  DateTime
                                      .now()
                                      .year,
                                  DateTime
                                      .now()
                                      .month,
                                  DateTime
                                      .now()
                                      .day - 4));
                          fivedayDateText = DateFormat("dd-MM-yyyy").format(
                              DateTime(
                                  DateTime
                                      .now()
                                      .year,
                                  DateTime
                                      .now()
                                      .month,
                                  DateTime
                                      .now()
                                      .day - 5));
                          sixdayDateText = DateFormat("dd-MM-yyyy").format(
                              DateTime(
                                  DateTime
                                      .now()
                                      .year,
                                  DateTime
                                      .now()
                                      .month,
                                  DateTime
                                      .now()
                                      .day - 6));
                          weekDateText = DateFormat("dd-MM-yyyy").format(
                              DateTime(
                                  DateTime
                                      .now()
                                      .year,
                                  DateTime
                                      .now()
                                      .month,
                                  DateTime
                                      .now()
                                      .day - 7));

                          int dayCount = DateTime
                              .now()
                              .difference(
                              DateTime.fromMillisecondsSinceEpoch(
                                  int.parse(snapshot.data.documents[i]
                                  ['timestamp'])))
                              .inDays;

                          //long dayCount = diff / (24 * 60 * 60 * 1000);
                          int week = (dayCount / 7).round();
                          int month = 0;

                          month = monthsBetweenDates(
                              DateTime.fromMillisecondsSinceEpoch(
                                  DateTime
                                      .now()
                                      .millisecondsSinceEpoch),
                              DateTime.fromMillisecondsSinceEpoch(int.parse(
                                  snapshot.data.documents[i]
                                  ['timestamp'])));

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
                                .format(DateTime.fromMillisecondsSinceEpoch(
                                int.parse(snapshot.data.documents[i]
                                ['timestamp'])))
                                .toString();

                            if (apiDateText == todayDateText) {
                              int hourOfDay =
                                  DateTime
                                      .fromMillisecondsSinceEpoch(
                                      int.parse(snapshot.data
                                          .documents[i]['timestamp']))
                                      .hour;

                              int minute =
                                  DateTime
                                      .fromMillisecondsSinceEpoch(
                                      int.parse(snapshot.data
                                          .documents[i]['timestamp']))
                                      .minute;

                              bool isPM = (hourOfDay >= 12);

                              String hourOfDayString =
                              ((hourOfDay == 12 || hourOfDay == 0)
                                  ? 12
                                  : hourOfDay % 12)
                                  .toString()
                                  .padLeft(2, '0');
                              showDateTime =
                              "$hourOfDayString:${minute.toString().padLeft(
                                  2, '0')} ${isPM ? "PM" : "AM"}";
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

                          return StreamBuilder<QuerySnapshot>(
                              stream: Firestore.instance
                                  .collection('users')
                                  .where('ID',
                                  isEqualTo: snapshot
                                      .data.documents[i].documentID)
                                  .snapshots(),
                              builder: (context, userSnapshot) {
                                if (userSnapshot.hasData) {
                                  return Row(
                                    children: <Widget>[
                                      Expanded(
                                          child: Card(
                                            color: Color.fromRGBO(
                                                55, 105, 205, 0.25),
                                            //semanticContainer: true,
                                            shape: StadiumBorder(
                                                side: BorderSide(
                                                  width: 1.0,
                                                  color: Color(0xff002251),
                                                  style: BorderStyle.solid,
                                                )),
                                            elevation: 5.0,
                                            margin:
                                            EdgeInsets.only(bottom: 15.0),
                                            child: ListTile(
                                              onTap: () {
                                                Firestore.instance
                                                    .collection('users')
                                                    .where('ID',
                                                    isEqualTo: widget
                                                        .userDocument
                                                        .data["ID"])
                                                    .getDocuments()
                                                    .then((userDoc) async {
                                                  await Firestore.instance
                                                      .collection('users')
                                                      .document(userDoc
                                                      .documents[0]
                                                      .documentID)
                                                      .updateData({
                                                    'chatWith': userSnapshot
                                                        .data
                                                        .documents[0]
                                                        .data["ID"]
                                                  });
                                                });

                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          ChatPage(
                                                            userDocument: widget
                                                                .userDocument,
                                                            peerDocument:
                                                            userSnapshot
                                                                .data
                                                                .documents[0],
                                                            type: 0,
                                                          )),
                                                );
                                              },
                                              leading: (profileImage != null &&
                                                  profileImage.length > 0)
                                                  ? CircleAvatar(
                                                  backgroundImage:
                                                  NetworkImage(
                                                      profileImage),
                                                  backgroundColor: colors[
                                                  random.nextInt(4)])
                                                  : CircleAvatar(
                                                backgroundColor: colors[
                                                i % colors.length],
                                                child: Text(userSnapshot
                                                    .data
                                                    ?.documents[0]
                                                ['name']
                                                    .length >
                                                    1
                                                    ? userSnapshot
                                                    .data
                                                    ?.documents[0]
                                                ['name']
                                                    ?.substring(0, 2)
                                                    : ""),
                                              ),
                                              title: Text(
                                                  userSnapshot
                                                      .data
                                                      ?.documents[0]
                                                  ['name'] ??
                                                      "",
                                                  style: TextStyle(
                                                      color: Colors.white70,
                                                      fontWeight:
                                                      FontWeight.bold)),
                                              subtitle: new Container(
                                                padding: const EdgeInsets.only(
                                                    top: 5.0),
                                                child: new Text(
                                                  snapshot.data.documents[i]
                                                  ['content'] !=
                                                      null
                                                      ? snapshot
                                                      .data.documents[i]
                                                  ['content']
                                                      : "Sample Message",
                                                  maxLines: 1,
                                                  style: new TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 15.0),
                                                ),
                                              ),
                                              dense: false,
                                              trailing: Container(
                                                height: 10.0,
                                                width: 10.0,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(
                                                      5.0),
                                                  color: userSnapshot
                                                      .data
                                                      .documents[0]
                                                  ['isOnline']
                                                      .toString() ==
                                                      "Online" || userSnapshot
                                                      .data
                                                      .documents[0]
                                                  ['isOnline']
                                                      .toString() ==
                                                      "isTyping"
                                                      ? Colors.green
                                                      : Color(0xFF7991b8),
                                                ),
                                              ),
                                              enabled: true,
                                              //onLongPress: _checkContactStatus,
                                            ),
                                          )),
                                    ],
                                  );
                                } else {
                                  return Center(
                                      child: CircularProgressIndicator());
                                }
                              });
                        });
                  } else {
                    return Center(
                        child: Text(
                          "No Chats Found!",
                          style: TextStyle(color: Colors.white),
                        ));

                    //return Center(child: CircularProgressIndicator());
                  }
                }),
          ),
        ));
  }

  Widget _checkColorGrey(String isOnline) {
    return Container(
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: isOnline == "Online" ? Colors.green : Color(0xFF7991b8),
      ),
    );
  }

  Widget _checkColorGreen() {
    return Container(
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Color(0xFF7991b8),
      ),
    );
  }

/*_checkContactStatus() async {
    FirebaseAuth.instance.currentUser().then((user) {
      if (user == null) {
        _checkColorGrey();
      } else {
        _checkColorGreen();
      }
    });
  }*/
}
