import 'package:flutter/material.dart';

/// Palette sampled from the reference video.
class C {
  static const bg = Color(0xFFFFFFFF);
  static const grid = Color(0xFFEDEFF0);
  static const ink = Color(0xFF151515);
  static const green = Color(0xFFACDB4D);
  static const greenDark = Color(0xFF36B546);
  static const blue = Color(0xFF55ACEA);
  static const blueLight = Color(0xFFC5E1F8);
  static const btnBlue = Color(0xFF4EA9EC);
  static const star = Color(0xFFFFF205);
  static const locked = Color(0xFFCACFC9);
  static const lockedDark = Color(0xFFB7B8B8);
  static const yellow = Color(0xFFFFEE1E);
  static const orange = Color(0xFFF9B56B);
  static const lockOrange = Color(0xFFF7A35C);
  static const coin = Color(0xFFFFEA00);
  static const water = Color(0xFF4DAFF0);
  static const teal = Color(0xFF53A8AE);
  static const panel = Color(0xFFE5E5E5);
  static const glass = Color(0xFF8A8A8A);
  static const packBlue = Color(0xFF50ACDB);
  static const packDark = Color(0xFF2B4E59);
  static const brick = Color(0xFFF7931E);
  static const redLine = Color(0xFFE53935);
  static const heart = Color(0xFFF0476A);
  static const faucet = Color(0xFF9CA4A9);
  static const barEmpty = Color(0xFF969FA1);
  static const overlay = Color(0x99000000);
}

TextStyle txt(double size,
    {FontWeight w = FontWeight.w600,
    Color c = C.ink,
    double sp = 0,
    double? h}) {
  return TextStyle(
    fontSize: size,
    fontWeight: w,
    color: c,
    letterSpacing: sp,
    height: h,
    decoration: TextDecoration.none,
  );
}
