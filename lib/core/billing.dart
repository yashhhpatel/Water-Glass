import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';

import 'ads.dart';
import 'data.dart';

/// Remove Ads purchases through Google Play Billing.
///
/// Create these products in Google Play Console (Monetize > Products):
///  * `remove_ads_monthly`  – subscription, 1-month base plan, ₹299
///  * `remove_ads_lifetime` – one-time (non-consumable) product, ₹2,999
class Billing {
  static const monthlyId = 'remove_ads_monthly';
  static const lifetimeId = 'remove_ads_lifetime';
  static const ids = {monthlyId, lifetimeId};

  /// Shown when the store has not returned product details yet.
  static const fallbackPrice = {monthlyId: '₹299', lifetimeId: '₹2,999'};

  static final InAppPurchase _iap = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _sub;
  static bool available = false;
  static final Map<String, ProductDetails> products = {};

  /// Latest status line for the Remove Ads screen.
  static final ValueNotifier<String?> message = ValueNotifier(null);
  static final ValueNotifier<bool> busy = ValueNotifier(false);

  /// Debug builds on devices without Google Play (e.g. emulators) can run a
  /// clearly-labelled simulated purchase to test the entitlement flow.
  static bool get testMode => kDebugMode && (!available || products.isEmpty);

  static Future<void> init() async {
    _sub ??= _iap.purchaseStream.listen(_onPurchases, onError: (Object e) {
      message.value = 'Purchase error: $e';
      busy.value = false;
    });
    try {
      available = await _iap.isAvailable();
    } catch (_) {
      available = false;
    }
    if (!available) return;
    final r = await _iap.queryProductDetails(ids);
    for (final p in r.productDetails) {
      products[p.id] = p;
    }
    await refreshEntitlements();
  }

  static String price(String id) => products[id]?.price ?? fallbackPrice[id]!;

  /// Re-reads what the account owns from Google Play (handles expiry,
  /// cancellation and refunds). Keeps the cached state when offline.
  static Future<void> refreshEntitlements() async {
    if (!available) return;
    try {
      final add = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      final r = await add.queryPastPurchases();
      if (r.error != null) return;
      final owned = r.pastPurchases.where((p) => p.status == PurchaseStatus.purchased || p.status == PurchaseStatus.restored).map((p) => p.productID).toSet();
      for (final p in r.pastPurchases) {
        if (p.pendingCompletePurchase) await _iap.completePurchase(p);
      }
      _setEntitlements(lifetime: owned.contains(lifetimeId), monthly: owned.contains(monthlyId));
    } catch (e) {
      debugPrint('Entitlement refresh failed: $e');
    }
  }

  static void _setEntitlements({required bool lifetime, required bool monthly}) {
    final d = GameData.I;
    final before = d.adsRemoved;
    d.noAdsLifetime = lifetime || d.noAdsTest == 2;
    d.noAdsMonthly = monthly || d.noAdsTest == 1;
    d.save();
    if (!before && d.adsRemoved) Ads.onAdsRemoved();
  }

  static Future<void> buy(String id) async {
    final d = GameData.I;
    if (id == lifetimeId && d.noAdsLifetime || id == monthlyId && (d.noAdsMonthly || d.noAdsLifetime)) {
      message.value = 'You already have this plan.';
      return;
    }
    final product = products[id];
    if (product == null) {
      message.value = available ? 'This plan is not available yet. Please try again later.' : 'Google Play Store is not available on this device.';
      return;
    }
    busy.value = true;
    message.value = null;
    Ads.skipNextResume();
    try {
      // subscriptions and non-consumables both use buyNonConsumable
      final ok = await _iap.buyNonConsumable(purchaseParam: PurchaseParam(productDetails: product));
      if (!ok) {
        busy.value = false;
        message.value = 'Could not start the purchase.';
      }
    } catch (e) {
      busy.value = false;
      message.value = 'Could not start the purchase: $e';
    }
  }

  static Future<void> restore() async {
    if (!available) {
      message.value = 'Google Play Store is not available on this device.';
      return;
    }
    busy.value = true;
    await refreshEntitlements();
    busy.value = false;
    message.value = GameData.I.adsRemoved ? 'Purchases restored. Ads are removed.' : 'No previous purchases found.';
  }

  /// Debug-only simulated purchase (never compiled into release behaviour).
  static void testPurchase(String id) {
    if (!kDebugMode) return;
    GameData.I.noAdsTest = id == lifetimeId ? 2 : 1;
    _setEntitlements(lifetime: GameData.I.noAdsLifetime, monthly: GameData.I.noAdsMonthly);
    message.value = 'TEST purchase complete (debug build only).';
  }

  static void clearTestPurchase() {
    if (!kDebugMode) return;
    GameData.I.noAdsTest = 0;
    _setEntitlements(lifetime: false, monthly: false);
    message.value = 'TEST purchase cleared.';
  }

  static Future<void> _onPurchases(List<PurchaseDetails> list) async {
    for (final p in list) {
      switch (p.status) {
        case PurchaseStatus.pending:
          message.value = 'Purchase pending… it will apply once Google Play confirms it.';
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          if (ids.contains(p.productID)) {
            _setEntitlements(
              lifetime: GameData.I.noAdsLifetime || p.productID == lifetimeId,
              monthly: GameData.I.noAdsMonthly || p.productID == monthlyId,
            );
            message.value = p.productID == lifetimeId ? 'Thank you! Ads are removed for life.' : 'Thank you! Ads are removed for 1 month (renews monthly).';
          }
          busy.value = false;
          break;
        case PurchaseStatus.error:
          message.value = 'Purchase failed: ${p.error?.message ?? 'unknown error'}';
          busy.value = false;
          break;
        case PurchaseStatus.canceled:
          message.value = 'Purchase cancelled.';
          busy.value = false;
          break;
      }
      // acknowledge so Google Play does not refund it after 3 days
      if (p.pendingCompletePurchase) await _iap.completePurchase(p);
    }
  }
}
