import 'package:flutter/material.dart';

import '../core/ads.dart';
import '../core/catalog.dart';
import '../core/data.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/painters.dart';
import 'home.dart';
import 'onboarding.dart';

/// Logo + "Loading..." bar, then the home screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..forward();

  @override
  void initState() {
    super.initState();
    _a.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) _next();
    });
  }

  Future<void> _next() async {
    if (!GameData.I.onboarded) {
      // first launch: onboarding before anything else (no ads)
      Navigator.of(context).pushReplacement(fadeRoute(const OnboardingScreen()));
      return;
    }
    await Ads.showAppOpenOnLaunch();
    if (mounted) Navigator.of(context).pushReplacement(fadeRoute(const HomeScreen()));
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DesignScreen(
      child: Column(children: [
        const SizedBox(height: 372),
        PaintBox(140, 160, (c, s) {
          c.translate(70, 84);
          c.scale(1.75);
          drawGlass(c, glassSkins[0], fill: .82, water: C.water, expr: Expr.happy, dotted: true);
        }),
        Text('WATER', style: txt(84, w: FontWeight.w900, h: 1.0)),
        Text('GLASS', style: txt(84, w: FontWeight.w900, c: C.blue, h: 1.0)),
        const SizedBox(height: 40),
        Text('Loading...', style: txt(26, w: FontWeight.w500)),
        const SizedBox(height: 10),
        AnimatedBuilder(
          animation: _a,
          builder: (_, __) => Container(
            width: 300,
            height: 34,
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFF222222), width: 2.4)),
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(widthFactor: Curves.easeInOut.transform(_a.value), child: Container(color: const Color(0xFFADDC45))),
          ),
        ),
        if (GameData.I.onboarded && !GameData.I.adsRemoved) ...[
          const SizedBox(height: 60),
          Text("Ad may show while we're loading...", style: txt(22, w: FontWeight.w500)),
        ],
      ]),
    );
  }
}
