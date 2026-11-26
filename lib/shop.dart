import 'package:flutter/material.dart';
import 'common.dart';
import 'play.dart' show HeroAvatar, heroes;
import 'gsessions.dart';

// ---------------------------------------------------------------------
// MY CAFE: spend coins on products linked to cellular respiration
// (products, prices and descriptions come from the client's spec)
// ---------------------------------------------------------------------
class Product {
  final String id, name, use, title, tip, emoji;
  final int cost;
  const Product(this.id, this.name, this.cost, this.use, this.title, this.tip, this.emoji);
}

const products = [
  Product('smoothie', 'Glucose Smoothie', 100, 'Supplies glucose, the fuel for cells.', 'Yum!', 'Glucose gives your cells fuel!', '🍹'),
  Product('tea', 'Oxygen Bubble Tea', 100, 'Supplies oxygen, which cells need to release energy.', 'Refreshing!', 'Oxygen helps your cells release energy from food!', '🧋'),
  Product('bar', 'ATP Energy Bar', 150, 'Shows the energy cells make (ATP).', 'Energy up!', 'ATP is the energy currency cells use for work!', '🔋'),
  Product('muffin', 'Mito Muffin', 200, 'Boosts the mitochondria, the powerhouse of the cell.', 'Delicious!', 'Mitochondria are the powerhouse of the cell!', '🧁'),
  Product('bowl', 'Aerobic Smoothie Bowl', 250, 'Combines glucose and oxygen to make a full energy meal.', 'Great mix!', 'Aerobic respiration needs both glucose and oxygen!', '🥗'),
  Product('combo', 'Cell Energy Combo', 400, 'Gives all items: glucose, oxygen, ATP and mitochondria power.', 'Wow!', 'You now have glucose, oxygen, ATP and mitochondria power!', '🍱'),
];

// SAMPLE items for the Session 2 "Mito Lab Shop". The client's Session 2
// document does not list the shop items yet. Replace these when they do.
const mitoProducts = [
  Product('cookie', 'Cristae Cookie', 100, 'Folded like the cristae: more surface, more room!', 'Yum!', 'Cristae are folds that give more surface area!', '🍪'),
  Product('mix', 'Matrix Mix', 100, 'A busy workshop in a cup, like the matrix.', 'Tasty!', 'The matrix is the fluid-filled space inside the inner membrane!', '🥤'),
  Product('spinner', 'ATP Synthase Spinner', 150, 'Spins like the tiny turbine that makes ATP.', 'Spin!', 'ATP synthase spins when protons flow through it!', '🌀'),
  Product('book', 'mtDNA Recipe Book', 200, 'The mitochondrion keeps its own recipe book.', 'Smart!', 'Mitochondrial DNA carries instructions for some proteins!', '📖'),
  Product('kit', 'Ribosome Builder Kit', 250, 'Tiny builders that link beads into proteins.', 'Nice build!', 'Ribosomes are tiny protein builders!', '🧩'),
  Product('coat', 'Mito Lab Coat', 400, 'Dress like a real mitochondria scientist.', 'Wow!', 'Every part of the mitochondrion has a job!', '🥼'),
];

class ShopScreen extends StatefulWidget {
  final int session;
  const ShopScreen({super.key, this.session = 1});
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  int tab = 0;
  bool get s2 => widget.session == 2;
  bool get gen => isGeneric(widget.session);
  List<Product> get items => gen ? specFor(widget.session)!.products : (s2 ? mitoProducts : products);
  String get shopName => gen ? specFor(widget.session)!.shopName : (s2 ? 'Mito Lab Shop' : 'My Cafe');
  double get cardW => items.length > 6 ? 104 : 140;
  Product? detail, bought;

