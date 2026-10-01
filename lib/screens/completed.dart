import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/catalog.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../game/levels.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'challenges.dart';
import 'dialogs.dart';
import 'home.dart';
import 'level_packs.dart';
import 'play.dart';
import 'shop.dart';
import 'store.dart';

/// Classic "COMPLETED!" screen with stars, confetti and follow-up buttons.
class CompletedScreen extends StatefulWidget {
  final int level, stars;
  const CompletedScreen({super.key, required this.level, required this.stars});
  @override
  State<CompletedScreen> createState() => _CompletedScreenState();
}

class _CompletedScreenState extends State<CompletedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400))..forward();
  final List<_Confetti> _conf = [];
  int _starSnd = 0;

  @override
  void initState() {
    super.initState();
    final r = math.Random();
    for (var i = 0; i < 70; i++) {
      _conf.add(_Confetti(
        Offset(288 + (r.nextDouble() - .5) * 60, 340 + (r.nextDouble() - .5) * 40),
        Offset((r.nextDouble() - .5) * 520, -r.nextDouble() * 380 - 60),
        [const Color(0xFFE5402B), const Color(0xFF3B8FE0), const Color(0xFF1FA05A), const Color(0xFFFFB21E), const Color(0xFFB04FC9)][i % 5],
        r.nextDouble() * 6,
      ));
    }
    _a.addListener(() {
      final n = ((_a.value - .05) / .12).floor().clamp(0, widget.stars);
      if (n > _starSnd) {
        _starSnd = n;
        Sfx.play('star', volume: .8);
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  double _seg(double a, double b) => ((_a.value - a) / (b - a)).clamp(0, 1);

  void _next() async {
    final n = widget.level;
    final d = GameData.I;
    if (hasBossAfter(n) && !d.bossesDone.contains(bossIndexAfter(n))) {
      final play = await showBossPopup(context);
      if (!mounted) return;
      if (play) {
        Navigator.of(context).pushReplacement(fadeRoute(PlayScreen(mode: PlayMode.boss, index: bossIndexAfter(n))));
        return;
      }
      d.bossesDone.add(bossIndexAfter(n));
      d.save();
    }
    if (n + 1 > kClassicCount) {
      Navigator.of(context).pushAndRemoveUntil(fadeRoute(const HomeScreen()), (r) => false);
    } else {
      Navigator.of(context).pushReplacement(fadeRoute(PlayScreen(index: n + 1)));
    }
  }

  void _freePrize() async {
    if (!await watchRewardAd(context) || !mounted) return;
    final won = await showDailyWheel(context);
    if (won != null) {
      GameData.I.coins += won;
      GameData.I.save();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannerT = Curves.easeOutBack.transform(_seg(0, .2));
    return DesignScreen(
      child: Stack(children: [
        Positioned(
          left: 18,
          right: 14,
          top: 56,
          child: Row(children: [
            Tap(
                onTap: () => Navigator.of(context).pushAndRemoveUntil(fadeRoute(const HomeScreen()), (r) => false),
                child: const PaintBox(66, 66, iconHome)),
            const SizedBox(width: 12),
            Text('Level ${widget.level}', style: txt(34, w: FontWeight.w500, sp: 1)),
            const Spacer(),
            const StarCounter(total: kClassicCount * 3, size: 40),
          ]),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: PaintBox(kW, kH, (c, s) {
              // confetti
              final ct = _seg(0.02, .6);
              if (ct > 0 && ct < 1) {
                for (final p in _conf) {
                  final pos = p.o + p.v * ct + Offset(0, 520 * ct * ct);
                  c.save();
                  c.translate(pos.dx, pos.dy);
                  c.rotate(p.rot + ct * 8);
                  c.drawRect(const Rect.fromLTWH(-3, -1.5, 6, 3), fillP(p.color.withOpacity(1 - ct)));
                  c.restore();
                }
              }
              // stars
              const pos = [Offset(210, 352), Offset(288, 318), Offset(366, 352)];
              for (var i = 0; i < 3; i++) {
                final st = Curves.elasticOut.transform(_seg(.05 + i * .12, .3 + i * .12));
                if (st <= 0) continue;
                c.save();
                c.translate(pos[i].dx, pos[i].dy);
                c.scale(st);
                drawStar(c, Offset.zero, i == 1 ? 42 : 40, filled: i < widget.stars, ol: 2.2);
                c.restore();
              }
              // banner zooms in from large
              c.save();
              final sc = 3.2 - 2.2 * bannerT;
              c.translate(288, 430);
              c.scale(sc);
              drawRibbon(c, Rect.fromCenter(center: Offset.zero, width: 296, height: 54), text: tr('COMPLETED!'), fontSize: 22);
              c.restore();
            }),
          ),
        ),
        _fadeIn(.42, Positioned(left: 118, top: 495, child: Pill(tr('NEXT LEVEL'), w: 340, h: 96, onTap: _next))),
        _fadeIn(.55,
            Positioned(left: 118, top: 617, child: Pill(tr('RETRY'), w: 340, h: 96, icon: const PaintBox(56, 56, _retryIcon), onTap: () => Navigator.of(context).pushReplacement(fadeRoute(PlayScreen(index: widget.level)))))),
        _fadeIn(.3, Positioned(left: 136, top: 740, child: _FreePrize(onTap: _freePrize))),
        _fadeIn(.55, Positioned(left: 294, top: 875, child: _Round(child: Text('LEVEL', style: txt(24, w: FontWeight.w400)), onTap: () => Navigator.of(context).push(fadeRoute(const LevelPacksScreen()))))),
        _fadeIn(.6, Positioned(left: 420, top: 875, child: _Round(child: const PaintBox(62, 62, iconPencil), onTap: () => Navigator.of(context).push(fadeRoute(const ShopScreen(tab: 0)))))),
        _fadeIn(.65, Positioned(left: 294, top: 1000, child: _Round(child: const PaintBox(62, 62, iconCart), onTap: () => Navigator.of(context).push(fadeRoute(const StoreScreen()))))),
      ]),
    );
  }

  Widget _fadeIn(double at, Positioned p) {
    final v = _seg(at, at + .1);
    return Positioned(
      left: p.left,
      top: p.top,
      child: IgnorePointer(ignoring: v < 1, child: Opacity(opacity: v, child: p.child)),
    );
  }
}

class _Confetti {
  final Offset o, v;
  final Color color;
  final double rot;
  _Confetti(this.o, this.v, this.color, this.rot);
}

void _retryIcon(Canvas c, Size s) {
  final p = strokeP(const Color(0xFF222222), 2.6);
  final o = Offset(s.width / 2, s.height / 2);
  c.drawArc(Rect.fromCircle(center: o, radius: 20), math.pi * .1, math.pi * 1.6, false, p);
  c.drawArc(Rect.fromCircle(center: o, radius: 12), math.pi * .1, math.pi * 1.6, false, p);
  final a = Path()
    ..moveTo(o.dx + 26, o.dy - 6)
    ..lineTo(o.dx + 16, o.dy + 8)
    ..lineTo(o.dx + 6, o.dy - 6)
    ..close();
  c.drawPath(a, fillP(C.green));
  c.drawPath(a, p);
}

class _FreePrize extends StatelessWidget {
  final VoidCallback onTap;
  const _FreePrize({required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          width: 302,
          height: 124,
          decoration: BoxDecoration(
            color: C.blueLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFA9C7E0), width: 2),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Opacity(
              opacity: .6,
              child: PaintBox(90, 90, (c, s) {
                drawWheel(c, const Offset(42, 46), 36);
                const r = Rect.fromLTWH(58, 58, 26, 24);
                c.drawRect(r, fillP(const Color(0xFFE8F5A0)));
                c.drawRect(r, strokeP(const Color(0xFF555555), 1.4));
                final t = Path()
                  ..moveTo(66, 63)
                  ..lineTo(66, 77)
                  ..lineTo(77, 70)
                  ..close();
                c.drawPath(t, strokeP(const Color(0xFF555555), 1.4));
              }),
            ),
            const SizedBox(width: 12),
            Text('FREE\nPRIZE', style: txt(30, w: FontWeight.w500, sp: 5, c: const Color(0xFF8E9DAA), h: 1.25)),
          ]),
        ),
      );
}

