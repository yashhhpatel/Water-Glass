import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/ads.dart';
import '../core/audio.dart';
import '../core/catalog.dart';
import '../core/data.dart';
import '../core/theme.dart';
import '../game/levels.dart';
import '../game/render.dart';
import '../game/sim.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'completed.dart';

/// Don't Spill minigame: tap bricks away so the filled glass reaches the red
/// line without spilling.
class DontSpillScreen extends StatefulWidget {
  final int level;
  const DontSpillScreen({super.key, required this.level});
  @override
  State<DontSpillScreen> createState() => _DontSpillState();
}

class _Puff {
  final Offset at;
  double t = 0;
  _Puff(this.at);
}

class _DontSpillState extends State<DontSpillScreen> with SingleTickerProviderStateMixin {
  late Sim sim;
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final RenderOpts _opts = RenderOpts();
  final List<_Puff> _puffs = [];
  Duration _last = Duration.zero;
  double _t = 0;
  double _countdown = -1;
  int _lastTick = 0;
  bool _ended = false;
  bool _dark = false;
  bool _ready = false;
  bool _hint = false;
  bool _bubble = true;
  bool _pourSnd = false;

  @override
  void initState() {
    super.initState();
    _reset();
    _ticker = createTicker(_tick)..start();
  }

  void _reset() {
    sim = Sim(dsLevel(widget.level))..start();
    _countdown = -1;
    _ended = false;
    _dark = false;
    _ready = false;
    _hint = false;
    _bubble = widget.level == 1;
    _puffs.clear();
  }

  @override
  void dispose() {
    _ticker.dispose();
    Sfx.pour(false);
    super.dispose();
  }

  void _tick(Duration now) {
    final dt = _last == Duration.zero ? 1 / 60 : (now - _last).inMicroseconds / 1e6;
    _last = now;
    _t += dt;
    sim.step(dt);
    if (sim.pouring != _pourSnd) {
      _pourSnd = sim.pouring;
      Sfx.pour(_pourSnd);
    }
    for (final p in _puffs) {
      p.t += dt;
    }
    _puffs.removeWhere((p) => p.t > .45);
    if (!_ready && sim.pourDone && sim.time > sim.pourDuration + .9) {
      sim.markInitialFill();
      _ready = true;
    }
    if (_ready && !_ended) {
      final spilled = sim.initialFill > 0 && sim.retained < .55;
      final lost = px(sim.glasses[0].position).dy > 1400;
      if (spilled || lost) {
        _fail();
      } else if (sim.glassOnGround && sim.retained >= .6) {
        if (_countdown < 0) {
          _countdown = 3;
          _lastTick = 4;
        }
      } else if (_countdown >= 0) {
        _countdown = -1;
        setState(() {});
      }
      if (_countdown >= 0) {
        _countdown -= dt;
        final n = _countdown.ceil();
        if (n != _lastTick && n > 0) {
          _lastTick = n;
          Sfx.play('tick');
          setState(() {});
        }
        if (_countdown <= 0) _win();
      }
    }
    final full = sim.countIn(0) >= kFillTarget * .8;
    _opts.exprs = [
      _ended && _countdown <= 0 && !_dark ? Expr.happy : (_ready && !sim.glassUpright ? Expr.worried : (full ? Expr.happy : Expr.surprised))
    ];
    _frame.value++;
  }

  void _win() {
    Ads.levelCompleted();
    _ended = true;
    _countdown = -1;
    Sfx.play('win');
    final d = GameData.I;
    if (widget.level >= d.dsLevel) d.dsLevel = math.min(widget.level + 1, kDsCount + 1);
    d.save();
    Future.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(RewardCompleted(
        reward: 5,
        title: 'COMPLETED!',
        counter: '${widget.level}/$kDsCount',
        onBack: () => Navigator.of(context).maybePop(),
        onNext: (ctx) {
          final next = widget.level + 1;
          if (next > kDsCount) {
            Navigator.of(ctx).pop();
          } else {
            Navigator.of(ctx).pushReplacement(fadeRoute(DontSpillScreen(level: next)));
          }
        },
      )));
    });
  }

  void _fail() {
    _ended = true;
    _countdown = -1;
    Sfx.play('splash');
    setState(() => _dark = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(_reset);
    });
  }

  void _tap(Offset p) {
    if (_ended || !_ready) return;
    final b = sim.brickAt(p);
    if (b == null) return;
    _puffs.add(_Puff(px(b.position)));
    sim.removeBrick(b);
    _bubble = false;
    _hint = false;
    Sfx.play('pop');
    setState(() {});
  }

  /// Hint: point at the brick directly under the glass.
  Offset? get _hintTarget {
    if (!_hint || sim.bricks.isEmpty) return null;
    final g = px(sim.glasses[0].position);
    final under = sim.bricks.map((b) => px(b.position)).where((p) => p.dy > g.dy).toList()..sort((a, b) => a.dy.compareTo(b.dy));
    return under.isEmpty ? px(sim.bricks.first.position) : under.first;
  }

  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    _opts
      ..skin = glassSkins[d.glass]
      ..water = waterColors[d.water];
    return DesignScreen(
      child: Stack(children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (e) => _tap(e.localPosition),
            child: RepaintBoundary(child: CustomPaint(painter: _DsPainter(this))),
          ),
        ),
        Positioned(
          left: 10,
          right: 14,
          top: 36,
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            BackArrow(onTap: () => Navigator.of(context).pop()),
            Tap(onTap: () => setState(_reset), child: const PaintBox(64, 70, _restartIcon)),
            const Spacer(),
            const Padding(padding: EdgeInsets.only(top: 8), child: CoinCounter(size: 44)),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Tap(
                onTap: () async {
                  if (await watchRewardAd(context)) setState(() => _hint = true);
                },
                child: const PaintBox(140, 64, _hintPill),
              ),
              Text('${widget.level}/$kDsCount', style: txt(40, w: FontWeight.w500, sp: 6)),
            ]),
          ]),
        ),
        if (_countdown > 0)
          Positioned(
            left: 208,
            top: px(sim.glasses[0].position).dy - 96,
            child: IgnorePointer(child: CountdownBox(_countdown.ceil().clamp(1, 3))),
          ),
        if (_dark) const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x77000000)))),
      ]),
    );
  }
}

