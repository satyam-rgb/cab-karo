import 'package:flutter/material.dart';

SizedBox buildHeight(double height) => SizedBox(height: height);
SizedBox buildWidth(double width) => SizedBox(width: width);

double deviceHeight(BuildContext context) =>
    MediaQuery.of(context).size.height;

double deviceWidth(BuildContext context) =>
    MediaQuery.of(context).size.width;
