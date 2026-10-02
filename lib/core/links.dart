import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:url_launcher/url_launcher.dart';

import 'ads.dart';

const kPrivacyPolicyUrl = 'https://api.buildprivacypolicy.com/policy/77ad91be-73c2-4d36-b3de-cd948405b315';

/// Opens the privacy policy in an in-app browser tab (falls back to the
/// external browser). Returns false if nothing could open it.
Future<bool> openPrivacyPolicy() async {
  final uri = Uri.parse(kPrivacyPolicyUrl);
  Ads.skipNextResume();
  try {
    if (await launchUrl(uri, mode: LaunchMode.inAppBrowserView)) return true;
  } catch (_) {}
  try {
    return await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {
    return false;
  }
}

/// Whether Google's consent form must offer a way to change the ad-consent
/// choice (EEA, UK and Switzerland).
Future<bool> privacyOptionsRequired() async {
  try {
    return await ConsentInformation.instance.getPrivacyOptionsRequirementStatus() == PrivacyOptionsRequirementStatus.required;
  } catch (_) {
    return false;
  }
}

/// Re-opens Google's ad-consent form so the player can change their choice.
Future<void> showPrivacyOptions() async {
  Ads.skipNextResume();
  await ConsentForm.showPrivacyOptionsForm((FormError? e) {
    if (e != null) debugPrint('Privacy options form error: ${e.message}');
  });
}

/// Small underlined "Privacy Policy" link used on several screens.
class PrivacyLink extends StatelessWidget {
  final Color color;
  final double size;
  const PrivacyLink({super.key, this.color = const Color(0xFF3B8FE0), this.size = 17});
  @override
  Widget build(BuildContext context) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: openPrivacyPolicy,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Privacy Policy',
              style: TextStyle(fontSize: size, fontWeight: FontWeight.w700, color: color, decoration: TextDecoration.underline, decorationColor: color)),
        ),
      );
}
