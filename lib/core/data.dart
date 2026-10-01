import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'catalog.dart';

/// All persistent player progress. Saved as one JSON blob.
class GameData extends ChangeNotifier {
  GameData._();
  static final GameData I = GameData._();
  static const _key = 'water_glass_save_v1';
  SharedPreferences? _prefs;

  int coins = 0;
  int hints = 3;
  int level = 1; // next classic level to play (1-based)
  Map<int, int> stars = {}; // classic level -> stars
  int bottle = 0; // reward bottle %
  int unlockedWaters = 1;
  int water = 0;
  int ink = 0;
  int pen = 0;
  int glass = 0;
  Set<int> ownedInks = {0};
  Set<int> ownedPens = {0};
  Set<int> ownedGlasses = {0};
  bool music = true;
  bool sfx = true;
  String lang = 'en';
  int dsLevel = 1; // next Don't Spill level
  Set<int> challengesDone = {};
  Set<int> bossesDone = {};
  int lastSpin = 0; // epoch ms of last daily wheel spin
  int levelsSinceOffer = 0;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_key);
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      coins = m['coins'] ?? 0;
      hints = m['hints'] ?? 3;
      level = m['level'] ?? 1;
      stars = ((m['stars'] ?? {}) as Map).map((k, v) => MapEntry(int.parse(k.toString()), v as int));
      bottle = m['bottle'] ?? 0;
      unlockedWaters = m['unlockedWaters'] ?? 1;
      water = m['water'] ?? 0;
      ink = m['ink'] ?? 0;
      pen = m['pen'] ?? 0;
      glass = m['glass'] ?? 0;
      ownedInks = Set<int>.from(m['ownedInks'] ?? [0]);
      ownedPens = Set<int>.from(m['ownedPens'] ?? [0]);
      ownedGlasses = Set<int>.from(m['ownedGlasses'] ?? [0]);
      music = m['music'] ?? true;
      sfx = m['sfx'] ?? true;
      lang = m['lang'] ?? 'en';
      dsLevel = m['dsLevel'] ?? 1;
      challengesDone = Set<int>.from(m['challengesDone'] ?? []);
      bossesDone = Set<int>.from(m['bossesDone'] ?? []);
      lastSpin = m['lastSpin'] ?? 0;
      levelsSinceOffer = m['levelsSinceOffer'] ?? 0;
    } catch (_) {}
  }

  void save() {
    notifyListeners();
    _prefs?.setString(
        _key,
        jsonEncode({
          'coins': coins,
          'hints': hints,
          'level': level,
          'stars': stars.map((k, v) => MapEntry(k.toString(), v)),
          'bottle': bottle,
          'unlockedWaters': unlockedWaters,
          'water': water,
          'ink': ink,
          'pen': pen,
          'glass': glass,
          'ownedInks': ownedInks.toList(),
          'ownedPens': ownedPens.toList(),
          'ownedGlasses': ownedGlasses.toList(),
          'music': music,
          'sfx': sfx,
          'lang': lang,
          'dsLevel': dsLevel,
          'challengesDone': challengesDone.toList(),
          'bossesDone': bossesDone.toList(),
          'lastSpin': lastSpin,
          'levelsSinceOffer': levelsSinceOffer,
        }));
  }

  int get totalStars => stars.values.fold(0, (a, b) => a + b);
  int starsInPack(int pack) {
    var s = 0;
    for (var i = pack * 10 + 1; i <= pack * 10 + 10; i++) {
      s += stars[i] ?? 0;
    }
    return s;
  }

  /// Highest classic level completed.
  int get completed => level - 1;

  /// Stars needed to open a level pack (24 per pack, as in the reference).
  static int packCost(int pack) => pack * 24;
  bool packUnlocked(int pack) => pack == 0 || totalStars >= packCost(pack) || completed >= pack * 10;

  bool get dontSpillUnlocked => completed >= 10;
  bool get flippyUnlocked => completed >= 20;
  bool get preciseUnlocked => challengesDone.length >= 18;
  bool challengeUnlocked(int i) => completed >= (i + 1) * 5; // i: 0-based
  bool dsPackUnlocked(int pack) {
    if (pack == 0) return dontSpillUnlocked;
    if (pack == 1) return completed >= 25 && [0, 1, 2, 3, 4].every(challengesDone.contains);
    return completed >= 60 && [5, 6, 7, 8, 9, 10, 11].every(challengesDone.contains);
  }

  bool inkOwned(int i) {
    final it = inks[i];
    if (it.unlock == UnlockKind.dontSpill) return dsLevel > it.dsLevel;
    return ownedInks.contains(i);
  }

  bool get dailyReady => DateTime.now().millisecondsSinceEpoch - lastSpin >= 24 * 3600 * 1000;
  Duration get dailyLeft {
    final left = 24 * 3600 * 1000 - (DateTime.now().millisecondsSinceEpoch - lastSpin);
    return Duration(milliseconds: left < 0 ? 0 : left);
  }
}
