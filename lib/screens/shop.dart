import 'package:flutter/material.dart';

import '../core/audio.dart';
import '../core/catalog.dart';
import '../core/data.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import '../widgets/hud.dart';
import '../widgets/painters.dart';
import 'dialogs.dart';

/// CATEGORY shop: pens, glass skins, water colours, ink colours.
class ShopScreen extends StatefulWidget {
  final int tab;
  const ShopScreen({super.key, this.tab = 0});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  late int tab = widget.tab;

  Future<bool> _buy(int price) async {
    final d = GameData.I;
    if (d.coins < price) {
      await showMessage(context, 'Whoops!', 'You need more coins\nto unlock this item.');
      return false;
    }
    d.coins -= price;
    Sfx.play('coin');
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return DesignScreen(
      child: Column(children: [
        BackCoinsBar(onBack: () => Navigator.of(context).pop()),
        const SizedBox(height: 50),
        Text(tr('CATEGORY'), style: txt(34, w: FontWeight.w500, sp: 9)),
        const SizedBox(height: 22),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          for (var i = 0; i < 4; i++)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Tap(
                onTap: () => setState(() => tab = i),
                child: Container(
                  width: 104,
                  height: 82,
                  decoration: BoxDecoration(
                    color: tab == i ? C.green : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF222222), width: 2),
                  ),
                  child: PaintBox(104, 82, _tabIcon(i)),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 16),
        Expanded(child: ListenableBuilder(listenable: GameData.I, builder: (_, __) => _grid())),
      ]),
    );
  }

  void Function(Canvas, Size) _tabIcon(int i) => (c, s) {
        final o = Offset(s.width / 2, s.height / 2);
        final p = strokeP(const Color(0xFF222222), 2.2);
        switch (i) {
          case 0:
            c.save();
            c.translate(o.dx, o.dy);
            c.rotate(.8);
            c.drawRect(const Rect.fromLTWH(-6, -18, 12, 28), p);
            c.drawPath(
                Path()
                  ..moveTo(-6, 10)
                  ..lineTo(0, 20)
                  ..lineTo(6, 10),
                p);
            c.restore();
            break;
          case 1:
            for (final s in [-1.0, 1.0]) {
              c.drawCircle(o + Offset(s * 11, -4), 8, p);
              c.drawCircle(o + Offset(s * 11, -2), 3.5, fillP(const Color(0xFF222222)));
            }
            c.drawArc(Rect.fromCenter(center: o + const Offset(0, 10), width: 16, height: 10), .2, 2.7, false, p);
            break;
          case 2:
            final d = Path()
              ..moveTo(o.dx, o.dy - 18)
              ..quadraticBezierTo(o.dx - 14, o.dy + 2, o.dx - 11, o.dy + 9)
              ..arcToPoint(o + const Offset(11, 9), radius: const Radius.circular(12), clockwise: false)
              ..quadraticBezierTo(o.dx + 14, o.dy + 2, o.dx, o.dy - 18);
            c.drawPath(d, p);
            break;
          default:
            drawInkJar(c, o, 42, const Color(0xFF111111));
        }
      };

  Widget _grid() {
    final d = GameData.I;
    switch (tab) {
      case 0:
        return _twoCol(pens.length, 128, (i) {
          final owned = d.ownedPens.contains(i);
          return _Card(
            used: d.pen == i,
            price: owned ? null : pens[i].price,
            art: PaintBox(110, 110, (c, s) => drawPen(c, const Offset(16, 98), 108, pens[i].style)),
            onTap: () async {
              if (!owned && !await _buy(pens[i].price)) return;
              d.ownedPens.add(i);
              d.pen = i;
              d.save();
            },
          );
        });
      case 1:
        return _twoCol(glassSkins.length, 228, (i) {
          final owned = d.ownedGlasses.contains(i);
          return _Card(
            used: d.glass == i,
            vertical: true,
            price: owned ? null : glassSkins[i].price,
            art: PaintBox(150, 160, (c, s) {
              c.translate(75, 80);
              c.scale(1.85);
              drawGlass(c, glassSkins[i], fill: .7, water: waterColors[d.water], expr: Expr.happy, dotted: false);
            }),
            onTap: () async {
              if (!owned && !await _buy(glassSkins[i].price)) return;
              d.ownedGlasses.add(i);
              d.glass = i;
              d.save();
            },
          );
        });
      case 2:
        return Column(children: [
          Text('Unlocked by filling the Water Bottle\nin Classic Game mode', textAlign: TextAlign.center, style: txt(22, w: FontWeight.w500, h: 1.4)),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(70, 0, 70, 40),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 18, crossAxisSpacing: 18),
              itemCount: waterColors.length,
              itemBuilder: (_, i) {
                final open = i < d.unlockedWaters;
                return Tap(
                  onTap: open
                      ? () {
                          d.water = i;
                          d.save();
                        }
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: waterColors[i],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF222222), width: 2),
                    ),
                    child: Stack(children: [
                      if (!open) Center(child: PaintBox(70, 76, (c, s) => drawLock(c, const Offset(35, 38), 64))),
                      if (d.water == i) ...[
                        Positioned(left: 8, top: 8, child: _check()),
                        Positioned(left: 0, right: 0, bottom: 10, child: Text('USED', textAlign: TextAlign.center, style: txt(20, w: FontWeight.w600, sp: 3))),
                      ],
                    ]),
                  ),
                );
              },
            ),
          ),
        ]);
      default:
        return _twoCol(inks.length, 128, (i) {
          final it = inks[i];
          final owned = d.inkOwned(i);
          Widget? side;
          if (!owned && it.unlock == UnlockKind.ad) {
            side = Container(
              width: 116,
              height: 60,
              decoration: BoxDecoration(color: C.btnBlue, borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF222222), width: 2)),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                PaintBox(28, 28, (c, s) {
                  c.drawRect(const Rect.fromLTWH(2, 2, 24, 24), fillP(C.coin));
                  c.drawRect(const Rect.fromLTWH(2, 2, 24, 24), strokeP(const Color(0xFF222222), 1.6));
                  c.drawPath(
                      Path()
                        ..moveTo(10, 8)
                        ..lineTo(10, 20)
                        ..lineTo(20, 14)
                        ..close(),
                      strokeP(const Color(0xFF222222), 1.6));
                }),
                const SizedBox(width: 6),
                Text('FREE', style: txt(18, w: FontWeight.w600, c: Colors.white, sp: 2)),
              ]),
            );
          } else if (!owned) {
            side = Column(mainAxisSize: MainAxisSize.min, children: [
              PaintBox(40, 44, (c, s) => drawLock(c, const Offset(20, 22), 38)),
              Text("Don't Spill\nLevel ${it.dsLevel}", textAlign: TextAlign.center, style: txt(16, w: FontWeight.w500, h: 1.2)),
            ]);
          }
          return _Card(
            used: d.ink == i,
            side: side,
            art: PaintBox(90, 100, (c, s) => drawInkJar(c, const Offset(45, 54), 80, it.color, ink2: it.color2)),
            onTap: () async {
              if (!owned) {
                if (it.unlock != UnlockKind.ad) {
                  await showMessage(context, 'Locked', "Complete Don't Spill\nlevel ${it.dsLevel} to unlock.");
                  return;
                }
                if (!await watchRewardAd(context)) return;
                d.ownedInks.add(i);
              }
              d.ink = i;
              d.save();
            },
          );
        });
    }
  }

  Widget _twoCol(int n, double h, Widget Function(int) item) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(52, 0, 52, 40),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 18, crossAxisSpacing: 22, childAspectRatio: 224 / h),
        itemCount: n,
        itemBuilder: (_, i) => item(i),
      );
}

