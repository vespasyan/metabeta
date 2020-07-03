import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:metaphor_beta/ChatPage.dart';
import 'package:metaphor_beta/Model/CustomContact.dart';
import 'package:metaphor_beta/my_colors.dart';
import 'package:metaphor_beta/tablayouts/chat/chat_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_sms/flutter_sms.dart';
import 'package:share/share.dart';

class UserListWidget extends StatefulWidget {
  final Iterable<Contact> contacts;
  final String dynamicLink;
  final DocumentSnapshot userDocument;
  final List<CustomContact> customContact;

  UserListWidget(
      {this.userDocument, this.contacts, this.dynamicLink, this.customContact});

  @override
  _UserListWidgetState createState() => _UserListWidgetState();
}

class _UserListWidgetState extends State<UserListWidget> {
  TextEditingController editingController = TextEditingController();
  Random random;
  int contactLen = 0;
  GoogleSignInAccount _account;

  final List<CustomContact> duplicateContact = new List();

  void filterSearchResults(String query) {
    List<CustomContact> dummySearchList = List<CustomContact>();
    dummySearchList.addAll(duplicateContact);
    if (query.isNotEmpty) {
      List<CustomContact> dummyListData = List<CustomContact>();
      dummySearchList.forEach((item) {
        if (item.contact.displayName
            .toLowerCase()
            .contains(query.toLowerCase())) {
          dummyListData.add(item);
        }
      });
      setState(() {
        widget.customContact.clear();
        widget.customContact.addAll(dummyListData);
      });
      return;
    } else {
      setState(() {
        widget.customContact.clear();
        widget.customContact.addAll(duplicateContact);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    widget.customContact.clear();
    widget.customContact.addAll(duplicateContact);
  }

  @override
  void initState() {
    super.initState();

    Firestore.instance.collection('users').getDocuments().then((user) {
      if (user.documents.length > 0) {
        widget.customContact.forEach((customCont) {
          for (int i = 0; i < user.documents.length; i++) {
            if (customCont.phoneNumber
                .contains(user.documents[i]['phone']
                .toString())) {
              customCont.inDatabase = true;
              customCont.peerDocument = user.documents[i];
              setState(() {});
            }
          }
        });

        duplicateContact.addAll(widget.customContact);
      }
    });

    //refreshContacts();
  }

  refreshContacts() async {
    widget.contacts.forEach((cont) {
      cont.phones.forEach((phone) {
        print("Phone " +
            phone.value.trim().replaceAll("-", "").replaceAll("(", "")
                .replaceAll(")", "").replaceAll(" ", ""));
        List<dynamic> phoneList = new List();
        phoneList
            .add(phone.value.trim().replaceAll("-", "").replaceAll("(", "")
            .replaceAll(")", "").replaceAll(" ", ""));
        Firestore.instance
            .collection('users')
            //.where('phone', isEqualTo:phone.value.trim().replaceAll("-", "").replaceAll(" ", ""))
            // .limit(1)
            .getDocuments()
            .then((user) {
          /*if (user.documents != null && user.documents.length > 0) {
            print("User ");
            customContact.add(new CustomContact(cont, phone.value, true,
                peerDocument: user.documents[0]));
          } else {
            customContact.add(new CustomContact(cont, phone.value, false));
          }*/
          //print("Custom ${customContact.length}");
          setState(() {});
        });
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(29, 23, 58, 1.0),
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: Colors.red[800],
        title: Text("Contacts"),
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.only(left: 10.0, right: 10.0),
          decoration: new BoxDecoration(
            image: new DecorationImage(
                image: new AssetImage('images/navy_blue_6.jpg'),
                fit: BoxFit.fill),
          ),
          child: widget.customContact != null
              ? Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.transparent),
                          borderRadius: BorderRadius.all(Radius.circular(25.0)),
                          color: Color.fromRGBO(55, 105, 205, 0.15)
                        ),
                        child: TextField(
                          style: TextStyle(color: Colors.white),

                          maxLines: 1,
                          onChanged: (value) {
                            filterSearchResults(value);
                          },
                          controller: editingController,
                          decoration: InputDecoration(

                              hintStyle: TextStyle(color: Colors.grey),
                              prefixStyle: TextStyle(color: Colors.white),
                              //labelText: "Search",
                              hintText: "Enter contact name",
                              prefixIcon: Icon(Icons.search,color: Colors.blue,),
                              fillColor: Colors.white,
                              enabled: true,
                          
                            border: OutlineInputBorder(
                              //borderSide: BorderSide(width: 0.0),
                                borderRadius:
                                    BorderRadius.all(Radius.circular(25.0)))),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: widget.customContact?.length ?? 0,
                        itemBuilder: (BuildContext context, int index) {
                          // Contact c = customContact?.elementAt(index);

                          return Row(
                            children: <Widget>[
                              Expanded(
                                  child: Card(
                                color: Color.fromRGBO(55, 105, 205, 0.25),
                                //semanticContainer: true,
                                shape: StadiumBorder(
                                    side: BorderSide(
                                  width: 0.0,
                                  color: Color(0xff002251),
                                  style: BorderStyle.solid,

                                )),
                                elevation: 5.0,
                                margin: EdgeInsets.only(bottom: 15.0),
                                child: ListTile(
                                  onTap: () {
                                    /*Firestore.instance
                                        .collection('users')
                                        .where('ID',
                                            isEqualTo: widget.userDocument.data["ID"])
                                        .getDocuments()
                                        .then((userDoc) {
                                      Firestore.instance
                                          .collection('users')
                                          .document(userDoc.documents[0].documentID)
                                          .updateData({
                                        'chatWith': widget.customContact[index]
                                            .peerDocument.data["ID"]
                                      }).then((val) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (BuildContext context) =>
                                                  ChatPage(
                                                    userDocument: widget.userDocument,
                                                    peerDocument: widget
                                                        .customContact[index]
                                                        .peerDocument,
                                                    type: 0,
                                                  )),
                                        );
                                      });
                                    });*/
                                  },
                                  leading: (widget.customContact[index].contact
                                                  .avatar !=
                                              null &&
                                          widget.customContact[index].contact
                                                  .avatar.length >
                                              0)
                                      ? CircleAvatar(
                                          backgroundImage: NetworkImage(_account.photoUrl), //MemoryImage(widget.customContact[index].contact.avatar),
                                          backgroundColor:
                                              colors[random.nextInt(4)])
                                      : CircleAvatar(
                                          backgroundColor:
                                              colors[index % colors.length],
                                          child: Text(widget
                                                      .customContact[index]
                                                      .contact
                                                      .displayName
                                                      .length >
                                                  1
                                              ? widget.customContact[index]
                                                  .contact.displayName
                                                  ?.substring(0, 2)
                                              : ""),
                                        ),
                                  title: Text(
                                      widget.customContact[index].contact
                                              .displayName ??
                                          "",
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Text(
                                      widget.customContact[index].phoneNumber ??
                                          "",
                                      style: TextStyle(
                                        color: Color(0xFFa7adb7),
                                        fontWeight: FontWeight.w100,
                                      )),
                                  dense: false,
                                  trailing: GestureDetector(
                                    onTap: () {
                                      if (widget
                                          .customContact[index].inDatabase) {
                                        Firestore.instance
                                            .collection('users')
                                            .where('ID',
                                                isEqualTo: widget
                                                    .userDocument.data["ID"])
                                            .getDocuments()
                                            .then((userDoc) {
                                          Firestore.instance
                                              .collection('users')
                                              .document(userDoc
                                                  .documents[0].documentID)
                                              .updateData({
                                            'chatWith': widget
                                                .customContact[index]
                                                .peerDocument
                                                .data["ID"]
                                          }).then((val) {
                                            Navigator.pop(context);
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                  builder:
                                                      (BuildContext context) =>
                                                          ChatPage(
                                                            userDocument: widget
                                                                .userDocument,
                                                            peerDocument: widget
                                                                .customContact[
                                                                    index]
                                                                .peerDocument,
                                                            type: 0,
                                                          )),
                                            );
                                          });
                                        });
                                      } else {
                                        /* Share.share(
                                            "${widget.userDocument.data['name']} invite you to use Metaphor messenger : ${widget.dynamicLink}");*/
                                        List<String> recipents = [
                                          widget
                                              .customContact[index].phoneNumber
                                        ];

                                        _sendSMS(
                                            "${widget.userDocument.data['name']} invite you to use Metaphor messenger : ${widget.dynamicLink}",
                                            recipents);
                                      }
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(10.0),//
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(8.0),
                                        color: widget.customContact[index].inDatabase
                                            ? Color(0xFF00d419)
                                            : Color(0xFF6483b5),
                                      ),
                                      child: Text(
                                        widget.customContact[index].inDatabase
                                            ? "Chat"
                                            : "Invite",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                  ),
                                  enabled: true,
                                  onLongPress: _checkContactStatus,
                                ),
                              )),
                            ],
                          );
                        },
                      ),
                    )
                  ],
                )
              : Center(child: CircularProgressIndicator()),
        ),
      ),
    );
  }

  Widget _checkColorGrey() {
    return Container(
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Color(0xFF7991b8),
      ),
    );
  }

  Widget _checkColorGreen() {
    return Container(
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5.0),
        color: Color(0xFF02ab26),
      ),
    );
  }

  _checkContactStatus() async {
    FirebaseAuth.instance.currentUser().then((user) {
      if (user == null) {
        _checkColorGrey();
      } else {
        _checkColorGreen();
      }
    });
  }

  void _sendSMS(String message, Iterable<String> recipents) async {
    String _result =
        await FlutterSms.sendSMS(message: message, recipients: recipents)
            .catchError((onError) {
      print(onError);
    });
    print(_result);
  }
}
