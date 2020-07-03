import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:metaphor_beta/const.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:contacts_service/contacts_service.dart';

class Chat extends StatelessWidget {
  final String peerId;
  final String peerAvatar;
  final Contact userName;

  final DocumentSnapshot userDocument;
  final DocumentSnapshot peerDocument;
  final int type;

  Chat(
      {Key key,
        @required this.peerId,
        @required this.peerAvatar,
        @required this.userName,
        @required this.userDocument,
        @required this.peerDocument,
        @required this.type})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: new Color.fromRGBO(29, 23, 58, 0.85),
      appBar: new AppBar(
        backgroundColor: Colors.red,
        title: new Text(
          userName.displayName ?? '',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        //centerTitle: true,
      ),
      body: new Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
                image: new AssetImage('images/particles_dark.gif'),
                fit: BoxFit.cover)),
        child: new ChatScreen(
          peerId: peerId,
          peerAvatar: peerAvatar,
          userName: userName,
        ),
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final Contact userName;

  ChatScreen(
      {Key key,
        @required this.peerId,
        @required this.peerAvatar,
        @required this.userName})
      : super(key: key);

  @override
  State createState() => new ChatScreenState(
    peerId: peerId,
    peerAvatar: peerAvatar,
    userName: userName,
  );
}

class ChatScreenState extends State<ChatScreen> {
  ChatScreenState({
    Key key,
    @required this.peerId,
    @required this.peerAvatar,
    @required this.userName,
  });

  String peerId;
  String peerAvatar;
  String id;
  Contact userName;

  var listMessage;
  String groupChatId;
  SharedPreferences prefs;

  File imageFile;
  bool isLoading;
  bool isShowSticker;
  String imageUrl;

  String _debugLabelString = "";

  bool _requireConsent = true;

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();
  final FocusNode focusNode = new FocusNode();

  @override
  void initState() {
    super.initState();
    focusNode.addListener(onFocusChange);

    groupChatId = '';

    isLoading = false;
    isShowSticker = false;
    imageUrl = '';

    readLocal();
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      // Hide sticker when keyboard appear
      setState(() {
        isShowSticker = false;
      });
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }

