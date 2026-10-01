import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../game/levels.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'dialogs.dart';
import 'dont_spill.dart';
import 'home.dart';
import 'level_packs.dart';
import 'play.dart';

class ChallengesScreen extends StatefulWidget {
  final int tab;
  const ChallengesScreen({super.key, this.tab = 0});
  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late int tab = widget.tab;

  void _back() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignScreen(
      child: Column(children: [
        BackCoinsBar(onBack: _back),
        const SizedBox(height: 40),
        Text(tr('CHALLENGES'), style: txt(34, w: FontWeight.w500, sp: 9)),
        const SizedBox(height: 40),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Tap(
                onTap: () => setState(() => tab = i),
                child: Container(
                  width: 104,
                  height: 84,
                  decoration: BoxDecoration(
                    color: tab == i ? C.yellow : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF222222), width: 2),
                  ),
                  child: PaintBox(104, 84, _tabIcon(i)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 24),
        Expanded(child: _body()),
      ]),
    );
  }

  void Function(Canvas, Size) _tabIcon(int i) => (c, s) {
        final o = Offset(s.width / 2, s.height / 2);
        switch (i) {
          case 0:
            drawBrain(c, o, 52, fill: const Color(0xFFF7A1C4));
            break;
          case 1:
            for (final r in [Rect.fromLTWH(o.dx - 22, o.dy + 4, 44, 10), Rect.fromLTWH(o.dx - 22, o.dy + 20, 44, 10)]) {
              c.drawRect(r, fillP(C.brick));
              c.drawRect(r, strokeP(const Color(0xFF7A3A00), 1.2));
            }
            c.drawCircle(o + const Offset(-12, 18), 5, fillP(C.brick));
            c.drawCircle(o + const Offset(12, 18), 5, fillP(C.brick));
            c.save();
            c.translate(o.dx, o.dy - 14);
            c.scale(.3);
            drawGlass(c, glassSkins[0], fill: .8, expr: Expr.happy, dotted: false);
            c.restore();
            break;
          case 2:
            c.drawRect(Rect.fromLTWH(o.dx - 32, o.dy + 20, 64, 6), fillP(C.teal));
            c.drawLine(o + const Offset(-24, 18), o + const Offset(4, -6), strokeP(const Color(0xFF555555), 3));
            c.save();
            c.translate(o.dx + 4, o.dy - 10);
            c.rotate(-.7);
            c.scale(.34);
            drawGlass(c, glassSkins[0], fill: .7, expr: Expr.surprised, dotted: false);
            c.restore();
            break;
          default:
            c.drawRect(Rect.fromLTWH(o.dx - 4, o.dy - 34, 8, 12), fillP(C.water));
            final p = strokeP(const Color(0xFF555555), 2.2);
            final cup = Path()
              ..moveTo(o.dx - 18, o.dy - 18)
              ..quadraticBezierTo(o.dx, o.dy + 22, o.dx + 18, o.dy - 18);
            c.drawPath(cup, fillP(const Color(0xFFBFE3F8)));
            c.drawPath(cup, p);
            c.drawLine(o + const Offset(0, 2), o + const Offset(0, 22), p);
            c.drawLine(o + const Offset(-12, 24), o + const Offset(12, 24), p);
        }
      };

  Widget _body() {
    final d = GameData.I;
    switch (tab) {
      case 0:
        return Column(children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(62, 0, 62, 12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 13, crossAxisSpacing: 12, childAspectRatio: 141 / 176),
              itemCount: kChallengeCount,
              itemBuilder: (_, i) => _ChallengeTile(
                i: i,
                onPlay: () => Navigator.of(context).pushReplacement(fadeRoute(PlayScreen(mode: PlayMode.challenge, index: i))),
              ),
            ),
          ),
          PaintBox(70, 70, (c, s) => drawLock(c, const Offset(35, 35), 62)),
          Container(
            width: 210,
            height: 22,
            decoration: BoxDecoration(color: const Color(0xFFDDDDDD), border: Border.all(color: const Color(0xFF333333), width: 1.6)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: d.challengesDone.length / kChallengeCount, child: Container(color: C.yellow)),
          ),
          const SizedBox(height: 10),
          Text('Complete all 12 Challenge levels + score 10 points on\nFlippy Glass to unlock more levels',
              textAlign: TextAlign.center, style: txt(16, w: FontWeight.w500, h: 1.3)),
          const SizedBox(height: 18),
        ]);
      case 1:
        return ListView(padding: const EdgeInsets.only(bottom: 40), children: [
          _dsPack(0, '1-10', "Complete level 10 in\nClassic Mode to unlock\n\"Don't Spill\" minigame."),
          _dsPack(1, '11-15', 'Complete level 25 in\nClassic Mode and\nChallenge Level 1-5 to\nunlock'),
          _dsPack(2, '16-20', 'Complete level 60 in\nClassic Mode and\nChallenge Level 6-12 to\nunlock'),
          _comingSoon(),
        ]);
      case 2:
        return _lockedInfo(d.flippyUnlocked, 'Complete level 20 in Classic Mode\nto unlock ', 'Flippy Glass', ' minigame');
      default:
        return _lockedInfo(d.preciseUnlocked, 'Complete Level 90 in Classic and Challenge\nLevel 13-18 to unlock ', 'Precise', ' minigame');
    }
  }

  Widget _lockedInfo(bool unlocked, String a, String b, String c) {
    return Padding(
      padding: const EdgeInsets.only(top: 120),
      child: Column(children: [
        if (unlocked) ...[
          Text('COMING SOON', style: txt(32, w: FontWeight.w700, sp: 4)),
        ] else ...[
          PaintBox(110, 120, (cv, s) => drawLock(cv, const Offset(55, 60), 104)),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(style: txt(22, w: FontWeight.w500, h: 1.4), children: [
              TextSpan(text: a),
              TextSpan(text: b, style: txt(22, w: FontWeight.w800)),
              TextSpan(text: c),
            ]),
            textAlign: TextAlign.center,
          ),
        ],
      ]),
    );
  }

  Widget _dsPack(int pack, String label, String lockText) {
    final d = GameData.I;
    final open = d.dsPackUnlocked(pack);
    final first = pack == 0 ? 1 : (pack == 1 ? 11 : 16);
    return Padding(
      padding: const EdgeInsets.only(bottom: 26),
      child: Center(
        child: Tap(
          onTap: open
              ? () {
                  final lv = math.max(first, math.min(d.dsLevel, kDsCount));
                  Navigator.of(context).push(fadeRoute(DontSpillScreen(level: lv)));
                }
              : null,
          child: SizedBox(
            width: 302,
            height: 336,
            child: Stack(children: [
              Positioned(
                left: 50,
                top: 0,
                child: Container(
                  width: 200,
                  height: 46,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E2E2),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    border: Border.all(color: const Color(0xFF555555), width: 1.6),
                  ),
                  child: Text(label, style: txt(22, w: FontWeight.w500, sp: 2)),
                ),
              ),
              Positioned(
                left: 0,
                top: 42,
                child: Container(
                  width: 302,
                  height: 290,
                  decoration: BoxDecoration(
                    color: open ? C.packBlue : C.packDark,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFF1E2A30), width: 2.4),
                    boxShadow: const [BoxShadow(color: Color(0xFF1E2A30), offset: Offset(0, 5))],
                  ),
                  child: Stack(alignment: Alignment.center, children: [
                    Container(width: 210, height: 210, color: const Color(0xFFE6E6E6)),
                    Opacity(opacity: open ? 1 : .3, child: LevelThumb(dsLevel(first), w: 200, h: 200)),
                    if (!open) ...[
                      Container(width: 210, height: 210, color: const Color(0x55000000)),
                      Positioned(top: 34, child: PaintBox(120, 130, (c, s) => drawLock(c, const Offset(60, 65), 110))),
                      Positioned(
                        bottom: 30,
                        child: Text(lockText, textAlign: TextAlign.center, style: txt(18, w: FontWeight.w500, c: Colors.white, h: 1.15)),
                      ),
                    ],
                  ]),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _comingSoon() => Center(
        child: SizedBox(
          width: 302,
          height: 336,
          child: Stack(children: [
            Positioned(
              left: 50,
              top: 0,
              child: Container(
                width: 200,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E2E2),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  border: Border.all(color: const Color(0xFF555555), width: 1.6),
                ),
                child: Text('Coming Soon', style: txt(20, w: FontWeight.w500)),
              ),
            ),
            Positioned(
              left: 0,
              top: 42,
              child: Container(
                width: 302,
                height: 290,
                decoration: BoxDecoration(color: C.packDark, borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFF1E2A30), width: 2.4)),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  PaintBox(120, 130, (c, s) => drawLock(c, const Offset(60, 65), 110)),
                  Text('COMING SOON', style: txt(22, w: FontWeight.w600, c: Colors.white, sp: 3)),
                ]),
              ),
            ),
          ]),
        ),
      );
}

