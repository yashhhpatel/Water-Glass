import 'dart:math' as math;
import 'dart:ui';

import 'hints.g.dart';
import 'level.dart';

const int kClassicCount = 1000;
const int kChallengeCount = 12;
const int kDsCount = 20;

/// Boss levels appear after classic levels 5, 25, 45, ... (50 bosses).
const int kBossCount = 50;
bool hasBossAfter(int level) => level % 20 == 5 && level <= kClassicCount;
int bossIndexAfter(int level) => (level - 5) ~/ 20;

Obj _seg(Offset a, Offset b, {double t = 7}) {
  final d = b - a;
  return Obj.rect((a.dx + b.dx) / 2, (a.dy + b.dy) / 2, d.distance, t, angle: math.atan2(d.dy, d.dx) * 180 / math.pi);
}

/// Classic levels 1-11 are recreated from the reference footage; the rest are
/// built from the same building blocks.
/// Public level getters apply the solver output (tool/solve_levels_test.dart):
/// a layout variant for generated levels and a verified hint path.
LevelDef classicLevel(int n) => _solved('c$n', classicLevelRaw(n, kVariants['c$n'] ?? 0));
LevelDef bossLevel(int k) => _solved('b$k', bossLevelRaw(k, kVariants['b$k'] ?? 0));
LevelDef challengeLevel(int i) => _solved('x$i', challengeLevelRaw(i, kVariants['x$i'] ?? 0));

LevelDef _solved(String key, LevelDef d) {
  final h = kSolvedHints[key];
  return h == null ? d : d.withHint(h);
}

LevelDef classicLevelRaw(int n, [int variant = 0]) {
  switch (n) {
    case 1:
      return const LevelDef(
        faucets: [FaucetDef(286, 566, amount: 140)],
        glasses: [GlassDef(210, 759), GlassDef(362, 759)],
        objs: [
          Obj.rect(212, 803, 100, 10),
          Obj.rect(260, 763, 8, 90),
          Obj.rect(360, 803, 100, 10),
          Obj.rect(312, 763, 8, 90),
        ],
        hint: [
          [Offset(244, 708), Offset(328, 708)]
        ],
        tutorial: true,
      );
    case 2:
      return const LevelDef(
        faucets: [FaucetDef(289, 494)],
        glasses: [GlassDef(289, 580)],
        objs: [
          Obj.rect(173, 681, 140, 17),
          Obj.rect(403, 681, 140, 17),
          Obj.poly([Offset(131, 903), Offset(333, 770), Offset(576, 770), Offset(576, 903)]),
        ],
        hint: [
          [Offset(238, 668), Offset(340, 668)]
        ],
      );
    case 3:
      return LevelDef(
        faucets: const [FaucetDef(206, 568)],
        glasses: const [GlassDef(206, 662)],
        objs: [_seg(const Offset(140, 744), const Offset(404, 840))],
        hint: const [
          [Offset(172, 548), Offset(206, 528), Offset(240, 556), Offset(252, 640), Offset(236, 708), Offset(178, 714), Offset(162, 690)]
        ],
      );
    case 4:
      return const LevelDef(
        faucets: [FaucetDef(286, 556)],
        glasses: [GlassDef(286, 662)],
        objs: [
          Obj.rect(240, 690, 20, 20),
          Obj.rect(332, 690, 20, 20),
          Obj.rect(240, 752, 20, 20),
          Obj.rect(332, 752, 20, 20),
        ],
        hint: [
          [Offset(226, 736), Offset(286, 756), Offset(346, 736)]
        ],
      );
    case 5:
      return const LevelDef(
        faucets: [FaucetDef(286, 548)],
        glasses: [GlassDef(286, 650)],
        objs: [Obj.rect(230, 760, 96, 40), Obj.rect(380, 760, 44, 40)],
        hint: [
          [Offset(270, 738), Offset(368, 738)]
        ],
      );
    case 6:
      return const LevelDef(
        faucets: [FaucetDef(286, 572)],
        glasses: [GlassDef(286, 720)],
        objs: [Obj.rect(346, 700, 28, 28)],
        hint: [
          [Offset(256, 556), Offset(236, 640), Offset(242, 772), Offset(290, 792), Offset(334, 772), Offset(330, 742)]
        ],
      );
    case 7:
      return const LevelDef(
        faucets: [FaucetDef(288, 556)],
        glasses: [GlassDef(288, 700)],
        objs: [Obj.rect(226, 786, 140, 6), Obj.rect(342, 758, 92, 6)],
        hint: [
          [Offset(238, 750), Offset(300, 750)]
        ],
      );
    case 8:
      return const LevelDef(
        faucets: [FaucetDef(286, 528)],
        glasses: [GlassDef(288, 738)],
        objs: [
          Obj.rect(288, 572, 44, 6),
          Obj.poly([Offset(160, 640), Offset(200, 604), Offset(200, 640)]),
          Obj.rect(184, 643, 140, 6),
          Obj.rect(391, 643, 142, 6),
          Obj.rect(287, 779, 330, 6),
        ],
        hint: [
          [Offset(318, 590), Offset(314, 640), Offset(306, 694)],
          [Offset(256, 590), Offset(262, 640), Offset(270, 694)],
        ],
      );
    case 9:
      return const LevelDef(
        faucets: [FaucetDef(288, 572)],
        glasses: [GlassDef(288, 690)],
        objs: [Obj.circle(214, 790, 14), Obj.circle(288, 790, 14)],
        hint: [
          [Offset(232, 748), Offset(288, 762), Offset(344, 748)]
        ],
      );
    case 10:
      return const LevelDef(
        faucets: [FaucetDef(360, 556, dir: 1)],
        glasses: [GlassDef(300, 700)],
        objs: [Obj.rect(262, 790, 28, 28, angle: 45), Obj.rect(314, 790, 28, 28, angle: 45)],
        hint: [
          [Offset(376, 578), Offset(352, 620), Offset(330, 660)]
        ],
      );
    case 11:
      return const LevelDef(
        faucets: [FaucetDef(270, 556)],
        glasses: [GlassDef(278, 640)],
        objs: [
          Obj.rect(110, 725, 220, 70),
          Obj.rect(214, 674, 12, 32),
          Obj.poly([Offset(336, 760), Offset(380, 690), Offset(576, 690), Offset(576, 760)]),
        ],
        hint: [
          [Offset(212, 700), Offset(344, 700)]
        ],
      );
  }
  return _generated(n, variant);
}

