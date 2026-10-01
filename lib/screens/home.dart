import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../game/levels.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';
import 'dialogs.dart';
import 'dont_spill.dart';
import 'level_packs.dart';
import 'play.dart';
import 'settings.dart';
import 'shop.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) => mounted ? setState(() {}) : null);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final d = GameData.I;
      if (d.levelsSinceOffer >= 6 && mounted) {
        d.levelsSinceOffer = 0;
        d.save();
        await showLimitedOffer(context);
      }
    });
  }

  @override
  void dispose() {
    _a.dispose();
    _clock?.cancel();
    super.dispose();
  }

  void _open(Widget w) async {
    await Navigator.of(context).push(fadeRoute(w));
    if (mounted) setState(() {});
  }

  void _wheel() async {
    final d = GameData.I;
    if (!d.dailyReady) {
      await showMessage(context, 'Whoops!', 'Your daily reward is not ready\nyet.\nPlease come back later.');
      return;
    }
    final won = await showDailyWheel(context);
    if (won != null) {
      d.coins += won;
      d.lastSpin = DateTime.now().millisecondsSinceEpoch;
      d.save();
    }
  }

  String _fmt(Duration x) => '${x.inHours.toString().padLeft(2, '0')}:${(x.inMinutes % 60).toString().padLeft(2, '0')}:${(x.inSeconds % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    final water = waterColors[d.water];
    return DesignScreen(
      child: Stack(children: [
        Positioned(left: 10, top: 56, child: Tap(onTap: () => _open(const SettingsScreen()), child: const Icon(Icons.settings_outlined, size: 72, color: Color(0xFF222222)))),
        Positioned(left: 12, top: 144, child: Tap(onTap: () => _open(const LevelPacksScreen()), child: const PaintBox(68, 68, _gridIcon))),
        const Positioned(right: 12, top: 64, child: CoinCounter(size: 50)),
        // title + faucet through the A + pouring glass
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _a,
              builder: (_, __) => PaintBox(kW, kH, (c, s) => _paintTitle(c, _a.value, water)),
            ),
          ),
        ),
        Positioned(left: 474, top: 318, child: Tap(onTap: () => showMessage(context, 'No Ads', 'Ads are already disabled\nin this version.'), child: PaintBox(76, 76, (c, s) => drawNoAds(c, const Offset(38, 38), 35)))),
        Positioned(left: 474, top: 408, child: Tap(onTap: _wheel, child: PaintBox(76, 80, (c, s) => drawWheel(c, const Offset(38, 44), 34)))),
        Positioned(
            left: 446,
            top: 482,
            child: SizedBox(width: 130, child: Text(_fmt(d.dailyLeft), textAlign: TextAlign.center, style: txt(23, w: FontWeight.w600, sp: 1)))),
        Positioned(left: 16, top: 598, child: _classicBar()),
        Positioned(
          left: 18,
          top: 708,
          child: _ModeRow(
            title: "DON'T SPILL",
            sub: 'Complete level 10 in\nClassic mode to unlock',
            unlocked: d.dontSpillUnlocked,
            count: '${math.min(d.dsLevel - 1, kDsCount)}/$kDsCount',
            icon: _iconDontSpill,
            onTap: () => d.dontSpillUnlocked
                ? _open(DontSpillScreen(level: math.min(d.dsLevel, kDsCount)))
                : showMessage(context, "DON'T SPILL", 'Complete level 10 in\nClassic mode to unlock'),
          ),
        ),
        Positioned(
          left: 442,
          top: 708,
          child: Tap(
            onTap: () => _open(const ShopScreen(tab: 0)),
            child: Container(
              width: 116,
              height: 100,
              decoration: BoxDecoration(color: C.yellow, borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF222222), width: 2)),
              child: PaintBox(116, 100, (c, s) => drawPen(c, const Offset(36, 76), 76, PenStyle.pencil)),
            ),
          ),
        ),
        Positioned(
          left: 18,
          top: 820,
          child: _ModeRow(
            title: 'FLIPPY GLASS',
            sub: 'Complete level 20 in\nClassic mode to unlock',
            unlocked: d.flippyUnlocked,
            count: '0/0',
            icon: _iconFlippy,
            onTap: () => d.flippyUnlocked ? showComingSoon(context) : showMessage(context, 'FLIPPY GLASS', 'Complete level 20 in\nClassic mode to unlock'),
          ),
        ),
        Positioned(
          left: 18,
          top: 930,
          child: _ModeRow(
            title: 'PRECISE',
            sub: 'Complete 18 Challenge\nLevels',
            unlocked: d.preciseUnlocked,
            count: '0/0',
            icon: _iconPrecise,
            onTap: () => d.preciseUnlocked ? showComingSoon(context) : showMessage(context, 'PRECISE', 'Complete 18 Challenge\nLevels'),
          ),
        ),
      ]),
    );
  }

  Widget _classicBar() {
    final d = GameData.I;
    return Tap(
      onTap: () => _open(PlayScreen(index: math.min(d.level, kClassicCount))),
      child: Container(
        width: 544,
        height: 98,
        decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF222222), width: 2.2)),
        child: Row(children: [
          const SizedBox(width: 60),
          PaintBox(80, 90, (c, s) {
            c.save();
            c.translate(40, 46);
            c.scale(.95);
            drawGlass(c, glassSkins[d.glass], fill: .9, water: waterColors[d.water], expr: Expr.surprised);
            c.restore();
          }),
          Expanded(child: Center(child: Text(tr('CLASSIC'), style: txt(28, w: FontWeight.w700, sp: 5)))),
          Container(
            width: 134,
            decoration: const BoxDecoration(
              color: C.greenDark,
              border: Border(left: BorderSide(color: Color(0xFF222222), width: 2.2)),
              borderRadius: BorderRadius.horizontal(right: Radius.circular(8)),
            ),
            alignment: Alignment.center,
            child: Text('${math.min(d.completed, kClassicCount)}/$kClassicCount', style: txt(26, w: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }
}

void _gridIcon(Canvas c, Size s) {
  final p = strokeP(const Color(0xFF222222), 2.6);
  for (final o in const [Offset(8, 8), Offset(36, 8), Offset(8, 36), Offset(36, 36)]) {
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(o.dx, o.dy, 24, 24), const Radius.circular(5)), p);
  }
}

void _paintTitle(Canvas c, double t, Color water) {
  final d = GameData.I;
  TextPainter tp(String s, Color col) =>
      TextPainter(text: TextSpan(text: s, style: TextStyle(fontSize: 92, fontWeight: FontWeight.w900, color: col, letterSpacing: 1, height: 1)), textDirection: TextDirection.ltr)..layout();
  final w = tp('WATER', const Color(0xFF151515));
  w.paint(c, Offset(288 - w.width / 2, 132));
  final g = tp('GLASS', C.blue);
  g.paint(c, Offset(288 - g.width / 2, 214));
  // faucet pipe dropping through the middle "A"
  const fx = 288.0;
  c.drawRect(const Rect.fromLTWH(fx - 15, 196, 30, 108), fillP(C.faucet));
  c.drawRect(const Rect.fromLTWH(fx - 15, 196, 30, 108), strokeP(const Color(0xFF555555), 1.4));
  c.drawRect(const Rect.fromLTWH(fx - 19, 304, 38, 12), fillP(const Color(0xFFB7BEC2)));
  c.drawRect(const Rect.fromLTWH(fx - 19, 304, 38, 12), strokeP(const Color(0xFF555555), 1.4));
  // pour stream for the first 40% of the cycle
  final pour = t < .4;
  if (pour) {
    final p = Path();
    for (var y = 318.0; y <= 470; y += 6) {
      final x = fx + math.sin(y / 14 + t * 60) * 2.5;
      y == 318 ? p.moveTo(x - 6, y) : p.lineTo(x - 6, y);
    }
    for (var y = 470.0; y >= 318; y -= 6) {
      p.lineTo(fx + math.sin(y / 14 + t * 60) * 2.5 + 6, y);
    }
    p.close();
    c.drawPath(p, fillP(water));
  }
  final bounce = pour ? 0.0 : math.sin(t * math.pi * 6) * 2;
  c.save();
  c.translate(fx, 487 + bounce);
  drawGlass(c, glassSkins[d.glass], fill: pour ? .55 + t : .95, water: water, expr: pour ? Expr.surprised : Expr.happy, t: t * 6, dotted: false);
  c.restore();
  if (!pour && t < .55) {
    final k = (t - .4) / .15;
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i - 2.5) * .45;
      drawStar(c, const Offset(fx, 440) + Offset(math.cos(a), math.sin(a)) * (30 + 40 * k), 4 * (1 - k) + .1, ol: .5);
    }
  }
}

