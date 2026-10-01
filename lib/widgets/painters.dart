import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/theme.dart';

const _outline = Color(0xFF2A2A2A);

Paint fillP(Color c) => Paint()
  ..color = c
  ..style = PaintingStyle.fill
  ..isAntiAlias = true;

Paint strokeP(Color c, double w) => Paint()
  ..color = c
  ..style = PaintingStyle.stroke
  ..strokeWidth = w
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round
  ..isAntiAlias = true;

enum Expr { sad, surprised, happy, love, worried }

/// Glass geometry in local units (height 76, centred on the origin).
class GlassGeo {
  static const h = 76.0;
  static const topW = 66.0;
  static const botW = 46.0;
  static const wall = 6.0;
  static const fillLineY = -26.0; // dotted target line
  static double halfWidthAt(double y) => botW / 2 + (topW - botW) / 2 * ((h / 2 - y) / h);
}

/// Draws a glass centred at the canvas origin (local units, height 76).
void drawGlass(Canvas c, GlassSkin skin,
    {double fill = 0, Color water = C.water, Expr expr = Expr.sad, bool dotted = true, double t = 0}) {
  const h2 = GlassGeo.h / 2;
  const tw = GlassGeo.topW / 2, bw = GlassGeo.botW / 2, w = GlassGeo.wall;
  // water fill
  if (fill > 0) {
    final top = h2 - w - (h2 * 2 - w - 8) * fill.clamp(0, 1);
    final hwTop = GlassGeo.halfWidthAt(top) - w;
    const hwBot = bw - w;
    final p = Path()
      ..moveTo(-hwTop, top)
      ..lineTo(hwTop, top)
      ..lineTo(hwBot, h2 - w)
      ..lineTo(-hwBot, h2 - w)
      ..close();
    c.drawPath(p, fillP(water));
    // little wave highlight on the surface
    final wave = Path()..moveTo(-hwTop, top);
    for (var x = -hwTop; x <= hwTop; x += 2) {
      wave.lineTo(x, top + math.sin(x / 5 + t * 6) * 1.6);
    }
    wave
      ..lineTo(hwTop, top + 5)
      ..lineTo(-hwTop, top + 5)
      ..close();
    c.drawPath(wave, fillP(Color.lerp(water, Colors.white, .25)!));
  }
  if (skin.extra == Extra.dogEars) {
    for (final s in [-1.0, 1.0]) {
      final ear = Path()
        ..moveTo(s * 14, -6)
        ..quadraticBezierTo(s * 26, -22, s * 22, 4)
        ..close();
      c.drawPath(ear, fillP(const Color(0xFF6B3410)));
    }
  }
  // dotted target line
  if (dotted) {
    const y = GlassGeo.fillLineY;
    final hw = GlassGeo.halfWidthAt(y) - w;
    final dp = strokeP(const Color(0xFF555555), 1.2);
    for (var x = -hw; x < hw; x += 5) {
      c.drawLine(Offset(x, y), Offset(math.min(x + 2.5, hw), y), dp);
    }
  }
  // walls + base
  final frame = fillP(skin.frame);
  final ol = strokeP(_outline, 1.6);
  final left = Path()
    ..moveTo(-tw, -h2)
    ..lineTo(-tw + w, -h2)
    ..lineTo(-bw + w, h2 - w)
    ..lineTo(-bw, h2)
    ..close();
  final right = Path()
    ..moveTo(tw, -h2)
    ..lineTo(tw - w, -h2)
    ..lineTo(bw - w, h2 - w)
    ..lineTo(bw, h2)
    ..close();
  final base = Path()
    ..moveTo(-bw, h2)
    ..lineTo(-bw + w, h2 - w)
    ..lineTo(bw - w, h2 - w)
    ..lineTo(bw, h2)
    ..close();
  for (final p in [left, right, base]) {
    c.drawPath(p, frame);
  }
  if (skin.extra == Extra.leopard || skin.extra == Extra.camo) {
    final sp = fillP(skin.extra == Extra.leopard ? const Color(0xFF3A2A10) : const Color(0xFF8FB8E8));
    for (final o in const [Offset(-30, -28), Offset(-27, -6), Offset(-24, 14), Offset(29, -22), Offset(26, 0), Offset(23, 20)]) {
      c.drawCircle(o, 2.2, sp);
    }
  }
  final outlinePath = Path()
    ..moveTo(-tw, -h2)
    ..lineTo(-bw, h2)
    ..lineTo(bw, h2)
    ..lineTo(tw, -h2)
    ..moveTo(-tw + w, -h2)
    ..lineTo(-bw + w, h2 - w)
    ..lineTo(bw - w, h2 - w)
    ..lineTo(tw - w, -h2);
  c.drawPath(outlinePath, ol);
  c.drawLine(const Offset(-tw, -h2), const Offset(-tw + w, -h2), ol);
  c.drawLine(const Offset(tw, -h2), const Offset(tw - w, -h2), ol);
  _drawFace(c, skin, expr);
}