/// Bag-shaped hint around faucet and glass (works for most layouts).
List<List<Offset>> _bagHint(double fx, double fy, double gx, double gy) => [
      [
        Offset(fx - 34, fy - 26),
        Offset(math.min(fx, gx) - 50, (fy + gy) / 2),
        Offset(gx - 44, gy + 48),
        Offset(gx, gy + 56),
        Offset(gx + 44, gy + 48),
        Offset(math.max(fx, gx) + 50, (fy + gy) / 2),
        Offset(fx + 30, fy - 20),
      ]
    ];

/// Difficulty 0..1: 0 at level 12, 1 at level 1000 (levels 1-11 come from the
/// reference footage). The curve is gentle at first and steadier later.
double difficultyOf(int n) => n <= 11 ? 0 : math.pow((n - 11) / (kClassicCount - 11), 0.9).toDouble();

const List<String> kTierNames = ['EASY', 'MEDIUM', 'HARD', 'VERY HARD'];

/// Easy 1-150, Medium 151-450, Hard 451-800, Very Hard 801-1000.
int tierOf(int n) => n <= 150 ? 0 : (n <= 450 ? 1 : (n <= 800 ? 2 : 3));

Rect _bounds(Obj o) {
  switch (o.kind) {
    case ObjKind.poly:
      var l = double.infinity, t = double.infinity, r = -double.infinity, b = -double.infinity;
      for (final p in o.pts) {
        l = math.min(l, p.dx);
        t = math.min(t, p.dy);
        r = math.max(r, p.dx);
        b = math.max(b, p.dy);
      }
      return Rect.fromLTRB(l, t, r, b);
    case ObjKind.circle:
      return Rect.fromCircle(center: Offset(o.x, o.y), radius: o.r);
    case ObjKind.cross:
      return Rect.fromCenter(center: Offset(o.x, o.y), width: o.w, height: o.w);
    case ObjKind.rect:
      final a = o.angle * math.pi / 180;
      final hw = (o.w / 2 * math.cos(a)).abs() + (o.h / 2 * math.sin(a)).abs();
      final hh = (o.w / 2 * math.sin(a)).abs() + (o.h / 2 * math.cos(a)).abs();
      return Rect.fromCenter(center: Offset(o.x, o.y), width: hw * 2, height: hh * 2);
  }
}

