import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/catalog.dart';
import '../core/theme.dart';
import '../widgets/painters.dart';
import 'level.dart';
import 'sim.dart';

const _tealEdge = Color(0xFF2F6F73);
const _brickEdge = Color(0xFFB55A00);

ui.Image? _blob;

/// Soft round sprite used to render water as merged blobs (metaballs).
ui.Image blobSprite() {
  if (_blob != null) return _blob!;
  final rec = ui.PictureRecorder();
  final c = Canvas(rec);
  const s = 32.0;
  c.drawCircle(
      const Offset(s / 2, s / 2),
      s / 2,
      Paint()
        ..shader = ui.Gradient.radial(const Offset(s / 2, s / 2), s / 2, [
          Colors.black,
          Colors.black.withOpacity(.6),
          Colors.black.withOpacity(0),
        ], [
          0,
          .45,
          1
        ]));
  _blob = rec.endRecording().toImageSync(32, 32);
  return _blob!;
}

ColorFilter _threshold(Color c, double cut) {
  // alpha' = k*alpha - k*cut  (Flutter's matrix offsets are in 0..255 units)
  const k = 30.0;
  return ColorFilter.matrix([
    0, 0, 0, 0, c.red.toDouble(), //
    0, 0, 0, 0, c.green.toDouble(),
    0, 0, 0, 0, c.blue.toDouble(),
    0, 0, 0, k, -k * cut * 255,
  ]);
}

void paintWater(Canvas c, List<Offset> pts, Color color, {double scale = 1}) {
  if (pts.isEmpty) return;
  final img = blobSprite();
  final xf = Float32List(pts.length * 4);
  final rects = Float32List(pts.length * 4);
  final sc = 0.62 * scale; // sprite 32px -> ~20px blob
  for (var i = 0; i < pts.length; i++) {
    xf[i * 4] = sc;
    xf[i * 4 + 1] = 0;
    xf[i * 4 + 2] = pts[i].dx - 16 * sc;
    xf[i * 4 + 3] = pts[i].dy - 16 * sc;
    rects[i * 4] = 0;
    rects[i * 4 + 1] = 0;
    rects[i * 4 + 2] = 32;
    rects[i * 4 + 3] = 32;
  }
  const bounds = Rect.fromLTWH(-100, -100, 800, 1500);
  final dark = Color.lerp(color, Colors.black, .22)!;
  for (final pass in [(dark, .32), (color, .5)]) {
    c.saveLayer(bounds, Paint()..colorFilter = _threshold(pass.$1, pass.$2));
    c.drawRawAtlas(img, xf, rects, null, null, null, Paint()..filterQuality = FilterQuality.low);
    c.restore();
  }
}

Path _objPath(Obj o) {
  switch (o.kind) {
    case ObjKind.poly:
      return Path()..addPolygon(o.pts, true);
    case ObjKind.circle:
      return Path()..addOval(Rect.fromCircle(center: Offset.zero, radius: o.r));
    case ObjKind.rect:
      return Path()..addRect(Rect.fromCenter(center: Offset.zero, width: o.w, height: o.h));
    case ObjKind.cross:
      final p = Path();
      for (final a in [math.pi / 4, -math.pi / 4]) {
        final m = Matrix4.rotationZ(a);
        p.addPath(Path()..addRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: o.w, height: o.h), const Radius.circular(2))), Offset.zero,
            matrix4: m.storage);
      }
      return p;
  }
}

void _paintObjAt(Canvas c, Obj o, Offset pos, double angle) {
  final path = _objPath(o);
  c.save();
  if (o.kind != ObjKind.poly) {
    c.translate(pos.dx, pos.dy);
    c.rotate(angle);
  }
  if (o.kind == ObjKind.cross) {
    c.drawPath(path, fillP(const Color(0xFFF7931E)));
    c.drawPath(path, strokeP(const Color(0xFF7A3A00), 1.6));
    c.drawCircle(Offset.zero, 3, fillP(const Color(0xFF7A3A00)));
  } else if (o.color == 1) {
    c.drawPath(path, fillP(C.brick));
    c.drawPath(path, strokeP(_brickEdge, 1.6));
  } else {
    c.drawPath(path, fillP(C.teal));
    c.drawPath(path, strokeP(_tealEdge, 1.4));
  }
  c.restore();
}

