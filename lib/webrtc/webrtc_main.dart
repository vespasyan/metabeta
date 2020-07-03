import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:core';

import 'basic_sample/basic_sample.dart';
import 'call_sample/call_sample.dart';
import 'call_sample/data_channel_sample.dart';
import 'route_item.dart';



class MyWebRtc extends StatefulWidget {
  @override
  MyWebRtcState createState() => new MyWebRtcState();
}

enum DialogDemoAction {
  cancel,
  connect,
}

class MyWebRtcState extends State<MyWebRtc> {
  List<RouteItem> items;
  String _serverAddress = '';
  SharedPreferences prefs;
  bool _datachannel = false;
  @override
  initState() {
    super.initState();
    _initData();
    _initItems();
  }

  _buildRow(context, item) {
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(item.title, style: TextStyle(color: Colors.white70),),
        onTap: () => item.push(context),
        trailing: Icon(Icons.arrow_right, color: Colors.white70,),
      ),
      Divider(height: 3.0, indent: 20.0, color: Colors.white70,)
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      home: new Scaffold(
          backgroundColor: new Color.fromRGBO(29, 23, 58, 0.85),
          appBar: new AppBar(
            leading: new IconButton(
              icon: new Icon(Icons.arrow_back, color: Colors.white70),
              onPressed: () => Navigator.of(context).pop(),
            ),
            centerTitle: true,
            backgroundColor: Colors.red,
            title: new Text('Flutter-WebRTC'),
          ),
          body: new ListView.builder(

              shrinkWrap: true,
              padding: const EdgeInsets.all(0.0),
              itemCount: items.length,
              itemBuilder: (context, i) {
                return _buildRow(context, items[i]);
              })),
    );
  }

  _initData() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      _serverAddress = prefs.getString('server') ?? 'demo.cloudwebrtc.com';
    });
  }

  void showDemoDialog<T>({BuildContext context, Widget child}) {
    showDialog<T>(
      context: context,
      builder: (BuildContext context) => child,
    ).then<void>((T value) {
      // The value passed to Navigator.pop() or null.
      if (value != null) {
        if (value == DialogDemoAction.connect) {
          prefs.setString('server', _serverAddress);
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (BuildContext context) =>
                  _datachannel? DataChannelSample(ip: _serverAddress) : CallSample(ip: _serverAddress)));
        }
      }
    });
  }

  _showAddressDialog(context) {
    showDemoDialog<DialogDemoAction>(
        context: context,
        child: new AlertDialog(
            title: const Text('Enter server address:'),
            content: TextField(
              onChanged: (String text) {
                setState(() {
                  _serverAddress = text;
                });
              },
              decoration: InputDecoration(
                hintText: _serverAddress,
              ),
              textAlign: TextAlign.center,
            ),
            actions: <Widget>[
              new FlatButton(
                  child: const Text('CANCEL'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.cancel);
                  }),
              new FlatButton(
                  child: const Text('CONNECT'),
                  onPressed: () {
                    Navigator.pop(context, DialogDemoAction.connect);
                  })
            ]));
  }

  _initItems() {
    items = <RouteItem>[
      RouteItem(
          title: 'RouteItem',
          subtitle: 'Basic API Tests.',
          push: (BuildContext context) {
            Navigator.push(
                context,
                new MaterialPageRoute(
                    builder: (BuildContext context) => new BasicSample()));
          }),
      RouteItem(
          title: 'P2P Call Sample',
          subtitle: 'P2P Call Sample.',
          push: (BuildContext context) {
            _datachannel = false;
            _showAddressDialog(context);
          }),
      RouteItem(
          title: 'Data Channel Sample',
          subtitle: 'P2P Data Channel.',
          push: (BuildContext context) {
            _datachannel = true;
            _showAddressDialog(context);
          }),
    ];
  }
}