double _lerp(double a, double b, double t) => a + (b - a) * t;

/// Generated classic level [n]. [variant] re-rolls the layout (used by the
/// solver when a roll is unsolvable or trivial); later variants ease off a
/// little so every level ends up solvable.
LevelDef _generated(int n, [int variant = 0, int salt = 0]) {
  final r = math.Random(n * 7919 + 13 + variant * 104723 + salt * 15485863);
  double rr(double a, double b) => a + r.nextDouble() * (b - a);
  // variants 0-11 ease a little more each roll; the extra retry rolls (12+)
  // keep a moderate ease so a level never drops out of its tier
  final ease = variant <= 11 ? 1 - 0.06 * math.max(0, variant - 3) : 0.55;
  final d = (difficultyOf(n) * ease).clamp(0.0, 1.0);
  final objs = <Obj>[];
  final taken = <Rect>[];
  bool place(Obj o, {bool force = false}) {
    final b = _bounds(o);
    if (!force && taken.any((t) => t.overlaps(b.inflate(6)))) return false;
    objs.add(o);
    taken.add(b);
    return true;
  }

  T pick<T>(List<T> items, List<double> easyW, List<double> hardW) {
    final w = [for (var i = 0; i < items.length; i++) math.max(0.0, _lerp(easyW[i], hardW[i], d))];
    var x = r.nextDouble() * w.fold<double>(0, (a, b) => a + b);
    for (var i = 0; i < items.length; i++) {
      x -= w[i];
      if (x <= 0) return items[i];
    }
    return items.last;
  }

  // ---------------------------------------------------------------- two glasses
  if (r.nextDouble() < _lerp(0.04, 0.24, d)) {
    final cx = rr(250, 326), sep = rr(150, _lerp(185, 250, d));
    final gy1 = rr(660, 760), gy2 = gy1 + (d > .35 ? rr(-70, 70) * d : 0);
    final gl = [GlassDef(cx - sep / 2, gy1), GlassDef(cx + sep / 2, gy2)];
    for (final g in gl) {
      final inner = g.x < cx ? 1.0 : -1.0;
      place(Obj.rect(g.x, g.y + 44, 100, 10), force: true);
      place(Obj.rect(g.x + inner * 50, g.y + 4, 8, 90), force: true);
    }
    final fx = cx + rr(-1, 1) * _lerp(4, 70, d);
    final fy = math.max(440.0, math.min(gy1, gy2) - rr(130, _lerp(170, 270, d)));
    if (d > .3 && r.nextDouble() < d) {
      // a bar under the faucet that throws water to one side
      final s = r.nextBool() ? 1.0 : -1.0;
      place(_seg(Offset(fx - s * 34, fy + 70), Offset(fx + s * 40, fy + 92)), force: true);
    }
    return LevelDef(
      faucets: [FaucetDef(fx, fy, amount: 140)],
      glasses: gl,
      objs: objs,
      ink: _lerp(1250, 850, d),
    );
  }

  // ---------------------------------------------------------------- one glass
  final gx = rr(140, 436);
  final gy = rr(_lerp(600, 640, d), _lerp(700, 800, d));
  final s = r.nextBool() ? 1.0 : -1.0; // faucet -> glass direction
  final off = rr(0, _lerp(30, 210, d));
  final sidePipe = off > 70 && r.nextDouble() < _lerp(.04, .22, d);
  var fx = gx - s * off;
  fx = sidePipe ? (s > 0 ? fx.clamp(160.0, 470.0) : fx.clamp(106.0, 416.0)) : fx.clamp(80.0, 496.0);
  final fy = (gy - rr(_lerp(110, 150, d), _lerp(150, 320, d))).clamp(440.0, gy - 100);
  final dir = sidePipe ? (s > 0 ? 2 : 1) : 0;
  taken.add(Rect.fromCenter(center: Offset(gx, gy), width: 84, height: 92));
  taken.add(dir == 0
      ? Rect.fromLTWH(fx - 26, fy - 32, 52, 48)
      : Rect.fromLTRB(math.min(fx, fx - s * 150), fy - 16, math.max(fx, fx - s * 150), fy + 16));

  // how the glass is held up
  final support = pick(
    ['platform', 'gap', 'slope', 'pegs', 'balls', 'float', 'tilted', 'diamonds'],
    [3, 3, 2, 2, 1, 1, .5, .5],
    [.3, 2, 2, 1, 2, 2, 2.2, 2],
  );
  switch (support) {
    case 'platform':
      place(Obj.rect(gx + rr(-10, 10), gy + 44, rr(90, 120), 10), force: true);
      break;
    case 'gap':
      final py = gy + rr(60, _lerp(80, 160, d)), gap = rr(_lerp(80, 96, d), _lerp(100, 140, d));
      place(Obj.rect(gx - gap / 2 - 70, py, 140, 14), force: true);
      place(Obj.rect(gx + gap / 2 + 70, py, 140, 14), force: true);
      break;
    case 'slope':
      final a = rr(_lerp(8, 18, d), _lerp(18, 34, d)) * (r.nextBool() ? 1 : -1) * math.pi / 180;
      final c = Offset(gx + rr(-25, 25), gy + rr(70, 110));
      place(_seg(c - Offset(math.cos(a), math.sin(a)) * 130, c + Offset(math.cos(a), math.sin(a)) * 130), force: true);
      break;
    case 'pegs':
      for (final dx in [-46.0, 46.0]) {
        for (final dy in [28.0, 90.0]) {
          place(Obj.rect(gx + dx, gy + dy, 20, 20), force: true);
        }
      }
      break;
    case 'balls':
      final cy = gy + rr(85, 120);
      place(Obj.circle(gx - 40, cy, 14), force: true);
      place(Obj.circle(gx + rr(-6, 6), cy + 4, 14), force: true);
      if (r.nextBool()) place(Obj.circle(gx + 42, cy - 6, 14), force: true);
      break;
    case 'tilted':
      place(Obj.rect(gx, gy + 46, 84, 10, angle: (r.nextBool() ? 1 : -1) * rr(_lerp(10, 16, d), _lerp(16, 30, d))), force: true);
      break;
    case 'diamonds':
      final dy = rr(85, 110);
      place(Obj.rect(gx - 26, gy + dy, 28, 28, angle: 45), force: true);
      place(Obj.rect(gx + 26, gy + dy, 28, 28, angle: 45), force: true);
      break;
    default: // float: nothing under the glass
      break;
  }

  // things in the water's way (more of them as levels get harder)
  final hurdles = math.min(4, (_lerp(0, 3.4, d) + r.nextDouble() * .8).floor());
  for (var i = 0; i < hurdles; i++) {
    final kind = pick(
      ['deflector', 'roof', 'wall', 'block', 'spinner'],
      [1, 1, .6, 1, 0],
      [1.2, 1, 1.2, .8, 1.4],
    );
    switch (kind) {
      case 'deflector':
        if (dir != 0) break;
        final h = rr(60, 120);
        place(_seg(Offset(fx + s * 30, fy + h), Offset(fx - s * 45, fy + h + rr(20, 34))), force: true);
        break;
      case 'roof':
        place(Obj.rect(gx + rr(-1, 1) * rr(10, 30), gy - rr(76, 110), rr(60, 90), 8));
        break;
      case 'wall':
        if (off < 60) break;
        final wx = gx - s * rr(55, 75);
        place(_seg(Offset(wx, gy - rr(20, 60)), Offset(wx, gy + 50)));
        break;
      case 'block':
        final sz = rr(30, 50);
        place(Obj.rect((fx + gx) / 2 + rr(-30, 30), (fy + gy) / 2 + rr(-30, 30), sz, sz, angle: rr(0, 45)));
        break;
      default:
        final spin = (r.nextBool() ? 1 : -1) * rr(1.6, 2.0 + d);
        if (r.nextBool()) {
          place(Obj.cross(gx + s * rr(80, 110), gy - rr(10, 60), 50, spin: spin));
        } else {
          place(Obj.cross(fx - s * rr(60, 80), fy + rr(80, 120), 46, spin: spin));
        }
    }
  }
  // scenery blocks high up on harder levels
  if (d > .35 && r.nextDouble() < d) {
    place(Obj.rect(rr(80, 496), rr(300, 380), rr(70, 130), rr(50, 90), angle: rr(10, 70)));
  }
  return LevelDef(
    faucets: [FaucetDef(fx, fy, dir: dir, amount: (72 - 12 * d).round())],
    glasses: [GlassDef(gx, gy)],
    objs: objs,
    ink: _lerp(1150, 700, d),
    hint: _bagHint(fx, fy, gx, gy),
  );
}

