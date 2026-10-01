import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/data.dart';
import '../core/theme.dart';
import 'painters.dart';

/// Design resolution of the reference video (portrait phone).
const double kW = 576, kH = 1280;

/// Graph-paper background seen on every screen.
class GridBackground extends StatelessWidget {
  const GridBackground({super.key});
  @override
  Widget build(BuildContext context) => const SizedBox.expand(child: CustomPaint(painter: _GridPainter()));
}

class _GridPainter extends CustomPainter {
  const _GridPainter();
  @override
  void paint(Canvas c, Size s) {
    c.drawRect(Offset.zero & s, fillP(C.bg));
    final step = s.width / 24;
    final p = Paint()
      ..color = C.grid
      ..strokeWidth = 1;
    for (var x = 0.0; x < s.width; x += step) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (var y = 0.0; y < s.height; y += step) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

/// Grid background + content laid out in 576x1280 design units, scaled to fit.
class DesignScreen extends StatelessWidget {
  final Widget child;
  final Color? tint;
  const DesignScreen({super.key, required this.child, this.tint});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: C.bg,
      child: Stack(children: [
        const GridBackground(),
        if (tint != null) Positioned.fill(child: ColoredBox(color: tint!)),
        SafeArea(
          child: Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(width: kW, height: kH, child: child),
            ),
          ),
        ),
      ]),
    );
  }
}

/// Press feedback (scale down) + click sound.
class Tap extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool sound;
  const Tap({super.key, required this.child, this.onTap, this.sound = true});
  @override
  State<Tap> createState() => _TapState();
}

class _TapState extends State<Tap> {
  bool _down = false;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: widget.onTap == null ? null : (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: widget.onTap == null ? null : (_) => setState(() => _down = false),
      onTap: widget.onTap == null
          ? null
          : () {
              if (widget.sound) Sfx.click();
              widget.onTap!();
            },
      child: AnimatedScale(scale: _down ? .92 : 1, duration: const Duration(milliseconds: 90), child: widget.child),
    );
  }
}

/// Rounded green pill button with dark outline and spaced capitals.
class Pill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double w, h, fs;
  final Color color;
  final Widget? icon;
  final Color textColor;
  const Pill(this.text,
      {super.key, this.onTap, this.w = 340, this.h = 96, this.fs = 30, this.color = C.green, this.icon, this.textColor = C.ink});
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(h / 2),
          border: Border.all(color: const Color(0xFF222222), width: 2.2),
        ),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[icon!, SizedBox(width: fs * .5)],
          Text(text, style: txt(fs, w: FontWeight.w700, sp: fs * .2, c: textColor)),
        ]),
      ),
    );
  }
}

/// Blue "GET 10x (coin)" rewarded-video button.
class AdPill extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final double w, h;
  final bool coin;
  const AdPill(this.text, {super.key, this.onTap, this.w = 340, this.h = 96, this.coin = true});
  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          color: C.btnBlue,
          borderRadius: BorderRadius.circular(h / 2),
          border: Border.all(color: const Color(0xFF222222), width: 2.2),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          PaintBox(54, 50, (c, s) => drawClapper(c, const Rect.fromLTWH(4, 8, 46, 40))),
          const SizedBox(width: 12),
          Text(text, style: txt(30, w: FontWeight.w600, c: C.ink)),
          if (coin) ...[const SizedBox(width: 4), PaintBox(32, 32, (c, s) => drawCoin(c, const Offset(16, 16), 14))],
        ]),
      ),
    );
  }
}

/// Coin icon + live coin total.
class CoinCounter extends StatelessWidget {
  final double size;
  const CoinCounter({super.key, this.size = 46});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameData.I,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
        PaintBox(size + 6, size + 6, (c, s) => drawCoin(c, Offset(s.width / 2, s.height / 2), size / 2)),
        const SizedBox(width: 4),
        Text('${GameData.I.coins}', style: txt(size * .62, w: FontWeight.w500, sp: size * .1)),
      ]),
    );
  }
}