void _iconDontSpill(Canvas c, Size s) {
  for (final r in const [Rect.fromLTWH(14, 52, 44, 10), Rect.fromLTWH(18, 40, 12, 12), Rect.fromLTWH(42, 40, 12, 12), Rect.fromLTWH(14, 30, 44, 10)]) {
    c.drawRect(r, fillP(C.brick));
    c.drawRect(r, strokeP(const Color(0xFF7A3A00), 1));
  }
  c.drawCircle(const Offset(36, 46), 5, fillP(C.brick));
  c.save();
  c.translate(36, 17);
  c.scale(.32);
  drawGlass(c, glassSkins[0], fill: .8, water: waterColors[GameData.I.water], expr: Expr.happy, dotted: false);
  c.restore();
}

void _iconFlippy(Canvas c, Size s) {
  c.drawRect(const Rect.fromLTWH(6, 52, 60, 6), fillP(C.teal));
  final p = Path()
    ..moveTo(12, 50)
    ..lineTo(40, 28)
    ..lineTo(46, 34);
  c.drawPath(p, strokeP(const Color(0xFF555555), 3));
  c.save();
  c.translate(40, 24);
  c.rotate(-.7);
  c.scale(.3);
  drawGlass(c, glassSkins[0], fill: .6, expr: Expr.surprised, dotted: false);
  c.restore();
}