void _drawFace(Canvas c, GlassSkin skin, Expr expr) {
  final ol = strokeP(_outline, 1.6);
  const ey = 4.0, ex = 9.0;
  // extras behind/around the face
  switch (skin.extra) {
    case Extra.bearEars:
      for (final s in [-1.0, 1.0]) {
        c.drawCircle(Offset(s * 13, -8), 5, fillP(const Color(0xFFF08A3B)));
        c.drawCircle(Offset(s * 13, -8), 5, ol);
      }
      c.drawOval(const Rect.fromLTWH(-10, 8, 20, 13), fillP(const Color(0xFFF7C99A)));
      break;
    case Extra.pigNose:
      break;
    case Extra.birdBrows:
      c.drawLine(const Offset(-16, -6), const Offset(-4, -3), strokeP(_outline, 3));
      c.drawLine(const Offset(16, -6), const Offset(4, -3), strokeP(_outline, 3));
      break;
    default:
      break;
  }
  // eyes
  if (expr == Expr.love) {
    for (final s in [-1.0, 1.0]) {
      drawHeart(c, Offset(s * ex, ey), 9, C.heart.withRed(235));
    }
  } else {
    switch (skin.eyes) {
      case Eyes.sunglasses:
        final g = fillP(const Color(0xFF111111));
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(-ex, ey), width: 15, height: 9), const Radius.circular(3)), g);
        c.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(ex, ey), width: 15, height: 9), const Radius.circular(3)), g);
        c.drawLine(const Offset(-2, ey - 2), const Offset(2, ey - 2), strokeP(const Color(0xFF111111), 2));
        break;
      case Eyes.panda:
        for (final s in [-1.0, 1.0]) {
          c.drawOval(Rect.fromCenter(center: Offset(s * ex, ey), width: 14, height: 12), fillP(const Color(0xFF111111)));
          c.drawCircle(Offset(s * ex, ey), 4, fillP(Colors.white));
          c.drawCircle(Offset(s * ex, ey), 2, fillP(const Color(0xFF111111)));
        }
        break;
      case Eyes.sleepy:
        for (final s in [-1.0, 1.0]) {
          c.drawArc(Rect.fromCenter(center: Offset(s * ex, ey), width: 12, height: 10), 0, math.pi, false, strokeP(_outline, 2));
        }
        break;
      default:
        final r = skin.eyes == Eyes.big ? 7.0 : 6.0;
        for (final s in [-1.0, 1.0]) {
          final o = Offset(s * ex, ey);
          c.drawCircle(o, r, fillP(Colors.white));
          c.drawCircle(o, r, ol);
          final look = expr == Expr.sad || expr == Expr.worried ? const Offset(0, -1.6) : Offset.zero;
          c.drawCircle(o + look, r * .55, fillP(const Color(0xFF111111)));
          c.drawCircle(o + look + const Offset(-1.2, -1.4), r * .18, fillP(Colors.white));
          if (skin.eyes == Eyes.lashes) {
            for (var k = -1; k <= 1; k++) {
              final a = -math.pi / 2 + k * .5;
              c.drawLine(o + Offset(math.cos(a), math.sin(a)) * r, o + Offset(math.cos(a), math.sin(a)) * (r + 3.5), strokeP(_outline, 1.2));
            }
          }
        }
        if (skin.eyes == Eyes.nerd) {
          for (final s in [-1.0, 1.0]) {
            c.drawCircle(Offset(s * ex, ey), 8, strokeP(const Color(0xFF1C4E8A), 2.2));
          }
          c.drawLine(const Offset(-1, ey), const Offset(1, ey), strokeP(const Color(0xFF1C4E8A), 2.2));
        }
        if (skin.eyes == Eyes.angry) {
          c.drawLine(const Offset(-15, -4), const Offset(-4, -1), strokeP(_outline, 2));
          c.drawLine(const Offset(15, -4), const Offset(4, -1), strokeP(_outline, 2));
        }
    }
  }
  // brows for sad / worried
  if (expr == Expr.sad || expr == Expr.worried) {
    c.drawLine(const Offset(-14, -5), const Offset(-5, -8), strokeP(_outline, 1.6));
    c.drawLine(const Offset(14, -5), const Offset(5, -8), strokeP(_outline, 1.6));
  }
  // mouth
  const my = 17.0;
  switch (expr) {
    case Expr.sad:
      c.drawArc(Rect.fromCenter(center: const Offset(0, my + 4), width: 12, height: 8), math.pi * 1.1, math.pi * .8, false, ol);
      break;
    case Expr.worried:
      final p = Path()..moveTo(-6, my);
      for (var x = -6.0; x <= 6; x += 1) {
        p.lineTo(x, my + math.sin(x * 1.2) * 1.5);
      }
      c.drawPath(p, ol);
      break;
    case Expr.surprised:
      c.drawOval(Rect.fromCenter(center: const Offset(0, my), width: 6, height: 8), fillP(const Color(0xFF222222)));
      break;
    case Expr.love:
      final p = Path()
        ..moveTo(-9, my - 4)
        ..quadraticBezierTo(0, my + 12, 9, my - 4)
        ..close();
      c.drawPath(p, fillP(const Color(0xFFE53935)));
      c.drawPath(p, ol);
      break;
    case Expr.happy:
      switch (skin.mouth) {
        case Mouth.teeth:
          final p = Path()
            ..moveTo(-9, my - 3)
            ..lineTo(9, my - 3)
            ..quadraticBezierTo(0, my + 9, -9, my - 3);
          c.drawPath(p, fillP(const Color(0xFF222222)));
          c.drawRect(const Rect.fromLTWH(-6, my - 3, 12, 3), fillP(Colors.white));
          break;
        case Mouth.tongue:
          c.drawArc(Rect.fromCenter(center: const Offset(0, my - 2), width: 14, height: 10), .1, math.pi - .2, false, ol);
          c.drawOval(const Rect.fromLTWH(-3.5, my + 1, 7, 8), fillP(const Color(0xFFF04F6A)));
          break;
        case Mouth.beak:
          final p = Path()
            ..moveTo(-5, my - 3)
            ..lineTo(5, my - 3)
            ..lineTo(0, my + 4)
            ..close();
          c.drawPath(p, fillP(const Color(0xFFF7931E)));
          c.drawPath(p, strokeP(_outline, 1));
          break;
        case Mouth.cat:
        case Mouth.wide:
          c.drawArc(const Rect.fromLTWH(-7, my - 5, 7, 6), 0, math.pi, false, ol);
          c.drawArc(const Rect.fromLTWH(0, my - 5, 7, 6), 0, math.pi, false, ol);
          break;
        case Mouth.bunny:
          c.drawArc(Rect.fromCenter(center: const Offset(0, my - 3), width: 14, height: 9), .2, math.pi - .4, false, ol);
          c.drawRect(const Rect.fromLTWH(-3, my + 1, 6, 4), fillP(Colors.white));
          c.drawRect(const Rect.fromLTWH(-3, my + 1, 6, 4), strokeP(_outline, 1));
          break;
        case Mouth.flat:
        case Mouth.smile:
          c.drawArc(Rect.fromCenter(center: const Offset(0, my - 3), width: 16, height: 10), .2, math.pi - .4, false, strokeP(_outline, 2));
      }
  }
  if (skin.extra == Extra.pigNose) {
    c.drawOval(const Rect.fromLTWH(-6, 8, 12, 8), fillP(const Color(0xFFF59AA8)));
    c.drawOval(const Rect.fromLTWH(-6, 8, 12, 8), strokeP(_outline, 1.2));
    c.drawCircle(const Offset(-2, 12), 1.2, fillP(_outline));
    c.drawCircle(const Offset(2, 12), 1.2, fillP(_outline));
  }
  if (skin.extra == Extra.whiskers) {
    final wp = strokeP(_outline, 1.2);
    for (final s in [-1.0, 1.0]) {
      c.drawLine(Offset(s * 14, 14), Offset(s * 24, 12), wp);
      c.drawLine(Offset(s * 14, 17), Offset(s * 24, 18), wp);
    }
  }
  if (skin.extra == Extra.earrings) {
    c.drawCircle(const Offset(-20, 20), 2.5, fillP(C.coin));
    c.drawCircle(const Offset(20, 20), 2.5, fillP(C.coin));
  }
}