class StarCounter extends StatelessWidget {
  final double size;
  final int total;
  const StarCounter({super.key, this.size = 44, required this.total});
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: GameData.I,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
        PaintBox(size, size, (c, s) => drawStar(c, Offset(s.width / 2, s.height / 2), size * .48)),
        const SizedBox(width: 6),
        Text('${GameData.I.totalStars}/$total', style: txt(size * .74, w: FontWeight.w500, sp: size * .1)),
      ]),
    );
  }
}

class IconTap extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  const IconTap(this.icon, {super.key, this.onTap, this.size = 62});
  @override
  Widget build(BuildContext context) =>
      Tap(onTap: onTap, child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: size, color: const Color(0xFF222222))));
}

/// Outlined back arrow used in the top-left corner of sub screens.
class BackArrow extends StatelessWidget {
  final VoidCallback onTap;
  const BackArrow({super.key, required this.onTap});
  @override
  Widget build(BuildContext context) => Tap(
      onTap: onTap,
      child: SizedBox(
          width: 80,
          height: 70,
          child: PaintBox(80, 70, (c, s) {
            final p = Path()
              ..moveTo(12, 35)
              ..lineTo(36, 14)
              ..lineTo(36, 26)
              ..lineTo(66, 26)
              ..lineTo(66, 44)
              ..lineTo(36, 44)
              ..lineTo(36, 56)
              ..close();
            c.drawPath(p, fillP(Colors.white));
            c.drawPath(p, strokeP(const Color(0xFF222222), 2.6));
          })));
}

/// White rounded card used for popups.
class PopupCard extends StatelessWidget {
  final Widget child;
  final double width;
  const PopupCard({super.key, required this.child, this.width = 460});
  @override
  Widget build(BuildContext context) => Container(
        width: width,
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFDDDDDD), width: 2),
        ),
        child: child,
      );
}

/// Show a dimmed full-screen popup laid out in design units.
Future<T?> showPopup<T>(BuildContext context, Widget Function(BuildContext ctx) builder, {bool dismissible = false}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierLabel: 'popup',
    barrierColor: const Color(0x99000000),
    transitionDuration: const Duration(milliseconds: 220),
    transitionBuilder: (ctx, a, _, child) => FadeTransition(
      opacity: a,
      child: ScaleTransition(scale: Tween(begin: .85, end: 1.0).animate(CurvedAnimation(parent: a, curve: Curves.easeOutBack)), child: child),
    ),
    pageBuilder: (ctx, _, __) => SafeArea(
      child: Center(
        child: FittedBox(
          child: SizedBox(width: kW, height: kH, child: Center(child: Material(type: MaterialType.transparency, child: builder(ctx)))),
        ),
      ),
    ),
  );
}

Route<T> fadeRoute<T>(Widget page) => PageRouteBuilder<T>(
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
    );

/// Simple "rewarded video" stand-in: there is no ad network in this build, so
/// rewarded buttons grant their reward after a short sponsor card.
Future<bool> watchRewardAd(BuildContext context) async {
  final r = await showPopup<bool>(context, (ctx) => const _AdCard());
  return r ?? false;
}

class _AdCard extends StatefulWidget {
  const _AdCard();
  @override
  State<_AdCard> createState() => _AdCardState();
}

class _AdCardState extends State<_AdCard> with SingleTickerProviderStateMixin {
  late final AnimationController _a = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..forward();
  @override
  void initState() {
    super.initState();
    _a.addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) Navigator.of(context).pop(true);
    });
  }

  @override
  void dispose() {
    _a.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopupCard(
        width: 420,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          PaintBox(90, 80, (c, s) => drawClapper(c, const Rect.fromLTWH(10, 14, 70, 60))),
          const SizedBox(height: 16),
          Text('REWARD', style: txt(26, w: FontWeight.w700, sp: 5)),
          const SizedBox(height: 18),
          AnimatedBuilder(
            animation: _a,
            builder: (_, __) => Container(
              width: 300,
              height: 22,
              decoration: BoxDecoration(border: Border.all(color: const Color(0xFF222222), width: 2), color: Colors.white),
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(widthFactor: _a.value, child: Container(color: C.green)),
            ),
          ),
        ]),
      );
}
