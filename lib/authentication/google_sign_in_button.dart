import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final Function onPressed;

  GoogleSignInButton({
    Key key,
    this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //var assetImage = new AssetImage("images/google_assistant_logo.png");
    //var image = new Image(image: assetImage, height: 50.0, width: 330.0);
    return MaterialButton(
      onPressed: () => this.onPressed(),
      color: Color.fromRGBO(55, 155, 255, 0.3),
      elevation: 0.9,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new Image.asset(
            'images/google.png',
            height: 30.0,
            width: 30.0,
          ),
          //SizedBox(width: 16.0),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0,horizontal: 8.0),
            child: Text(
              "Sign in with Google",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w500,
                  color: Color(0xff9AB5FF)
              ),
            ),
          ),

        ],
      ),
    );
  }
}