  Widget productCard(Product p) {
    final owned = Store.bag.value.contains(p.id);
    final afford = Store.coins.value >= p.cost;
    final gray = !afford && !owned;
    Widget card = Container(
      width: cardW,
      height: 178,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE0B97A), width: 3), boxShadow: const [BoxShadow(color: Colors.black38, blurRadius: 8, offset: Offset(0, 4))]),
      child: Column(children: [
        Expanded(child: Center(child: Text(p.emoji, style: TextStyle(fontSize: items.length > 6 ? 40 : 52)))),
        Text(p.name, textAlign: TextAlign.center, maxLines: 2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF4A2C0A), height: 1.15)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
          decoration: BoxDecoration(color: owned ? cGreen : const Color(0xFFFFE9B0), borderRadius: BorderRadius.circular(12)),
          child: owned
              ? const Text('Owned', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0B3D1B)))
              : Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star_rounded, size: 16, color: Color(0xFFFFA000)),
                  const SizedBox(width: 4),
                  Text('${p.cost}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: Color(0xFF4A2C0A))),
                ]),
        ),
      ]),
    );
    if (gray) card = Opacity(opacity: 0.5, child: ColorFiltered(colorFilter: const ColorFilter.mode(Colors.grey, BlendMode.saturation), child: card));
    return Pressable(onTap: () => setState(() => detail = p), child: card);
  }

  Widget menuTab() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        for (var i = 0; i < items.length; i++) ...[productCard(items[i]), if (i < items.length - 1) const SizedBox(width: 10)],
      ]);

  Widget bagTab() {
    final mine = items.where((p) => Store.bag.value.contains(p.id)).toList();
    return Row(children: [
      const SizedBox(width: 30),
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        HeroAvatar(hero: Store.hero.value, size: 120),
        const SizedBox(height: 4),
        Text(heroName(), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
      ]),
      const SizedBox(width: 24),
      Expanded(
        child: mine.isEmpty
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: panelDeco(),
                child: const Text('Your bag is empty. Buy something from the Menu!', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              )
            : Wrap(spacing: 12, runSpacing: 12, children: [
                for (final p in mine)
                  Container(
                    width: 110,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: const Color(0xFFFFF6E5), borderRadius: BorderRadius.circular(14), border: Border.all(color: cGreen, width: 3)),
                    child: Column(children: [
                      Text(p.emoji, style: const TextStyle(fontSize: 38)),
                      Text(p.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: Color(0xFF4A2C0A))),
                    ]),
                  ),
              ]),
      ),
      const SizedBox(width: 30),
    ]);
  }

  String heroName() => heroes[Store.hero.value.clamp(0, 3).toInt()].name;

  Widget tabBtn(String label, int i, IconData ic) => Pressable(
        onTap: () => setState(() => tab = i),
        child: Container(
          width: 150,
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(21),
            gradient: tab == i ? const LinearGradient(colors: [Color(0xFFFFB74D), Color(0xFFFF8A1F)]) : null,
            color: tab == i ? null : cPanel,
            border: Border.all(color: Colors.white54, width: 2),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(ic, size: 20), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900))]),
        ),
      );

  Widget overlay(Widget child) => Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.7), alignment: Alignment.center, child: child));

  Widget detailCard(Product p) {
    final owned = Store.bag.value.contains(p.id);
    final afford = Store.coins.value >= p.cost;
    return overlay(Container(
      width: 740,
      height: 360,
      padding: const EdgeInsets.all(22),
      decoration: panelDeco(),
      child: Column(children: [
        Row(children: [
          Pressable(onTap: () => setState(() => detail = null), child: const Icon(Icons.arrow_back_rounded, size: 36)),
          const SizedBox(width: 12),
          Text(shopName, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF7CD4FF))),
          const Spacer(),
          CoinPill(coins: Store.coins.value),
        ]),
        const SizedBox(height: 10),
        Expanded(
          child: Row(children: [
            Container(
              width: 200,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFB74D).withValues(alpha: 0.5), Colors.transparent])),
              child: Text(p.emoji, style: const TextStyle(fontSize: 120)),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Row(children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFC107), size: 36),
                  const SizedBox(width: 6),
                  Text('${p.cost}', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFFFD54F))),
                ]),
                const SizedBox(height: 8),
                Text(p.use, style: const TextStyle(fontSize: 21, height: 1.3)),
                const SizedBox(height: 14),
                GlowButton(
                  label: owned ? 'Owned' : (afford ? 'Buy' : 'Need ${p.cost - Store.coins.value} more coins'),
                  width: 320,
                  height: 58,
                  font: 26,
                  onTap: (owned || !afford)
                      ? null
                      : () {
                          if (Store.buy(p.id, p.cost)) {
                            setState(() {
                              detail = null;
                              bought = p;
                            });
                          }
                        },
                ),
              ]),
            ),
          ]),
        ),
      ]),
    ));
  }

  Widget tipCard(Product p) => overlay(Container(
        width: 640,
        height: 320,
        padding: const EdgeInsets.all(22),
        decoration: panelDeco(border: cGreen),
        child: Column(children: [
          Expanded(
            child: Row(children: [
              Container(
                width: 190,
                alignment: Alignment.center,
                decoration: BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [const Color(0xFFFFD54F).withValues(alpha: 0.6), Colors.transparent])),
                child: Stack(alignment: Alignment.center, children: [
                  Text(p.emoji, style: const TextStyle(fontSize: 100)),
                  const Positioned(top: 18, left: 18, child: Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 30)),
                  const Positioned(bottom: 20, right: 20, child: Icon(Icons.auto_awesome, color: Color(0xFFFFD54F), size: 26)),
                ]),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.title, style: const TextStyle(fontSize: 44, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(p.tip, style: const TextStyle(fontSize: 24, height: 1.3)),
                ]),
              ),
            ]),
          ),
          GlowButton(label: 'OK', width: 220, height: 56, font: 26, onTap: () => setState(() => bought = null)),
        ]),
      ));

  @override
  Widget build(BuildContext context) {
    return Stage(
      child: AnimatedBuilder(
        animation: Listenable.merge([Store.coins, Store.bag]),
        builder: (_, __) => Stack(children: [
          // cozy cafe scene
          Positioned(
            left: 14,
            top: 10,
            right: 14,
            bottom: 10,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF6B3E1F), Color(0xFF8D5A2B), Color(0xFFB07840)])),
                child: Stack(children: [
                  Positioned(left: 330, top: 30, child: Container(width: 90, height: 100, decoration: BoxDecoration(color: const Color(0xFFFFCC80).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(40), border: Border.all(color: const Color(0xFF4E2A0E), width: 6)))),
                  Positioned(left: 560, top: 30, child: Container(width: 90, height: 100, decoration: BoxDecoration(color: const Color(0xFFFFCC80).withValues(alpha: 0.8), borderRadius: BorderRadius.circular(40), border: Border.all(color: const Color(0xFF4E2A0E), width: 6)))),
                  const Positioned(left: 700, top: 70, child: Text('🪴', style: TextStyle(fontSize: 60))),
                  const Positioned(left: 190, top: 60, child: Text('🪴', style: TextStyle(fontSize: 44))),
                  Positioned(left: 0, right: 0, top: 150, child: Container(height: 10, color: const Color(0xFF4E2A0E).withValues(alpha: 0.6))),
                ]),
              ),
            ),
          ),
          // header
          Positioned(
            left: 28,
            top: 22,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF3A2008), borderRadius: BorderRadius.circular(22)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(s2 && !gen ? Icons.science_rounded : Icons.local_cafe_rounded, size: 26), const SizedBox(width: 8), Text(shopName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900))]),
            ),
          ),
          Positioned(right: 80, top: 22, child: CoinPill(coins: Store.coins.value)),
          const Positioned(right: 24, top: 22, child: HomeButton()),
          // hero + speech bubble
          Positioned(left: 40, top: 78, child: HeroAvatar(hero: Store.hero.value, size: 130)),
          Positioned(
            left: 190,
            top: 84,
            child: Container(
              width: 230,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Text(gen ? 'Spend your coins on items you learned about!' : (s2 ? 'Spend your coins on items for your mitochondria!' : 'Spend your coins on healthy items for your cells!'), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF4A2C0A), height: 1.25)),
            ),
          ),
          // products or bag
          Positioned(left: 24, right: 24, top: 218, height: 190, child: tab == 0 ? menuTab() : bagTab()),
          // tabs and finish
          Positioned(
            left: 0,
            right: 0,
            top: 428,
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              tabBtn('Menu', 0, Icons.restaurant_menu_rounded),
              const SizedBox(width: 12),
              tabBtn('My Items', 1, Icons.shopping_bag_rounded),
            ]),
          ),
          Positioned(
            right: 36,
            bottom: 24,
            child: GlowButton(
              label: 'Finish',
              icon: Icons.flag_rounded,
              width: 170,
              height: 50,
              onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => WeekCompleteScreen(session: widget.session))),
            ),
          ),
          if (detail != null) detailCard(detail!),
          if (bought != null) tipCard(bought!),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// FINISH: ends the session and shows the "Week 1 complete" badge
