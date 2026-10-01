import 'dart:math' as math;
import 'dart:ui' show Offset;

import 'package:forge2d/forge2d.dart';

import '../widgets/painters.dart' show GlassGeo;
import 'level.dart';

/// Pixels (design units) per physics metre.
const double kPx = 40;
Vector2 v(Offset o) => Vector2(o.dx / kPx, o.dy / kPx);
Offset px(Vector2 p) => Offset(p.x * kPx, p.y * kPx);

const double kParticleR = 4.4; // px
const double kLineThick = 6.0; // px
const int kFillTarget = 30; // particles inside a glass that reach the dotted line

class Tag {
  final String kind; // static, glass, line, water, faucet, cross, brick
  final int index;
  final Obj? obj;
  Tag(this.kind, [this.index = 0, this.obj]);
}

class DrawnLine {
  final Body body;
  final List<Offset> local; // px, relative to body origin
  DrawnLine(this.body, this.local);
}

class _Ray implements RayCastCallback {
  bool hit = false;
  @override
  double reportFixture(Fixture f, Vector2 p, Vector2 n, double fr) {
    final t = f.body.userData as Tag?;
    if (t != null && t.kind == 'water') return -1;
    hit = true;
    return 0;
  }
}

class _Query implements QueryCallback {
  final Vector2 p;
  bool hit = false;
  bool includeWater;
  _Query(this.p, {this.includeWater = false});
  @override
  bool reportFixture(Fixture f) {
    final t = f.body.userData as Tag?;
    if (!includeWater && t != null && t.kind == 'water') return true;
    if (t != null && t.kind == 'water') {
      if ((f.body.position - p).length < (kParticleR + kLineThick) / kPx) {
        hit = true;
        return false;
      }
      return true;
    }
    if (f.testPoint(p)) {
      hit = true;
      return false;
    }
    return true;
  }
}

class Sim {
  final LevelDef def;
  final World world = World(Vector2(0, 21));
  final List<Body> glasses = [];
  final List<Body> water = [];
  final List<DrawnLine> lines = [];
  final List<Body> crosses = [];
  final List<Body> bricks = [];
  final List<Body> statics = [];
  final List<int> emitted = [];
  final math.Random _rnd = math.Random(3);
  bool running = false;
  double time = 0;
  double _acc = 0;
  double _emitAcc = 0;
  int _initialFill = 0;

  Sim(this.def) {
    for (final o in def.objs) {
      _addObj(o);
    }
    for (var i = 0; i < def.glasses.length; i++) {
      glasses.add(_addGlass(def.glasses[i], i));
    }
    for (final f in def.faucets) {
      emitted.add(0);
      // faucet nozzle is solid (lines can hook on it)
      final b = world.createBody(BodyDef(position: v(Offset(f.x, f.y)), userData: Tag('faucet')));
      if (f.dir == 0) {
        b.createFixture(FixtureDef(PolygonShape()..setAsBox(19 / kPx, 16 / kPx, Vector2(0, -8 / kPx), 0), friction: .5));
      } else {
        final s = f.dir == 1 ? 1.0 : -1.0;
        b.createFixture(FixtureDef(PolygonShape()..setAsBox(70 / kPx, 13 / kPx, Vector2(s * 76 / kPx, 0), 0), friction: .5));
      }
      statics.add(b);
    }
  }

  bool get isDontSpill => def.groundY > 0;

  void _addObj(Obj o) {
    final type = o.kind == ObjKind.cross ? BodyType.kinematic : (o.dyn ? BodyType.dynamic : BodyType.static);
    final tag = Tag(o.kind == ObjKind.cross ? 'cross' : (o.dyn ? 'brick' : 'static'), 0, o);
    final pos = o.kind == ObjKind.poly ? Vector2.zero() : v(Offset(o.x, o.y));
    final b = world.createBody(BodyDef(type: type, position: pos, angle: o.angle * math.pi / 180, userData: tag));
    final fr = o.dyn ? .9 : .6;
    switch (o.kind) {
      case ObjKind.rect:
        b.createFixture(FixtureDef(PolygonShape()..setAsBoxXY(o.w / 2 / kPx, o.h / 2 / kPx), friction: fr, density: 1.2));
        break;
      case ObjKind.poly:
        b.createFixture(FixtureDef(PolygonShape()..set(o.pts.map(v).toList()), friction: fr));
        break;
      case ObjKind.circle:
        b.createFixture(FixtureDef(CircleShape()..radius = o.r / kPx, friction: fr, density: 1.2));
        break;
      case ObjKind.cross:
        for (final a in [math.pi / 4, -math.pi / 4]) {
          b.createFixture(FixtureDef(PolygonShape()..setAsBox(o.w / 2 / kPx, o.h / 2 / kPx, Vector2.zero(), a), friction: .3));
        }
        break;
    }
    if (o.kind == ObjKind.cross) {
      crosses.add(b);
    } else if (o.dyn) {
      bricks.add(b);
    } else {
      statics.add(b);
    }
  }