Widget _check() => PaintBox(40, 40, (c, s) {
      c.drawCircle(const Offset(20, 20), 18, fillP(const Color(0xFF7CC242)));
      c.drawCircle(const Offset(20, 20), 18, strokeP(Colors.white, 2));
      c.drawPath(
          Path()
            ..moveTo(11, 20)
            ..lineTo(18, 27)
            ..lineTo(30, 13),
          strokeP(Colors.white, 3.4));
    });

class _Card extends StatelessWidget {
  final bool used;
  final int? price;
  final Widget art;
  final Widget? side;
  final bool vertical;
  final VoidCallback onTap;
  const _Card({required this.used, required this.art, required this.onTap, this.price, this.side, this.vertical = false});

  Widget _label() {
    if (used) return Text('USED', style: txt(22, w: FontWeight.w600, sp: 4));
    if (side != null) return side!;
    if (price == null || price == 0) return Text('OWNED', style: txt(18, w: FontWeight.w600, sp: 2, c: const Color(0xFF666666)));
    return Row(mainAxisSize: MainAxisSize.min, children: [
      PaintBox(30, 30, (c, s) => drawCoin(c, const Offset(15, 15), 12)),
      const SizedBox(width: 6),
      Text('$price', style: txt(24, w: FontWeight.w500, sp: 2)),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Tap(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF222222), width: 2),
          boxShadow: const [BoxShadow(color: Color(0x33000000), offset: Offset(0, 3))],
        ),
        child: Stack(children: [
          if (vertical)
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [art, const SizedBox(height: 10), _label()])
          else
            Row(children: [const SizedBox(width: 4), art, Expanded(child: Center(child: _label())), const SizedBox(width: 4)]),
          if (used) Positioned(left: 4, top: 4, child: _check()),
        ]),
      ),
    );
  }
}
