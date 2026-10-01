import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/catalog.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';

/// "Hint — No more hints available." / "Whoops! ..." style message.
Future<void> showMessage(BuildContext context, String title, String body) {
  return showPopup(
      context,
      (ctx) => PopupCard(
            width: 470,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title, style: txt(32, w: FontWeight.w700)),
              const SizedBox(height: 24),
              Text(body, textAlign: TextAlign.center, style: txt(27, w: FontWeight.w500, h: 1.45)),
              const SizedBox(height: 22),
              Pill('Ok', w: 136, h: 54, fs: 22, onTap: () => Navigator.of(ctx).pop()),
            ]),
          ));
}

/// Boss/challenge out of lives. Returns true when the player takes 3 more tries.
Future<bool> showTryAgain(BuildContext context) async {
  final r = await showPopup<bool>(context, (ctx) => const _TryAgain());
  return r ?? false;
}

class _TryAgain extends StatefulWidget {
  const _TryAgain();
  @override
  State<_TryAgain> createState() => _TryAgainState();
}

class _TryAgainState extends State<_TryAgain> {
  bool _showGiveUp = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () => mounted ? setState(() => _showGiveUp = true) : null);
  }

  @override
  Widget build(BuildContext context) => PopupCard(
        width: 460,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PaintBox(110, 120, (c, s) {
            c.save();
            c.translate(55, 58);
            c.scale(1.35);
            drawGlass(c, glassSkins[0], expr: Expr.worried);
            c.restore();
          }),
          const SizedBox(height: 8),
          Text('TRY AGAIN?', style: txt(38, w: FontWeight.w600)),
          const SizedBox(height: 20),
          SizedBox(
            height: 64,
            child: AnimatedOpacity(
              opacity: _showGiveUp ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Pill('GIVE UP!', w: 360, h: 60, fs: 24, onTap: _showGiveUp ? () => Navigator.of(context).pop(false) : null),
            ),
          ),
          const SizedBox(height: 14),
          Stack(clipBehavior: Clip.none, children: [
            AdPillText('Get 3 more tries!', onTap: () async {
              if (await watchRewardAd(context) && context.mounted) Navigator.of(context).pop(true);
            }),
            const Positioned(right: -6, top: -14, child: PaintBox(30, 30, _adBadge)),
          ]),
        ]),
      );
}

void _adBadge(Canvas c, Size s) {
  final r = Rect.fromLTWH(2, 2, s.width - 4, s.height - 4);
  c.drawRect(r, fillP(C.coin));
  c.drawRect(r, strokeP(const Color(0xFF333333), 1.6));
  final tri = Path()
    ..moveTo(s.width * .38, s.height * .3)
    ..lineTo(s.width * .38, s.height * .7)
    ..lineTo(s.width * .7, s.height * .5)
    ..close();
  c.drawPath(tri, strokeP(const Color(0xFF333333), 1.8));
}

class AdPillText extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const AdPillText(this.text, {super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          width: 360,
          height: 64,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: C.btnBlue,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: const Color(0xFF222222), width: 2),
          ),
          child: Text(text, style: txt(26, w: FontWeight.w600, sp: 2)),
        ),
      );
}