// ---------------------------------------------------------------------
class WeekCompleteScreen extends StatefulWidget {
  final int session;
  const WeekCompleteScreen({super.key, this.session = 1});
  @override
  State<WeekCompleteScreen> createState() => _WeekCompleteScreenState();
}

class _WeekCompleteScreenState extends State<WeekCompleteScreen> {
  @override
  void initState() {
    super.initState();
    Store.mark('finish');
  }

  @override
  Widget build(BuildContext context) => Stage(
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 210,
              height: 210,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(center: Alignment(-0.3, -0.4), colors: [Color(0xFFFFF59D), Color(0xFFFFC107), Color(0xFFFF8F00)]),
                border: Border.all(color: Colors.white, width: 8),
                boxShadow: [BoxShadow(color: const Color(0xFFFFC107).withValues(alpha: 0.8), blurRadius: 40, spreadRadius: 4)],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.emoji_events_rounded, size: 84, color: Color(0xFF7A3E00)),
                Text(isGeneric(widget.session) ? specFor(widget.session)!.week : (widget.session == 2 ? 'SESSION 2' : 'WEEK 1'), style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Color(0xFF7A3E00))),
              ]),
            ),
            const SizedBox(height: 16),
            Text(isGeneric(widget.session) ? 'Week ${widget.session} complete!' : (widget.session == 2 ? 'Session 2 complete!' : 'Week 1 complete!'), style: const TextStyle(fontSize: 46, fontWeight: FontWeight.w900)),
            Text(isGeneric(widget.session) ? specFor(widget.session)!.doneMsg : (widget.session == 2 ? 'You learned the parts of the mitochondrion.' : 'You learned how cells turn food into energy.'), style: const TextStyle(fontSize: 20, color: Colors.white70)),
            const SizedBox(height: 18),
            GlowButton(label: 'Back to Home', icon: Icons.home_rounded, width: 300, height: 58, font: 24, onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
          ]),
        ),
      );
}
