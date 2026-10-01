import 'data.dart';

const _ja = {
  'SETTINGS': '設定',
  'ENGLISH': '日本語',
  'PRIVACY': 'プライバシー',
  'MUSIC: ON': 'ミュージック: オン',
  'MUSIC: OFF': 'ミュージック: オフ',
  'SFX: ON': 'SFX: オン',
  'SFX: OFF': 'SFX: オフ',
  'LIKE US': 'いいね！してください',
  'FOLLOW US': 'フォローしてください',
  'CLASSIC': 'クラシック',
  'NEXT LEVEL': '次のレベル',
  'RETRY': 'リトライ',
  'COMPLETED!': 'クリア！',
  'CATEGORY': 'カテゴリー',
  'CHALLENGES': 'チャレンジ',
  'SKIP': 'スキップ',
  'PLAY': 'プレイ',
  'NO THANKS': 'いいえ',
  'COLLECTED': '獲得',
  'TO UNLOCK': 'でアンロック',
};

/// Translate a UI label (English default, Japanese when selected in Settings).
String tr(String s) => GameData.I.lang == 'ja' ? (_ja[s] ?? s) : s;
