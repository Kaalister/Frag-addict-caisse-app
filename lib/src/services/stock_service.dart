part of '../../main.dart';

class StockService {
  List<StockShortage> shortages(Map<Article, int> requirements) {
    return [
      for (final entry in requirements.entries)
        if (entry.key.stock < entry.value)
          StockShortage(
            article: entry.key,
            requiredQuantity: entry.value,
            availableQuantity: entry.key.stock,
          ),
    ];
  }

  Map<Article, int> cartRequirements(
      List<CartItem> cart, List<Article> articles) {
    final result = <Article, int>{};
    for (final item in cart) {
      final article =
          articles.where((entry) => entry.id == item.articleId).firstOrNull;
      if (article == null) continue;
      _mergeRequirements(result, articleConsumption(article, item.quantity));
    }
    return result;
  }

  Map<Article, int> saleRequirements(Sale sale, List<Article> articles) {
    final result = <Article, int>{};
    for (final item in sale.items) {
      final article = articles
          .where(
              (entry) => entry.id == item.articleId || entry.name == item.name)
          .firstOrNull;
      if (article != null) {
        _mergeRequirements(result, articleConsumption(article, item.quantity));
      }
    }
    return result;
  }

  Map<Article, int> articleConsumption(Article article, int quantity) {
    final result = <Article, int>{};
    if (article.tracksStock) result[article] = quantity;
    return result;
  }

  StockMovement? applyDelta(
    Article article,
    int delta, {
    required String? sessionId,
    required String movementType,
    required String reason,
    String? saleId,
  }) {
    if (delta == 0) return null;
    final before = article.stock;
    final after = before + delta;
    if (after < 0) {
      throw StateError('Stock insuffisant pour ${article.name}');
    }
    article.stock = after;
    if (sessionId == null) return null;
    return StockMovement(
      id: makeId('stock'),
      sessionId: sessionId,
      articleId: article.id,
      saleId: saleId,
      movementType: movementType,
      quantityDelta: delta,
      stockBefore: before,
      stockAfter: after,
      reason: reason,
      createdAt: DateTime.now(),
    );
  }

  void _mergeRequirements(Map<Article, int> target, Map<Article, int> added) {
    for (final entry in added.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }
}