class _Round extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const _Round({required this.child, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
        onTap: onTap,
        child: Container(
          width: 112,
          height: 112,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: const Color(0xFFD5D5D5), shape: BoxShape.circle, border: Border.all(color: const Color(0xFF222222), width: 2.2)),
          child: child,
        ),
      );
}

/// Reward screen used after a boss level and after Don't Spill levels.
class RewardCompleted extends StatefulWidget {
  final int reward;
  final String title;
  final String? counter;
  final void Function(BuildContext ctx) onNext;
  final VoidCallback? onBack;
  const RewardCompleted({super.key, required this.reward, required this.title, required this.onNext, this.counter, this.onBack});
  @override
  State<RewardCompleted> createState() => _RewardCompletedState();
}

class _RewardCompletedState extends State<RewardCompleted> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
  bool _claimed = false;
  @override
  void initState() {
    super.initState();
    _a.addListener(() => setState(() {}));
    Future.delayed(const Duration(milliseconds: 600), _claim);
  }

  void _claim() {
    if (_claimed || !mounted) return;
    _claimed = true;
    GameData.I.coins += widget.reward;
    GameData.I.save();
    Sfx.play('coin');
    _a.forward();
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _a.value;
    return DesignScreen(
      child: Stack(children: [
        Positioned(
          left: 10,
          right: 16,
          top: 36,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (widget.onBack != null) BackArrow(onTap: widget.onBack!) else const SizedBox(width: 80),
            const Spacer(),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              const CoinCounter(size: 44),
              if (widget.counter != null) Text(widget.counter!, style: txt(40, w: FontWeight.w500, sp: 6)),
            ]),
          ]),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: PaintBox(kW, kH, (c, s) {
              c.save();
              c.translate(288, 384);
              c.scale(1.65);
              drawGlass(c, glassSkins[GameData.I.glass], fill: 1, water: C.water, expr: Expr.happy);
              c.restore();
              drawRibbon(c, const Rect.fromLTWH(134, 456, 308, 58), text: tr('COMPLETED!'), fontSize: 22);
              final tp = TextPainter(text: TextSpan(text: 'REWARD', style: txt(22, w: FontWeight.w500, sp: 4)), textDirection: TextDirection.ltr)..layout();
              tp.paint(c, Offset(288 - tp.width / 2, 560));
              final box = RRect.fromRectAndRadius(const Rect.fromLTWH(206, 596, 166, 114), const Radius.circular(10));
              c.drawRRect(box, fillP(Colors.white));
              c.drawRRect(box, strokeP(const Color(0xFF222222), 2.2));
              drawCoin(c, const Offset(244, 653), 24);
              final tn = TextPainter(text: TextSpan(text: '${widget.reward}', style: txt(56, w: FontWeight.w500)), textDirection: TextDirection.ltr)..layout();
              tn.paint(c, Offset(318 - tn.width / 2, 653 - tn.height / 2));
              if (t > 0 && t < 1) {
                for (var i = 0; i < 6; i++) {
                  final k = Curves.easeIn.transform(((t - i * .07) / .6).clamp(0, 1));
                  if (k <= 0 || k >= 1) continue;
                  final p = Offset.lerp(Offset(250 + i * 12.0, 650 + (i % 3) * 10.0), const Offset(470, 70), k)!;
                  drawCoin(c, p, 20);
                }
              }
            }),
          ),
        ),
        Positioned(left: 116, top: 850, child: Pill(tr('NEXT LEVEL'), w: 344, h: 92, fs: 28, onTap: () => widget.onNext(context))),
      ]),
    );
  }
}

