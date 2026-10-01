import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/catalog.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';
import 'completed.dart';
import 'dialogs.dart';

/// After every classic win: +25 coins fly to the counter and water pours into
/// the reward bottle (+12%). A full bottle unlocks the next water colour.
class BottleScreen extends StatefulWidget {
  final int level, stars;
  const BottleScreen({super.key, required this.level, required this.stars});
  @override
  State<BottleScreen> createState() => _BottleScreenState();
}

class _BottleScreenState extends State<BottleScreen> with TickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200))..forward();
  late final int from, to;
  late final int nextColor;
  bool _full = false;
  bool _done = false;
  int _shownCoins = 0;

  @override
  void initState() {
    super.initState();
    final d = GameData.I;
    from = d.bottle;
    final allColors = d.unlockedWaters >= waterColors.length;
    to = allColors ? 100 : math.min(100, from + 12);
    nextColor = d.unlockedWaters;
    _shownCoins = d.coins;
    d.coins += 25;
    d.bottle = to;
    _full = to >= 100 && !allColors;
    d.save();
    Sfx.play('coin');
    _a.addListener(() {
      final v = _a.value;
      if (v > .18 && _shownCoins < GameData.I.coins) {
        _shownCoins = GameData.I.coins;
        Sfx.play('coin', volume: .6);
      }
      setState(() {});
    });
    Future.delayed(const Duration(milliseconds: 650), () => mounted ? Sfx.pour(true) : null);
    Future.delayed(const Duration(milliseconds: 2400), () => Sfx.pour(false));
  }

  @override
  void dispose() {
    _a.dispose();
    Sfx.pour(false);
    super.dispose();
  }

  double _seg(double a, double b) => ((_a.value - a) / (b - a)).clamp(0, 1);

  Future<void> _finish({bool ad = false}) async {
    if (_done) return;
    if (ad) {
      final ok = await watchRewardAd(context);
      if (!ok || !mounted) return;
      GameData.I.coins += 225; // 10x the 25 coin reward in total
      GameData.I.save();
      Sfx.play('coin');
    }
    _done = true;
    final d = GameData.I;
    if (_full) {
      d.unlockedWaters = math.min(waterColors.length, d.unlockedWaters + 1);
      d.bottle = 0;
      d.save();
      await showWaterColor(context, nextColor);
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(fadeRoute(CompletedScreen(level: widget.level, stars: widget.stars)));
  }

  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    final pourT = _seg(.15, .55);
    final fill = (from + (to - from) * Curves.easeOut.transform(_seg(.48, .75))) / 100;
    final pct = (fill * 100).round();
    final coinT = _seg(0, .22);
    final water = waterColors[d.water];
    return DesignScreen(
      child: Stack(children: [
        Positioned(
          right: 14,
          top: 52,
          child: Row(children: [
            PaintBox(52, 52, (c, s) => drawCoin(c, const Offset(26, 26), 23)),
            const SizedBox(width: 4),
            Text('${coinT < 1 ? _shownCoins : d.coins}', style: txt(29, w: FontWeight.w500, sp: 3)),
          ]),
        ),
        // flying coins
        Positioned.fill(
          child: IgnorePointer(
            child: PaintBox(kW, kH, (c, s) {
              if (coinT >= 1) return;
              for (var i = 0; i < 5; i++) {
                final start = Offset(250 + i * 9.0, 340 + (i.isEven ? -6 : 6));
                final k = Curves.easeIn.transform(((coinT - i * .08) / .6).clamp(0, 1));
                final p = Offset.lerp(start, const Offset(500, 78), k)!;
                if (k < 1) drawCoin(c, p, 20);
              }
              if (coinT < .7) {
                final tp = TextPainter(text: TextSpan(text: '+25', style: txt(42, w: FontWeight.w500)), textDirection: TextDirection.ltr)..layout();
                tp.paint(c, const Offset(296, 318));
              }
            }),
          ),
        ),
        // pouring stream + bottle
        Positioned.fill(
          child: IgnorePointer(
            child: PaintBox(kW, kH, (c, s) {
              if (pourT > 0 && pourT < 1) {
                // a single elongated drop falls from the top into the bottle neck
                final y = -120 + Curves.easeIn.transform(pourT) * 600;
                final len = 70 + 40 * pourT;
                final r = RRect.fromRectAndRadius(Rect.fromLTRB(280, y - len, 296, math.min(y, 500.0)), const Radius.circular(8));
                if (r.bottom > r.top) c.drawRRect(r, fillP(water));
              }
              drawBottle(c, const Offset(288, 585), 200, fill, water);
            }),
          ),
        ),
        Positioned(
          left: 200,
          top: 735,
          child: Container(
            width: 176,
            height: 70,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: const Color(0xFF222222), width: 2.5)),
            child: Text('$pct%', style: txt(36, w: FontWeight.w500, sp: 4)),
          ),
        ),
        if (_full && _a.value > .62)
          Positioned(left: 118, top: 900, child: Pill('CLAIM', w: 340, h: 100, onTap: _finish))
        else ...[
          if (_a.value > .82) Positioned(left: 118, top: 830, child: Pill(tr('SKIP'), w: 340, h: 100, onTap: _finish)),
          if (_a.value > .5) Positioned(left: 118, top: 950, child: AdPill('GET 10x', w: 340, h: 100, onTap: () => _finish(ad: true))),
        ],
      ]),
    );
  }
}