void drawHeart(Canvas c, Offset o, double s, Color color, {bool outline = true, bool empty = false}) {
  final p = Path()
    ..moveTo(o.dx, o.dy + s * .45)
    ..cubicTo(o.dx - s * .9, o.dy - s * .15, o.dx - s * .45, o.dy - s * .75, o.dx, o.dy - s * .25)
    ..cubicTo(o.dx + s * .45, o.dy - s * .75, o.dx + s * .9, o.dy - s * .15, o.dx, o.dy + s * .45)
    ..close();
  if (!empty) c.drawPath(p, fillP(color));
  if (outline) c.drawPath(p, strokeP(_outline, math.max(1, s * .08)));
}

Path starPath(Offset o, double r, {double inner = .5}) {
  final p = Path();
  for (var i = 0; i < 10; i++) {
    final a = -math.pi / 2 + i * math.pi / 5;
    final rr = i.isEven ? r : r * inner;
    final pt = o + Offset(math.cos(a), math.sin(a)) * rr;
    i == 0 ? p.moveTo(pt.dx, pt.dy) : p.lineTo(pt.dx, pt.dy);
  }
  return p..close();
}

void drawStar(Canvas c, Offset o, double r, {bool filled = true, double ol = 0}) {
  final p = starPath(o, r);
  c.drawPath(p, fillP(filled ? C.star : Colors.white));
  c.drawPath(p, strokeP(_outline, ol > 0 ? ol : math.max(1.2, r * .09)));
}

