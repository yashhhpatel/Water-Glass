import 'dart:math' as math;
import 'dart:ui';

import 'package:water_glass/game/level.dart';
import 'package:water_glass/game/sim.dart';

/// Draws [strokes] the way a finger would (a stroke stops where it would cross
/// a solid), runs the physics and reports whether every glass fills before
/// the 3-2-1 countdown would run out.
({bool won, int fill}) trySolve(LevelDef def, List<List<Offset>> strokes) {
  final sim = Sim(def);
  var ink = def.ink;
  for (final stroke in strokes) {
    final pts = <Offset>[];
    for (final p in stroke) {
      if (pts.isEmpty) {
        if (sim.freeAt(p)) pts.add(p);
        continue;
      }
      final last = pts.last;
      final steps = ((p - last).distance / 8).ceil();
      var prev = last;
      for (var i = 1; i <= steps; i++) {
        final q = last + (p - last) * (i / steps);
        final l = (q - prev).distance;
        if (l > ink || !sim.freeAt(q) || !sim.segmentClear(prev, q)) break;
        pts.add(q);
        ink -= l;
        prev = q;
      }
    }
    if (pts.length > 1) sim.addLine(pts, sim.lines.length);
  }
  if (sim.lines.isEmpty) return (won: false, fill: 0);
  sim.start();
  double? doneAt;
  while (sim.time < 16) {
    sim.step(1 / 60);
    if (sim.allFull) return (won: true, fill: kFillTarget);
    if (sim.pourDone) {
      doneAt ??= sim.time;
      if (sim.time - doneAt > 4.2) break;
    }
  }
  return (won: false, fill: sim.countIn(0));
}

double strokesLength(List<List<Offset>> s) {
  var l = 0.0;
  for (final st in s) {
    for (var i = 0; i < st.length - 1; i++) {
      l += (st[i + 1] - st[i]).distance;
    }
  }
  return l;
}

/// Candidate solutions, shortest first: supports, cups, faucet hooks holding a
/// cradle, ramps and the level's own hint.
List<List<List<Offset>>> candidates(LevelDef d) {
  final f = d.faucets.first;
  final gs = d.glasses;
  final g = gs.first;
  final out = <List<List<Offset>>>[];
  if (d.hint.isNotEmpty) out.add(d.hint);
  if (gs.length == 2) {
    final a = gs[0].x < gs[1].x ? gs[0] : gs[1];
    final b = gs[0].x < gs[1].x ? gs[1] : gs[0];
    for (final dy in [-51.0, -58, -44, -66]) {
      out.add([
        [Offset(a.x + 34, a.y + dy), Offset(b.x - 34, b.y + dy)]
      ]);
    }
  }
  // straight supports under the glass
  for (final dy in [46.0, 58, 76]) {
    for (final w in [55.0, 95, 150]) {
      out.add([
        [Offset(g.x - w, g.y + dy), Offset(g.x + w, g.y + dy)]
      ]);
    }
  }
  // cups under the glass
  for (final w in [58.0, 84]) {
    for (final dy in [0.0, 22]) {
      out.add([
        [Offset(g.x - w, g.y + 8 + dy), Offset(g.x - w * .45, g.y + 50 + dy), Offset(g.x + w * .45, g.y + 50 + dy), Offset(g.x + w, g.y + 8 + dy)]
      ]);
    }
  }
  if (f.dir == 0) {
    // hook over the faucet that hangs a cradle around the glass
    for (final s in [1.0, -1.0]) {
      for (final w in [50.0, 68]) {
        for (final dd in [48.0, 62]) {
          final top = f.y - 40;
          final reach = math.max((g.x - f.x).abs(), 0) + w;
          out.add([
            [
              Offset(f.x - s * 30, f.y + 4),
              Offset(f.x - s * 26, top),
              Offset(f.x + s * 26, top),
              Offset(f.x + s * 36, f.y + 12),
              Offset(f.x + s * reach * .9, (f.y + g.y) / 2 + 6),
              Offset(g.x + s * w * .8, g.y + dd),
              Offset(g.x - s * w * .8, g.y + dd),
              Offset(g.x - s * w, g.y - 4),
            ]
          ]);
        }
      }
    }
  }
  // ramps from below the outlet to the glass mouth
  final towards = g.x >= f.x ? 1.0 : -1.0;
  if (f.dir == 0) {
    // hooked chute: wrap over the faucet, pass under the outlet, then ramp
    // down to just above the glass mouth
    for (final s in [towards, -towards]) {
      for (final t in <double>[-12, 0, 12]) {
        for (final above in <double>[58, 80]) {
          out.add([
            [
              Offset(f.x + s * 30, f.y + 4),
              Offset(f.x + s * 26, f.y - 40),
              Offset(f.x - s * 26, f.y - 40),
              Offset(f.x - s * 34, f.y + 12),
              Offset(f.x - towards * 22, f.y + 46),
              Offset(f.x + towards * 22, f.y + 56),
              Offset(g.x + t, g.y - above),
            ]
          ]);
        }
      }
    }
  }
  final out0 = f.dir == 0 ? Offset(f.x, f.y + 14) : Offset(f.x + (f.dir == 1 ? -12.0 : 12.0), f.y);
  for (final drop in <double>[36, 64]) {
    out.add([
      [out0 + Offset(-towards * 26, drop), Offset(g.x - towards * 6, g.y - 46)]
    ]);
    // ramp plus a support under the glass
    out.add([
      [out0 + Offset(-towards * 26, drop), Offset(g.x - towards * 6, g.y - 46)],
      [Offset(g.x - 70, g.y + 50), Offset(g.x + 70, g.y + 50)],
    ]);
  }
  final viable = out.where((c) => strokesLength(c) <= d.ink).toList()..sort((a, b) => strokesLength(a).compareTo(strokesLength(b)));
  return viable;
}

/// True when the level is won without any meaningful stroke (a tiny dot far
/// away just starts the water).
bool isTrivial(LevelDef d) => trySolve(d, [
      [const Offset(24, 1250), const Offset(30, 1250)]
    ]).won;

List<List<Offset>> _shift(List<List<Offset>> s, Offset d) =>
    [for (final st in s) [for (final p in st) Offset(((p.dx + d.dx) * 10).roundToDouble() / 10, ((p.dy + d.dy) * 10).roundToDouble() / 10)]];

/// A hint is only useful if a person can repeat it: it must also win when the
/// whole stroke is drawn a few pixels off.
bool solvesRobustly(LevelDef d, List<List<Offset>> s) {
  for (final o in const [Offset.zero, Offset(4, 3), Offset(-4, -3)]) {
    if (!trySolve(d, _shift(s, o)).won) return false;
  }
  return true;
}

List<List<Offset>> rounded(List<List<Offset>> s) => _shift(s, Offset.zero);
