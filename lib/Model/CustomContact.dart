import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:contacts_service/contacts_service.dart';

class CustomContact {

  Contact contact;
  String phoneNumber;
  bool inDatabase;
  DocumentSnapshot peerDocument;

  CustomContact(this.contact,this.phoneNumber, this.inDatabase,{this.peerDocument});


}