void drawCoin(Canvas c, Offset o, double r) {
  c.drawCircle(o, r, fillP(C.coin));
  c.drawCircle(o, r, strokeP(_outline, math.max(1.2, r * .1)));
  c.drawCircle(o, r * .68, strokeP(_outline, math.max(1, r * .08)));
  final cp = strokeP(_outline, math.max(1.2, r * .11));
  c.drawArc(Rect.fromCircle(center: o, radius: r * .36), math.pi * .3, math.pi * 1.4, false, cp);
}

void drawLock(Canvas c, Offset o, double s) {
  final body = RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, s * .2), width: s * .9, height: s * .7), Radius.circular(s * .12));
  c.drawArc(Rect.fromCenter(center: o + Offset(0, -s * .15), width: s * .6, height: s * .7), math.pi, math.pi, false, strokeP(const Color(0xFFEDEDED), s * .13));
  c.drawArc(Rect.fromCenter(center: o + Offset(0, -s * .15), width: s * .6, height: s * .7), math.pi, math.pi, false, strokeP(_outline, s * .04));
  c.drawLine(o + Offset(-s * .3, -s * .15), o + Offset(-s * .3, s * .0), strokeP(const Color(0xFFEDEDED), s * .13));
  c.drawLine(o + Offset(s * .3, -s * .15), o + Offset(s * .3, s * .0), strokeP(const Color(0xFFEDEDED), s * .13));
  c.drawRRect(body, fillP(C.lockOrange));
  c.drawRRect(body.deflate(s * .06).shift(Offset(0, -s * .03)), fillP(C.orange));
  c.drawRRect(body, strokeP(_outline, s * .05));
  c.drawCircle(o + Offset(0, s * .13), s * .09, fillP(const Color(0xFF7A2E1E)));
  c.drawRect(Rect.fromCenter(center: o + Offset(0, s * .26), width: s * .07, height: s * .18), fillP(const Color(0xFF7A2E1E)));
}