/// Boss levels (two lives, spinning blades).
LevelDef bossLevelRaw(int k, [int variant = 0]) {
  if (k == 0) {
    return const LevelDef(
      faucets: [FaucetDef(189, 560, amount: 100)],
      glasses: [GlassDef(300, 761)],
      objs: [
        Obj.rect(166, 690, 46, 46),
        Obj.rect(212, 644, 46, 46),
        Obj.cross(270, 662, 54, spin: 2.2),
        Obj.cross(330, 662, 54, spin: -2.2),
        Obj.rect(300, 803, 64, 6),
      ],
      hint: [
        [Offset(150, 612), Offset(250, 616), Offset(300, 640)]
      ],
    );
  }
  // a boss follows the difficulty of the level it comes after, plus blades
  final level = 5 + 20 * k;
  final base = _generated(level, variant, 31); // own seed, same difficulty as its level
  final g = base.glasses.first;
  final spin = 1.8 + difficultyOf(level) * .8;
  return LevelDef(
    faucets: [for (final f in base.faucets) FaucetDef(f.x, f.y, dir: f.dir, amount: base.glasses.length > 1 ? 160 : 100)],
    glasses: base.glasses,
    objs: [...base.objs, Obj.cross(g.x - 62, g.y - 66, 48, spin: spin), Obj.cross(g.x + 62, g.y - 66, 48, spin: -spin)],
    ink: base.ink,
    hint: base.hint,
  );
}