  Body _addGlass(GlassDef g, int i) {
    final b = world.createBody(BodyDef(
      type: BodyType.dynamic,
      position: v(Offset(g.x, g.y)),
      angle: g.angle * math.pi / 180,
      userData: Tag('glass', i),
      angularDamping: .4,
    ));
    const h2 = GlassGeo.h / 2, tw = GlassGeo.topW / 2, bw = GlassGeo.botW / 2, w = GlassGeo.wall;
    List<Vector2> pts(List<List<double>> p) => p.map((e) => Vector2(e[0] / kPx, e[1] / kPx)).toList();
    final fd = [
      pts([
        [-tw, -h2],
        [-tw + w, -h2],
        [-bw + w, h2 - w],
        [-bw, h2]
      ]),
      pts([
        [tw - w, -h2],
        [tw, -h2],
        [bw, h2],
        [bw - w, h2 - w]
      ]),
      pts([
        [-bw, h2],
        [-bw + w, h2 - w],
        [bw - w, h2 - w],
        [bw, h2]
      ]),
    ];
    for (final p in fd) {
      b.createFixture(FixtureDef(PolygonShape()..set(p), density: 2.2, friction: .7));
    }
    return b;
  }

  /// Is the design-space point free for drawing (no solid object / water there)?
  bool freeAt(Offset p) {
    final q = _Query(v(p), includeWater: running);
    const r = (kLineThick / 2 + 1) / kPx;
    world.queryAABB(q, AABB.withVec2(q.p - Vector2.all(r), q.p + Vector2.all(r)));
    if (q.hit) return false;
    // keep a small margin around solids
    for (final d in const [Offset(3, 0), Offset(-3, 0), Offset(0, 3), Offset(0, -3)]) {
      final q2 = _Query(v(p + d));
      world.queryAABB(q2, AABB.withVec2(q2.p - Vector2.all(.02), q2.p + Vector2.all(.02)));
      if (q2.hit) return false;
    }
    return true;
  }

  bool segmentClear(Offset a, Offset b) {
    if ((b - a).distance < .5) return true;
    final n = Offset(-(b - a).dy, (b - a).dx) / (b - a).distance * (kLineThick / 2);
    for (final o in [Offset.zero, n, -n]) {
      final r = _Ray();
      world.raycast(r, v(a + o), v(b + o));
      if (r.hit) return false;
    }
    return true;
  }

  /// Turn a finished stroke into a falling rigid body.
  void addLine(List<Offset> pts, int seed) {
    if (pts.isEmpty) return;
    final origin = pts.first;
    final body = world.createBody(BodyDef(
      type: BodyType.dynamic,
      position: v(origin),
      userData: Tag('line', seed),
      angularDamping: .2,
    ));
    final local = pts.map((p) => p - origin).toList();
    const ht = kLineThick / 2 / kPx;
    if (local.length == 1) {
      body.createFixture(FixtureDef(CircleShape()..radius = ht * 1.4, density: 1, friction: .6));
    }
    for (var i = 0; i < local.length - 1; i++) {
      final a = local[i], b = local[i + 1];
      final d = b - a;
      final len = d.distance;
      if (len < .5) continue;
      final c = (a + b) / 2;
      body.createFixture(FixtureDef(
          PolygonShape()..setAsBox(len / 2 / kPx + ht * .5, ht, v(c), math.atan2(d.dy, d.dx)),
          density: 1,
          friction: .6));
    }
    lines.add(DrawnLine(body, local));
  }

  void start() {
    running = true;
  }

