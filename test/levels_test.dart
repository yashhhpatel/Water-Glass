import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:water_glass/game/level.dart';
import 'package:water_glass/game/levels.dart';

import '../tool/solver_lib.dart';

/// Every level's in-game hint must actually solve it.
/// Optional sharding: SHARD=0 SHARDS=4 flutter test test/levels_test.dart
void main() {
  test('every level is solvable with its hint', () {
    final shard = int.parse(Platform.environment['SHARD'] ?? '0');
    final shards = int.parse(Platform.environment['SHARDS'] ?? '1');
    final jobs = <(String, LevelDef Function())>[
      for (var n = 1; n <= kClassicCount; n++) ('classic $n', () => classicLevel(n)),
      for (var k = 0; k < kBossCount; k++) ('boss $k', () => bossLevel(k)),
      for (var i = 0; i < kChallengeCount; i++) ('challenge $i', () => challengeLevel(i)),
    ];
    final failed = <String>[];
    for (var j = shard; j < jobs.length; j += shards) {
      final (name, build) = jobs[j];
      final def = build();
      if (def.hint.isEmpty || !trySolve(def, def.hint).won) failed.add(name);
    }
    expect(failed, isEmpty);
  }, timeout: const Timeout(Duration(hours: 1)));
}
