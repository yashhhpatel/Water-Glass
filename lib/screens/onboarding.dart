import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/data.dart';
import '../core/links.dart';
import '../core/theme.dart';
import '../game/levels.dart';
import '../game/render.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'home.dart';

/// First-launch walkthrough shown once before the main menu.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _Page {
  final String title, body;
  final void Function(Canvas c, double t) art;
  const _Page(this.title, this.body, this.art);
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final _pager = PageController();
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  int _page = 0;

  late final List<_Page> _pages = [
    const _Page('DRAW LINES', 'Draw with your finger to guide\nthe water into the glass.', _artDraw),
    const _Page('FILL THE GLASS', 'Fill it up to the dotted line to win.\nYour lines fall with gravity,\nso plan their shape!', _artFill),
    const _Page('SAVE INK, GET STARS', 'Use less ink to earn 3 stars.\nStars unlock new level packs.', _artInk),
    const _Page('HINTS & REWARDS', 'Stuck? Tap the bulb for a hint.\nEarn coins to unlock pens,\nglasses and water colours.', _artRewards),
    const _Page('1,000 LEVELS', 'From Easy to Very Hard, plus bosses,\nchallenges and the Don\'t Spill game.', _artLevels),
  ];

  @override
  void dispose() {
    _a.dispose();
    _pager.dispose();
    super.dispose();
  }

  void _finish() {
    GameData.I.onboarded = true;
    GameData.I.save();
    Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  void _next() {
    if (_page == _pages.length - 1) {
      _finish();
    } else {
      _pager.nextPage(duration: const Duration(milliseconds: 320), curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return DesignScreen(
      child: Stack(children: [
        PageView.builder(
          controller: _pager,
          itemCount: _pages.length,
          onPageChanged: (i) => setState(() => _page = i),
          itemBuilder: (_, i) {
            final p = _pages[i];
            return Column(children: [
              const SizedBox(height: 150),
              SizedBox(
                width: kW,
                height: 560,
                child: AnimatedBuilder(animation: _a, builder: (_, __) => PaintBox(kW, 560, (c, s) => p.art(c, _a.value))),
              ),
              const SizedBox(height: 30),
              Text(p.title, textAlign: TextAlign.center, style: txt(38, w: FontWeight.w800, sp: 4)),
              const SizedBox(height: 18),
              Text(p.body, textAlign: TextAlign.center, style: txt(25, w: FontWeight.w500, h: 1.45, c: const Color(0xFF333333))),
            ]);
          },
        ),
        if (!last)
          Positioned(
            right: 24,
            top: 56,
            child: Tap(onTap: _finish, child: Padding(padding: const EdgeInsets.all(10), child: Text('SKIP', style: txt(26, w: FontWeight.w700, sp: 3, c: const Color(0xFF666666))))),
          ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 210,
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < _pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: i == _page ? 34 : 14,
                height: 14,
                decoration: BoxDecoration(
                  color: i == _page ? C.green : const Color(0xFFD6D6D6),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: const Color(0xFF222222), width: 1.6),
                ),
              ),
          ]),
        ),
        Positioned(left: 118, bottom: 80, child: Pill(last ? "LET'S PLAY!" : 'NEXT', w: 340, h: 96, onTap: _next)),
        if (last)
          Positioned(
            left: 0,
            right: 0,
            bottom: 18,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('By playing you agree to our', style: txt(17, w: FontWeight.w500, c: const Color(0xFF555555))),
              const PrivacyLink(size: 17),
            ]),
          ),
      ]),
    );
  }
}

// ------------------------------------------------------------------ artwork
const _skin = GlassSkin(Color(0xFF8A8A8A), Eyes.round, Mouth.smile, Extra.none, 0);

void _glass(Canvas c, Offset o, double scale, {double fill = 0, Expr expr = Expr.sad, double t = 0}) {
  c.save();
  c.translate(o.dx, o.dy);
  c.scale(scale);
  drawGlass(c, _skin, fill: fill, water: C.water, expr: expr, t: t);
  c.restore();
}

/// Pencil draws a ramp, water runs down it into the glass.
void _artDraw(Canvas c, double t) {
  const faucet = Offset(330, 120);
  drawFaucet(c, faucet);
  c.drawRect(const Rect.fromLTWH(140, 452, 150, 14), fillP(C.teal));
  const a = Offset(372, 210), b = Offset(250, 300);
  final drawT = (t / .3).clamp(0.0, 1.0);
  final tip = Offset.lerp(a, b, drawT)!;
  c.drawLine(a, tip, strokeP(const Color(0xFF111111), 6));
  if (t < .32) drawPen(c, tip, 110, PenStyle.pencil);
  final pour = ((t - .32) / .45).clamp(0.0, 1.0);
  if (pour > 0 && pour < 1) {
    final pts = <Offset>[];
    for (var i = 0; i < 26; i++) {
      final k = (pour * 1.6 - i * .045);
      if (k < 0 || k > 1.25) continue;
      if (k < .25) {
        pts.add(Offset(faucet.dx + math.sin(i * 1.7) * 2, faucet.dy + 16 + k / .25 * 70));
      } else if (k < .85) {
        pts.add(Offset.lerp(Offset(faucet.dx, 206), b, (k - .25) / .6)! + const Offset(0, -10));
      } else {
        pts.add(Offset.lerp(b, const Offset(215, 410), (k - .85) / .4)!);
      }
    }
    paintWater(c, pts, C.water, scale: 1.6);
  }
  final fill = ((t - .45) / .35).clamp(0.0, 1.0);
  _glass(c, const Offset(215, 380), 1.9, fill: fill * .8, expr: fill >= 1 ? Expr.happy : (fill > 0 ? Expr.surprised : Expr.sad), t: t * 4);
}

