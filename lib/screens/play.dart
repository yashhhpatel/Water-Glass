import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../core/audio.dart';
import '../core/catalog.dart';
import '../core/data.dart';
import '../core/theme.dart';
import '../game/level.dart';
import '../game/levels.dart';
import '../game/render.dart';
import '../game/sim.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'bottle.dart';
import 'challenges.dart';
import 'completed.dart';
import 'dialogs.dart';
import 'home.dart';
import 'level_packs.dart';
import 'shop.dart';
import 'store.dart';

enum PlayMode { classic, boss, challenge }

class PlayScreen extends StatefulWidget {
  final PlayMode mode;
  final int index; // classic level number, boss index or challenge index
  const PlayScreen({super.key, this.mode = PlayMode.classic, required this.index});
  @override
  State<PlayScreen> createState() => _PlayScreenState();
}

enum _Phase { play, won, failed }

class _PlayScreenState extends State<PlayScreen> with SingleTickerProviderStateMixin {
  late LevelDef def;
  late Sim sim;
  late final Ticker _ticker;
  final RenderOpts _opts = RenderOpts();
  final ValueNotifier<int> _frame = ValueNotifier(0);
  Duration _last = Duration.zero;
  double _t = 0;

  _Phase phase = _Phase.play;
  List<Offset>? _cur;
  Offset? _pen;
  double ink = 1;
  double inkMax = 1;
  double? _pourDoneAt;
  double _countdown = -1;
  int _lastTick = 0;
  double _wonAt = 0;
  double _drawSnd = 0;
  bool _hintOn = false;
  double _hintT = 0;
  int hearts = 0;
  int heartsMax = 0;
  bool _fade = false;
  bool _dark = false;
  bool _pourSnd = false;

  bool get classic => widget.mode == PlayMode.classic;

  @override
  void initState() {
    super.initState();
    def = switch (widget.mode) {
      PlayMode.classic => classicLevel(widget.index),
      PlayMode.boss => bossLevel(widget.index),
      PlayMode.challenge => challengeLevel(widget.index),
    };
    heartsMax = widget.mode == PlayMode.boss ? 2 : (widget.mode == PlayMode.challenge ? 3 : 0);
    hearts = heartsMax;
    _reset();
    _ticker = createTicker(_tick)..start();
  }

  void _reset() {
    sim = Sim(def);
    inkMax = def.ink;
    ink = def.ink;
    phase = _Phase.play;
    _cur = null;
    _pen = null;
    _pourDoneAt = null;
    _countdown = -1;
    _hintOn = def.tutorial;
    _hintT = 0;
    _fade = false;
    _dark = false;
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
    if (_hintOn) _hintT += dt;
    sim.step(dt);
    final pouring = sim.pouring;
    if (pouring != _pourSnd) {
      _pourSnd = pouring;
      Sfx.pour(pouring);
    }
    if (phase == _Phase.play && sim.running) {
      if (sim.allFull) {
        _win();
      } else if (sim.pourDone) {
        _pourDoneAt ??= sim.time;
        if (_countdown < 0 && sim.time - _pourDoneAt! > 1.2) {
          _countdown = 3;
          _lastTick = 4;
        }
      }
      if (_countdown >= 0 && phase == _Phase.play) {
        _countdown -= dt;
        final n = _countdown.ceil();
        if (n != _lastTick && n > 0) {
          _lastTick = n;
          Sfx.play('tick');
          setState(() {});
        }
        if (_countdown <= 0) _fail();
      }
    }
    if (phase == _Phase.won && _t - _wonAt > 1.3 && !_fade) {
      _fade = true;
      setState(() {});
      Future.delayed(const Duration(milliseconds: 350), _afterWin);
    }
    // faces
    _opts.exprs = [
      for (var i = 0; i < sim.glasses.length; i++)
        phase == _Phase.won || sim.countIn(i) >= kFillTarget
            ? Expr.happy
            : (sim.countIn(i) > 0 || (sim.running && sim.waterNear(i)) ? Expr.surprised : Expr.sad)
    ];
    _frame.value++;
  }

  int get _stars => classic ? InkBar.starsFor(inkMax == 0 ? 1 : ink / inkMax) : 3;