/// Challenge levels (three lives).
LevelDef challengeLevelRaw(int i, [int variant = 0]) {
  if (i == 0) {
    // corners measured from the reference footage
    return LevelDef(
      faucets: const [FaucetDef(390, 546)],
      glasses: const [GlassDef(206, 708, angle: 37)],
      objs: [
        const Obj.poly([Offset(237, 173), Offset(451, 352), Offset(271, 567), Offset(56, 387)]),
        const Obj.poly([Offset(20, 428), Offset(236, 607), Offset(150, 712), Offset(-66, 533)]),
        const Obj.poly([Offset(-89, 522), Offset(222, 778), Offset(72, 957), Offset(-239, 701)]),
        _seg(const Offset(326, 680), const Offset(600, 346)),
        _seg(const Offset(326, 680), const Offset(600, 680)),
      ],
      hint: const [
        [Offset(398, 572), Offset(300, 630), Offset(250, 664)]
      ],
    );
  }
  final r = math.Random(i * 104729 + variant * 7907);
  double rr(double a, double b) => a + r.nextDouble() * (b - a);
  // Faucet off to one side of the glass; spinning blades sit beside the
  // water's path (not on it) so a ramp or a hooked chute can get past them.
  final fx = rr(150, 426), fy = rr(430, 500);
  final s = fx < 288 ? 1.0 : -1.0; // direction from faucet towards the glass
  final gx = (fx + s * rr(90, 170)).clamp(110.0, 466.0), gy = rr(650, 750);
  final objs = <Obj>[
    Obj.rect(rr(120, 456), rr(200, 250), rr(120, 160), rr(100, 140), angle: rr(20, 70)),
    Obj.rect(gx, gy + 46, 90, 10, angle: rr(-10, 10)),
    Obj.cross(gx + s * 100, gy - 30, 54, spin: i.isEven ? 2.0 : -2.0),
  ];
  if (i > 4) objs.add(Obj.cross(fx - s * 80, fy + 110, 46, spin: -2.4));
  if (i > 7) objs.add(_seg(Offset(fx + s * 20, fy + 120), Offset(fx - s * 90, fy + 160)));
  return LevelDef(
    faucets: [FaucetDef(fx, fy)],
    glasses: [GlassDef(gx, gy)],
    objs: objs,
    ink: 1000,
    hint: _bagHint(fx, fy, gx, gy),
  );
}

