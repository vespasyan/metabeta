import 'dart:io';

/// Notification Model Class

class NotificationUser{
  String peerId;
  String peerName;
  String peerProfilePic;
  String peerDeviceToken;
  String peerDeviceType;
  NotificationUser({this.peerId, this.peerName, this.peerProfilePic,
      this.peerDeviceToken,this.peerDeviceType});



  factory NotificationUser.fromJson(Map<String, dynamic> parsedJson){
    print("parsedJson");
    print(parsedJson);
    return NotificationUser(
        peerId: parsedJson['user_id'],
        peerName : parsedJson['user_name'] ,
        peerProfilePic : parsedJson ['user_pic'],
        peerDeviceToken : parsedJson ['user_token'],
        peerDeviceType : parsedJson ['user_type'],
    );
  }

}