/// Faucet nozzle: grey box with a down arrow. dir: 0 = down, 1 = left, 2 = right.
void drawFaucet(Canvas c, Offset o, {int dir = 0, double len = 140}) {
  final ol = strokeP(const Color(0xFF555555), 1.4);
  if (dir == 0) {
    final box = Rect.fromCenter(center: o + const Offset(0, -10), width: 32, height: 24);
    c.drawRect(box, fillP(const Color(0xFFB7BEC2)));
    c.drawRect(box, ol);
    final lip = Rect.fromCenter(center: o + const Offset(0, 5), width: 38, height: 8);
    c.drawRect(lip, fillP(C.faucet));
    c.drawRect(lip, ol);
    final a = Path()
      ..moveTo(o.dx - 5, o.dy - 18)
      ..lineTo(o.dx + 5, o.dy - 18)
      ..lineTo(o.dx + 5, o.dy - 11)
      ..lineTo(o.dx + 9, o.dy - 11)
      ..lineTo(o.dx, o.dy - 3)
      ..lineTo(o.dx - 9, o.dy - 11)
      ..lineTo(o.dx - 5, o.dy - 11)
      ..close();
    c.drawPath(a, fillP(Colors.white));
  } else {
    final s = dir == 1 ? 1.0 : -1.0;
    final box = Rect.fromLTRB(o.dx + (s > 0 ? 6 : -len), o.dy - 11, o.dx + (s > 0 ? len : -6), o.dy + 11);
    c.drawRect(box, fillP(C.faucet));
    c.drawRect(box, ol);
    final lip = Rect.fromCenter(center: o + Offset(s * 3, 0), width: 8, height: 28);
    c.drawRect(lip, fillP(const Color(0xFFB7BEC2)));
    c.drawRect(lip, ol);
    final ax = o.dx + s * 20;
    final a = Path()
      ..moveTo(ax - s * 6, o.dy)
      ..lineTo(ax + s * 2, o.dy - 5)
      ..lineTo(ax + s * 2, o.dy - 2)
      ..lineTo(ax + s * 10, o.dy - 2)
      ..lineTo(ax + s * 10, o.dy + 2)
      ..lineTo(ax + s * 2, o.dy + 2)
      ..lineTo(ax + s * 2, o.dy + 5)
      ..close();
    c.drawPath(a, fillP(Colors.white));
  }
}

/// Reward bottle with "?" label, fill 0..1.
void drawBottle(Canvas c, Offset o, double s, double fill, Color water) {
  // slim milk-bottle silhouette: long neck, rounded shoulders
  const nk = .08, bd = .22, top = -.46, neckEnd = -.3, shoulder = -.1, bot = .47;
  final p = Path()
    ..moveTo(o.dx - s * nk, o.dy + s * top)
    ..lineTo(o.dx - s * nk, o.dy + s * neckEnd)
    ..cubicTo(o.dx - s * nk, o.dy + s * (neckEnd + .08), o.dx - s * bd, o.dy + s * (shoulder - .08), o.dx - s * bd, o.dy + s * shoulder)
    ..lineTo(o.dx - s * bd, o.dy + s * (bot - .05))
    ..quadraticBezierTo(o.dx - s * bd, o.dy + s * bot, o.dx - s * (bd - .05), o.dy + s * bot)
    ..lineTo(o.dx + s * (bd - .05), o.dy + s * bot)
    ..quadraticBezierTo(o.dx + s * bd, o.dy + s * bot, o.dx + s * bd, o.dy + s * (bot - .05))
    ..lineTo(o.dx + s * bd, o.dy + s * shoulder)
    ..cubicTo(o.dx + s * bd, o.dy + s * (shoulder - .08), o.dx + s * nk, o.dy + s * (neckEnd + .08), o.dx + s * nk, o.dy + s * neckEnd)
    ..lineTo(o.dx + s * nk, o.dy + s * top)
    ..close();
  c.drawPath(p, fillP(const Color(0xFFE4F3FB)));
  if (fill > 0) {
    c.save();
    c.clipPath(p);
    final y = o.dy + s * bot - s * (bot - neckEnd) * fill.clamp(0, 1);
    c.drawRect(Rect.fromLTRB(o.dx - s, y, o.dx + s, o.dy + s), fillP(water));
    c.restore();
  }
  c.drawPath(p, strokeP(const Color(0xFF3A6E8A), s * .022));
  // highlight + dotted neck line
  c.drawLine(o + Offset(-s * .16, s * .0), o + Offset(-s * .16, s * .32), strokeP(Colors.white.withOpacity(.8), s * .025));
  final dp = strokeP(const Color(0xFF3A6E8A), s * .008);
  for (var y = top + .03; y < neckEnd; y += .03) {
    c.drawLine(o + Offset(-s * .03, s * y), o + Offset(-s * .03, s * (y + .015)), dp);
  }
  // cap
  final cap = Rect.fromCenter(center: o + Offset(0, s * (top - .02)), width: s * .22, height: s * .045);
  c.drawRect(cap, fillP(const Color(0xFFB7D9EE)));
  c.drawRect(cap, strokeP(const Color(0xFF3A6E8A), s * .018));
  // question mark
  final tp = TextPainter(
      text: TextSpan(text: '?', style: TextStyle(fontSize: s * .3, fontWeight: FontWeight.w900, color: C.coin, shadows: const [
        Shadow(color: Color(0xFF3A3A1A), offset: Offset(1.5, 1.5), blurRadius: 0),
      ])),
      textDirection: TextDirection.ltr)
    ..layout();
  tp.paint(c, o + Offset(-tp.width / 2, s * .1 - tp.height / 2));
}

