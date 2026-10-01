import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'dialogs.dart';

/// Cart screen: free coins (rewarded) + bundle offer.
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return DesignScreen(
      child: Column(children: [
        BackCoinsBar(
          onBack: () => Navigator.of(context).pop(),
          extra: ListenableBuilder(
            listenable: GameData.I,
            builder: (_, __) => Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                PaintBox(46, 52, (c, s) => drawBulb(c, const Offset(23, 28), 44)),
                Text('${GameData.I.hints}', style: txt(29, w: FontWeight.w500)),
              ]),
            ),
          ),
        ),
        const SizedBox(height: 154),
        Tap(
          onTap: () async {
            if (await watchRewardAd(context)) {
              GameData.I.coins += 500;
              GameData.I.save();
              Sfx.play('coin');
            }
          },
          child: Container(
            width: 436,
            height: 100,
            decoration: BoxDecoration(color: const Color(0xFFD9EDA6), borderRadius: BorderRadius.circular(50), border: Border.all(color: const Color(0xFFB5CC86), width: 2)),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Opacity(opacity: .7, child: PaintBox(70, 60, (c, s) => drawClapper(c, const Rect.fromLTWH(6, 12, 58, 46)))),
              const SizedBox(width: 18),
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('FREE', style: txt(30, w: FontWeight.w500, sp: 5, c: const Color(0xFFA9B98A))),
                Text('+500 COINS', style: txt(20, w: FontWeight.w500, sp: 4, c: const Color(0xFFA9B98A))),
              ]),
            ]),
          ),
        ),
        const SizedBox(height: 22),
        Tap(
          onTap: () => showMessage(context, 'Store', 'In-app purchases are not\navailable in this version.'),
          child: const BundleCard(),
        ),
      ]),
    );
  }
}
