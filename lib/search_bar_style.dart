import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SearchBarStyle {
  final Color backgroundColor;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  BoxBorder border;

  SearchBarStyle({
    this.backgroundColor = Colors.transparent, // const Color.fromRGBO(142, 142, 147, .15),
    this.padding = const EdgeInsets.symmetric(horizontal: 5.0),
    this.borderRadius = const BorderRadius.only(topLeft: Radius.circular(30.0), bottomLeft: Radius.circular(30.0)),
    BoxBorder border,
  }) : border = border ?? Border.all(color: Colors.black26);
}