/// "COLLECT ALL 3 STARS?" offered after finishing with fewer than 3 stars.
Future<bool> showCollectStars(BuildContext context, int stars) async {
  final r = await showGeneralDialog<bool>(
    context: context,
    barrierDismissible: false,
    barrierColor: const Color(0xDD1E1E1E),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, _, __) => SafeArea(
      child: Center(
        child: FittedBox(
          child: SizedBox(
            width: kW,
            height: kH,
            child: Material(
              type: MaterialType.transparency,
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                PaintBox(300, 110, (c, s) {
                  for (var i = 0; i < 3; i++) {
                    final p = starPath(Offset(60.0 + i * 90, 55), 46);
                    c.drawPath(p, fillP(i < stars ? C.star : const Color(0xFF4A4A20)));
                  }
                }),
                const SizedBox(height: 22),
                Text('COLLECT ALL 3 STARS?', style: txt(26, w: FontWeight.w600, c: Colors.white, sp: 4)),
                const SizedBox(height: 30),
                Pill(tr('SKIP'), w: 366, h: 92, fs: 28, onTap: () => Navigator.of(ctx).pop(false)),
                const SizedBox(height: 22),
                Tap(
                  onTap: () async {
                    if (await watchRewardAd(ctx) && ctx.mounted) Navigator.of(ctx).pop(true);
                  },
                  child: Container(
                    width: 366,
                    height: 92,
                    decoration: BoxDecoration(color: const Color(0xFF2E6F9E), borderRadius: BorderRadius.circular(46)),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      PaintBox(54, 50, (c, s) => drawClapper(c, const Rect.fromLTWH(4, 8, 46, 40))),
                      const SizedBox(width: 12),
                      Text('COLLECT', style: txt(28, w: FontWeight.w600, sp: 4, c: const Color(0xFF9EC9E8))),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    ),
  );
  return r ?? false;
}

/// "BOSS LEVEL! TEST YOUR SKILLS! (coin)250  PLAY / NO THANKS".
Future<bool> showBossPopup(BuildContext context) async {
  final r = await showPopup<bool>(context, (ctx) => const _BossPopup());
  return r ?? false;
}

class _BossPopup extends StatefulWidget {
  const _BossPopup();
  @override
  State<_BossPopup> createState() => _BossPopupState();
}

class _BossPopupState extends State<_BossPopup> {
  bool _no = false;
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1600), () => mounted ? setState(() => _no = true) : null);
  }

  @override
  Widget build(BuildContext context) => PopupCard(
        width: 440,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('BOSS LEVEL!', style: txt(36, w: FontWeight.w600)),
          const SizedBox(height: 10),
          PaintBox(380, 250, (c, s) {
            // red pipes with water and two crosses under a scared glass
            final red = fillP(const Color(0xFFF0582B));
            final ol = strokeP(const Color(0xFF222222), 1.6);
            for (final r in [
              const Rect.fromLTWH(10, 200, 90, 16),
              const Rect.fromLTWH(280, 200, 90, 16),
              const Rect.fromLTWH(84, 140, 16, 76),
              const Rect.fromLTWH(280, 140, 16, 76),
              const Rect.fromLTWH(100, 160, 180, 16),
              const Rect.fromLTWH(182, 80, 16, 96),
            ]) {
              c.drawRect(r, red);
              c.drawRect(r, ol);
            }
            c.drawRect(const Rect.fromLTWH(100, 140, 82, 20), fillP(C.water));
            c.drawRect(const Rect.fromLTWH(198, 140, 82, 20), fillP(C.water));
            for (final x in [140.0, 240.0]) {
              for (final a in [math.pi / 4, -math.pi / 4]) {
                c.save();
                c.translate(x, 100);
                c.rotate(a);
                final r = RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 44, height: 9), const Radius.circular(2));
                c.drawRRect(r, fillP(const Color(0xFFF7931E)));
                c.drawRRect(r, ol);
                c.restore();
              }
            }
            c.save();
            c.translate(190, 42);
            c.scale(.95);
            drawGlass(c, glassSkins[0], expr: Expr.worried);
            c.restore();
          }),
          Text('TEST YOUR SKILLS!', style: txt(17, w: FontWeight.w600, sp: 3)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(border: Border.all(color: const Color(0xFF222222), width: 2), borderRadius: BorderRadius.circular(8)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              PaintBox(36, 36, (c, s) => drawCoin(c, const Offset(18, 18), 15)),
              const SizedBox(width: 6),
              Text('250', style: txt(38, w: FontWeight.w500, sp: 2)),
            ]),
          ),
          const SizedBox(height: 18),
          Pill(tr('PLAY'), w: 370, h: 64, fs: 24, onTap: () => Navigator.of(context).pop(true)),
          const SizedBox(height: 12),
          SizedBox(
            height: 64,
            child: AnimatedOpacity(
              opacity: _no ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: Pill(tr('NO THANKS'), w: 370, h: 60, fs: 22, onTap: _no ? () => Navigator.of(context).pop(false) : null),
            ),
          ),
        ]),
      );
}

/// "YOU RECEIVED A WATER COLOR!" with USE / TAP TO CLOSE.
Future<void> showWaterColor(BuildContext context, int colorIndex) {
  Sfx.play('reward');
  return showPopup(
      context,
      (ctx) => PopupCard(
            width: 500,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('YOU RECEIVED A WATER COLOR!', style: txt(19, w: FontWeight.w600, sp: 2)),
              const SizedBox(height: 26),
              PaintBox(120, 130, (c, s) {
                final p = Path()
                  ..moveTo(60, 8)
                  ..cubicTo(60, 8, 20, 60, 20, 84)
                  ..arcToPoint(const Offset(100, 84), radius: const Radius.circular(40), clockwise: false)
                  ..cubicTo(100, 60, 60, 8, 60, 8)
                  ..close();
                c.drawPath(p, fillP(waterColors[colorIndex]));
                c.drawPath(p, strokeP(const Color(0xFF222222), 3));
                c.drawCircle(const Offset(44, 90), 6, fillP(Colors.white.withOpacity(.7)));
                for (final o in const [Offset(16, 40), Offset(102, 36), Offset(10, 70)]) {
                  c.drawCircle(o, 2.5, fillP(C.coin));
                }
              }),
              const SizedBox(height: 26),
              Pill('USE', w: 250, h: 76, fs: 28, onTap: () {
                GameData.I.water = colorIndex;
                GameData.I.save();
                Navigator.of(ctx).pop();
              }),
              const SizedBox(height: 14),
              Pill('TAP TO CLOSE', w: 250, h: 66, fs: 20, onTap: () => Navigator.of(ctx).pop()),
            ]),
          ));
}