/// Pen / pencil drawn diagonally, tip at bottom-left of the box (size s).
void drawPen(Canvas c, Offset tip, double s, PenStyle style) {
  c.save();
  c.translate(tip.dx, tip.dy);
  c.rotate(-math.pi / 4 - .25);
  final ol = strokeP(_outline, s * .03);
  final len = s * 1.0, wdt = s * .16;
  Color body;
  Color? stripe;
  switch (style) {
    case PenStyle.pencil:
      body = const Color(0xFFE5402B);
      break;
    case PenStyle.caterpillar:
      body = const Color(0xFF9BD14A);
      break;
    case PenStyle.starPen:
      body = const Color(0xFF1F2A7A);
      stripe = C.coin;
      break;
    case PenStyle.branch:
      body = const Color(0xFFC98A4A);
      break;
    case PenStyle.silver:
      body = const Color(0xFFC9CED2);
      break;
    case PenStyle.fountain:
      body = const Color(0xFF1A1A1A);
      stripe = const Color(0xFFE0A82E);
      break;
    case PenStyle.yellowPencil:
      body = const Color(0xFFFFE21E);
      break;
    case PenStyle.ballpoint:
      body = const Color(0xFF3B8FE0);
      break;
    case PenStyle.candy:
      body = Colors.white;
      stripe = const Color(0xFFE5402B);
      break;
  }
  // tip
  final tipP = Path()
    ..moveTo(0, 0)
    ..lineTo(s * .22, -wdt / 2)
    ..lineTo(s * .22, wdt / 2)
    ..close();
  c.drawPath(tipP, fillP(style == PenStyle.pencil || style == PenStyle.yellowPencil || style == PenStyle.candy ? const Color(0xFFF3D3A0) : const Color(0xFF9AA0A6)));
  c.drawPath(tipP, ol);
  c.drawCircle(Offset(s * .03, 0), s * .03, fillP(const Color(0xFF333333)));
  final bodyR = Rect.fromLTWH(s * .22, -wdt / 2, len * .7, wdt);
  if (style == PenStyle.caterpillar) {
    final cols = [const Color(0xFFE5402B), const Color(0xFFFFB21E), const Color(0xFF9BD14A), const Color(0xFF3B8FE0), const Color(0xFFB04FC9)];
    for (var i = 0; i < 6; i++) {
      final cc = Offset(s * .3 + i * s * .12, 0);
      c.drawCircle(cc, wdt * .62, fillP(cols[i % cols.length]));
      c.drawCircle(cc, wdt * .62, ol);
    }
    final head = Offset(s * .3 + 6 * s * .12, 0);
    c.drawCircle(head, wdt * .75, fillP(C.coin));
    c.drawCircle(head, wdt * .75, ol);
  } else {
    c.drawRect(bodyR, fillP(body));
    if (stripe != null) {
      final sp = strokeP(stripe, wdt * .3);
      for (var x = s * .3; x < s * .9; x += s * .14) {
        if (style == PenStyle.starPen) {
          c.drawPath(starPath(Offset(x, 0), wdt * .3), fillP(stripe));
        } else if (style == PenStyle.candy) {
          c.drawLine(Offset(x, -wdt / 2), Offset(x + s * .06, wdt / 2), sp);
        } else {
          c.drawLine(Offset(x, -wdt / 2), Offset(x, wdt / 2), strokeP(stripe, wdt * .15));
          break;
        }
      }
    }
    if (style == PenStyle.branch) {
      c.drawOval(Rect.fromCenter(center: Offset(s * .75, -wdt * .9), width: s * .16, height: s * .07), fillP(const Color(0xFF3FA34A)));
      c.drawOval(Rect.fromCenter(center: Offset(s * .85, wdt * .9), width: s * .16, height: s * .07), fillP(const Color(0xFF3FA34A)));
    }
    c.drawRect(bodyR, ol);
    final end = Rect.fromLTWH(s * .22 + len * .7, -wdt / 2, s * .08, wdt);
    c.drawRect(end, fillP(style == PenStyle.pencil ? const Color(0xFFF48FB1) : Color.lerp(body, Colors.black, .25)!));
    c.drawRect(end, ol);
  }
  c.restore();
}

