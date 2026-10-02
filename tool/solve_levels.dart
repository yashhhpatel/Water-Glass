// Searches every classic/boss/challenge level for a working stroke, re-rolls
// generated layouts that have none (or that need no drawing at all) and
// appends results to tool/out/shard_<i>.jsonl. Resumable: solved keys are
// skipped. Merge afterwards with: python tool/merge_hints.py
//
// Run 4 shards in parallel, e.g.:
//   SHARD=0 SHARDS=4 flutter test tool/solve_levels.dart
// FORCE_KEYS=c12,b3 re-solves those keys even if already solved.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:water_glass/game/level.dart';
import 'package:water_glass/game/levels.dart';

import 'solver_lib.dart';

Set<String> _solvedKeys() {
  final dir = Directory('tool/out');
  if (!dir.existsSync()) return {};
  final keys = <String>{};
  for (final f in dir.listSync().whereType<File>().where((f) => f.path.endsWith('.jsonl'))) {
    for (final line in f.readAsLinesSync()) {
      if (line.trim().isEmpty) continue;
      final m = jsonDecode(line) as Map<String, dynamic>;
      if (m['hint'] != null) keys.add(m['key'] as String);
    }
  }
  return keys;
}

void main() {
  test('solve levels', () {
    final env = Platform.environment;
    final shard = int.parse(env['SHARD'] ?? '0'), shards = int.parse(env['SHARDS'] ?? '1');
    final force = (env['FORCE_KEYS'] ?? '').split(',').where((k) => k.isNotEmpty).toSet();
    final done = _solvedKeys().difference(force);
    Directory('tool/out').createSync(recursive: true);
    final out = File('tool/out/shard_$shard.jsonl');
    final jobs = <(String, bool, LevelDef Function(int))>[
      for (var n = 1; n <= kClassicCount; n++) ('c$n', n > 11, (v) => classicLevelRaw(n, v)),
      for (var k = 0; k < kBossCount; k++) ('b$k', k > 0, (v) => bossLevelRaw(k, v)),
      for (var i = 0; i < kChallengeCount; i++) ('x$i', i > 0, (v) => challengeLevelRaw(i, v)),
    ];
    for (var j = 0; j < jobs.length; j++) {
      final (key, canVary, build) = jobs[j];
      if (j % shards != shard || done.contains(key)) continue;
      if (force.isNotEmpty && !force.contains(key)) continue;
      int? variant;
      List<List<Offset>>? hint;
      // VMIN/VMAX let a retry pass try extra layout rolls for unsolved keys
      final vmin = canVary ? int.parse(env['VMIN'] ?? '0') : 0, vmax = canVary ? int.parse(env['VMAX'] ?? '12') : 1;
      for (var v = vmin; v < vmax && hint == null; v++) {
        final def = build(v);
        if (canVary && isTrivial(def)) continue;
        for (final c in candidates(def)) {
          if (trySolve(def, c).won && solvesRobustly(def, c)) {
            variant = v;
            hint = rounded(c);
            break;
          }
        }
      }
      out.writeAsStringSync(
        '${jsonEncode({
              'key': key,
              't': DateTime.now().millisecondsSinceEpoch,
              'v': variant,
              'hint': hint?.map((s) => s.map((p) => [p.dx, p.dy]).toList()).toList(),
            })}\n',
        mode: FileMode.append,
        flush: true,
      );
      stdout.writeln('$key ${hint != null ? 'solved v$variant len ${strokesLength(hint).round()}' : 'UNSOLVED'}');
    }
  }, timeout: const Timeout(Duration(hours: 8)));
}
