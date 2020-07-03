import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:metaphor_beta/const.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:contacts_service/contacts_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:metaphor_beta/tablayouts/tablayout.dart';

//void main() => runApp(new WelcomeScreen());

/*class WelcomeScreen extends StatelessWidget {
  static String tag;
  static String firestore;

  final DocumentSnapshot userDocument;

  WelcomeScreen({this.userDocument});

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Metaphor',
      theme: new ThemeData(

        primarySwatch: Colors.red,
      ),
      home: new DemoPage(userDocument: userDocument,),
    );
  }
}*/

class WelcomeScreen extends StatefulWidget {
  final DocumentSnapshot userDocument;

  WelcomeScreen({this.userDocument});

  @override
  _WelcomeScreenState createState() => new _WelcomeScreenState();

/*DemoPage() {
    timeDilation = 1.0;
  }*/
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  startTime() async {
    var _duration = new Duration(milliseconds: 3200);
    return new Timer(_duration, navigationPage);
  }

  void navigationPage() {
    Navigator.of(context).pushReplacement(CupertinoPageRoute(
        builder: (context) => TabLayouts(
              userDocument: widget.userDocument,
            )));
  }

  @override
  void initState() {
    super.initState();
    startTime();
    updateDeviceToken();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: new Color.fromRGBO(29, 23, 58, 0.85),
      body: new DemoBody(screenSize: MediaQuery.of(context).size),
    );
  }

  void updateDeviceToken() async {
    await Firestore.instance
        .collection('users')
        .document(widget.userDocument.documentID)
        .updateData({
      'device_token': Constants.deviceToken,
      'user_device_type': Platform.isIOS ? "I" : "A"
    });
  }
}

class DemoBody extends StatefulWidget {
  final Size screenSize;

  DemoBody({Key key, @required this.screenSize}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return new _DemoBodyState();
  }
}

class _DemoBodyState extends State<DemoBody> with TickerProviderStateMixin {
  AnimationController animationController;
  final nodeList = <Node>[];
  final numNodes = 38;
  CrossFadeState crossFadeState;
  Iterable<Contact> _contacts;

  bool _first() {
    animationController.value.floor();
    return true;
  }

