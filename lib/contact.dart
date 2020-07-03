import 'dart:async';
import 'package:flutter/services.dart';

class ContactPicker{
  static const  _channel = const MethodChannel('contact_picker');

  Future<Contact> selectContact() async{
    final Map<dynamic, dynamic> result = await _channel.invokeMethod('selectContact');

    if(result == null){
      return null;
    }
    return new Contact.fromMap(result);
  }


}

class Contact{
  Contact({this.fullName, this.phoneNumber});

  factory Contact.fromMap(Map<dynamic, dynamic> map) => new Contact(
      fullName: map['fullName'],
      phoneNumber: new PhoneNumber.fromMap(map['phoneNumber']));

  final String fullName;
  final PhoneNumber phoneNumber;

  @override
  String toString() {
    return '$fullName: $phoneNumber';
  }
}

class PhoneNumber{
  PhoneNumber({this.number, this.label});

  factory PhoneNumber.fromMap(Map<dynamic, dynamic> map) =>
      new PhoneNumber(number: map['number'], label: map['label']);
  final String number;
  final String label;

  @override
  String toString() {
    return '$number ($label)';
  }


}