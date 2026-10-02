import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/ads.dart';
import '../core/audio.dart';
import '../core/data.dart';
import '../core/links.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'dialogs.dart';
import 'remove_ads.dart';

const kSupportEmail = 'aakashmangukiya10@gmail.com';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _consentOptions = false;

  @override
  void initState() {
    super.initState();
    privacyOptionsRequired().then((v) => mounted ? setState(() => _consentOptions = v) : null);
  }

  Widget _btn(String t, double w, VoidCallback onTap) => Pill(t, w: w, h: 80, fs: GameData.I.lang == 'ja' ? (w < 200 ? 13 : 18) : 20, onTap: onTap);

  @override
  Widget build(BuildContext context) {
    final d = GameData.I;
    return DesignScreen(
      child: Stack(children: [
        Positioned(left: 10, top: 56, child: BackArrow(onTap: () => Navigator.of(context).pop())),
        Positioned(
          left: 0,
          right: 0,
          top: 340,
          child: Column(children: [
            Text(tr('SETTINGS'), style: txt(34, w: FontWeight.w500, sp: 9)),
            const SizedBox(height: 46),
            _btn(tr('ENGLISH'), 364, () {
              d.lang = d.lang == 'en' ? 'ja' : 'en';
              d.save();
              setState(() {});
            }),
            const SizedBox(height: 18),
            ListenableBuilder(
              listenable: d,
              builder: (_, __) => _btn(d.adsRemoved ? tr('ADS REMOVED') : tr('REMOVE ADS'), 364, () => Navigator.of(context).push(fadeRoute(const RemoveAdsScreen()))),
            ),
            const SizedBox(height: 18),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              _btn(tr(d.music ? 'MUSIC: ON' : 'MUSIC: OFF'), 188, () {
                d.music = !d.music;
                d.save();
                Sfx.syncMusic();
                setState(() {});
              }),
              const SizedBox(width: 16),
              _btn(tr(d.sfx ? 'SFX: ON' : 'SFX: OFF'), 188, () {
                d.sfx = !d.sfx;
                d.save();
                setState(() {});
              }),
            ]),
            const SizedBox(height: 18),
            _btn(tr('CONTACT US'), 364, _contact),
            const SizedBox(height: 18),
            _btn(tr('PRIVACY POLICY'), 364, () async {
              if (!await openPrivacyPolicy() && context.mounted) {
                await showMessage(context, tr('PRIVACY POLICY'), 'Could not open the link.\n$kPrivacyPolicyUrl');
              }
            }),
            if (_consentOptions) ...[
              const SizedBox(height: 18),
              _btn(tr('PRIVACY SETTINGS'), 364, showPrivacyOptions),
            ],
          ]),
        ),
      ]),
    );
  }

  /// Opens the mail app addressed to support; shows the address if none.
  Future<void> _contact() async {
    final uri = Uri(scheme: 'mailto', path: kSupportEmail, query: 'subject=${Uri.encodeComponent('Water Glass Support')}');
    var opened = false;
    try {
      Ads.skipNextResume();
      opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
    if (!opened && mounted) {
      await showMessage(context, tr('CONTACT US'), 'No email app found.\nPlease write to us at:\n$kSupportEmail');
    }
  }
}
