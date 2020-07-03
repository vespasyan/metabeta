import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:metaphor_beta/const.dart';


class ShowImage extends StatelessWidget {

  final String imageUrl;
  final String imageTitle;

  ShowImage({@required this.imageUrl,@required this.imageTitle});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          //title: Text(imageTitle,style: TextStyle(color: Colors.white,fontSize: 14.0),),
        ),
        body: Center(
          child: Container(
            child: CachedNetworkImage(
              placeholder: (context, url) =>
                  Container(
                    child: CircularProgressIndicator(
                      valueColor:
                      AlwaysStoppedAnimation<Color>(themeColor),
                    ),
                    /*width: 200.0,
                    height: 200.0,*/
                    padding: EdgeInsets.all(70.0),
                    decoration: BoxDecoration(
                      color: greyColor2,
                      borderRadius: BorderRadius.all(
                        Radius.circular(8.0),
                      ),
                    ),
                  ),
              errorWidget: (context, url, error) =>
                  Material(
                    child: Image.asset(
                      'images/img_not_available.jpeg',
                     /* width: 200.0,
                      height: 200.0,*/
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.all(
                      Radius.circular(8.0),
                    ),
                    clipBehavior: Clip.hardEdge,
                  ),
              imageUrl: imageUrl,
              /*width: 200.0,
              height: 200.0,*/
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }
}
