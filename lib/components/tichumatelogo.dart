import 'package:flutter/material.dart';

class TichuMateLogo extends StatelessWidget {
  final double width, height;
  TichuMateLogo({this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/launcher/icon.png',
      width: width,
      height: height,
    );
  }
}