class _ChallengeTile extends StatelessWidget {
  final int i;
  final VoidCallback onPlay;
  const _ChallengeTile({required this.i, required this.onPlay});
  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    final done = d.challengesDone.contains(i);
    final open = d.challengeUnlocked(i);
    return Tap(
      onTap: open ? onPlay : () => showMessage(context, 'Challenge ${i + 1}', 'Complete level ${(i + 1) * 5} in\nClassic Mode to unlock.'),
      child: Container(
        decoration: BoxDecoration(
          color: done ? const Color(0xFF8BD04A) : C.locked,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF333333), width: 2),
        ),
        child: Stack(children: [
          Positioned(left: 8, top: 4, child: Text('${i + 1}', style: txt(24, w: FontWeight.w700))),
          if (done)
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 16),
              PaintBox(90, 96, (c, s) {
                c.translate(45, 48);
                c.scale(1.05);
                drawGlass(c, glassSkins[d.glass], fill: .8, expr: Expr.love, dotted: false);
              }),
              Text('COMPLETED', style: txt(15, w: FontWeight.w700, c: Colors.white)),
            ])
          else if (open)
            Column(children: [
              const SizedBox(height: 26),
              PaintBox(50, 54, (c, s) => drawLock(c, const Offset(25, 27), 44)),
              Text('REWARD', style: txt(14, w: FontWeight.w600)),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                PaintBox(22, 22, (c, s) => drawCoin(c, const Offset(11, 11), 9)),
                Text(' 150', style: txt(18, w: FontWeight.w600)),
              ]),
              const Spacer(),
              Container(
                height: 32,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: C.greenDark, borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
                child: Text(tr('PLAY'), style: txt(18, w: FontWeight.w700, c: Colors.white, sp: 2)),
              ),
            ])
          else
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const SizedBox(height: 22),
              PaintBox(56, 60, (c, s) => drawLock(c, const Offset(28, 30), 50)),
              Text('Complete level\n${(i + 1) * 5} in Classic\nMode', textAlign: TextAlign.center, style: txt(16, w: FontWeight.w500, h: 1.15)),
            ]),
        ]),
      ),
    );
  }
}