void drawInkJar(Canvas c, Offset o, double s, Color ink, {Color? ink2}) {
  final body = RRect.fromRectAndRadius(Rect.fromCenter(center: o + Offset(0, s * .12), width: s * .8, height: s * .6), Radius.circular(s * .1));
  c.drawRRect(body, fillP(Colors.white));
  c.save();
  c.clipRRect(body);
  final r = Rect.fromLTRB(body.left, o.dy + s * .05, body.right, body.bottom);
  c.drawRect(r, Paint()..shader = LinearGradient(colors: [ink, ink2 ?? ink]).createShader(r));
  c.restore();
  c.drawRRect(body, strokeP(_outline, s * .04));
  final neck = Rect.fromCenter(center: o + Offset(0, -s * .25), width: s * .5, height: s * .16);
  c.drawRect(neck, fillP(Colors.white));
  c.drawRect(neck, strokeP(_outline, s * .04));
  for (var i = 1; i < 4; i++) {
    final x = neck.left + neck.width * i / 4;
    c.drawLine(Offset(x, neck.top), Offset(x, neck.bottom), strokeP(_outline, s * .03));
  }
}

/// Blue "COMPLETED!" ribbon banner.
void drawRibbon(Canvas c, Rect r, {String text = 'COMPLETED!', double fontSize = 22}) {
  final ol = strokeP(_outline, 1.6);
  final tailW = r.height * .9;
  for (final s in [-1.0, 1.0]) {
    final x0 = s < 0 ? r.left : r.right;
    final tail = Path()
      ..moveTo(x0 - s * tailW * .2, r.top + r.height * .25)
      ..lineTo(x0 + s * tailW * .8, r.top + r.height * .25)
      ..lineTo(x0 + s * tailW * .45, r.top + r.height * .75)
      ..lineTo(x0 + s * tailW * .8, r.bottom + r.height * .25)
      ..lineTo(x0 - s * tailW * .2, r.bottom + r.height * .25)
      ..close();
    c.drawPath(tail, fillP(const Color(0xFF3F92D2)));
    c.drawPath(tail, ol);
  }
  c.drawRect(r, fillP(C.blue));
  c.drawRect(r, ol);
  for (final s in [-1.0, 1.0]) {
    final x = s < 0 ? r.left + 10 : r.right - 10;
    for (var i = 0; i < 4; i++) {
      final y = r.top + r.height * (.25 + i * .17);
      c.drawLine(Offset(x - 6, y), Offset(x + 6, y), strokeP(const Color(0xFF1F5E8F), 1.2));
    }
  }
  final tp = TextPainter(
      text: TextSpan(text: text, style: txt(fontSize, w: FontWeight.w700, sp: fontSize * .28, c: const Color(0xFF13202A))),
      textDirection: TextDirection.ltr)
    ..layout();
  tp.paint(c, r.center - Offset(tp.width / 2, tp.height / 2));
}

/// Multi-colour prize wheel icon.
void drawWheel(Canvas c, Offset o, double r, {double rot = 0}) {
  const cols = [Color(0xFFE5402B), Color(0xFFFFB21E), Color(0xFF9BD14A), Color(0xFF3B8FE0), Color(0xFFB04FC9), Color(0xFFF2649B), Color(0xFF1FD1C4), Color(0xFFFFE21E)];
  c.drawCircle(o, r, fillP(const Color(0xFF3A3A3A)));
  for (var i = 0; i < 8; i++) {
    c.drawArc(Rect.fromCircle(center: o, radius: r * .8), rot + i * math.pi / 4, math.pi / 4, true, fillP(cols[i]));
  }
  c.drawCircle(o, r * .15, fillP(Colors.white));
  c.drawCircle(o, r, strokeP(_outline, r * .08));
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    c.drawCircle(o + Offset(math.cos(a), math.sin(a)) * r * .9, r * .04, fillP(Colors.white));
  }
  final ptr = Path()
    ..moveTo(o.dx - r * .18, o.dy - r * 1.1)
    ..lineTo(o.dx + r * .18, o.dy - r * 1.1)
    ..lineTo(o.dx, o.dy - r * .7)
    ..close();
  c.drawPath(ptr, fillP(C.coin));
  c.drawPath(ptr, strokeP(_outline, r * .05));
}

