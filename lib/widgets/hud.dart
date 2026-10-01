import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme.dart';
import 'common.dart';
import 'painters.dart';

/// Grey rounded toolbar at the top of the gameplay screen.
class TopPanel extends StatelessWidget {
  final List<Widget> children;
  const TopPanel({super.key, required this.children});
  @override
  Widget build(BuildContext context) => Container(
        width: 516,
        height: 88,
        decoration: BoxDecoration(
          color: C.panel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF8E8E8E), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3), blurRadius: 2)],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: children),
      );
}

/// Circular-arrow badge showing the level number.
class LevelBadge extends StatelessWidget {
  final int level;
  final VoidCallback? onTap;
  const LevelBadge(this.level, {super.key, this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: PaintBox(84, 72, (c, s) {
          final o = Offset(s.width / 2, s.height / 2);
          final p = strokeP(const Color(0xFF222222), 2.6);
          c.drawArc(Rect.fromCircle(center: o, radius: 31), math.pi * .62, math.pi * 1.76, false, p);
          final end = o + Offset(math.cos(math.pi * .38), math.sin(math.pi * .38)) * 31;
          c.drawLine(end, end + const Offset(9, -1), p);
          c.drawLine(end, end + const Offset(2, -9), p);
          final tp = TextPainter(text: TextSpan(text: '$level', style: txt(level > 99 ? 20 : 24, w: FontWeight.w700)), textDirection: TextDirection.ltr)..layout();
          tp.paint(c, o + Offset(-tp.width / 2, -tp.height / 2 - 7));
          final tl = TextPainter(text: TextSpan(text: 'Level', style: txt(15, w: FontWeight.w500)), textDirection: TextDirection.ltr)..layout();
          tl.paint(c, o + Offset(-tl.width / 2, 7));
        }),
      );
}

class PanelIcon extends StatelessWidget {
  final void Function(Canvas c, Size s) paint;
  final VoidCallback? onTap;
  final bool dim;
  const PanelIcon(this.paint, {super.key, this.onTap, this.dim = false});
  @override
  Widget build(BuildContext context) =>
      Tap(onTap: onTap, child: Opacity(opacity: dim ? .35 : 1, child: PaintBox(62, 62, paint)));
}

void iconPencil(Canvas c, Size s) {
  final p = strokeP(const Color(0xFF222222), 2.4);
  c.save();
  c.translate(s.width / 2, s.height / 2);
  c.rotate(math.pi / 4);
  final body = Rect.fromCenter(center: const Offset(0, -2), width: 12, height: 34);
  c.drawRect(body, fillP(Colors.white));
  c.drawRect(body, p);
  final tip = Path()
    ..moveTo(-6, 15)
    ..lineTo(0, 26)
    ..lineTo(6, 15);
  c.drawPath(tip, p);
  c.drawLine(const Offset(-6, -12), const Offset(6, -12), p);
  c.restore();
}

void iconCart(Canvas c, Size s) {
  final p = strokeP(const Color(0xFF222222), 2.4);
  final path = Path()
    ..moveTo(8, 16)
    ..lineTo(16, 16)
    ..lineTo(22, 40)
    ..lineTo(50, 40)
    ..lineTo(55, 22)
    ..lineTo(18, 22);
  c.drawPath(path, p);
  for (var x = 26.0; x < 52; x += 7) {
    c.drawLine(Offset(x, 22), Offset(x - 1, 40), strokeP(const Color(0xFF222222), 1.4));
  }
  c.drawLine(const Offset(20, 31), const Offset(53, 31), strokeP(const Color(0xFF222222), 1.4));
  c.drawCircle(const Offset(25, 47), 3.5, p);
  c.drawCircle(const Offset(46, 47), 3.5, p);
}

void iconHome(Canvas c, Size s) {
  final p = strokeP(const Color(0xFF222222), 2.4);
  final path = Path()
    ..moveTo(9, 30)
    ..lineTo(31, 10)
    ..lineTo(53, 30)
    ..moveTo(15, 25)
    ..lineTo(15, 52)
    ..lineTo(47, 52)
    ..lineTo(47, 25)
    ..moveTo(26, 52)
    ..lineTo(26, 38)
    ..lineTo(36, 38)
    ..lineTo(36, 52);
  c.drawPath(path, p);
}

void iconBrain(Canvas c, Size s) => drawBrain(c, Offset(s.width / 2, s.height / 2), 46);

void iconX(Canvas c, Size s) {
  final p = strokeP(const Color(0xFF222222), 2.2);
  final o = Offset(s.width / 2, s.height / 2);
  for (final a in [math.pi / 4, -math.pi / 4]) {
    final d = Offset(math.cos(a), math.sin(a));
    final n = Offset(-d.dy, d.dx) * 4;
    c.drawLine(o - d * 18 + n, o + d * 18 + n, p);
    c.drawLine(o - d * 18 - n, o + d * 18 - n, p);
  }
}

/// Green bulb button (free hints) or grey bulb with ad icon.
class HintButton extends StatelessWidget {
  final int hints;
  final VoidCallback onTap;
  const HintButton({super.key, required this.hints, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: PaintBox(66, 66, (c, s) {
          final r = RRect.fromRectAndRadius(const Rect.fromLTWH(6, 8, 52, 52), const Radius.circular(6));
          final has = hints > 0;
          c.drawRRect(r, fillP(has ? C.green : const Color(0xFFDDE3E6)));
          c.drawRRect(r, strokeP(const Color(0xFF333333), 2));
          drawBulb(c, const Offset(32, 36), 36, fill: has ? const Color(0xFFFFE94A) : const Color(0xFFF2EDC2));
          if (has) {
            c.drawCircle(const Offset(54, 12), 11, fillP(const Color(0xFFE5402B)));
            c.drawCircle(const Offset(54, 12), 11, strokeP(Colors.white, 1.6));
            final tp = TextPainter(text: TextSpan(text: '$hints', style: txt(14, w: FontWeight.w800, c: Colors.white)), textDirection: TextDirection.ltr)..layout();
            tp.paint(c, Offset(54 - tp.width / 2, 12 - tp.height / 2));
          } else {
            final b = RRect.fromRectAndRadius(const Rect.fromLTWH(44, 2, 20, 16), const Radius.circular(2));
            c.drawRRect(b, fillP(const Color(0xFFFFF59D)));
            c.drawRRect(b, strokeP(const Color(0xFF555555), 1.2));
            final tri = Path()
              ..moveTo(50, 6)
              ..lineTo(50, 14)
              ..lineTo(58, 10)
              ..close();
            c.drawPath(tri, strokeP(const Color(0xFF555555), 1.2));
          }
        }),
      );
}

/// Ink meter: green remaining, grey used; ticks at 1/3 and 2/3; stars below.
class InkBar extends StatelessWidget {
  final double frac;
  const InkBar(this.frac, {super.key});
  static int starsFor(double f) => f > 2 / 3 ? 3 : (f > 1 / 3 ? 2 : 1);
  @override
  Widget build(BuildContext context) => PaintBox(300, 62, (c, s) {
        const r = Rect.fromLTWH(6, 4, 288, 20);
        c.drawRect(r, fillP(C.barEmpty));
        c.drawRect(Rect.fromLTWH(r.left, r.top, r.width * frac.clamp(0, 1), r.height), fillP(const Color(0xFFADDC45)));
        c.drawLine(Offset(r.left + r.width / 3, r.top), Offset(r.left + r.width / 3, r.bottom), strokeP(const Color(0xFFE5402B), 1.4));
        c.drawLine(Offset(r.left + r.width * 2 / 3, r.top), Offset(r.left + r.width * 2 / 3, r.bottom), strokeP(const Color(0xFF555555), 1.4));
        c.drawRect(r, strokeP(const Color(0xFF333333), 1.6));
        final n = starsFor(frac);
        final x0 = 150 - (n - 1) * 13.0;
        for (var i = 0; i < n; i++) {
          drawStar(c, Offset(x0 + i * 26, 44), 11);
        }
      });
}

class Hearts extends StatelessWidget {
  final int left, total;
  const Hearts(this.left, this.total, {super.key});
  @override
  Widget build(BuildContext context) => PaintBox(total * 50.0, 44, (c, s) {
        for (var i = 0; i < total; i++) {
          drawHeart(c, Offset(25 + i * 50.0, 24), 34, C.heart, empty: i >= left);
        }
      });
}

/// Grey square with the 3-2-1 countdown digit.
class CountdownBox extends StatelessWidget {
  final int n;
  const CountdownBox(this.n, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: 160,
        height: 160,
        decoration: BoxDecoration(color: const Color(0xEE5E5E5E), borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.center,
        child: Text('$n', style: txt(112, w: FontWeight.w500, c: Colors.white)),
      );
}

/// Pen cursor that follows the finger while drawing.
class PenCursor extends StatelessWidget {
  final Offset at;
  final int pen;
  const PenCursor(this.at, this.pen, {super.key});
  @override
  Widget build(BuildContext context) => const SizedBox();
}

double clamp01(double v) => v < 0 ? 0 : (v > 1 ? 1 : v);

/// Common pieces reused by screens: Coin+back header.
class BackCoinsBar extends StatelessWidget {
  final VoidCallback onBack;
  final Widget? extra;
  const BackCoinsBar({super.key, required this.onBack, this.extra});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: kW,
        height: 110,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 30, 16, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BackArrow(onTap: onBack),
            const Spacer(),
            if (extra != null) ...[extra!, const SizedBox(width: 10)],
            const Padding(padding: EdgeInsets.only(top: 6), child: CoinCounter()),
          ]),
        ),
      );
}
