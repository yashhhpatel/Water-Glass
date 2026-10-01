import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../game/level.dart';
import '../game/levels.dart';
import '../game/render.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'home.dart';
import 'play.dart';

/// Paper-stack preview of a level layout.
class LevelThumb extends StatelessWidget {
  final LevelDef def;
  final double w, h;
  final bool done;
  const LevelThumb(this.def, {super.key, required this.w, required this.h, this.done = false});
  @override
  Widget build(BuildContext context) => PaintBox(w, h, (c, s) {
        c.drawRect(Offset.zero & s, fillP(Colors.white));
        c.save();
        c.clipRect(Offset.zero & s);
        // fit the interesting part of the 576x1280 design (y 380..900)
        final sc = s.width / 576;
        c.scale(sc);
        c.translate(0, -(380 - (s.height / sc - 520) / 2));
        paintLevelStatic(c, def, skin: glassSkins[GameData.I.glass], fill: done ? 1 : 0, water: waterColors[GameData.I.water]);
        c.restore();
      });
}

class LevelPacksScreen extends StatelessWidget {
  const LevelPacksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    final packs = (kClassicCount / 10).ceil();
    return DesignScreen(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 52, 12, 0),
          child: Row(children: [
            Tap(onTap: () => Navigator.of(context).pushAndRemoveUntil(fadeRoute(const HomeScreen()), (r) => false), child: const PaintBox(66, 66, iconHome)),
            const Spacer(),
            const StarCounter(total: kClassicCount * 3),
          ]),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(top: 40, bottom: 60),
            itemCount: packs,
            itemBuilder: (ctx, p) {
              final unlocked = d.packUnlocked(p);
              return Padding(
                padding: const EdgeInsets.only(bottom: 34),
                child: Column(children: [
                  Tap(
                    onTap: unlocked ? () => Navigator.of(context).push(fadeRoute(PackLevelsScreen(pack: p))) : null,
                    child: _PackCard(pack: p, unlocked: unlocked),
                  ),
                  const SizedBox(height: 10),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    PaintBox(50, 50, (c, s) => drawStar(c, const Offset(25, 25), 24)),
                    const SizedBox(width: 8),
                    Text('${d.starsInPack(p)}/30', style: txt(40, w: FontWeight.w500)),
                  ]),
                  Text(tr('COLLECTED'), style: txt(22, w: FontWeight.w500, sp: 3)),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _PackCard extends StatelessWidget {
  final int pack;
  final bool unlocked;
  const _PackCard({required this.pack, required this.unlocked});
  @override
  Widget build(BuildContext context) {
    final first = pack * 10 + 1;
    return SizedBox(
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
            child: Text('$first-${first + 9}', style: txt(22, w: FontWeight.w500, sp: 2)),
          ),
        ),
        Positioned(
          left: 0,
          top: 42,
          child: Container(
            width: 302,
            height: 290,
            decoration: BoxDecoration(
              color: unlocked ? C.packBlue : C.packDark,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFF1E2A30), width: 2.4),
              boxShadow: const [BoxShadow(color: Color(0xFF1E2A30), offset: Offset(0, 5))],
            ),
            child: Stack(alignment: Alignment.center, children: [
              Transform.rotate(angle: .03, child: Container(width: 210, height: 210, color: const Color(0xFFBDBDBD))),
              Transform.rotate(angle: -.02, child: Container(width: 210, height: 210, color: const Color(0xFFE6E6E6))),
              Opacity(opacity: unlocked ? 1 : .35, child: LevelThumb(classicLevel(first), w: 200, h: 200)),
              if (!unlocked) ...[
                Container(width: 200, height: 200, color: const Color(0x66000000)),
                Positioned(top: 52, child: PaintBox(130, 140, (c, s) => drawLock(c, const Offset(65, 70), 120))),
                Positioned(
                  bottom: 34,
                  child: Column(children: [
                    Row(children: [
                      PaintBox(40, 40, (c, s) => drawStar(c, const Offset(20, 20), 18)),
                      Text('${GameData.packCost(pack)}', style: txt(34, w: FontWeight.w600, c: Colors.white)),
                    ]),
                    Text(tr('TO UNLOCK'), style: txt(16, w: FontWeight.w600, c: Colors.white, sp: 2)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

class PackLevelsScreen extends StatelessWidget {
  final int pack;
  const PackLevelsScreen({super.key, required this.pack});
  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    final first = pack * 10 + 1;
    final done = [for (var i = first; i < first + 10; i++) if ((d.stars[i] ?? 0) > 0) i].length;
    return DesignScreen(
      child: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 36, 12, 0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BackArrow(onTap: () => Navigator.of(context).pop()),
            const Spacer(),
            const Padding(padding: EdgeInsets.only(top: 14), child: StarCounter(total: kClassicCount * 3)),
          ]),
        ),
        Text('LEVEL $first-${first + 9}', style: txt(36, w: FontWeight.w500, sp: 7)),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          PaintBox(30, 30, (c, s) => drawStar(c, const Offset(15, 15), 13)),
          Text('${d.starsInPack(pack)}/30', style: txt(26, w: FontWeight.w500)),
        ]),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 260,
            height: 18,
            decoration: BoxDecoration(color: C.barEmpty, border: Border.all(color: const Color(0xFF333333), width: 1.6)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: done / 10, child: Container(color: const Color(0xFFADDC45))),
          ),
          const SizedBox(width: 10),
          Text('$done/10', style: txt(20, w: FontWeight.w500)),
        ]),
        const SizedBox(height: 26),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(76, 0, 76, 40),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 26, crossAxisSpacing: 24, childAspectRatio: 200 / 256),
            itemCount: 10,
            itemBuilder: (ctx, i) {
              final n = first + i;
              final open = n <= d.level && n <= kClassicCount;
              final st = d.stars[n] ?? 0;
              return Tap(
                onTap: open ? () => Navigator.of(context).pushAndRemoveUntil(fadeRoute(PlayScreen(index: n)), (r) => r.isFirst) : null,
                child: Column(children: [
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: const Color(0xFF333333), width: 1.6)),
                    child: Stack(children: [
                      LevelThumb(classicLevel(n), w: 196, h: 190, done: st > 0),
                      if (!open) ...[
                        Container(width: 196, height: 190, color: const Color(0xAA1E2A30)),
                        Positioned.fill(child: Center(child: PaintBox(80, 90, (c, s) => drawLock(c, const Offset(40, 45), 74)))),
                      ],
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          color: open ? Colors.white : const Color(0xFF3A3A3A),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          child: Text('$n', style: txt(20, w: FontWeight.w600, c: open ? C.ink : Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 6),
                  PaintBox(140, 44, (c, s) {
                    for (var k = 0; k < 3; k++) {
                      drawStar(c, Offset(26 + k * 44.0, 22), 19, filled: k < st);
                    }
                  }),
                ]),
              );
            },
          ),
        ),
      ]),
    );
  }
}
