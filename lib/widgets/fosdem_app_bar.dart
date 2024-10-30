import 'package:flutter/material.dart';
import 'package:fosdem/utils/style.dart';
import 'dart:ui' as ui;


class FosdemAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  List<Widget>? actions;
  final bool canGoBack;

  FosdemAppBar(
    this.title, {
    List<Widget>? actions,
    super.key,
    this.canGoBack = false,
  });

  @override
  Size get preferredSize => Size.fromHeight(AppBar().preferredSize.height);

  @override
  _FosdemAppBarState createState() => _FosdemAppBarState();
}

class _FosdemAppBarState extends State<FosdemAppBar> {
  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: 5.0,
          sigmaY: 5.0,
        ),
        child: Container(
          //height: widget.preferredSize.height,
          margin: EdgeInsets.only(
              top: MediaQuery.of(context).viewPadding.top, bottom: 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              /*Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    widget.canGoBack ? const FosdemBackButton() : Container()
                  ],
                ),
              ),
              */
              Expanded(child:
              SizedBox(
                //flex: 1,
                child:
                //Column(
                    //mainAxisAlignment: MainAxisAlignment.center,
                //    crossAxisAlignment: CrossAxisAlignment.center,
                //    children: [
                      Container(
                        padding: const EdgeInsets.fromLTRB(7.0, 7.0, 7.0, 7.0),
                        decoration: BoxDecoration(
                          color: fosdemBlue,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          widget.title,
                          style: const TextStyle(
                              color: fosdemWhite,
                              fontSize: 18,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                 //   ]),
              ),
              ),//Expanded(flex: 1, child: Container()),
            ],
          ),
        ),
      ),
    );
  }
}
