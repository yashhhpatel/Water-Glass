import 'dart:ui';

enum ObjKind { rect, poly, circle, cross }

/// One level object in design pixels (576 x 1280 canvas).
class Obj {
  final ObjKind kind;
  final double x, y, w, h, angle, r, spin;
  final List<Offset> pts;
  final bool dyn; // dynamic body (bricks)
  final bool tappable; // removable by tapping (Don't Spill)
  final int color; // 0 teal, 1 brick orange
  const Obj.rect(this.x, this.y, this.w, this.h, {this.angle = 0, this.dyn = false, this.tappable = false, this.color = 0, this.spin = 0})
      : kind = ObjKind.rect,
        r = 0,
        pts = const [];
  const Obj.poly(this.pts, {this.dyn = false, this.color = 0})
      : kind = ObjKind.poly,
        x = 0,
        y = 0,
        w = 0,
        h = 0,
        angle = 0,
        r = 0,
        spin = 0,
        tappable = false;
  const Obj.circle(this.x, this.y, this.r, {this.dyn = false, this.tappable = false, this.color = 0})
      : kind = ObjKind.circle,
        w = 0,
        h = 0,
        angle = 0,
        spin = 0,
        pts = const [];

  /// Rotating orange "X" (boss / challenge levels).
  const Obj.cross(this.x, this.y, this.w, {this.spin = 1.6, this.angle = 0})
      : kind = ObjKind.cross,
        h = 9,
        r = 0,
        pts = const [],
        dyn = false,
        tappable = false,
        color = 1;
}

class GlassDef {
  final double x, y, angle; // centre of glass, degrees
  const GlassDef(this.x, this.y, {this.angle = 0});
}

class FaucetDef {
  final double x, y; // outlet point
  final int dir; // 0 down, 1 left, 2 right
  final int amount;
  const FaucetDef(this.x, this.y, {this.dir = 0, this.amount = 70});
}

class LevelDef {
  final List<FaucetDef> faucets;
  final List<GlassDef> glasses;
  final List<Obj> objs;
  final double ink;
  final List<List<Offset>> hint;
  final bool tutorial;
  final double groundY; // Don't Spill red line (0 = none)
  const LevelDef({
    required this.faucets,
    required this.glasses,
    this.objs = const [],
    this.ink = 1100,
    this.hint = const [],
    this.tutorial = false,
    this.groundY = 0,
  });

  LevelDef withHint(List<List<Offset>> h) =>
      LevelDef(faucets: faucets, glasses: glasses, objs: objs, ink: ink, hint: h, tutorial: tutorial, groundY: groundY);
}
