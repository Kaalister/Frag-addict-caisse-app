part of '../../main.dart';

class MealService {
  MealOrder createMealOrder({
    required Player player,
    required String source,
    required String status,
    required String mealArticleId,
    required String drinkArticleId,
    required String snackArticleId,
    required String formula,
    required List<String> options,
    required String note,
    String payment = '',
    DateTime? now,
  }) {
    final createdAt = now ?? DateTime.now();
    return MealOrder(
      id: makeId('meal'),
      playerId: player.id,
      playerName: player.name,
      playerType: player.type,
      source: source,
      status: status,
      saleId: source == 'onsite' ? makeId('sale') : '',
      payment: payment,
      mealArticleId: mealArticleId,
      drinkArticleId: drinkArticleId,
      snackArticleId: snackArticleId,
      formula: formula,
      options: List<String>.of(options),
      note: note.trim(),
      createdAt: createdAt,
      preparedAt: status == 'prepared' || status == 'served' ? createdAt : null,
      servedAt: status == 'served' ? createdAt : null,
      updatedAt: createdAt,
    );
  }

  MealOrder helloAssoMeal({
    required Player player,
    required HelloAssoRegistrant registrant,
    required Article mealArticle,
    Article? drinkArticle,
    Article? snackArticle,
  }) {
    final now = DateTime.now();
    final mealLabel = registrant.mealLabel.trim();
    return MealOrder(
      id: makeId('meal'),
      playerId: player.id,
      playerName: player.name,
      playerType: player.type,
      source: 'helloasso',
      status: 'planned',
      mealArticleId: mealArticle.id,
      drinkArticleId: drinkArticle?.id ?? '',
      snackArticleId: snackArticle?.id ?? '',
      formula: 'Standard',
      options: const [],
      note: mealLabel.isEmpty ? '' : 'HelloAsso : $mealLabel',
      createdAt: now,
      updatedAt: now,
    );
  }

  Sale saleForMeal(MealOrder meal, Player player, List<Article> articles,
      {String sessionId = '', DateTime? createdAt}) {
    final article =
        articles.where((entry) => entry.id == meal.mealArticleId).firstOrNull;
    if (article == null) {
      throw StateError('Article repas introuvable');
    }
    final price = article.priceFor(player.isMember);
    return Sale(
      id: meal.saleId,
      playerId: player.id,
      playerName: player.name,
      playerType: player.type,
      tariff: player.isMember ? 'adherent' : 'public',
      items: [
        SaleItem(
          articleId: article.id,
          name: article.name,
          icon: article.icon,
          type: article.type,
          quantity: 1,
          price: price,
          publicPrice: article.price,
          memberPrice: article.memberPrice,
        ),
      ],
      totalArticles: price,
      donation: 0,
      payment: meal.payment,
      session: sessionId,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  List<StockMovement> stockTransition(
    MealOrder? previous,
    MealOrder next, {
    required List<Article> articles,
    required StockService stockService,
    required String? sessionId,
  }) {
    final oldItems = previous != null && previous.consumesStock
        ? previous.stockItems
        : <String, int>{};
    final newItems = next.consumesStock ? next.stockItems : <String, int>{};
    final ids = {...oldItems.keys, ...newItems.keys};
    for (final id in ids) {
      final article = articles.where((entry) => entry.id == id).firstOrNull;
      if (article == null) continue;
      final delta = (oldItems[id] ?? 0) - (newItems[id] ?? 0);
      if (delta < 0 && article.stock < -delta) {
        throw StateError('Stock insuffisant pour ${article.name}');
      }
    }
    final movements = <StockMovement>[];
    for (final id in ids) {
      final article = articles.where((entry) => entry.id == id).firstOrNull;
      if (article == null) continue;
      final delta = (oldItems[id] ?? 0) - (newItems[id] ?? 0);
      final movement = stockService.applyDelta(
        article,
        delta,
        sessionId: sessionId,
        movementType: 'meal',
        saleId: next.saleId.isEmpty ? null : next.saleId,
        reason: 'Repas ${next.id}',
      );
      if (movement != null) movements.add(movement);
    }
    return movements;
  }
}