  void _win() {
    phase = _Phase.won;
    _wonAt = _t;
    _countdown = -1;
    Sfx.play('win');
    setState(() {});
  }

  void _fail() {
    if (phase != _Phase.play) return;
    phase = _Phase.failed;
    _countdown = -1;
    Sfx.play('fail');
    Sfx.pour(false);
    setState(() => _dark = true);
    Future.delayed(const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      if (heartsMax > 0) {
        hearts--;
        if (hearts <= 0) {
          setState(() {});
          final again = await showTryAgain(context);
          if (!mounted) return;
          if (again) {
            hearts = 3;
            heartsMax = math.max(heartsMax, 3);
          } else {
            _giveUp();
            return;
          }
        }
      }
      setState(_reset);
    });
  }

  void _giveUp() {
    if (widget.mode == PlayMode.boss) {
      GameData.I.bossesDone.add(widget.index);
      GameData.I.save();
      _replace(PlayScreen(index: math.min(GameData.I.level, kClassicCount)));
    } else {
      _replace(const ChallengesScreen());
    }
  }

  void _replace(Widget w) => Navigator.of(context).pushReplacement(fadeRoute(w));

  Future<void> _afterWin() async {
    if (!mounted) return;
    Sfx.pour(false);
    final d = GameData.I;
    switch (widget.mode) {
      case PlayMode.classic:
        final n = widget.index;
        final stars = _stars;
        if (stars > (d.stars[n] ?? 0)) d.stars[n] = stars;
        if (n >= d.level) d.level = math.min(n + 1, kClassicCount + 1);
        d.levelsSinceOffer++;
        d.save();
        var finalStars = stars;
        if (stars < 3) {
          final collect = await showCollectStars(context, stars);
          if (!mounted) return;
          if (collect) {
            finalStars = 3;
            d.stars[n] = 3;
            d.save();
          }
        }
        _replace(BottleScreen(level: n, stars: finalStars));
        break;
      case PlayMode.boss:
        d.bossesDone.add(widget.index);
        d.save();
        _replace(RewardCompleted(
          reward: 250,
          title: 'COMPLETED!',
          onNext: (ctx) => Navigator.of(ctx).pushReplacement(fadeRoute(PlayScreen(index: math.min(d.level, kClassicCount)))),
        ));
        break;
      case PlayMode.challenge:
        d.challengesDone.add(widget.index);
        d.save();
        _replace(const ChallengeCompletedScreen(reward: 150));
        break;
    }
  }

  // ------------------------------------------------------------ input
  void _down(Offset p) {
    if (phase != _Phase.play || ink <= 0) return;
    if (!sim.freeAt(p)) return;
    _hintOn = false;
    _cur = [p];
    _pen = p;
    setState(() {});
  }

  void _move(Offset p) {
    final cur = _cur;
    if (cur == null) return;
    _pen = p;
    final last = cur.last;
    var d = (p - last).distance;
    if (d < 6) return;
    if (ink <= 0) return;
    var target = p;
    if (d > ink) {
      target = last + (p - last) * (ink / d);
      d = ink;
    }
    // subdivide long moves so lines never skip through thin objects
    final steps = (d / 8).ceil();
    var prev = last;
    for (var i = 1; i <= steps; i++) {
      final q = last + (target - last) * (i / steps);
      if (!sim.freeAt(q) || !sim.segmentClear(prev, q)) break;
      cur.add(q);
      ink -= (q - prev).distance;
      prev = q;
    }
    _drawSnd -= d;
    if (_drawSnd <= 0) {
      Sfx.play('draw', volume: .5);
      _drawSnd = 120;
    }
    _opts.strokes = [cur];
    setState(() {});
  }

  void _up() {
    final cur = _cur;
    if (cur == null) return;
    _cur = null;
    _pen = null;
    _opts.strokes = const [];
    if (phase == _Phase.play) {
      sim.addLine(cur, sim.lines.length);
      if (!sim.running) sim.start();
    }
    setState(() {});
  }

  void _hint() async {
    final d = GameData.I;
    if (_hintOn) return;
    if (d.hints > 0) {
      d.hints--;
      d.save();
      setState(() {
        _hintOn = true;
        _hintT = 0;
      });
    } else {
      await showMessage(context, 'Hint', 'No more hints available.');
    }
  }

  void _go(Widget w) {
    Sfx.pour(false);
    Navigator.of(context).pushAndRemoveUntil(fadeRoute(w), (r) => false);
  }

  void _push(Widget w) async {
    _ticker.muted = true;
    Sfx.pour(false);
    await Navigator.of(context).push(fadeRoute(w));
    if (mounted) {
      _ticker.muted = false;
      _last = Duration.zero;
      setState(() {});
    }
  }

  // ------------------------------------------------------------ UI
  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    _opts
      ..skin = glassSkins[d.glass]
      ..water = waterColors[d.water]
      ..ink = inks[d.ink].color
      ..hint = def.hint;
    return DesignScreen(
      child: Stack(children: [
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.opaque,
            onPointerDown: (e) => _down(e.localPosition),
            onPointerMove: (e) => _move(e.localPosition),
            onPointerUp: (e) => _up(),
            onPointerCancel: (e) => _up(),
            child: CustomPaint(painter: _WorldPainter(this)),
          ),
        ),
        Positioned(left: 30, top: 48, child: _panel()),
        Positioned(left: 0, right: 0, top: 196, child: Center(child: heartsMax > 0 ? Hearts(hearts, heartsMax) : InkBar(ink / inkMax))),
        if (_countdown > 0)
          Positioned(left: 208, top: 584, child: IgnorePointer(child: CountdownBox(_countdown.ceil().clamp(1, 3)))),
        if (_dark)
          const Positioned.fill(child: IgnorePointer(child: ColoredBox(color: Color(0x88000000)))),
        if (_fade)
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 320),
                builder: (_, v, __) => ColoredBox(color: Colors.black.withOpacity(.25 * v)),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _panel() {
    final d = GameData.I;
    final lvlNum = classic ? widget.index : 1;
    void toPacks() => _push(const LevelPacksScreen());
    switch (widget.mode) {
      case PlayMode.challenge:
        return TopPanel(children: [
          LevelBadge(widget.index + 1),
          const Spacer(),
          HintButton(hints: d.hints, onTap: _hint),
          const SizedBox(width: 24),
          PanelIcon(iconX, onTap: () => _go(const ChallengesScreen())),
        ]);
      case PlayMode.boss:
        return TopPanel(children: [
          LevelBadge(lvlNum, onTap: toPacks),
          PanelIcon(iconPencil, onTap: () => _push(const ShopScreen(tab: 0))),
          PanelIcon(iconCart, onTap: () => _push(const StoreScreen())),
          PanelIcon(iconHome, onTap: () => _go(const HomeScreen())),
          PanelIcon(iconX, dim: true, onTap: _giveUp),
        ]);
      case PlayMode.classic:
        final badge = d.completed >= 5 && !d.challengesDone.contains(0);
        return TopPanel(children: [
          LevelBadge(lvlNum, onTap: toPacks),
          PanelIcon(iconPencil, onTap: () => _push(const ShopScreen(tab: 0))),
          PanelIcon(iconCart, onTap: () => _push(const StoreScreen())),
          PanelIcon(iconHome, onTap: () => _go(const HomeScreen())),
          PanelIcon((c, s) {
            iconBrain(c, s);
            if (badge) {
              c.drawCircle(const Offset(50, 12), 9, fillP(const Color(0xFFE5402B)));
              final tp = TextPainter(text: TextSpan(text: '!', style: txt(13, w: FontWeight.w800, c: Colors.white)), textDirection: TextDirection.ltr)..layout();
              tp.paint(c, Offset(50 - tp.width / 2, 12 - tp.height / 2));
            }
          }, onTap: () => _push(const ChallengesScreen())),
          HintButton(hints: d.hints, onTap: _hint),
        ]);
    }
  }
}

class _WorldPainter extends CustomPainter {
  final _PlayScreenState s;
  _WorldPainter(this.s) : super(repaint: s._frame);
  @override
  void paint(Canvas c, Size size) {
    s._opts
      ..t = s._t
      ..hintT = s._hintOn ? s._hintT : -1;
    paintSim(c, s.sim, s._opts);
    final pen = s._pen;
    if (pen != null) drawPen(c, pen, 70, pens[GameData.I.pen].style);
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) => true;
}
