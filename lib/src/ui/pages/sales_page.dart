part of '../../../main.dart';

class CaissePage extends StatelessWidget {
  const CaissePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 840;
        if (wide) {
          return Row(
            children: [
              SizedBox(width: 240, child: PlayerPanel(controller: controller)),
              const VerticalDivider(width: 1, color: AppColors.border),
              Expanded(child: ProductsPanel(controller: controller)),
              const VerticalDivider(width: 1, color: AppColors.border),
              SizedBox(width: 320, child: CartPanel(controller: controller)),
            ],
          );
        }
        return Column(
          children: [
            SizedBox(
                height: 150,
                child: PlayerPanel(controller: controller, compact: true)),
            const Divider(height: 1, color: AppColors.border),
            Expanded(child: ProductsPanel(controller: controller)),
            SizedBox(height: 285, child: CartPanel(controller: controller)),
          ],
        );
      },
    );
  }
}

class PlayerPanel extends StatefulWidget {
  const PlayerPanel(
      {required this.controller, this.compact = false, super.key});

  final AppController controller;
  final bool compact;

  @override
  State<PlayerPanel> createState() => _PlayerPanelState();
}

class _PlayerPanelState extends State<PlayerPanel> {
  final searchController = TextEditingController();

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = searchController.text.trim().toLowerCase();
    final filteredPlayers = widget.controller.players
        .where((player) => player.name.toLowerCase().contains(query))
        .toList();
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionTitle(
            'Joueur',
            trailing: IconButton.filledTonal(
              onPressed: () => showPlayerDialog(context, widget.controller),
              icon: const Icon(Icons.person_add),
              tooltip: 'Nouveau joueur',
            ),
          ),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              isDense: true,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Effacer la recherche',
                      onPressed: () => setState(searchController.clear),
                      icon: const Icon(Icons.close),
                    ),
              hintText: 'Rechercher un joueur',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.controller.players.isEmpty
                ? Center(
                    child: FilledButton.icon(
                      onPressed: () =>
                          showPlayerDialog(context, widget.controller),
                      icon: const Icon(Icons.person_add),
                      label: const Text('Ajouter un joueur'),
                    ),
                  )
                : filteredPlayers.isEmpty
                    ? const Center(
                        child: Text('Aucun joueur trouvé',
                            style: TextStyle(color: AppColors.muted)))
                    : ListView.separated(
                        scrollDirection:
                            widget.compact ? Axis.horizontal : Axis.vertical,
                        itemCount: filteredPlayers.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 8, height: 8),
                        itemBuilder: (context, index) {
                          final player = filteredPlayers[index];
                          final selected =
                              widget.controller.selectedPlayerId == player.id;
                          final count = widget.controller.sales
                              .where((s) => s.playerId == player.id)
                              .length;
                          return ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth: widget.compact ? 220 : 0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(8),
                              onTap: () =>
                                  widget.controller.selectPlayer(player),
                              child: TacticalCard(
                                borderColor: selected
                                    ? AppColors.accent
                                    : AppColors.border,
                                child: Row(
                                  children: [
                                    Icon(
                                        player.isMember
                                            ? Icons.verified_user
                                            : Icons.person,
                                        color: player.isMember
                                            ? AppColors.accent2
                                            : AppColors.muted),
                                    const SizedBox(width: 8),
                                    Expanded(
                                        child: Text(player.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.w700))),
                                    if (count > 0)
                                      Chip(
                                          label: Text('$count'),
                                          visualDensity: VisualDensity.compact),
                                    IconButton(
                                      tooltip: 'Modifier le joueur',
                                      onPressed: () => showPlayerDialog(
                                          context, widget.controller,
                                          player: player),
                                      icon: const Icon(Icons.edit, size: 18),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class ProductsPanel extends StatelessWidget {
  const ProductsPanel({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 54,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            scrollDirection: Axis.horizontal,
            itemCount: controller.categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = controller.categories[index];
              final selected = controller.categoryFilter == cat;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                label: Text(cat),
                labelStyle: TextStyle(
                  color: selected ? Colors.black : AppColors.muted,
                  fontWeight: FontWeight.w800,
                ),
                onSelected: (_) => controller.setCategory(cat),
                selectedColor: AppColors.accent,
              );
            },
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 170,
              mainAxisExtent: 138,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: controller.visibleArticles.length,
            itemBuilder: (context, index) {
              final article = controller.visibleArticles[index];
              final price = article.priceFor(controller.memberTariff);
              final noStock = article.tracksStock && article.stock == 0;
              final lowStock = article.tracksStock &&
                  article.stock > 0 &&
                  article.stock <= article.threshold;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: controller.selectedPlayerId == null
                    ? () => snack(context, 'Sélectionnez un joueur')
                    : () => controller.addToCart(article),
                child: TacticalCard(
                  borderColor: noStock
                      ? AppColors.danger
                      : lowStock
                          ? AppColors.warn
                          : article.isLocation
                              ? AppColors.sumup
                              : AppColors.border,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          const Spacer(),
                          if (article.tracksStock)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: noStock
                                        ? AppColors.danger
                                        : lowStock
                                            ? AppColors.warn
                                            : AppColors.border),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text('${article.stock}',
                                  style: TextStyle(
                                      color: noStock
                                          ? AppColors.danger
                                          : lowStock
                                              ? AppColors.warn
                                              : AppColors.muted,
                                      fontSize: 12)),
                            ),
                        ],
                      ),
                      Text(article.icon, style: const TextStyle(fontSize: 28)),
                      const SizedBox(height: 4),
                      Expanded(
                        child: Center(
                          child: Text(article.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w800)),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(price == 0 ? 'Libre' : money(price),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w900)),
                          ),
                          if (controller.memberTariff &&
                              article.memberPrice > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                border: Border.all(color: AppColors.accent2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('ADH',
                                  style: TextStyle(
                                      color: AppColors.accent2,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800)),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class CartPanel extends StatelessWidget {
  const CartPanel({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final shortages = controller.cartStockShortages;
    final hasPendingPayment = controller.hasPendingPayment;
    final canCheckout = controller.canCheckout;
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_cart, color: AppColors.accent),
              const SizedBox(width: 8),
              Text('PANIER (${controller.cartCount})',
                  style: const TextStyle(
                      fontWeight: FontWeight.w900, letterSpacing: 1.2)),
              const Spacer(),
              Text(money(controller.cartTotal),
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 18)),
            ],
          ),
          const SizedBox(height: 8),
          if (shortages.isNotEmpty)
            TacticalCard(
              borderColor: AppColors.warn,
              padding: const EdgeInsets.all(8),
              child: Text(
                  'Stock insuffisant : ${shortages.map((item) => item.message).join(' ; ')}',
                  style: const TextStyle(color: AppColors.warn)),
            ),
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            value: controller.memberTariff,
            onChanged: (_) => controller.toggleMemberTariff(),
            title: Text(
                controller.memberTariff ? 'Tarif adhérent' : 'Tarif public'),
            secondary: const Icon(Icons.badge),
          ),
          Expanded(
            child: controller.cart.isEmpty
                ? Center(
                    child: Text(
                      controller.donation > 0
                          ? 'Don sans article'
                          : 'Panier vide',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  )
                : ListView.builder(
                    itemCount: controller.cart.length,
                    itemBuilder: (context, index) {
                      final item = controller.cart[index];
                      final article = controller.articles
                          .firstWhere((a) => a.id == item.articleId);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: TacticalCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 6),
                          child: Row(
                            children: [
                              Text(article.icon),
                              const SizedBox(width: 6),
                              Expanded(
                                  child: Text(article.name,
                                      overflow: TextOverflow.ellipsis)),
                              IconButton.filledTonal(
                                  onPressed: () => controller
                                      .changeCartQuantity(article.id, -1),
                                  icon: const Icon(Icons.remove),
                                  iconSize: 16),
                              Text('${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900)),
                              IconButton.filledTonal(
                                  onPressed: () => controller
                                      .changeCartQuantity(article.id, 1),
                                  icon: const Icon(Icons.add),
                                  iconSize: 16),
                              SizedBox(
                                  width: 64,
                                  child: Text(money(item.price * item.quantity),
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          color: AppColors.accent))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          TextFormField(
            key: ValueKey(controller.donation),
            initialValue: controller.donation == 0
                ? ''
                : controller.donation.toStringAsFixed(2),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
                prefixIcon: Icon(Icons.volunteer_activism), labelText: 'Don'),
            onChanged: (value) => controller
                .setDonation(double.tryParse(value.replaceAll(',', '.')) ?? 0),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: FilledButton.icon(
                      onPressed: canCheckout
                          ? () => showCashDialog(context, controller)
                          : null,
                      icon: const Icon(Icons.payments),
                      label: const Text('ESP'))),
              const SizedBox(width: 6),
              Expanded(
                  child: FilledButton.tonal(
                      onPressed: canCheckout
                          ? () => _checkout(context, 'PayPal')
                          : null,
                      child: const Text('PayPal'))),
              const SizedBox(width: 6),
              Expanded(
                  child: FilledButton.tonal(
                      onPressed: canCheckout
                          ? () => _checkout(context, 'SumUp')
                          : null,
                      child: const Text('SumUp'))),
            ],
          ),
          TextButton.icon(
              onPressed: hasPendingPayment ? controller.clearCart : null,
              icon: const Icon(Icons.delete_outline),
              label: const Text('Vider')),
        ],
      ),
    );
  }

  Future<void> _checkout(BuildContext context, String payment) async {
    try {
      await controller.checkout(payment);
      if (context.mounted) snack(context, 'Vente validée en $payment');
    } on StateError catch (error) {
      if (context.mounted) snack(context, '$error');
    }
  }
}