void drawNoAds(Canvas c, Offset o, double r) {
  c.drawCircle(o, r, fillP(Colors.white));
  final tp = TextPainter(text: TextSpan(text: 'AD', style: txt(r * .75, w: FontWeight.w900)), textDirection: TextDirection.ltr)..layout();
  tp.paint(c, o - Offset(tp.width / 2, tp.height / 2));
  c.drawCircle(o, r * .9, strokeP(const Color(0xFFE5262B), r * .2));
  c.drawLine(o + Offset(-r * .62, -r * .62), o + Offset(r * .62, r * .62), strokeP(const Color(0xFFE5262B), r * .2));
  c.drawCircle(o, r, strokeP(_outline, r * .06));
}

/// Video clapper icon with a smiling face (ad buttons).
void drawClapper(Canvas c, Rect r) {
  final body = Rect.fromLTRB(r.left, r.top + r.height * .3, r.right, r.bottom);
  c.drawRect(body, fillP(C.coin));
  c.drawRect(body, strokeP(_outline, 1.4));
  final top = Path()
    ..moveTo(r.left, r.top + r.height * .3)
    ..lineTo(r.left - 2, r.top + r.height * .08)
    ..lineTo(r.right - 4, r.top - r.height * .1)
    ..lineTo(r.right, r.top + r.height * .12)
    ..close();
  c.drawPath(top, fillP(Colors.white));
  for (var i = 0; i < 3; i++) {
    final x = r.left + r.width * (.15 + i * .3);
    c.drawLine(Offset(x, r.top + r.height * .25), Offset(x + 5, r.top + r.height * .02), strokeP(_outline, 3));
  }
  c.drawPath(top, strokeP(_outline, 1.4));
  final f = body.center;
  c.drawCircle(f + Offset(-r.width * .15, -2), 3, fillP(Colors.white));
  c.drawCircle(f + Offset(r.width * .15, -2), 3, fillP(Colors.white));
  c.drawCircle(f + Offset(-r.width * .15, -2), 3, strokeP(_outline, 1));
  c.drawCircle(f + Offset(r.width * .15, -2), 3, strokeP(_outline, 1));
  c.drawArc(Rect.fromCenter(center: f + const Offset(0, 3), width: 10, height: 6), .2, math.pi - .4, false, strokeP(_outline, 1.3));
}

/// Light bulb used by the hint button.
void drawBulb(Canvas c, Offset o, double s, {Color fill = const Color(0xFFFFE94A)}) {
  c.drawCircle(o + Offset(0, -s * .1), s * .3, fillP(fill));
  c.drawCircle(o + Offset(0, -s * .1), s * .3, strokeP(_outline, s * .05));
  final base = Rect.fromCenter(center: o + Offset(0, s * .3), width: s * .26, height: s * .16);
  c.drawRect(base, fillP(const Color(0xFFBDBDBD)));
  c.drawRect(base, strokeP(_outline, s * .05));
  c.drawLine(o + Offset(-s * .06, s * .2), o + Offset(-s * .06, -s * .02), strokeP(_outline, s * .04));
  c.drawLine(o + Offset(s * .06, s * .2), o + Offset(s * .06, -s * .02), strokeP(_outline, s * .04));
}

void drawBrain(Canvas c, Offset o, double s, {Color? fill}) {
  final p = strokeP(_outline, s * .06);
  final r = Rect.fromCenter(center: o, width: s * .9, height: s * .78);
  if (fill != null) c.drawOval(r, fillP(fill));
  c.drawOval(r, p);
  c.drawLine(o + Offset(0, -s * .39), o + Offset(0, s * .39), p);
  for (final sx in [-1.0, 1.0]) {
    c.drawArc(Rect.fromCenter(center: o + Offset(sx * s * .2, -s * .14), width: s * .22, height: s * .2), sx > 0 ? math.pi : 0, math.pi, false, p);
    c.drawArc(Rect.fromCenter(center: o + Offset(sx * s * .22, s * .14), width: s * .24, height: s * .2), sx > 0 ? 0 : math.pi, math.pi, false, p);
  }
}

class PaintBox extends StatelessWidget {
  final double w, h;
  final void Function(Canvas c, Size s) paint;
  const PaintBox(this.w, this.h, this.paint, {super.key});
  @override
  Widget build(BuildContext context) => CustomPaint(size: Size(w, h), painter: _FnPainter(paint));
}

class _FnPainter extends CustomPainter {
  final void Function(Canvas c, Size s) fn;
  _FnPainter(this.fn);
  @override
  void paint(Canvas canvas, Size size) => fn(canvas, size);
  @override
  bool shouldRepaint(covariant _FnPainter old) => true;
}
