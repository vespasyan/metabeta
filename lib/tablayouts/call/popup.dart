import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metaphor_beta/ChatListPage.dart';
import 'call_layout.dart';
import 'package:metaphor_beta/tablayouts/tablayout.dart';
import 'package:metaphor_beta/tablayouts/chat/chat_layout.dart';
import 'package:metaphor_beta/welcome_screen/welcomeScreen.dart';

class ReturnPopup{

 information(BuildContext context, String title, String description){
   return showDialog(
       context: context,
       barrierDismissible: true,
       builder: (BuildContext context){
         var widget;
         return AlertDialog(
           backgroundColor: Colors.amber,
           shape: RoundedRectangleBorder(side: BorderSide(
             width: 1.0,
                 color: Colors.blue,

           )),
           title: Text(title, style: TextStyle(color: Colors.red),),
           content: SingleChildScrollView(
             child: ListBody(
               children: <Widget>[
                 Text(description, style: TextStyle(color: Colors.blue[900], fontWeight: FontWeight.bold),)
               ],
             ),
           ),
           actions: <Widget>[
             FlatButton.icon(
                 onPressed: () => Navigator.pop(context),
                 icon: Icon(Icons.keyboard_return),
                 label: Text(''))
           ],
         );
       });
 }
}