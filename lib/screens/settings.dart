import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';
import 'dialogs.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Widget _btn(String t, double w, VoidCallback onTap) => Pill(t, w: w, h: 80, fs: GameData.I.lang == 'ja' ? 19 : 20, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    return DesignScreen(
      child: Stack(children: [
        Positioned(left: 10, top: 56, child: BackArrow(onTap: () => Navigator.of(context).pop())),
        Positioned(
          left: 0,
          right: 0,
          top: 418,
          child: Column(children: [
            Text(tr('SETTINGS'), style: txt(34, w: FontWeight.w500, sp: 9)),
            const SizedBox(height: 46),
            _btn(tr('ENGLISH'), 364, () {
              d.lang = d.lang == 'en' ? 'ja' : 'en';
              d.save();
              setState(() {});
            }),
            const SizedBox(height: 18),
            _btn(tr('PRIVACY'), 364, () {
              showMessage(context, tr('PRIVACY'), 'Water Glass stores your progress\nonly on this device.\nNo personal data is collected.');
            }),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _btn(tr(d.music ? 'MUSIC: ON' : 'MUSIC: OFF'), 188, () {
                d.music = !d.music;
                d.save();
                Sfx.syncMusic();
                setState(() {});
              }),
              const SizedBox(width: 16),
              _btn(tr(d.sfx ? 'SFX: ON' : 'SFX: OFF'), 188, () {
                d.sfx = !d.sfx;
                d.save();
                setState(() {});
              }),
            ]),
            const SizedBox(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _social(tr('LIKE US'), _thumb, () => showMessage(context, tr('LIKE US'), 'Thank you for playing!')),
              const SizedBox(width: 40),
              _social(tr('FOLLOW US'), _camera, () => showMessage(context, tr('FOLLOW US'), 'Thank you for playing!')),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _social(String label, void Function(Canvas, Size) icon, VoidCallback onTap) => Tap(
        onTap: onTap,
        child: SizedBox(
          width: 130,
          child: Column(children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(color: C.green, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF222222), width: 2)),
              child: PaintBox(76, 76, icon),
            ),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center, style: txt(GameData.I.lang == 'ja' ? 13 : 17, w: FontWeight.w600, sp: 2)),
          ]),
        ),
      );
}

void _thumb(Canvas c, Size s) {
  final p = Path()
    ..moveTo(26, 36)
    ..lineTo(34, 36)
    ..lineTo(42, 20)
    ..quadraticBezierTo(48, 18, 47, 28)
    ..lineTo(45, 34)
    ..lineTo(55, 34)
    ..quadraticBezierTo(60, 36, 57, 42)
    ..lineTo(53, 54)
    ..quadraticBezierTo(51, 57, 46, 57)
    ..lineTo(34, 57)
    ..lineTo(26, 57)
    ..close();
  c.drawPath(p, fillP(const Color(0xFF6FA8E8)));
  c.drawPath(p, strokeP(const Color(0xFF222222), 2));
  c.drawRect(const Rect.fromLTWH(18, 36, 8, 22), fillP(Colors.white));
  c.drawRect(const Rect.fromLTWH(18, 36, 8, 22), strokeP(const Color(0xFF222222), 2));
}

void _camera(Canvas c, Size s) {
  final r = RRect.fromRectAndRadius(const Rect.fromLTWH(20, 20, 36, 36), const Radius.circular(10));
  c.drawRRect(r, fillP(Colors.white));
  c.drawRRect(r, strokeP(const Color(0xFF222222), 2.4));
  c.drawCircle(const Offset(38, 38), 9, strokeP(const Color(0xFF222222), 2.4));
  c.drawCircle(const Offset(49, 28), 2, fillP(const Color(0xFF222222)));
}