class _DsPainter extends CustomPainter {
  final _DontSpillState s;
  _DsPainter(this.s) : super(repaint: s._frame);
  @override
  void paint(Canvas c, Size size) {
    s._opts.t = s._t;
    paintSim(c, s.sim, s._opts);
    for (final p in s._puffs) {
      final k = p.t / .45;
      for (var i = 0; i < 6; i++) {
        final a = i * math.pi / 3;
        c.drawCircle(p.at + Offset(math.cos(a), math.sin(a)) * (10 + 22 * k), 7 * (1 - k) + 1, fillP(const Color(0xFFBDBDBD).withOpacity(1 - k)));
      }
    }
    final g = px(s.sim.glasses[0].position);
    if (s._bubble) {
      final r = RRect.fromRectAndRadius(Rect.fromCenter(center: g + const Offset(0, -180), width: 200, height: 104), const Radius.circular(10));
      c.drawRRect(r, fillP(Colors.white));
      c.drawRRect(r, strokeP(const Color(0xFF333333), 2));
      final tail = Path()
        ..moveTo(g.dx - 10, r.bottom)
        ..lineTo(g.dx, r.bottom + 14)
        ..lineTo(g.dx + 10, r.bottom);
      c.drawPath(tail, fillP(Colors.white));
      c.drawPath(tail, strokeP(const Color(0xFF333333), 2));
      final tp = TextPainter(
          text: TextSpan(text: 'HELP ME TO\nREACH THE\nBOTTOM', style: txt(17, w: FontWeight.w600, sp: 3, h: 1.5)),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(c, r.center - Offset(tp.width / 2, tp.height / 2));
    }
    final ht = s._bubble && s._ready ? (s.sim.bricks.isEmpty ? null : px(s.sim.bricks.last.position)) : s._hintTarget;
    if (ht != null) _hand(c, ht + Offset(0, math.sin(s._t * 6) * 6));
  }

  @override
  bool shouldRepaint(covariant _DsPainter old) => true;
}

/// Pointing hand used by the tap tutorial and the hint.
void _hand(Canvas c, Offset tip) {
  final p = Path()
    ..moveTo(tip.dx, tip.dy)
    ..lineTo(tip.dx + 9, tip.dy - 2)
    ..lineTo(tip.dx + 12, tip.dy + 30)
    ..quadraticBezierTo(tip.dx + 26, tip.dy + 22, tip.dx + 30, tip.dy + 32)
    ..quadraticBezierTo(tip.dx + 44, tip.dy + 28, tip.dx + 46, tip.dy + 40)
    ..quadraticBezierTo(tip.dx + 60, tip.dy + 36, tip.dx + 60, tip.dy + 50)
    ..lineTo(tip.dx + 58, tip.dy + 76)
    ..quadraticBezierTo(tip.dx + 50, tip.dy + 96, tip.dx + 26, tip.dy + 96)
    ..quadraticBezierTo(tip.dx + 6, tip.dy + 90, tip.dx - 10, tip.dy + 60)
    ..lineTo(tip.dx - 18, tip.dy + 44)
    ..quadraticBezierTo(tip.dx - 16, tip.dy + 36, tip.dx - 6, tip.dy + 42)
    ..lineTo(tip.dx + 2, tip.dy + 52)
    ..close();
  c.drawPath(p, fillP(Colors.white));
  c.drawPath(p, strokeP(const Color(0xFF222222), 2.4));
}

void _restartIcon(Canvas c, Size s) {
  final p = strokeP(const Color(0xFF222222), 2.4);
  final o = Offset(s.width / 2, s.height / 2);
  c.drawArc(Rect.fromCircle(center: o, radius: 18), math.pi * .15, math.pi * 1.6, false, p);
  c.drawArc(Rect.fromCircle(center: o, radius: 10), math.pi * .15, math.pi * 1.6, false, p);
  final a = Path()
    ..moveTo(o.dx + 24, o.dy - 4)
    ..lineTo(o.dx + 14, o.dy + 10)
    ..lineTo(o.dx + 5, o.dy - 4)
    ..close();
  c.drawPath(a, fillP(Colors.white));
  c.drawPath(a, p);
}

void _hintPill(Canvas c, Size s) {
  final r = RRect.fromRectAndRadius(const Rect.fromLTWH(2, 8, 120, 46), const Radius.circular(23));
  c.drawRRect(r, fillP(C.btnBlue));
  c.drawRRect(r, strokeP(const Color(0xFF222222), 2));
  drawBulb(c, const Offset(24, 30), 30);
  final tp = TextPainter(text: TextSpan(text: 'HINT', style: txt(17, w: FontWeight.w700, c: Colors.white, sp: 1)), textDirection: TextDirection.ltr)..layout();
  tp.paint(c, Offset(44, 31 - tp.height / 2));
  const b = Rect.fromLTWH(106, 22, 32, 32);
  c.drawRect(b, fillP(C.coin));
  c.drawRect(b, strokeP(const Color(0xFF222222), 2));
  c.drawPath(
      Path()
        ..moveTo(116, 29)
        ..lineTo(116, 47)
        ..lineTo(131, 38)
        ..close(),
      strokeP(const Color(0xFF222222), 2));
}