/// Draws a level layout without physics (thumbnails, previews).
void paintLevelStatic(Canvas c, LevelDef d, {GlassSkin? skin, double fill = 0, Color water = C.water}) {
  for (final o in d.objs) {
    _paintObjAt(c, o, Offset(o.x, o.y), o.angle * math.pi / 180);
  }
  for (final f in d.faucets) {
    drawFaucet(c, Offset(f.x, f.y), dir: f.dir);
  }
  for (final g in d.glasses) {
    c.save();
    c.translate(g.x, g.y);
    c.rotate(g.angle * math.pi / 180);
    drawGlass(c, skin ?? glassSkins[0], fill: fill, water: water, expr: fill > 0 ? Expr.happy : Expr.sad);
    c.restore();
  }
  if (d.groundY > 0) {
    c.drawRect(Rect.fromLTRB(-200, d.groundY, 800, d.groundY + 5), fillP(C.redLine));
  }
}

class RenderOpts {
  GlassSkin skin = glassSkins[0];
  Color water = C.water;
  Color ink = const Color(0xFF111111);
  List<List<Offset>> strokes = const [];
  List<List<Offset>> hint = const [];
  double hintT = -1; // >=0 draws hint with animated pencil
  List<Expr> exprs = const [];
  double t = 0;
}

void paintSim(Canvas c, Sim sim, RenderOpts o) {
  final d = sim.def;
  if (d.groundY > 0) {
    c.drawRect(Rect.fromLTRB(-200, d.groundY, 800, d.groundY + 5), fillP(C.redLine));
  }
  for (final ob in d.objs) {
    if (ob.kind == ObjKind.cross || ob.dyn) continue;
    _paintObjAt(c, ob, Offset(ob.x, ob.y), ob.angle * math.pi / 180);
  }
  for (final b in [...sim.crosses, ...sim.bricks]) {
    final ob = (b.userData as Tag).obj!;
    _paintObjAt(c, ob, px(b.position), b.angle);
  }
  // drawn lines
  final lp = strokeP(o.ink, 4.2);
  for (final l in sim.lines) {
    c.save();
    final p = px(l.body.position);
    c.translate(p.dx, p.dy);
    c.rotate(l.body.angle);
    _strokePath(c, l.local, lp);
    c.restore();
  }
  for (final s in o.strokes) {
    _strokePath(c, s, lp);
  }
  // water
  paintWater(c, [for (final w in sim.water) px(w.position)], o.water);
  // glasses
  for (var i = 0; i < sim.glasses.length; i++) {
    final g = sim.glasses[i];
    final p = px(g.position);
    c.save();
    c.translate(p.dx, p.dy);
    c.rotate(g.angle);
    drawGlass(c, o.skin, expr: i < o.exprs.length ? o.exprs[i] : Expr.sad, t: o.t);
    c.restore();
  }
  for (final f in d.faucets) {
    drawFaucet(c, Offset(f.x, f.y), dir: f.dir);
  }
  if (o.hintT >= 0) _paintHint(c, o.hint, o.hintT);
}

void _strokePath(Canvas c, List<Offset> pts, Paint p) {
  if (pts.isEmpty) return;
  if (pts.length == 1) {
    c.drawCircle(pts.first, p.strokeWidth / 2, Paint()..color = p.color);
    return;
  }
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length; i++) {
    path.lineTo(pts[i].dx, pts[i].dy);
  }
  c.drawPath(path, p);
}

/// Green dashed hint line, revealed by an animated pencil (loops every 2.4 s).
void _paintHint(Canvas c, List<List<Offset>> hint, double t) {
  if (hint.isEmpty) return;
  final total = hint.fold<double>(0, (a, s) => a + _len(s));
  final phase = (t % 2.4) / 1.8;
  final shown = total * phase.clamp(0, 1);
  final dash = strokeP(const Color(0xFF2BB673), 2.6);
  var acc = 0.0;
  Offset? tip;
  for (final s in hint) {
    for (var i = 0; i < s.length - 1; i++) {
      final a = s[i], b = s[i + 1];
      final l = (b - a).distance;
      for (var d = 0.0; d < l; d += 9) {
        if (acc + d > shown) break;
        final p0 = a + (b - a) * (d / l);
        final p1 = a + (b - a) * (math.min(d + 5, l) / l);
        c.drawLine(p0, p1, dash);
        tip = p1;
      }
      acc += l;
    }
  }
  if (tip != null) drawPen(c, tip, 70, PenStyle.pencil);
}

double _len(List<Offset> s) {
  var l = 0.0;
  for (var i = 0; i < s.length - 1; i++) {
    l += (s[i + 1] - s[i]).distance;
  }
  return l;
}
