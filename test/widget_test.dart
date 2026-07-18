import 'dart:convert';

import 'package:tilly/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryAppController extends AppController {
  _MemoryAppController() {
    loading = false;
    activeSession = SessionRecord(
      id: 'session-test',
      name: 'Session test',
      eventDate: DateTime(2026, 7, 16),
    );
  }

  @override
  Future<void> setAssociationName(String value) async {
    appSettings = appSettings.copyWith(associationName: value.trim());
    notifyListeners();
  }
}

void main() {
  test('money formats French euro display', () {
    expect(money(12.5), '12,50 €');
  });

  test('default catalog starts empty with retained categories', () {
    expect(defaultArticles(), isEmpty);
    expect(defaultArticleCategories(), [
      'BOISSONS',
      'REPAS',
      'GOODIES',
      'LOCATION',
    ]);
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
          playerName: 'Participant',
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
          playerName: 'Participant',
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
          playerName: 'Participant',
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

  test('planned HelloAsso meal does not consume stock before preparation', () {
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
          playerName: 'Participant',
          playerType: 'public',
          source: 'helloasso',
          status: 'planned',
          mealArticleId: 'repas',
          formula: 'Standard',
          createdAt: DateTime(2026, 5, 25),
        ),
      ];

    final row = kpiRows(controller).single;

    expect(row.mealUsed, 0);
    expect(row.outgoing, 0);
    expect(row.stockInitial, 9);
  });

  test('location checkout never consumes stock', () {
    final player = Player(id: 'player-1', name: 'Participant', type: 'public');
    final controller = AppController()
      ..articles = [
        Article(
          id: 'billes',
          category: 'GOODIES',
          type: 'standard',
          icon: '',
          name: 'Billes',
          price: 3,
          memberPrice: 2.5,
          stock: 0,
          threshold: 0,
        ),
        Article(
          id: 'location',
          category: 'LOCATION',
          type: 'location',
          icon: '',
          name: 'Location réplique',
          price: 15,
          memberPrice: 12,
          stock: 0,
          threshold: 0,
        ),
      ]
      ..players = [player]
      ..allPlayers = [player];

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
      organizationSlug: 'tilly',
      clientId: 'client',
      clientSecret: 'private-secret',
    );

    final exported = settings.toJson(includeSecret: false);

    expect(exported.containsKey('clientSecret'), isFalse);
    expect(settings.withoutSecret().clientSecret, isEmpty);
  });

  test('JSON backup payload excludes the HelloAsso client secret', () {
    final payload = _backupPayloadWithHelloAssoSecret('json-private-secret');

    final sanitized = sanitizePortableBackupPayload(payload);
    final exported = const JsonEncoder.withIndent('  ').convert(sanitized);

    expect(exported, isNot(contains('json-private-secret')));
    expect(_helloAssoSettingsFromPayload(sanitized).clientSecret, isEmpty);
    expect(_helloAssoSettingsFromPayload(payload).clientSecret,
        'json-private-secret');
  });

  test('Firebase sync payload excludes the HelloAsso client secret', () {
    final payload =
        _backupPayloadWithHelloAssoSecret('firebase-private-secret');

    final sanitized = FirebaseSyncService.sanitizePayloadForSync(payload);
    final encoded = jsonEncode(sanitized);

    expect(encoded, isNot(contains('firebase-private-secret')));
    expect(_helloAssoSettingsFromPayload(sanitized).clientSecret, isEmpty);
  });

  test('app settings persist the primary color', () {
    const settings = AppSettings(primaryColorValue: 0xFFFF6B35);
    final restored = AppSettings.fromJson(settings.toJson());

    expect(restored.primaryColor.toARGB32(), 0xFFFF6B35);
  });

  test('Firebase settings round-trip and build runtime options', () {
    const settings = FirebaseSettings(
      apiKey: 'api-key',
      appId: 'app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
      authDomain: 'project.firebaseapp.com',
    );

    final restored = FirebaseSettings.fromJson(settings.toJson());
    final options = restored.toOptions();

    expect(restored.isConfigured, isTrue);
    expect(options.apiKey, 'api-key');
    expect(options.projectId, 'project-id');
    expect(options.authDomain, 'project.firebaseapp.com');
  });

  test('Firebase settings require the four core identifiers', () {
    expect(const FirebaseSettings().isConfigured, isFalse);
    expect(
        const FirebaseSettings(
          apiKey: 'api-key',
          appId: 'app-id',
          messagingSenderId: 'sender-id',
        ).isConfigured,
        isFalse);
  });

  test('Firebase web configuration can be pasted as a single block', () {
    final settings = parseFirebaseSettings('''
      const firebaseConfig = {
        apiKey: "api-key",
        authDomain: "project.firebaseapp.com",
        projectId: "project-id",
        storageBucket: "project.firebasestorage.app",
        messagingSenderId: "sender-id",
        appId: "app-id"
      };
    ''');

    expect(settings.isConfigured, isTrue);
    expect(settings.projectId, 'project-id');
    expect(settings.authDomain, 'project.firebaseapp.com');
  });

  test('Firebase Android google-services JSON can be pasted', () {
    final settings = parseFirebaseSettings(jsonEncode({
      'project_info': {
        'project_number': 'sender-id',
        'project_id': 'project-id',
        'storage_bucket': 'project.firebasestorage.app',
      },
      'client': [
        {
          'client_info': {'mobilesdk_app_id': 'android-app-id'},
          'api_key': [
            {'current_key': 'api-key'}
          ],
        }
      ],
    }));

    expect(settings.isConfigured, isTrue);
    expect(settings.appId, 'android-app-id');
    expect(settings.messagingSenderId, 'sender-id');
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

  test('modern backups can restore an empty article catalog', () {
    expect(
      () => validateBackupPayload({
        'version': 3,
        'data': {
          'sessions': [
            {'id': 'session-1'}
          ],
          'articles': <Object>[],
          'appSettings': <Object>[],
        },
      }),
      returnsNormally,
    );
  });

  testWidgets('association rename dialog updates without framework exception',
      (tester) async {
    final controller = _MemoryAppController();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ConfigPage(
            controller: controller,
            updateResult: null,
            checkingUpdate: false,
            onCheckUpdate: () {},
            onOpenUpdate: (_) async {},
          ),
        ),
      ),
    );

    await tester.tap(find.text('Renommer'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Nouvelle asso');
    await tester.tap(find.text('Valider'));
    await tester.pump(kThemeAnimationDuration);
    await tester.pumpAndSettle();

    expect(controller.associationName, 'Nouvelle asso');
    expect(tester.takeException(), isNull);
  });

  testWidgets('sales page mobile layout does not overflow', (tester) async {
    final controller = _MemoryAppController()
      ..players = [
        Player(id: 'player-1', name: 'Alice Dupont', type: 'public'),
        Player(id: 'player-2', name: 'Bob Martin', type: 'membre'),
      ]
      ..articles = [
        Article(
          id: 'drink-1',
          category: 'BOISSONS',
          type: 'standard',
          icon: 'B',
          name: 'Boisson',
          price: 2,
          memberPrice: 1.5,
          stock: 20,
          threshold: 5,
        ),
        Article(
          id: 'goodie-1',
          category: 'GOODIES',
          type: 'standard',
          icon: 'G',
          name: 'Goodie',
          price: 5,
          memberPrice: 4,
          stock: 10,
          threshold: 3,
        ),
      ];
    controller
      ..selectPlayer(controller.players.first)
      ..addToCart(controller.articles.first);

    tester.view.physicalSize = const Size(393, 783);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: Scaffold(body: CaissePage(controller: controller)),
      ),
    );

    expect(find.byType(DraggableScrollableSheet), findsOneWidget);
    final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet));
    expect(sheet.maxChildSize, 1);
    expect(find.text('Alice Dupont'), findsOneWidget);
    expect(find.text('Vider'), findsNothing);
    expect(find.text('ESP'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.drag(find.text('PANIER (1)'), const Offset(0, -620));
    await tester.pumpAndSettle();

    expect(find.text('Vider'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart item list scrolls after seven lines', (tester) async {
    final articles = List.generate(
      8,
      (index) => Article(
        id: 'article-$index',
        category: 'BOISSONS',
        type: 'standard',
        icon: 'A',
        name: 'Article $index',
        price: 1,
        memberPrice: 1,
        stock: 20,
        threshold: 5,
      ),
    );
    final controller = _MemoryAppController()
      ..articles = articles
      ..cart = [
        for (final article in articles)
          CartItem(articleId: article.id, quantity: 1, price: article.price),
      ];

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: Scaffold(
          body: SizedBox(
            width: 360,
            height: 760,
            child: CartPanel(controller: controller),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('scrollable-cart-items')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('mobile cart keeps checkout controls visible with many items',
      (tester) async {
    final articles = List.generate(
      12,
      (index) => Article(
        id: 'mobile-article-$index',
        category: 'BOISSONS',
        type: 'standard',
        icon: 'A',
        name: 'Article mobile $index',
        price: 1,
        memberPrice: 1,
        stock: 20,
        threshold: 5,
      ),
    );
    final controller = _MemoryAppController()
      ..players = [Player(id: 'player-1', name: 'Alice Dupont', type: 'public')]
      ..articles = articles
      ..cart = [
        for (final article in articles)
          CartItem(articleId: article.id, quantity: 1, price: article.price),
      ];
    controller.selectPlayer(controller.players.first);

    tester.view.physicalSize = const Size(393, 783);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: Scaffold(body: CaissePage(controller: controller)),
      ),
    );

    await tester.drag(find.text('PANIER (12)'), const Offset(0, -620));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('scrollable-cart-items')), findsOneWidget);
    final clearButtonBottom = tester.getRect(find.text('Vider')).bottom;
    expect(clearButtonBottom, lessThanOrEqualTo(783));
    expect(tester.takeException(), isNull);
  });
}

Map<String, dynamic> _backupPayloadWithHelloAssoSecret(String secret) {
  final settings = HelloAssoSettings(
    organizationSlug: 'tilly',
    clientId: 'client',
    clientSecret: secret,
    environment: 'sandbox',
  );
  return {
    'version': 3,
    'data': {
      'sessions': [
        {'id': 'session-test'}
      ],
      'articles': <Map<String, Object?>>[],
      'appSettings': [
        {
          'key': 'helloasso_settings',
          'value': jsonEncode(settings.toJson()),
          'updated_at': '2026-07-18T00:00:00',
        },
      ],
    },
  };
}

HelloAssoSettings _helloAssoSettingsFromPayload(Map<String, dynamic> payload) {
  final data = Map<String, dynamic>.from(payload['data'] as Map);
  final rows = data['appSettings'] as List;
  final row = rows.whereType<Map>().firstWhere(
      (entry) => entry['key'] == 'helloasso_settings',
      orElse: () => const {});
  return HelloAssoSettings.fromJson(
      Map<String, dynamic>.from(jsonDecode('${row['value'] ?? '{}'}') as Map));
}