  @override
  void initState() {
    super.initState();

    // Generate list of node
    new List.generate(numNodes, (i) {
      nodeList.add(new Node(id: i, screenSize: widget.screenSize));
    });

    animationController =
        new AnimationController(vsync: this, duration: new Duration(seconds: 2))
          ..addListener(() {
            for (int i = 0; i < nodeList.length; i++) {
              nodeList[i].move(animationController.value);
              for (int j = i + 1; j < nodeList.length; j++) {
                nodeList[i].connect(nodeList[j]);
              }
            }
          })
          ..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: new Color.fromRGBO(29, 23, 58, 0.85),
      body: new Container(
        decoration: new BoxDecoration(
            image: new DecorationImage(
          image: AssetImage('images/navy_blue_2_1.png'),
          fit: BoxFit.cover,
        )),
        child: new Stack(
          children: <Widget>[
            new Container(
              child: new AnimatedBuilder(
                animation: new CurvedAnimation(
                    parent: animationController, curve: Curves.easeInOut),
                builder: (context, child) => new CustomPaint(
                  size: widget.screenSize,
                  painter: new _DemoPainter(widget.screenSize, nodeList),
                ),
              ),
            ),
            new Center(
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                decoration: new BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color.fromRGBO(255, 0, 0, 0.7),
                          const Color.fromRGBO(200, 0, 255, 0.7)
                        ]),
                    //color: new Color.fromRGBO(255, 55, 5, 0.75),
                    borderRadius:
                        new BorderRadius.all(const Radius.circular(10.0))),
                //color: new Color.fromRGBO(255, 55, 5, 0.75),
                child: AnimatedCrossFade(
                  firstChild: const Text('Welcome',
                      style: TextStyle(
                          fontSize: 44.0,
                          fontFamily: 'Times New Roman',
                          color: Colors.white)),
                  secondChild: const Text('to Metaphor',
                      style: TextStyle(
                          fontSize: 44.0,
                          fontFamily: 'Times New Roman',
                          color: Colors.white)),
                  crossFadeState: _first()
                      ? CrossFadeState.showFirst
                      : CrossFadeState.showSecond,
                  duration: const Duration(milliseconds: 3000),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _DemoPainter extends CustomPainter {
  final List<Node> nodeList;
  final Size screenSize;

  _DemoPainter(this.screenSize, this.nodeList);

  @override
  void paint(Canvas canvas, Size size) {
    for (var node in nodeList) {
      node.display(canvas);
    }
  }

  @override
  bool shouldRepaint(_DemoPainter oldDelegate) => true;
}

enum Direction {
  LEFT,
  RIGHT,
  TOP,
  BOTTOM,
  TOP_LEFT,
  TOP_RIGHT,
  BOTTOM_LEFT,
  BOTTOM_RIGHT
}

class Node {
  int id;

  Size screenSize;
  double radius;
  double width;
  double size;
  Offset position;
  Direction direction;
  Random random;
  Paint notePaint, linePaint;
  List mcolors = [
    Colors.red,
    Colors.amber,
    Colors.blue,
    Colors.green,
    Colors.deepOrange
  ];

  //double d  = Math.sqrt(xd * xd + yd * yd) *2;

  Map<int, Node> connected;

  Invocation invocation;

  Node(
      {@required this.id,
      this.size = 5.0,
      this.radius = 200.0,
      @required this.screenSize}) {
    random = new Random();
    connected = new Map();
    //position = screenSize.center(Offset(random.nextDouble() * size.floor() * size.ceil(), random.nextDouble() * size.floor()));
    position = new Offset(random.nextDouble() * screenSize.width,
        random.nextDouble() * screenSize.height);

    direction = Direction.values[random.nextInt(Direction.values.length)];
    size = (random.nextDouble() * 30) + 6;

    notePaint = new Paint()
      ..color = mcolors[random.nextInt(4)]
      ..strokeWidth = 1.0
      ..style = PaintingStyle.fill;
    linePaint = new Paint()
      ..color = mcolors[random.nextInt(4)]
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
  }

  void move(double seed) {
    switch (direction) {
      case Direction.LEFT:
        position -= new Offset(1.0 + seed, 0.0);
        if (position.dx <= 5.0) {
          List<Direction> dirAvailableList = [
            Direction.RIGHT,
            Direction.BOTTOM_RIGHT,
            Direction.TOP_RIGHT
          ];
          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }

        break;
      case Direction.RIGHT:
        position += new Offset(1.0 + seed, 0.0);
        if (position.dx >= screenSize.width - 5.0) {
          List<Direction> dirAvailableList = [
            Direction.LEFT,
            Direction.BOTTOM_LEFT,
            Direction.TOP_LEFT
          ];
          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }
        break;
      case Direction.TOP:
        position -= new Offset(0.0, 1.0 + seed);
        if (position.dy <= 5.0) {
          List<Direction> dirAvailableList = [
            Direction.BOTTOM,
            Direction.BOTTOM_LEFT,
            Direction.BOTTOM_RIGHT
          ];
          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }
        break;
      case Direction.BOTTOM:
        position += new Offset(0.0, 1.0 + seed);
        if (position.dy >= screenSize.height - 5.0) {
          List<Direction> dirAvailableList = [
            Direction.TOP,
            Direction.TOP_LEFT,
            Direction.TOP_RIGHT,
          ];
          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }
        break;
      case Direction.TOP_LEFT:
        position -= new Offset(1.0 + seed, 1.0 + seed);
        if (position.dx <= 5.0 || position.dy <= 5.0) {
          List<Direction> dirAvailableList = [
            Direction.BOTTOM_RIGHT,
          ];

          //if y invalid and x valid
          if (position.dy <= 5.0 && position.dx > 5.0) {
            dirAvailableList.add(Direction.LEFT);
            dirAvailableList.add(Direction.RIGHT);
            dirAvailableList.add(Direction.BOTTOM);
            dirAvailableList.add(Direction.BOTTOM_LEFT);
          }
          //if x invalid and y valid
          if (position.dx <= 5.0 && position.dy > 5.0) {
            dirAvailableList.add(Direction.TOP);
            dirAvailableList.add(Direction.RIGHT);
            dirAvailableList.add(Direction.BOTTOM);
            dirAvailableList.add(Direction.TOP_RIGHT);
          }

          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }
        break;
      case Direction.TOP_RIGHT:
        position -= new Offset(-1.0 - seed, 1.0 + seed);
        if (position.dx >= screenSize.width - 5.0 || position.dy <= 5.0) {
          List<Direction> dirAvailableList = [
            Direction.BOTTOM_LEFT,
          ];

          //if y invalid and x valid
          if (position.dy <= 5.0 && position.dx < screenSize.width - 5.0) {
            dirAvailableList.add(Direction.LEFT);
            dirAvailableList.add(Direction.RIGHT);
            dirAvailableList.add(Direction.BOTTOM);
            dirAvailableList.add(Direction.BOTTOM_RIGHT);
          }
          //if x invalid and y valid
          if (position.dx >= screenSize.width - 5.0 && position.dy > 5.0) {
            dirAvailableList.add(Direction.TOP);
            dirAvailableList.add(Direction.BOTTOM);
            dirAvailableList.add(Direction.LEFT);
            dirAvailableList.add(Direction.TOP_LEFT);
          }

          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }
        break;
      case Direction.BOTTOM_LEFT:
        position -= new Offset(1.0 + seed, -1.0 + seed);
        if (position.dx <= 5.0 || position.dy >= screenSize.height - 5.0) {
          List<Direction> dirAvailableList = [
            Direction.TOP_RIGHT,
          ];
          //if y invalid and x valid
          if (position.dy >= screenSize.height - 5.0 && position.dx > 5.0) {
            dirAvailableList.add(Direction.LEFT);
            dirAvailableList.add(Direction.RIGHT);
            dirAvailableList.add(Direction.TOP);
            dirAvailableList.add(Direction.TOP_LEFT);
          }
          //if x invalid and y valid
          if (position.dx <= 5.0 && position.dy < screenSize.height - 5.0) {
            dirAvailableList.add(Direction.TOP);
            dirAvailableList.add(Direction.BOTTOM);
            dirAvailableList.add(Direction.RIGHT);
            dirAvailableList.add(Direction.BOTTOM_RIGHT);
          }

          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }
        break;
      case Direction.BOTTOM_RIGHT:
        position += new Offset(1.0 + seed, 1.0 + seed);
        if (position.dx >= screenSize.width - 5.0 ||
            position.dy >= screenSize.height - 5.0) {
          List<Direction> dirAvailableList = [
            Direction.TOP_LEFT,
          ];
          //if y invalid and x valid
          if (position.dy >= screenSize.height - 5.0 &&
              position.dx < screenSize.width - 5.0) {
            dirAvailableList.add(Direction.LEFT);
            dirAvailableList.add(Direction.RIGHT);
            dirAvailableList.add(Direction.TOP);
            dirAvailableList.add(Direction.TOP_RIGHT);
          }
          //if x invalid and y valid
          if (position.dx >= screenSize.width - 5.0 &&
              position.dy < screenSize.height - 5.0) {
            dirAvailableList.add(Direction.TOP);
            dirAvailableList.add(Direction.BOTTOM);
            dirAvailableList.add(Direction.LEFT);
            dirAvailableList.add(Direction.BOTTOM_LEFT);
          }

          direction = dirAvailableList[random.nextInt(dirAvailableList.length)];
        }
        break;
    }
  }

  bool canConnect(Node node) {
    double x = node.position.dx - position.dx;
    double y = node.position.dy - position.dy;
    double d = x * x + y * y;
    return d <= radius / 2 * radius / 2;
  }

  void connect(Node node) {
    if (canConnect(node)) {
      if (!node.connected.containsKey(id)) {
        connected.putIfAbsent(node.id, () => node);
      }
    } else if (connected.containsKey(node.id)) {
      connected.remove(node.id);
    }
  }

  void display(Canvas canvas) {
    canvas.drawCircle(position, size, notePaint);

    connected.forEach((id, node) {
      canvas.drawLine(position, node.position, linePaint);
    });
  }

  bool operator ==(o) => o is Node && o.id == id;

  int get hashCode => id;
}
