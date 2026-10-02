// Renders a contact sheet of level layouts to build/levels_sheet.png.
// Run with: LEVELS=12,60,200 flutter test tool/render_levels.dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:water_glass/game/levels.dart';
import 'package:water_glass/game/render.dart';
import 'package:water_glass/widgets/painters.dart';

void main() {
  test('render level sheet', () async {
    final levels = (Platform.environment['LEVELS'] ?? '12,40,90,140,200,300,420,500,620,760,880,1000').split(',').map(int.parse).toList();
    const cw = 288.0, ch = 400.0, cols = 6;
    final rows = (levels.length / cols).ceil();
    final rec = ui.PictureRecorder();
    final c = Canvas(rec);
    c.drawRect(const Rect.fromLTWH(0, 0, cw * cols, ch * 6), fillP(Colors.white));
    for (var i = 0; i < levels.length; i++) {
      final n = levels[i];
      final def = classicLevel(n);
      c.save();
      c.translate((i % cols) * cw, (i ~/ cols) * ch);
      c.clipRect(const Rect.fromLTWH(0, 0, cw, ch));
      c.drawRect(const Rect.fromLTWH(0, 0, cw, ch), strokeP(Colors.black, 2));
      c.scale(.5);
      c.translate(0, -360);
      paintLevelStatic(c, def);
      final hp = strokeP(const Color(0xFF2BB673), 3);
      for (final s in def.hint) {
        for (var k = 0; k < s.length - 1; k++) {
          c.drawLine(s[k], s[k + 1], hp);
        }
      }
      c.restore();
      final tp = TextPainter(
          text: TextSpan(text: '$n ${kTierNames[tierOf(n)]} d=${difficultyOf(n).toStringAsFixed(2)} ink=${def.ink.round()}', style: const TextStyle(fontSize: 14, color: Colors.red)),
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, Offset((i % cols) * cw + 4, (i ~/ cols) * ch + 4));
    }
    final img = await rec.endRecording().toImage((cw * cols).toInt(), (ch * rows).toInt());
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('build/levels_sheet.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}