    setState(() {});
  }

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
      Fluttertoast.showToast(msg: 'This file is not an image');
    });
  }

  FutureOr onSendMessage(String content, int type) {
    // type: 0 = text, 1 = image, 2 = sticker
    if (content.trim() != '') {
      textEditingController.clear();

      var documentReference = Firestore.instance
          .collection('messages')
          .document(groupChatId)
          .collection(groupChatId)
          .document(DateTime.now().millisecondsSinceEpoch.toString());

      Firestore.instance.runTransaction((transaction) async {
        await transaction.set(
          documentReference,
          {
            'idFrom': id,
            'idTo': peerId,
            'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
            'content': content,
            'type': type
          },
        );
      });
      listScrollController.animateTo(0.0,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
    } else {
      Fluttertoast.showToast(msg: 'Nothing to send');
    }
  }

  Widget buildItem(int index, DocumentSnapshot document) {
    if (document['idFrom'] == id) {
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
                  child: Text(
                    document['content'],
                    style:
                    TextStyle(color: Colors.white70, fontSize: 16.0),
                  ),
                  flex: 11,
                  fit: FlexFit.tight,
                ),
                Flexible(
                    flex: 1,
                    fit: FlexFit.loose,
                    child: Ink(
                      child: Icon(
                        Icons.mail,
                        size: 8,
                        color: Colors.green,
                      ),
                    )),
                Padding(padding: EdgeInsets.only(right: 2.0)),
                Flexible(
                  flex: 3,
                  fit: FlexFit.loose,
                  child: Text(
                    DateFormat('dd MMM kk:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            int.parse(document['timestamp']))),
                    style: TextStyle(
                        color: Colors.white70,
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
            child: Material(
              child: CachedNetworkImage(
                placeholder: (context, url) => new Container(
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
                ),
                errorWidget: (context, url, error) => new Material(
                  child: Image.asset(
                    'images/img_not_available.jpeg',
                    width: 200.0,
                    height: 200.0,
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.all(
                    Radius.circular(8.0),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
                imageUrl: document['content'],
                width: 200.0,
                height: 200.0,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(8.0)),
              clipBehavior: Clip.hardEdge,
            ),
            margin: EdgeInsets.only(
                bottom: isLastMessageRight(index) ? 20.0 : 10.0,
                right: 10.0),
          )
          // Sticker
              : Container(
            padding: EdgeInsets.all(2.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10.0),
            ),
            height: 45,
            width: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Flexible(
                    fit: FlexFit.loose,
                    flex: 3,
                    child: Container(
                      child: new Image.asset(
                        'emoji/${document['content']}.png',
                        width: 40.0,
                        height: 40.0,
                        fit: BoxFit.cover,
                      ),
                    )),
                //Padding(padding: EdgeInsets.only(right: 15)),
                Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: Ink(
                      child: Icon(
                        Icons.mail,
                        size: 7,
                        color: Colors.green,
                      ),
                    )),
                //Padding(padding: EdgeInsets.symmetric(horizontal: 1.0)),
                Flexible(
                  flex: 3,
                  fit: FlexFit.tight,
                  child: Text(
                    DateFormat('dd MMM kk:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(
                            int.parse(document['timestamp']))),
                    style: TextStyle(
                        color: Colors.white70,
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
                        child: Text(
                          document['content'],
                          style: TextStyle(
                              color: Colors.white70, fontSize: 16.0),
                        ),
                        flex: 8,
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
                        flex: 2,
                        fit: FlexFit.loose,
                      )
                    ],
                  ),
                  padding: EdgeInsets.fromLTRB(15.0, 10.0, 15.0, 10.0),
                  width: 220.0,
                  decoration: BoxDecoration(
                      color: Color.fromRGBO(57, 173, 239, 0.85),
                      borderRadius: BorderRadius.circular(16.0)),
                  //margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 0.0),
                )
                    : document['type'] == 1
                    ? Container(
                  child: Material(
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Container(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              themeColor),
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
                      ),
                      errorWidget: (context, url, error) => Material(
                        child: Image.asset(
                          'images/img_not_available.jpeg',
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(
                          Radius.circular(8.0),
                        ),
                        clipBehavior: Clip.hardEdge,
                      ),
                      imageUrl: document['content'],
                      width: 200.0,
                      height: 200.0,
                      fit: BoxFit.cover,
                    ),
                    borderRadius:
                    BorderRadius.all(Radius.circular(8.0)),
                    clipBehavior: Clip.hardEdge,
                  ),
                  //margin: EdgeInsets.only(bottom: isLastMessageRight(index) ? 20.0 : 10.0, right: 0.0),
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
                        child: Image.asset(
                          'emoji/${document['content']}.png',
                          width: 40.0,
                          height: 40.0,
                          //fit: BoxFit.cover,
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

  bool isLastMessageLeft(int index) {
    if ((index > 0 &&
        listMessage != null &&
        listMessage[index - 1]['idFrom'] == id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
        listMessage != null &&
        listMessage[index - 1]['idFrom'] != id) ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    if (isShowSticker) {
      setState(() {
        isShowSticker = false;
      });
    } else {
      Navigator.pop(context);
    }

    return Future.value(false);
  }

  Future<bool> onPickEmoji() {
    var btn =
    FlatButton(onPressed: () => onSendMessage('image/', 2), child: null);

    Navigator.pop(context);

    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) {
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

  Widget buildLoading() {
    return Positioned(
      child: isLoading
          ? Container(
        child: Center(
          child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(themeColor)),
        ),
        color: Colors.blue.withOpacity(0.5),
      )
          : Container(),
    );
  }

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
                onPressed: () => onSendMessage(textEditingController.text, 0),
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
            .limit(40)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(
                child: CircularProgressIndicator(
                    valueColor:
                    AlwaysStoppedAnimation<Color>(themeColor)));
          } else {
            listMessage = snapshot.data.documents;
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
}
