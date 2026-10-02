import 'package:flutter/material.dart';

import '../core/billing.dart';
import '../core/data.dart';
import '../core/links.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';

/// Remove Ads: 1-month subscription or lifetime purchase via Google Play.
class RemoveAdsScreen extends StatefulWidget {
  const RemoveAdsScreen({super.key});
  @override
  State<RemoveAdsScreen> createState() => _RemoveAdsScreenState();
}

class _RemoveAdsScreenState extends State<RemoveAdsScreen> {
  @override
  void initState() {
    super.initState();
    Billing.message.value = null;
    if (Billing.available) Billing.refreshEntitlements();
  }

  void _buy(String id) {
    if (Billing.testMode) {
      _confirmTest(id);
    } else {
      Billing.buy(id);
    }
  }

  Future<void> _confirmTest(String id) async {
    final ok = await showPopup<bool>(
      context,
      (ctx) => PopupCard(
        width: 470,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('TEST PURCHASE', style: txt(28, w: FontWeight.w800, sp: 2)),
          const SizedBox(height: 14),
          Text('Google Play is not available on this device,\nso this debug build simulates the purchase.\nNo money is charged.',
              textAlign: TextAlign.center, style: txt(20, w: FontWeight.w500, h: 1.4)),
          const SizedBox(height: 20),
          Pill('BUY (TEST)', w: 300, h: 70, fs: 22, onTap: () => Navigator.of(ctx).pop(true)),
          const SizedBox(height: 12),
          Pill('CANCEL', w: 300, h: 60, fs: 20, color: C.locked, onTap: () => Navigator.of(ctx).pop(false)),
        ]),
      ),
    );
    if (ok == true) {
      Billing.testPurchase(id);
    } else {
      Billing.message.value = 'Purchase cancelled.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return DesignScreen(
      child: ListenableBuilder(
        listenable: Listenable.merge([GameData.I, Billing.message, Billing.busy]),
        builder: (_, __) {
          final d = GameData.I;
          final status = d.noAdsLifetime
              ? 'ADS REMOVED FOREVER'
              : d.noAdsMonthly
                  ? 'ADS REMOVED (MONTHLY PLAN ACTIVE)'
                  : null;
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 36, 16, 0),
              child: Row(children: [BackArrow(onTap: () => Navigator.of(context).pop()), const Spacer()]),
            ),
            const SizedBox(height: 10),
            PaintBox(150, 150, (c, s) => drawNoAds(c, const Offset(75, 75), 68)),
            const SizedBox(height: 12),
            Text(tr('REMOVE ADS'), style: txt(40, w: FontWeight.w800, sp: 6)),
            const SizedBox(height: 12),
            Text('No app-open, banner or interstitial ads.\nOptional reward videos stay available\nso you can still earn bonuses.',
                textAlign: TextAlign.center, style: txt(21, w: FontWeight.w500, h: 1.45, c: const Color(0xFF444444))),
            const SizedBox(height: 26),
            _Plan(
              title: '1 MONTH ADS-FREE',
              sub: 'Renews monthly · cancel anytime',
              price: Billing.price(Billing.monthlyId),
              owned: d.noAdsMonthly || d.noAdsLifetime,
              busy: Billing.busy.value,
              onBuy: () => _buy(Billing.monthlyId),
            ),
            const SizedBox(height: 18),
            _Plan(
              title: 'LIFETIME ADS-FREE',
              sub: 'Pay once · best value',
              price: Billing.price(Billing.lifetimeId),
              owned: d.noAdsLifetime,
              best: true,
              busy: Billing.busy.value,
              onBuy: () => _buy(Billing.lifetimeId),
            ),
            const SizedBox(height: 22),
            if (status != null) Text(status, style: txt(22, w: FontWeight.w800, c: C.greenDark, sp: 2)),
            if (Billing.message.value != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(30, 8, 30, 0),
                child: Text(Billing.message.value!, textAlign: TextAlign.center, style: txt(19, w: FontWeight.w600, c: const Color(0xFF555555), h: 1.3)),
              ),
            const Spacer(),
            Tap(
              onTap: Billing.busy.value ? null : () => Billing.testMode ? (Billing.message.value = 'Restore needs Google Play.') : Billing.restore(),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(tr('RESTORE PURCHASES'), style: txt(22, w: FontWeight.w700, sp: 3, c: C.btnBlue)),
              ),
            ),
            if (Billing.testMode && d.adsRemoved)
              Tap(
                onTap: Billing.clearTestPurchase,
                child: Padding(padding: const EdgeInsets.all(8), child: Text('RESET TEST PURCHASE (DEBUG)', style: txt(16, w: FontWeight.w700, c: const Color(0xFFE5402B)))),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(40, 6, 40, 0),
              child: Text('Payment is charged to your Google Play account. The monthly plan renews automatically unless cancelled in Google Play > Subscriptions.',
                  textAlign: TextAlign.center, style: txt(15, w: FontWeight.w500, c: const Color(0xFF777777), h: 1.35)),
            ),
            const PrivacyLink(size: 16),
            const SizedBox(height: 24),
          ]);
        },
      ),
    );
  }
}

class _Plan extends StatelessWidget {
  final String title, sub, price;
  final bool owned, best, busy;
  final VoidCallback onBuy;
  const _Plan({required this.title, required this.sub, required this.price, required this.owned, required this.onBuy, this.best = false, this.busy = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 480,
      height: 128,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 480,
          height: 128,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          decoration: BoxDecoration(
            color: best ? const Color(0xFFFFF7C2) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF222222), width: 2.4),
            boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 4))],
          ),
          child: Row(children: [
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: txt(23, w: FontWeight.w800, sp: 1.5)),
                const SizedBox(height: 6),
                Text(sub, style: txt(17, w: FontWeight.w500, c: const Color(0xFF666666))),
              ]),
            ),
            owned
                ? Text('OWNED', style: txt(22, w: FontWeight.w800, c: C.greenDark, sp: 2))
                : Opacity(opacity: busy ? .5 : 1, child: Pill(price, w: 150, h: 66, fs: 24, onTap: busy ? null : onBuy)),
          ]),
        ),
        if (best)
          Positioned(
            right: 18,
            top: -14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
              decoration: BoxDecoration(color: const Color(0xFFE5402B), borderRadius: BorderRadius.circular(10)),
              child: Text('BEST VALUE', style: txt(14, w: FontWeight.w800, c: Colors.white, sp: 1.5)),
            ),
          ),
      ]),
    );
  }
}