  /// Advance physics with a fixed time step.
  void step(double dt) {
    if (!running) return;
    _acc += math.min(dt, 1 / 20);
    const h = 1 / 60;
    while (_acc >= h) {
      _acc -= h;
      time += h;
      _emit(h);
      for (final c in crosses) {
        final o = (c.userData as Tag).obj!;
        c.angularVelocity = o.spin;
      }
      world.stepDt(h);
    }
    // remove water that left the screen
    for (var i = water.length - 1; i >= 0; i--) {
      final p = water[i].position;
      if (p.y * kPx > 1500 || p.x * kPx < -200 || p.x * kPx > 776) {
        world.destroyBody(water[i]);
        water.removeAt(i);
      }
    }
  }

  double get pourDuration => 2.6;

  void _emit(double h) {
    for (var i = 0; i < def.faucets.length; i++) {
      final f = def.faucets[i];
      if (emitted[i] >= f.amount) continue;
      final rate = f.amount / pourDuration;
      _emitAcc += rate * h;
      while (_emitAcc >= 1 && emitted[i] < f.amount) {
        _emitAcc -= 1;
        emitted[i]++;
        final jitter = (_rnd.nextDouble() - .5) * 6;
        Offset pos;
        Vector2 vel;
        if (f.dir == 0) {
          pos = Offset(f.x + jitter, f.y + 12);
          vel = Vector2(jitter * .05, 3.2);
        } else {
          final s = f.dir == 1 ? -1.0 : 1.0;
          pos = Offset(f.x + s * 6, f.y + jitter);
          vel = Vector2(s * 2.6, jitter * .05);
        }
        final b = world.createBody(BodyDef(
          type: BodyType.dynamic,
          position: v(pos),
          linearVelocity: vel,
          userData: Tag('water'),
          linearDamping: .05,
          fixedRotation: true,
        ));
        b.createFixture(FixtureDef(CircleShape()..radius = kParticleR / kPx, density: 1, friction: 0, restitution: 0));
        water.add(b);
      }
    }
  }

  bool get pourDone {
    for (var i = 0; i < def.faucets.length; i++) {
      if (emitted[i] < def.faucets[i].amount) return false;
    }
    return true;
  }

  bool get pouring => running && !pourDone;

  /// Number of water particles resting inside glass [g].
  int countIn(int g) {
    final b = glasses[g];
    var n = 0;
    for (final w in water) {
      final l = px(b.localPoint(w.position));
      if (l.dy < -GlassGeo.h / 2 - 2 || l.dy > GlassGeo.h / 2 - GlassGeo.wall + 1) continue;
      if (l.dx.abs() < GlassGeo.halfWidthAt(l.dy) - GlassGeo.wall + 1.5) n++;
    }
    return n;
  }

  /// 0..1 fill towards the dotted line.
  double fill(int g) => (countIn(g) / kFillTarget).clamp(0, 1.2);

  bool get allFull {
    for (var i = 0; i < glasses.length; i++) {
      if (countIn(i) < kFillTarget) return false;
    }
    return true;
  }

  /// Is any water near glass g (used for the surprised face)?
  bool waterNear(int g) {
    final c = glasses[g].position;
    for (final w in water) {
      if ((w.position - c).length < 140 / kPx) return true;
    }
    return false;
  }

  // ---------------- Don't Spill helpers ----------------
  void markInitialFill() => _initialFill = countIn(0);
  int get initialFill => _initialFill;
  double get retained => _initialFill == 0 ? 1 : countIn(0) / _initialFill;

  bool get glassOnGround {
    final g = glasses[0];
    final bottom = px(g.worldPoint(Vector2(0, GlassGeo.h / 2 / kPx)));
    return bottom.dy >= def.groundY - 10 && math.cos(g.angle) > .9;
  }

  bool get glassUpright => math.cos(glasses[0].angle) > .8;

  Body? brickAt(Offset p) {
    final q = v(p);
    for (final b in bricks) {
      for (final f in b.fixtures) {
        if (f.testPoint(q)) return b;
      }
    }
    // generous touch radius for small pieces
    Body? best;
    var bd = 22 / kPx;
    for (final b in bricks) {
      final d = (b.position - q).length;
      if (d < bd) {
        bd = d;
        best = b;
      }
    }
    return best;
  }

  void removeBrick(Body b) {
    bricks.remove(b);
    world.destroyBody(b);
  }

  /// Is everything (nearly) at rest?
  bool get settled {
    for (final g in glasses) {
      if (g.linearVelocity.length > .25) return false;
    }
    return true;
  }
}