/// "CHALLENGE COMPLETED" with a love-struck glass and CONTINUE (+150).
class ChallengeCompletedScreen extends StatefulWidget {
  final int reward;
  const ChallengeCompletedScreen({super.key, required this.reward});
  @override
  State<ChallengeCompletedScreen> createState() => _ChallengeCompletedState();
}

class _ChallengeCompletedState extends State<ChallengeCompletedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  bool _busy = false;
  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  void _continue() async {
    if (_busy) return;
    _busy = true;
    GameData.I.coins += widget.reward;
    GameData.I.save();
    Sfx.play('coin');
    await Future.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(const ChallengesScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return DesignScreen(
      child: Stack(children: [
        const Positioned(right: 16, top: 56, child: CoinCounter()),
        Positioned(
          left: 0,
          right: 0,
          top: 290,
          child: Column(children: [
            Text('CHALLENGE', style: txt(46, w: FontWeight.w600)),
            Text('COMPLETED', style: txt(46, w: FontWeight.w600, c: C.greenDark)),
          ]),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _a,
              builder: (_, __) => PaintBox(kW, kH, (c, s) {
                c.save();
                c.translate(288, 600);
                c.scale(2.3);
                drawGlass(c, glassSkins[GameData.I.glass], fill: .78, water: C.water, expr: Expr.love);
                c.restore();
                const hs = [Offset(150, 490), Offset(426, 496), Offset(160, 660), Offset(420, 664)];
                for (var i = 0; i < hs.length; i++) {
                  final b = math.sin(_a.value * math.pi * 2 + i) * 6;
                  drawHeart(c, hs[i] + Offset(0, b), 30, const Color(0xFFE5262B));
                }
              }),
            ),
          ),
        ),
        Positioned(
          left: 163,
          top: 808,
          child: Tap(
            onTap: _continue,
            child: Container(
              width: 250,
              height: 74,
              decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF222222), width: 2)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('CONTINUE', style: txt(21, w: FontWeight.w500, sp: 2)),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  PaintBox(24, 24, (c, s) => drawCoin(c, const Offset(12, 12), 10)),
                  const SizedBox(width: 4),
                  Text('${widget.reward}', style: txt(21, w: FontWeight.w700, sp: 2)),
                ]),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}