const double kGround = 782;

/// Don't Spill levels: tap bricks away to lower the filled glass to the red line.
LevelDef dsLevel(int n) {
  final objs = <Obj>[];
  double top = kGround;
  void brick(double x, double w, double h) => objs.add(Obj.rect(x, top - h / 2, w, h, dyn: true, tappable: true, color: 1));
  if (n == 1) {
    for (var i = 0; i < 4; i++) {
      brick(288, 94, 27);
      top -= 27;
    }
  } else if (n == 2) {
    for (var i = 0; i < 5; i++) {
      objs.add(Obj.rect(252 + i * 18.0, top - 26, 16, 52, dyn: true, tappable: true, color: 1));
    }
    top -= 52;
    brick(288, 130, 14);
    top -= 14;
    objs.add(Obj.rect(245, top - 20, 14, 40, dyn: true, tappable: true, color: 1));
    objs.add(Obj.rect(331, top - 20, 14, 40, dyn: true, tappable: true, color: 1));
    objs.add(Obj.circle(288, top - 18, 18, dyn: true, tappable: true, color: 1));
    top -= 40;
    brick(288, 130, 14);
    top -= 14;
    brick(288, 44, 20);
    top -= 20;
  } else {
    final r = math.Random(n * 31337);
    final layers = 3 + math.min(5, n ~/ 3);
    for (var l = 0; l < layers; l++) {
      switch (r.nextInt(5)) {
        case 0: // row of uprights
          final cnt = 3 + r.nextInt(3);
          for (var i = 0; i < cnt; i++) {
            objs.add(Obj.rect(288 + (i - (cnt - 1) / 2) * 20, top - 24, 16, 48, dyn: true, tappable: true, color: 1));
          }
          top -= 48;
          break;
        case 1: // plank
          brick(288, 120 + r.nextDouble() * 30, 14);
          top -= 14;
          break;
        case 2: // posts with a ball
          objs.add(Obj.rect(246, top - 20, 14, 40, dyn: true, tappable: true, color: 1));
          objs.add(Obj.rect(330, top - 20, 14, 40, dyn: true, tappable: true, color: 1));
          objs.add(Obj.circle(288, top - 18, 18, dyn: true, tappable: true, color: 1));
          top -= 40;
          brick(288, 130, 14);
          top -= 14;
          break;
        case 3: // two side bricks + plank
          objs.add(Obj.rect(250, top - 15, 40, 30, dyn: true, tappable: true, color: 1));
          objs.add(Obj.rect(326, top - 15, 40, 30, dyn: true, tappable: true, color: 1));
          top -= 30;
          brick(288, 124, 14);
          top -= 14;
          break;
        default: // solid block
          brick(288, 70 + r.nextDouble() * 30, 28);
          top -= 28;
      }
    }
    brick(288, 50, 18);
    top -= 18;
  }
  return LevelDef(
    faucets: [FaucetDef(288, top - 110, amount: 38)],
    glasses: [GlassDef(288, top - 38)],
    objs: objs,
    groundY: kGround,
    ink: 0,
  );
}