/// Glass fills to the dotted line and cheers.
void _artFill(Canvas c, double t) {
  final fill = (t / .6).clamp(0.0, 1.0);
  drawFaucet(c, const Offset(288, 110));
  if (t < .6) {
    c.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTRB(279, 124, 297, 330), const Radius.circular(9)), fillP(C.water));
  }
  _glass(c, const Offset(288, 380), 2.6, fill: fill * .86, expr: fill >= 1 ? Expr.happy : Expr.surprised, t: t * 4);
  if (fill >= 1) {
    for (var i = 0; i < 3; i++) {
      final k = ((t - .6) / .3).clamp(0.0, 1.0);
      drawStar(c, Offset(200.0 + i * 88, 150 - (i == 1 ? 24 : 0)), 30 * Curves.elasticOut.transform(k));
    }
  }
}

/// Ink bar empties while stars drop from 3 to 1.
void _artInk(Canvas c, double t) {
  final frac = 1 - .8 * (t / .85).clamp(0.0, 1.0);
  c.save();
  c.translate(138, 150);
  c.scale(1.0);
  const r = Rect.fromLTWH(0, 0, 300, 34);
  c.drawRect(r, fillP(C.barEmpty));
  c.drawRect(Rect.fromLTWH(0, 0, 300 * frac, 34), fillP(const Color(0xFFADDC45)));
  c.drawLine(const Offset(100, 0), const Offset(100, 34), strokeP(const Color(0xFFE5402B), 2));
  c.drawLine(const Offset(200, 0), const Offset(200, 34), strokeP(const Color(0xFF555555), 2));
  c.drawRect(r, strokeP(const Color(0xFF333333), 2.4));
  c.restore();
  final n = InkBar.starsFor(frac);
  for (var i = 0; i < 3; i++) {
    drawStar(c, Offset(198.0 + i * 90, 280), 36, filled: i < n);
  }
  // scribbled line being drawn
  final p = Path()..moveTo(150, 430);
  for (var x = 150.0; x <= 150 + 280 * (1 - frac) / .8; x += 6) {
    p.lineTo(x, 430 + math.sin(x / 22) * 30);
  }
  c.drawPath(p, strokeP(const Color(0xFF111111), 6));
  final tipX = 150 + 280 * (1 - frac) / .8;
  drawPen(c, Offset(tipX, 430 + math.sin(tipX / 22) * 30), 100, PenStyle.pencil);
}

/// Hint bulb, coins and unlockables.
void _artRewards(Canvas c, double t) {
  final bob = math.sin(t * math.pi * 2) * 8;
  c.save();
  c.translate(288, 140 + bob);
  final rr = RRect.fromRectAndRadius(const Rect.fromLTWH(-60, -60, 120, 120), const Radius.circular(14));
  c.drawRRect(rr, fillP(C.green));
  c.drawRRect(rr, strokeP(const Color(0xFF333333), 3));
  c.restore();
  drawBulb(c, Offset(288, 146 + bob), 84);
  for (var i = 0; i < 5; i++) {
    final a = t * math.pi * 2 + i * math.pi * 2 / 5;
    drawCoin(c, Offset(288 + math.cos(a) * 170, 150 + math.sin(a) * 60), 22);
  }
  drawPen(c, const Offset(90, 470), 110, PenStyle.caterpillar);
  _glass(c, const Offset(288, 400), 1.5, fill: .75, expr: Expr.happy, t: t * 4);
  c.save();
  c.translate(470, 400);
  c.scale(1.5);
  drawGlass(c, glassSkins[7], fill: .75, water: waterColors[1], expr: Expr.happy, t: t * 4);
  c.restore();
}

/// Four tier badges stepping up like stairs.
void _artLevels(Canvas c, double t) {
  const colors = [Color(0xFF7CC242), Color(0xFF3B8FE0), Color(0xFFF7931E), Color(0xFFE5402B)];
  for (var i = 0; i < 4; i++) {
    final k = Curves.easeOutBack.transform(((t * 1.4 - i * .15)).clamp(0.0, 1.0));
    final h = 90.0 + i * 70;
    final r = Rect.fromLTWH(48.0 + i * 122, 470 - h * k, 110, h * k);
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), fillP(colors[i]));
    c.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), strokeP(const Color(0xFF222222), 2.4));
    if (k > .6) {
      final tp = TextPainter(
          text: TextSpan(text: kTierNames[i].replaceAll(' ', '\n'), style: txt(17, w: FontWeight.w800, c: Colors.white, sp: 1)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr)
        ..layout(maxWidth: 104);
      tp.paint(c, Offset(r.center.dx - tp.width / 2, r.top + 12));
    }
  }
  _glass(c, Offset(48.0 + 3 * 122 + 55, 470 - 300 - 46 + math.sin(t * math.pi * 2) * 6), 1.1, fill: .8, expr: Expr.happy, t: t * 4);
}
