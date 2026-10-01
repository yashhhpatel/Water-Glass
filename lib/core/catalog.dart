import 'package:flutter/material.dart';

/// Water colours, unlocked one by one by filling the reward bottle in Classic mode.
const List<Color> waterColors = [
  Color(0xFF4DAFF0), // blue (default)
  Color(0xFF1FA05A), // green
  Color(0xFFFFEE1E), // yellow
  Color(0xFFF9A23B), // orange
  Color(0xFFF0473B), // red
  Color(0xFFA8A8A8), // grey
  Color(0xFF2E2E2E), // black
  Color(0xFFB04FC9), // purple
  Color(0xFFF2649B), // pink
  Color(0xFFB0662A), // brown
  Color(0xFF1FD1C4), // turquoise
  Color(0xFF128A4A), // dark green
  Color(0xFF9B6CF0), // lavender
  Color(0xFFE5455B), // crimson
];

enum UnlockKind { owned, coins, ad, dontSpill }

class InkItem {
  final Color color;
  final Color? color2;
  final UnlockKind unlock;
  final int dsLevel;
  const InkItem(this.color, this.unlock, {this.color2, this.dsLevel = 0});
}

/// Line ink colours (ink-jar tab of the shop).
const List<InkItem> inks = [
  InkItem(Color(0xFF111111), UnlockKind.owned),
  InkItem(Color(0xFF1E6FE0), UnlockKind.ad),
  InkItem(Color(0xFFE8262B), UnlockKind.ad),
  InkItem(Color(0xFF8A1FE0), UnlockKind.ad),
  InkItem(Color(0xFF2B3FD8), UnlockKind.dontSpill, color2: Color(0xFFFF2E8A), dsLevel: 10),
  InkItem(Color(0xFFFF6FA0), UnlockKind.dontSpill, color2: Color(0xFFFFD1E0), dsLevel: 10),
  InkItem(Color(0xFFB21FE8), UnlockKind.dontSpill, color2: Color(0xFFFF4FD8), dsLevel: 10),
  InkItem(Color(0xFFE81F1F), UnlockKind.dontSpill, color2: Color(0xFFFF1FC0), dsLevel: 20),
];

enum PenStyle { pencil, caterpillar, starPen, branch, silver, fountain, yellowPencil, ballpoint, candy }

class PenItem {
  final PenStyle style;
  final int price;
  const PenItem(this.style, this.price);
}

const List<PenItem> pens = [
  PenItem(PenStyle.pencil, 0),
  PenItem(PenStyle.caterpillar, 5000),
  PenItem(PenStyle.starPen, 5000),
  PenItem(PenStyle.branch, 2500),
  PenItem(PenStyle.silver, 2500),
  PenItem(PenStyle.fountain, 2500),
  PenItem(PenStyle.yellowPencil, 500),
  PenItem(PenStyle.ballpoint, 500),
  PenItem(PenStyle.candy, 500),
];

enum Eyes { round, big, sleepy, lashes, nerd, sunglasses, angry, panda }

enum Mouth { smile, teeth, tongue, wide, beak, cat, bunny, flat }

enum Extra { none, leopard, dogEars, pigNose, bearEars, whiskers, camo, birdBrows, earrings }

class GlassSkin {
  final Color frame;
  final Eyes eyes;
  final Mouth mouth;
  final Extra extra;
  final int price;
  const GlassSkin(this.frame, this.eyes, this.mouth, this.extra, this.price);
}

/// Glass skins (face tab of the shop), same order and prices as the reference.
const List<GlassSkin> glassSkins = [
  GlassSkin(Color(0xFF8A8A8A), Eyes.round, Mouth.smile, Extra.none, 0),
  GlassSkin(Color(0xFFFFE21E), Eyes.big, Mouth.teeth, Extra.leopard, 10000),
  GlassSkin(Color(0xFF8B4A1E), Eyes.round, Mouth.tongue, Extra.dogEars, 5000),
  GlassSkin(Color(0xFFF07A8A), Eyes.round, Mouth.smile, Extra.pigNose, 5000),
  GlassSkin(Color(0xFFDDDDDD), Eyes.panda, Mouth.flat, Extra.none, 5000),
  GlassSkin(Color(0xFF5A5A5A), Eyes.nerd, Mouth.smile, Extra.none, 5000),
  GlassSkin(Color(0xFFFFE21E), Eyes.round, Mouth.beak, Extra.birdBrows, 5000),
  GlassSkin(Color(0xFF26456E), Eyes.sunglasses, Mouth.smile, Extra.camo, 5000),
  GlassSkin(Color(0xFFF08A3B), Eyes.round, Mouth.smile, Extra.bearEars, 5000),
  GlassSkin(Color(0xFF3F3F3F), Eyes.sleepy, Mouth.cat, Extra.whiskers, 2000),
  GlassSkin(Color(0xFFFFE21E), Eyes.round, Mouth.wide, Extra.whiskers, 2000),
  GlassSkin(Color(0xFFDDDDDD), Eyes.big, Mouth.bunny, Extra.none, 2000),
  GlassSkin(Color(0xFF6E7B80), Eyes.angry, Mouth.smile, Extra.none, 1000),
  GlassSkin(Color(0xFFDDDDDD), Eyes.lashes, Mouth.flat, Extra.earrings, 1000),
];
