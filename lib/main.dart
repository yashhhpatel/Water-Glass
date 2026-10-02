import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/ads.dart';
import 'core/audio.dart';
import 'core/billing.dart';
import 'core/data.dart';
import 'screens/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await GameData.I.load();
  try {
    await Sfx.init();
  } catch (_) {}
  runApp(const WaterGlassApp());
  // ads and billing start in the background so the splash is never blocked
  Billing.init();
  Ads.init();
}

class WaterGlassApp extends StatefulWidget {
  const WaterGlassApp({super.key});
  @override
  State<WaterGlassApp> createState() => _WaterGlassAppState();
}

class _WaterGlassAppState extends State<WaterGlassApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) Sfx.pauseAll();
    if (state == AppLifecycleState.resumed) {
      Sfx.resume();
      Ads.onResume();
      Billing.refreshEntitlements();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Glass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: false, scaffoldBackgroundColor: Colors.white),
      home: const SplashScreen(),
    );
  }
}