void _iconPrecise(Canvas c, Size s) {
  c.drawRect(const Rect.fromLTWH(30, 2, 8, 14), fillP(C.faucet));
  final p = strokeP(const Color(0xFF555555), 2);
  final cup = Path()
    ..moveTo(16, 22)
    ..quadraticBezierTo(34, 62, 52, 22);
  c.drawPath(cup, fillP(const Color(0xFFDDDDDD)));
  c.drawPath(cup, p);
  c.drawLine(const Offset(34, 42), const Offset(34, 58), p);
  c.drawLine(const Offset(24, 58), const Offset(44, 58), p);
  c.drawCircle(const Offset(29, 30), 2, fillP(const Color(0xFF222222)));
  c.drawCircle(const Offset(39, 30), 2, fillP(const Color(0xFF222222)));
}

/// Grey (locked) or yellow (unlocked) minigame row on the home screen.
class _ModeRow extends StatelessWidget {
  final String title, sub, count;
  final bool unlocked;
  final void Function(Canvas c, Size s) icon;
  final VoidCallback onTap;
  const _ModeRow({required this.title, required this.sub, required this.unlocked, required this.count, required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: SizedBox(
        width: 414,
        height: 102,
        child: Stack(clipBehavior: Clip.none, children: [
          Container(
            width: 398,
            height: 100,
            decoration: BoxDecoration(
              color: unlocked ? C.yellow : C.locked,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF222222), width: 2),
            ),
            child: Row(children: [
              const SizedBox(width: 6),
              Opacity(opacity: unlocked ? 1 : .55, child: PaintBox(70, 70, icon)),
              Expanded(
                child: unlocked
                    ? Center(child: Text(title, style: txt(21, w: FontWeight.w800, sp: 3)))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(title, style: txt(21, w: FontWeight.w800, sp: 3)),
                        Text(sub, textAlign: TextAlign.center, style: txt(18, w: FontWeight.w500, h: 1.15)),
                      ]),
              ),
              Container(
                width: 86,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: unlocked ? C.orange : C.lockedDark,
                  border: const Border(left: BorderSide(color: Color(0xFF222222), width: 2)),
                  borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                ),
                child: Text(unlocked ? count : '?/?', style: txt(22, w: FontWeight.w800)),
              ),
            ]),
          ),
          if (!unlocked) Positioned(right: -4, top: -8, child: PaintBox(44, 48, (c, s) => drawLock(c, const Offset(22, 24), 42))),
        ]),
      ),
    );
  }
}
