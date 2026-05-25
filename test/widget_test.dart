import 'package:frags_addicts_caisse/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('money formats French euro display', () {
    expect(money(12.5), '12,50 €');
  });

  test('prepared meal inclusions are counted as stock outgoing', () {
    final controller = AppController()
      ..articles = [
        Article(
          id: 'repas',
          category: 'REPAS',
          type: 'standard',
          icon: '',
          name: 'Repas',
          price: 10,
          memberPrice: 9,
          stock: 9,
          threshold: 1,
        ),
        Article(
          id: 'coca',
          category: 'BOISSONS',
          type: 'standard',
          icon: '',
          name: 'Coca',
          price: 2,
          memberPrice: 2,
          stock: 9,
          threshold: 1,
        ),
      ]
      ..meals = [
        MealOrder(
          id: 'meal-1',
          playerId: 'player-1',
          playerName: 'Joueur',
          playerType: 'public',
          source: 'helloasso',
          status: 'prepared',
          mealArticleId: 'repas',
          drinkArticleId: 'coca',
          formula: 'Standard',
          createdAt: DateTime(2026, 5, 25),
        ),
      ];

    final rows = kpiRows(controller);
    final drink = rows.firstWhere((row) => row.article.id == 'coca');

    expect(drink.sold, 0);
    expect(drink.mealUsed, 1);
    expect(drink.outgoing, 1);
    expect(drink.stockInitial, 10);
  });

  test('onsite meal sale is not double counted in stock outgoing', () {
    final controller = AppController()
      ..articles = [
        Article(
          id: 'repas',
          category: 'REPAS',
          type: 'standard',
          icon: '',
          name: 'Repas',
          price: 10,
          memberPrice: 9,
          stock: 9,
          threshold: 1,
        ),
      ]
      ..meals = [
        MealOrder(
          id: 'meal-1',
          playerId: 'player-1',
          playerName: 'Joueur',
          playerType: 'public',
          source: 'onsite',
          status: 'served',
          saleId: 'sale-1',
          payment: 'ESP',
          mealArticleId: 'repas',
          formula: 'Standard',
          createdAt: DateTime(2026, 5, 25),
        ),
      ]
      ..sales = [
        Sale(
          id: 'sale-1',
          playerId: 'player-1',
          playerName: 'Joueur',
          playerType: 'public',
          tariff: 'public',
          items: [
            SaleItem(
              articleId: 'repas',
              name: 'Repas',
              icon: '',
              type: 'standard',
              quantity: 1,
              price: 10,
              publicPrice: 10,
              memberPrice: 9,
            ),
          ],
          totalArticles: 10,
          donation: 0,
          payment: 'ESP',
          session: 'session-1',
          createdAt: DateTime(2026, 5, 25),
        ),
      ];

    final row = kpiRows(controller).single;

    expect(row.sold, 1);
    expect(row.mealUsed, 1);
    expect(row.outgoing, 1);
    expect(row.ca, 10);
    expect(row.stockInitial, 10);
  });

  test('location checkout never consumes stock', () {
    final player = Player(id: 'player-1', name: 'Joueur', type: 'public');
    final controller = AppController()
      ..articles = defaultArticles()
      ..players = [player]
      ..allPlayers = [player];
    controller.articles.firstWhere((article) => article.id == 'billes').stock =
        0;

    controller.selectPlayer(player);
    controller.addToCart(
        controller.articles.firstWhere((article) => article.id == 'location'));

    expect(controller.cartStockShortages, isEmpty);
    expect(controller.canCheckout, isTrue);
  });

  test('association consumption is a stock outgoing without revenue', () {
    final article = Article(
      id: 'eau',
      category: 'BOISSONS',
      type: 'standard',
      icon: '',
      name: 'Eau',
      price: 1,
      memberPrice: 1,
      stock: 7,
      threshold: 1,
    );
    final controller = AppController()
      ..articles = [article]
      ..stockMovements = [
        StockMovement(
          id: 'stock-asso',
          sessionId: 'session-1',
          articleId: 'eau',
          movementType: 'association',
          quantityDelta: -3,
          stockBefore: 10,
          stockAfter: 7,
          reason: 'Consommation association',
          createdAt: DateTime(2026, 5, 25),
        ),
      ];

    final row = kpiRows(controller).single;

    expect(row.associationUsed, 3);
    expect(row.outgoing, 3);
    expect(row.ca, 0);
    expect(row.stockInitial, 10);
  });

  test('HelloAsso portable settings exclude the client secret', () {
    const settings = HelloAssoSettings(
      organizationSlug: 'frags',
      clientId: 'client',
      clientSecret: 'private-secret',
    );

    final exported = settings.toJson(includeSecret: false);

    expect(exported.containsKey('clientSecret'), isFalse);
    expect(settings.withoutSecret().clientSecret, isEmpty);
  });

  test('empty modern backups are rejected before replacement', () {
    expect(
      () => validateBackupPayload({
        'version': 3,
        'data': {
          'sessions': <Object>[],
          'articles': <Object>[],
          'appSettings': <Object>[],
        },
      }),
      throwsFormatException,
    );
  });
}
