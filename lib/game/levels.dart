import 'dart:math' as math;
import 'dart:ui';

import 'level.dart';

const int kClassicCount = 60;
const int kChallengeCount = 12;
const int kDsCount = 20;

/// Boss levels appear after classic levels 5, 15, 25, ...
bool hasBossAfter(int level) => level % 10 == 5 && level <= kClassicCount;
int bossIndexAfter(int level) => (level - 5) ~/ 10;

Obj _seg(Offset a, Offset b, {double t = 7}) {
  final d = b - a;
  return Obj.rect((a.dx + b.dx) / 2, (a.dy + b.dy) / 2, d.distance, t, angle: math.atan2(d.dy, d.dx) * 180 / math.pi);
}

/// Classic levels 1-11 are recreated from the reference footage; the rest are
/// built from the same building blocks.
LevelDef classicLevel(int n) {
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
  return _generated(n);
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

LevelDef _generated(int n) {
  final r = math.Random(n * 7919 + 13);
  double rr(double a, double b) => a + r.nextDouble() * (b - a);
  final t = (n * 5 + r.nextInt(3)) % 12;
  final ink = math.max(820.0, 1150 - n * 5.0);
  var gx = rr(190, 386);
  var gy = rr(600, 700);
  var fx = gx;
  var fy = gy - rr(100, 150);
  final objs = <Obj>[];
  final faucets = <FaucetDef>[];
  final glasses = <GlassDef>[];
  switch (t) {
    case 0: // gap between two platforms
      final py = gy + 70 + rr(0, 30), gap = rr(86, 120);
      objs.add(Obj.rect(gx - gap / 2 - 75, py, 150, 16));
      objs.add(Obj.rect(gx + gap / 2 + 75, py, 150, 16));
      if (r.nextBool()) objs.add(Obj.poly([Offset(80, py + 220), Offset(240, py + 120), Offset(576, py + 120), Offset(576, py + 220)]));
      break;
    case 1: // tilted slope under the glass
      final a = rr(12, 26) * (r.nextBool() ? 1 : -1) * math.pi / 180;
      final c = Offset(gx + rr(-20, 20), gy + 90);
      objs.add(_seg(c - Offset(math.cos(a), math.sin(a)) * 140, c + Offset(math.cos(a), math.sin(a)) * 140));
      fx = gx + rr(-40, 40);
      break;
    case 2: // pegs around the glass
      for (final dx in [-46.0, 46.0]) {
        for (final dy in [28.0, 90.0]) {
          objs.add(Obj.rect(gx + dx, gy + dy, 20, 20));
        }
      }
      if (n % 2 == 0) objs.add(Obj.rect(gx, gy + 150, 20, 20));
      break;
    case 3: // two blocks with a gap
      final by = gy + rr(100, 140), gap = rr(80, 100);
      objs.add(Obj.rect(gx - gap / 2 - rr(30, 60), by, rr(60, 120), 40));
      objs.add(Obj.rect(gx + gap / 2 + rr(25, 40), by, rr(44, 80), 40));
      break;
    case 4: // faucet off to the side, glass on a ledge
      fx = gx + (gx < 288 ? 1 : -1) * rr(110, 170);
      fx = fx.clamp(110, 466);
      objs.add(Obj.rect(gx, gy + 46, 110, 12));
      objs.add(Obj.rect(fx + (fx < gx ? -1 : 1) * 40, fy + 150, 60, 12, angle: (fx < gx ? 1 : -1) * 15));
      break;
    case 5: // balls under the glass
      final cy = gy + rr(90, 120);
      objs.add(Obj.circle(gx - 40, cy, 15));
      objs.add(Obj.circle(gx + rr(-5, 5), cy + 4, 15));
      if (r.nextBool()) objs.add(Obj.circle(gx + 42, cy - 6, 15));
      break;
    case 6: // side pipe + diamonds
      final left = r.nextBool();
      fx = left ? gx - rr(70, 100) : gx + rr(70, 100);
      fx = fx.clamp(60, 516);
      faucets.add(FaucetDef(fx, fy, dir: left ? 2 : 1, amount: 75));
      objs.add(Obj.rect(gx - 26, gy + 90, 28, 28, angle: 45));
      objs.add(Obj.rect(gx + 26, gy + 90, 28, 28, angle: 45));
      break;
    case 7: // two glasses on shelves
      final sep = rr(150, 190);
      gx = 288 + rr(-20, 20);
      final g1 = gx - sep / 2, g2 = gx + sep / 2;
      glasses
        ..add(GlassDef(g1, gy))
        ..add(GlassDef(g2, gy));
      for (final g in [g1, g2]) {
        final s = g < gx ? 1.0 : -1.0;
        objs.add(Obj.rect(g, gy + 44, 100, 10));
        objs.add(Obj.rect(g + s * 50, gy + 4, 8, 90));
      }
      fx = gx;
      faucets.add(FaucetDef(fx, fy, amount: 140));
      break;
    case 8: // deflector under the faucet
      objs.add(Obj.rect(fx + rr(-6, 6), fy + 44, 50, 6, angle: rr(-10, 10)));
      objs.add(Obj.rect(gx, gy + 42, 300, 6));
      gy += 4;
      break;
    case 9: // glass floating, single obstacle
      objs.add(Obj.rect(gx + (r.nextBool() ? 60 : -60), gy - rr(0, 30), 28, 28));
      break;
    case 10: // stairs
      final s = r.nextBool() ? 1.0 : -1.0;
      fx = gx - s * rr(90, 120);
      objs.add(Obj.rect(fx + s * 20, fy + 110, 46, 46));
      objs.add(Obj.rect(fx + s * 66, fy + 156, 46, 46));
      objs.add(Obj.rect(gx, gy + 44, 70, 8));
      break;
    default: // V walls
      objs.add(_seg(Offset(gx - 120, gy - 80), Offset(gx - 60, gy + 60)));
      objs.add(_seg(Offset(gx + 120, gy - 80), Offset(gx + 60, gy + 60)));
      fx = gx + (r.nextBool() ? 1 : -1) * rr(40, 70);
      objs.add(Obj.rect(gx, gy + 110, 140, 8));
  }
  if (glasses.isEmpty) glasses.add(GlassDef(gx, gy));
  if (faucets.isEmpty) faucets.add(FaucetDef(fx, math.max(440, fy)));
  final f = faucets.first;
  return LevelDef(faucets: faucets, glasses: glasses, objs: objs, ink: ink, hint: _bagHint(f.x, f.y, glasses.first.x, glasses.first.y));
}

/// Boss levels (two lives, spinning blades).
LevelDef bossLevel(int k) {
  if (k == 0) {
    return const LevelDef(
      faucets: [FaucetDef(189, 560)],
      glasses: [GlassDef(300, 761)],
      objs: [
        Obj.rect(166, 690, 46, 46),
        Obj.rect(212, 644, 46, 46),
        Obj.cross(270, 662, 54, spin: 2.2),
        Obj.cross(330, 662, 54, spin: -2.2),
        Obj.rect(300, 803, 64, 6),
      ],
      hint: [
        [Offset(160, 548), Offset(176, 520), Offset(214, 534), Offset(250, 600), Offset(250, 640)]
      ],
    );
  }
  final base = _generated(100 + k * 3);
  final g = base.glasses.first;
  return LevelDef(
    faucets: base.faucets,
    glasses: base.glasses,
    objs: [...base.objs, Obj.cross(g.x - 40, g.y - 70, 54, spin: 2.0), Obj.cross(g.x + 40, g.y - 70, 54, spin: -2.0)],
    hint: base.hint,
  );
}

/// Challenge levels (three lives).
LevelDef challengeLevel(int i) {
  if (i == 0) {
    return LevelDef(
      faucets: const [FaucetDef(390, 545)],
      glasses: const [GlassDef(204, 700, angle: -40)],
      objs: [
        const Obj.poly([Offset(235, 173), Offset(451, 353), Offset(271, 567), Offset(56, 387)]),
        const Obj.rect(40, 540, 300, 150, angle: 40),
        const Obj.rect(40, 790, 330, 210, angle: 40),
        _seg(const Offset(324, 682), const Offset(576, 380)),
        _seg(const Offset(324, 682), const Offset(576, 682)),
      ],
      hint: const [
        [Offset(360, 600), Offset(300, 650), Offset(236, 666)]
      ],
    );
  }
  final r = math.Random(i * 104729);
  double rr(double a, double b) => a + r.nextDouble() * (b - a);
  final gx = rr(200, 380), gy = rr(640, 760);
  final fx = gx + (r.nextBool() ? 1 : -1) * rr(80, 160);
  final fy = rr(430, 520);
  final objs = <Obj>[
    Obj.rect(rr(100, 476), rr(260, 360), rr(140, 220), rr(120, 180), angle: rr(20, 70)),
    Obj.rect(gx, gy + 46, 90, 10, angle: rr(-12, 12)),
    Obj.cross((fx + gx) / 2, (fy + gy) / 2, 54, spin: i.isEven ? 2.0 : -2.0),
  ];
  if (i > 4) objs.add(Obj.cross(gx + 70, gy - 40, 46, spin: -2.4));
  if (i > 7) objs.add(_seg(Offset(fx - 60, fy + 120), Offset(fx + 60, fy + 160)));
  return LevelDef(
    faucets: [FaucetDef(fx.clamp(80, 496), fy)],
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
    faucets: [FaucetDef(288, top - 110, amount: 46)],
    glasses: [GlassDef(288, top - 38)],
    objs: objs,
    groundY: kGround,
    ink: 0,
  );
}