/// Limited-time bundle offer (in-app purchases are not available in this build).
Future<void> showLimitedOffer(BuildContext context) {
  return showPopup(
    context,
    dismissible: true,
    (ctx) => GestureDetector(
      onTap: () => Navigator.of(ctx).pop(),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        PopupCard(
          width: 480,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('LIMITED OFFER!', style: txt(24, w: FontWeight.w600, sp: 2)),
            const SizedBox(height: 18),
            const BundleCard(compact: true),
          ]),
        ),
        const SizedBox(height: 30),
        Text('TAP TO CLOSE', style: txt(24, w: FontWeight.w600, c: Colors.white, sp: 3)),
      ]),
    ),
  );
}

/// "HAPPY BUNDLE"-style offer card: 3000 coins + 10 hints.
class BundleCard extends StatelessWidget {
  final bool compact;
  const BundleCard({super.key, this.compact = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 430 : 450,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(compact ? 10 : 2),
        border: Border.all(color: const Color(0xFF222222), width: 2),
        boxShadow: compact ? null : const [BoxShadow(color: Color(0xFF666666), offset: Offset(4, 6))],
      ),
      child: Stack(clipBehavior: Clip.none, children: [
        if (!compact)
          Positioned(
            left: -2,
            top: -20,
            child: PaintBox(70, 70, (c, s) {
              final p = Path()
                ..moveTo(0, 0)
                ..lineTo(70, 0)
                ..lineTo(0, 70)
                ..close();
              c.drawPath(p, fillP(const Color(0xFFF2649B)));
              c.save();
              c.translate(20, 22);
              c.rotate(-math.pi / 4);
              final tp = TextPainter(text: TextSpan(text: 'LIMITED\nOFFER', style: txt(9, w: FontWeight.w700, c: Colors.white)), textAlign: TextAlign.center, textDirection: TextDirection.ltr)..layout();
              tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
              c.restore();
            }),
          ),
        Column(children: [
          Center(child: Text('WATER BUNDLE', style: txt(compact ? 18 : 26, w: FontWeight.w600, sp: 3))),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Column(children: [
              PaintBox(64, 54, (c, s) {
                drawCoin(c, const Offset(22, 32), 16);
                drawCoin(c, const Offset(38, 26), 16);
                drawCoin(c, const Offset(30, 38), 16);
              }),
              Text('3000', style: txt(20, w: FontWeight.w500, sp: 2)),
            ]),
            const SizedBox(width: 18),
            Text('+', style: txt(26)),
            const SizedBox(width: 18),
            Column(children: [
              PaintBox(54, 54, (c, s) => drawBulb(c, const Offset(27, 28), 44)),
              Text('10', style: txt(20, w: FontWeight.w500, sp: 2)),
            ]),
          ]),
          const SizedBox(height: 4),
          Text('LOADING...', style: txt(14, w: FontWeight.w500, c: const Color(0xFFE5402B), sp: 1)),
        ]),
      ]),
    );
  }
}

/// Daily prize wheel. Returns coins won.
Future<int?> showDailyWheel(BuildContext context) => showPopup<int>(context, (ctx) => const _Wheel());

class _Wheel extends StatefulWidget {
  const _Wheel();
  @override
  State<_Wheel> createState() => _WheelState();
}

class _WheelState extends State<_Wheel> with SingleTickerProviderStateMixin {
  static const prizes = [25, 50, 100, 25, 200, 50, 75, 500];
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200));
  int _pick = 0;
  bool _spun = false;
  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  void _spin() {
    if (_spun) return;
    _spun = true;
    _pick = math.Random().nextInt(prizes.length);
    _a.forward().whenComplete(() {
      Sfx.play('coin');
      Future.delayed(const Duration(milliseconds: 700), () => mounted ? Navigator.of(context).pop(prizes[_pick]) : null);
    });
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopupCard(
      width: 470,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('DAILY REWARD', style: txt(30, w: FontWeight.w700, sp: 3)),
        const SizedBox(height: 20),
        AnimatedBuilder(
          animation: _a,
          builder: (_, __) {
            // pointer is at the top; segment i spans [i*45°, (i+1)*45°] from +x axis
            final target = -math.pi / 2 - (_pick + .5) * math.pi / 4 + math.pi * 2 * 5;
            final rot = Curves.easeOutCubic.transform(_a.value) * target;
            return PaintBox(300, 300, (c, s) {
              drawWheel(c, const Offset(150, 156), 130, rot: rot);
              for (var i = 0; i < 8; i++) {
                final a = rot + (i + .5) * math.pi / 4;
                final tp = TextPainter(text: TextSpan(text: '${prizes[i]}', style: txt(20, w: FontWeight.w800, c: Colors.white)), textDirection: TextDirection.ltr)..layout();
                c.save();
                c.translate(150 + math.cos(a) * 72, 156 + math.sin(a) * 72);
                c.rotate(a + math.pi / 2);
                tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
                c.restore();
              }
            });
          },
        ),
        const SizedBox(height: 20),
        Pill(_spun ? '...' : 'SPIN', w: 260, h: 70, fs: 26, onTap: _spun ? null : _spin),
      ]),
    );
  }
}

Future<void> showComingSoon(BuildContext context) => showMessage(context, 'Coming Soon', 'This minigame is coming soon.\nStay tuned!');
