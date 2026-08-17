import 'dart:convert';
import 'dart:io';

import 'package:tilly/tilly.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

  @override
  Future<void> setPrimaryColor(Color value) async {
    appSettings = appSettings.copyWith(primaryColorValue: value.toARGB32());
    notifyListeners();
  }

  @override
  Future<void> load() async {
    loading = false;
    notifyListeners();
  }

  @override
  Future<void> markTutorialWelcomeSeen() async {
    tutorialWelcomeSeen = true;
    notifyListeners();
  }

  @override
  Future<void> markTutorialPageSeen(String pageId) async {
    tutorialPagesSeen = {...tutorialPagesSeen, pageId};
    notifyListeners();
  }

  @override
  Future<void> addPlayer({
    required String firstName,
    required String lastName,
    required String email,
    required String type,
  }) async {
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final player = Player(
      id: 'player-${allPlayers.length + 1}',
      name: playerNameFromParts(cleanFirstName, cleanLastName,
          cleanEmail.isEmpty ? 'Participant' : cleanEmail),
      type: type,
      firstName: cleanFirstName,
      lastName: cleanLastName,
      email: cleanEmail,
    );
    allPlayers.add(player);
    players.add(player);
    notifyListeners();
  }

  @override
  Future<void> addArticleCategory(String category) async {
    final normalized = normalizedCategoryName(category);
    if (normalized.isEmpty || containsArticleCategory(normalized)) return;
    articleCategories.add(normalized);
    articleCategories.sort();
    notifyListeners();
  }

  @override
  Future<void> upsertArticle(Article article, {Article? replacing}) async {
    final category = normalizedCategoryName(article.category).isEmpty
        ? 'DIVERS'
        : normalizedCategoryName(article.category);
    article.category = category;
    if (!articleCategories.contains(category)) {
      articleCategories.add(category);
      articleCategories.sort();
    }
    if (replacing == null) {
      articles.add(article);
    } else {
      final index = articles.indexOf(replacing);
      if (index >= 0) articles[index] = article;
    }
    notifyListeners();
  }
}

class _FailingDatabase extends LocalDatabase {
  @override
  Future<void> saveAll(PersistableAppState state,
      {bool markUpdated = true}) async {
    throw StateError('Écriture simulée impossible');
  }
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('money formats French euro display', () {
    expect(money(12.5), '12,50 €');
  });

  test('default catalog starts empty with retained categories', () {
    expect(defaultArticles(), isEmpty);
    expect(defaultArticleCategories(), [
      'BOISSONS',
      'REPAS',
      'SNACKING',
      'GOODIES',
      'LOCATION',
    ]);
  });

  test('meal snack articles use the SNACKING category', () {
    final controller = AppController()
      ..articles = [
        Article(
          id: 'snacs',
          category: 'SNACS',
          type: 'standard',
          icon: '',
          name: 'Chips',
          price: 1,
          memberPrice: 1,
          stock: 12,
          threshold: 1,
        ),
        Article(
          id: 'snacking',
          category: 'SNACKING',
          type: 'standard',
          icon: '',
          name: 'Ancien snack',
          price: 1,
          memberPrice: 1,
          stock: 8,
          threshold: 1,
        ),
      ];

    expect(controller.snackArticles.map((article) => article.id), [
      'snacs',
      'snacking',
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

  test('KPI stock initial comes from the first stock movement', () {
    final article = Article(
      id: 'eau',
      category: 'BOISSONS',
      type: 'standard',
      icon: '',
      name: 'Eau',
      price: 1,
      memberPrice: 1,
      stock: 12,
      threshold: 1,
    );
    final controller = AppController()
      ..articles = [article]
      ..stockMovements = [
        StockMovement(
          id: 'stock-adjustment',
          sessionId: 'session-1',
          articleId: 'eau',
          movementType: 'adjustment',
          quantityDelta: 5,
          stockBefore: 10,
          stockAfter: 15,
          reason: 'Réassort',
          createdAt: DateTime(2026, 5, 25, 9),
        ),
        StockMovement(
          id: 'stock-sale',
          sessionId: 'session-1',
          articleId: 'eau',
          movementType: 'sale',
          quantityDelta: -3,
          stockBefore: 15,
          stockAfter: 12,
          reason: 'Vente',
          createdAt: DateTime(2026, 5, 25, 10),
        ),
      ];

    final row = kpiRows(controller).single;

    expect(row.stockInitial, 10);
  });

  test('cancelled sales stay in audit but not in business totals', () {
    final activeSale = _sale(id: 'sale-active');
    final cancelledSale = _sale(id: 'sale-cancelled').copyWith(
      status: 'cancelled',
      cancelledAt: DateTime(2026, 7, 18),
      cancellationReason: 'Test',
    );
    final controller = AppController()..sales = [activeSale, cancelledSale];

    expect(controller.sales, hasLength(2));
    expect(controller.activeSales, [activeSale]);
    expect(controller.paymentTotals()['ESP'], activeSale.total);

    final restored = Sale.fromJson(cancelledSale.toJson());
    expect(restored.status, 'cancelled');
    expect(restored.cancelledAt, DateTime(2026, 7, 18));
    expect(restored.cancellationReason, 'Test');
  });

  test('checkout rolls memory back when SQLite persistence fails', () async {
    final article = Article(
      id: 'article-1',
      category: 'BOISSONS',
      type: 'standard',
      icon: '',
      name: 'Eau',
      price: 2,
      memberPrice: 1.5,
      stock: 3,
      threshold: 1,
    );
    final player = Player(id: 'player-1', name: 'Participant', type: 'public');
    final controller = AppController(database: _FailingDatabase())
      ..activeSession = SessionRecord(
        id: 'session-1',
        name: 'Session test',
        eventDate: DateTime(2026, 7, 18),
      )
      ..players = [player]
      ..articles = [article];
    controller
      ..selectPlayer(player)
      ..addToCart(article);

    await expectLater(
      controller.checkout('ESP'),
      throwsA(isA<StateError>()),
    );

    expect(article.stock, 3);
    expect(controller.cart, hasLength(1));
    expect(controller.cart.single.quantity, 1);
    expect(controller.sales, isEmpty);
    expect(controller.stockMovements, isEmpty);
    expect(controller.pendingStockMovements, isEmpty);
  });

  test('SQLite keeps cancelled sale items and stock movement links', () async {
    final tempDirectory = await Directory.systemTemp.createTemp('tilly-test-');
    final database = LocalDatabase(
        databasePathOverride: path.join(tempDirectory.path, 'tilly.db'));
    addTearDown(() async {
      await database.close();
      await tempDirectory.delete(recursive: true);
    });

    final article = Article(
      id: 'article-1',
      category: 'BOISSONS',
      type: 'standard',
      icon: '',
      name: 'Eau',
      price: 2,
      memberPrice: 1.5,
      stock: 9,
      threshold: 2,
    );
    final player = Player(id: 'player-1', name: 'Participant', type: 'public');
    final sale = _sale(id: 'sale-1');
    final controller = AppController(database: database)
      ..activeSession = SessionRecord(
        id: 'session-1',
        name: 'Session test',
        eventDate: DateTime(2026, 7, 18),
      )
      ..allPlayers = [player]
      ..players = [player]
      ..articles = [article]
      ..articleCategories = ['BOISSONS']
      ..sales = [sale]
      ..pendingStockMovements = [
        StockMovement(
          id: 'movement-sale',
          sessionId: 'session-1',
          articleId: 'article-1',
          saleId: 'sale-1',
          movementType: 'sale',
          quantityDelta: -1,
          stockBefore: 10,
          stockAfter: 9,
          reason: 'Vente',
          createdAt: DateTime(2026, 7, 18, 10),
        ),
      ];

    await database.saveAll(controller);
    await controller.cancelSale(sale, reason: 'Annulation test');

    final restoredSales = await database.loadSales('session-1');
    final payload = await database.exportAll();
    validateBackupPayload(payload);
    final data = Map<String, dynamic>.from(payload['data'] as Map);
    final movements = (data['stockMovements'] as List).cast<Map>();
    final saleItems = (data['saleItems'] as List).cast<Map>();

    expect(restoredSales, hasLength(1));
    expect(restoredSales.single.status, 'cancelled');
    expect(restoredSales.single.items, hasLength(1));
    expect(saleItems, hasLength(1));
    expect(movements, hasLength(2));
    expect(movements.every((row) => row['sale_id'] == 'sale-1'), isTrue);
  });

  test('SQLite v7 meal schema migrates to nullable player foreign key',
      () async {
    final tempDirectory =
        await Directory.systemTemp.createTemp('tilly-migration-test-');
    final databasePath = path.join(tempDirectory.path, 'tilly-v7.db');
    final legacyDatabase = await openDatabase(
      databasePath,
      version: 7,
      onCreate: (database, version) async {
        await database.execute('''
          CREATE TABLE sessions (
            id TEXT PRIMARY KEY
          )
        ''');
        await database.execute('''
          CREATE TABLE players (
            id TEXT PRIMARY KEY
          )
        ''');
        await database.execute('''
          CREATE TABLE sales (
            id TEXT PRIMARY KEY
          )
        ''');
        await database.execute('''
          CREATE TABLE stock_movements (
            id TEXT PRIMARY KEY,
            sale_id TEXT
          )
        ''');
        await database.execute('''
          CREATE TABLE meal_orders (
            id TEXT PRIMARY KEY,
            session_id TEXT NOT NULL,
            player_id TEXT NOT NULL,
            player_name_snapshot TEXT NOT NULL,
            player_type_snapshot TEXT NOT NULL,
            source TEXT NOT NULL,
            status TEXT NOT NULL,
            sale_id TEXT,
            payment_method TEXT,
            meal_article_id TEXT NOT NULL,
            drink_article_id TEXT,
            snack_article_id TEXT,
            formula TEXT NOT NULL,
            options_json TEXT,
            note TEXT,
            created_at TEXT NOT NULL,
            prepared_at TEXT,
            served_at TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
    await legacyDatabase.insert('sessions', {'id': 'session-1'});
    await legacyDatabase.insert('players', {'id': 'player-1'});
    await legacyDatabase.insert('meal_orders', {
      'id': 'meal-1',
      'session_id': 'session-1',
      'player_id': 'player-1',
      'player_name_snapshot': 'Participant',
      'player_type_snapshot': 'public',
      'source': 'helloasso',
      'status': 'planned',
      'meal_article_id': 'article-1',
      'formula': 'Standard',
      'created_at': '2026-07-18T10:00:00',
      'updated_at': '2026-07-18T10:00:00',
    });
    await legacyDatabase.close();

    final database = LocalDatabase(databasePathOverride: databasePath);
    addTearDown(() async {
      await database.close();
      await tempDirectory.delete(recursive: true);
    });

    final meals = await database.loadMeals('session-1');
    final migratedDatabase = await openDatabase(databasePath);
    final columns =
        await migratedDatabase.rawQuery("PRAGMA table_info('meal_orders')");
    final playerIdColumn =
        columns.firstWhere((column) => column['name'] == 'player_id');
    await migratedDatabase.close();

    expect(meals.single.playerId, 'player-1');
    expect(playerIdColumn['notnull'], 0);
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

  test('Tiko tutorial progress persists locally', () async {
    final tempDirectory = await Directory.systemTemp.createTemp('tilly-test-');
    final databasePath = path.join(tempDirectory.path, 'tilly.db');
    final writer = LocalDatabase(databasePathOverride: databasePath);

    await writer.saveTutorialWelcomeSeen();
    await writer.saveTutorialPagesSeen({AppTabIds.sales, AppTabIds.players});
    await writer.close();

    final reader = LocalDatabase(databasePathOverride: databasePath);
    addTearDown(() async {
      await reader.close();
      await tempDirectory.delete(recursive: true);
    });

    expect(await reader.loadTutorialWelcomeSeen(), isTrue);
    expect(await reader.loadTutorialPagesSeen(),
        {AppTabIds.sales, AppTabIds.players});
  });

  test('Firebase settings round-trip and build runtime options', () {
    const settings = FirebaseSettings(
      apiKey: 'api-key',
      appId: 'app-id',
      messagingSenderId: 'sender-id',
      projectId: 'project-id',
      authDomain: 'project.firebaseapp.com',
      iosBundleId: 'com.tilly.caisse',
    );

    final restored = FirebaseSettings.fromJson(settings.toJson());
    final options = restored.toOptions();

    expect(restored.isConfigured, isTrue);
    expect(options.apiKey, 'api-key');
    expect(options.projectId, 'project-id');
    expect(options.authDomain, 'project.firebaseapp.com');
    expect(options.iosBundleId, 'com.tilly.caisse');
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

  test('Firebase Apple GoogleService-Info plist can be pasted', () {
    final settings = parseFirebaseSettings('''
      <?xml version="1.0" encoding="UTF-8"?>
      <plist version="1.0">
      <dict>
        <key>API_KEY</key>
        <string>api-key</string>
        <key>GCM_SENDER_ID</key>
        <string>sender-id</string>
        <key>PROJECT_ID</key>
        <string>project-id</string>
        <key>STORAGE_BUCKET</key>
        <string>project.firebasestorage.app</string>
        <key>GOOGLE_APP_ID</key>
        <string>apple-app-id</string>
        <key>BUNDLE_ID</key>
        <string>com.tilly.caisse</string>
      </dict>
      </plist>
    ''');

    final options = settings.toOptions();
    expect(settings.isConfigured, isTrue);
    expect(settings.appId, 'apple-app-id');
    expect(options.iosBundleId, 'com.tilly.caisse');
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
      () => validateBackupPayload(_validModernBackup()),
      returnsNormally,
    );
  });

  test('modern backups reject unknown columns and broken references', () {
    final unknownColumn = _validModernBackup();
    ((unknownColumn['data'] as Map)['sessions'] as List).first['unexpected'] =
        'value';
    expect(() => validateBackupPayload(unknownColumn), throwsFormatException);

    final brokenReference = _validModernBackup();
    ((brokenReference['data'] as Map)['sales'] as List).add({
      'id': 'sale-1',
      'session_id': 'missing-session',
      'player_name_snapshot': 'Participant',
      'player_type_snapshot': 'public',
      'tariff_applied': 'public',
      'payment_method': 'ESP',
      'status': 'active',
      'total_articles': 2.0,
      'donation_amount': 0.0,
      'total_amount': 2.0,
      'created_at': '2026-07-18T10:00:00',
    });
    expect(() => validateBackupPayload(brokenReference), throwsFormatException);
  });

  test('future backup versions are rejected before replacement', () {
    final payload = _validModernBackup()..['version'] = 99;
    expect(() => validateBackupPayload(payload), throwsFormatException);
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

  testWidgets('primary color picker applies preset without hex text field',
      (tester) async {
    final controller = _MemoryAppController();

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
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

    await tester.tap(find.text('Personnalisée'));
    await tester.pumpAndSettle();

    expect(find.text('Couleur hex'), findsNothing);
    expect(find.byType(ColorPicker), findsOneWidget);

    await tester.tap(find.byTooltip('#35C8F1').last);
    await tester.tap(find.widgetWithText(FilledButton, 'Valider'));
    await tester.pump(kThemeAnimationDuration);
    await tester.pumpAndSettle();

    expect(controller.primaryColor.toARGB32(), AppColors.accent2.toARGB32());
    expect(tester.takeException(), isNull);
  });

  testWidgets('configuration service help is presented by Tiko',
      (tester) async {
    final controller = _MemoryAppController();
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
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

    await tester.tap(find.text('Firebase'));
    await tester.pumpAndSettle();

    expect(find.text('À quoi ça sert ?'), findsOneWidget);
    await tester.tap(find.byTooltip('Tiko explique Firebase'));
    await tester.pumpAndSettle();

    expect(find.textContaining('synchronisation est entièrement manuelle'),
        findsOneWidget);

    for (var step = 0; step < 4; step++) {
      await tester.tap(find.text('Suivant'));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('organizations/default/users'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.textContaining('deux appareils en même temps'), findsOneWidget);
    expect(find.text('Ouvrir le tutoriel'), findsOneWidget);

    await tester.tap(find.byTooltip('Fermer le tuto'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HelloAsso'));
    await tester.pumpAndSettle();
    expect(find.text('À quoi ça sert ?'), findsOneWidget);
    await tester.tap(find.byTooltip('Tiko explique HelloAsso'));
    await tester.pumpAndSettle();

    expect(find.textContaining('HelloAsso est facultatif'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tiko first launch tour ends on articles page', (tester) async {
    final controller = _MemoryAppController();
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Future<void> finishCurrentTutorial(String finalLabel) async {
      var guard = 0;
      while (find.text('Suivant').evaluate().isNotEmpty && guard < 8) {
        await tester.tap(find.text('Suivant'));
        await tester.pumpAndSettle();
        guard += 1;
      }
      await tester.tap(find.text(finalLabel));
      await tester.pumpAndSettle();
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: RootShell(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('merci d\'avoir choisi'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Moi, c\'est Tiko'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(find.textContaining('en haut à droite'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();
    expect(
        find.textContaining('tour rapide de l\'application'), findsOneWidget);

    await finishCurrentTutorial('C\'est parti');

    expect(controller.tutorialWelcomeSeen, isTrue);
    expect(find.textContaining('La page Vente est le cœur'), findsOneWidget);

    final visitedTabs = <int>{};
    var guard = 0;
    while (
        find.byTooltip('Fermer le tuto').evaluate().isNotEmpty && guard < 12) {
      visitedTabs.add(controller.tab);
      final finalLabel =
          controller.tab == 7 ? 'Créer mon premier article' : 'Continuer';
      await finishCurrentTutorial(finalLabel);
      guard += 1;
    }

    expect(visitedTabs, containsAll(<int>{0, 1, 2, 3, 4, 5, 6, 7, 8}));
    expect(controller.tab, 7);
    expect(find.text('ARTICLES & PRIX'), findsWidgets);
    expect(controller.tutorialPagesSeen, isEmpty);

    await tester.tap(find.byTooltip('Revoir le tuto de Tiko'));
    await tester.pumpAndSettle();

    expect(
        find.textContaining('Commence par cet écran avant d\'ouvrir la caisse'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tiko page help appears once and remains manually available',
      (tester) async {
    final controller = _MemoryAppController()..tutorialWelcomeSeen = true;
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    Finder railLabel(String label) => find.descendant(
          of: find.byType(NavigationRail),
          matching: find.text(label),
        );

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: RootShell(controller: controller),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Pour faire une vente'), findsOneWidget);
    expect(controller.tutorialPagesSeen, contains(AppTabIds.sales));

    await tester.tap(find.byTooltip('Fermer le tuto'));
    await tester.pumpAndSettle();
    await tester.tap(railLabel('Participants'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Avant de vendre, ajoute ici les joueurs'),
        findsOneWidget);
    expect(controller.tutorialPagesSeen, contains(AppTabIds.players));

    await tester.tap(find.byTooltip('Fermer le tuto'));
    await tester.pumpAndSettle();
    await tester.tap(railLabel('Vente'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Fermer le tuto'), findsNothing);

    await tester.tap(find.byTooltip('Revoir le tuto de Tiko'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Pour faire une vente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('article dialog adds item without framework exception',
      (tester) async {
    final controller = _MemoryAppController();

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: Scaffold(body: ArticlesPricePage(controller: controller)),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ajouter').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(1), 'Patch test');
    await tester.enterText(find.byType(TextField).at(2), '2.50');
    await tester.enterText(find.byType(TextField).at(3), '2.00');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump(kThemeAnimationDuration);
    await tester.pumpAndSettle();

    expect(controller.articles.single.name, 'Patch test');
    expect(tester.takeException(), isNull);
  });

  testWidgets('category dialog adds category without framework exception',
      (tester) async {
    final controller = _MemoryAppController();

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: Scaffold(body: ArticlesPricePage(controller: controller)),
      ),
    );

    await tester.tap(find.widgetWithText(OutlinedButton, 'Ajouter').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Patch catégorie');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump(kThemeAnimationDuration);
    await tester.pumpAndSettle();

    expect(controller.articleCategories, contains('PATCH CATÉGORIE'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('player dialog adds participant without email', (tester) async {
    final controller = _MemoryAppController();

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: Scaffold(body: PlayersPage(controller: controller)),
      ),
    );

    await tester.tap(find.text('Ajouter un participant'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), 'Alice');
    await tester.enterText(find.byType(TextField).at(1), 'Martin');
    await tester.tap(find.text('Enregistrer'));
    await tester.pump(kThemeAnimationDuration);
    await tester.pumpAndSettle();

    expect(controller.players.single.name, 'Alice Martin');
    expect(controller.players.single.email, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('existing participant dropdown fits large text', (tester) async {
    final controller = _MemoryAppController()
      ..allPlayers = [
        Player(
          id: 'known-player',
          name: 'burn out',
          firstName: 'burn',
          lastName: 'out',
          type: 'membre',
        ),
      ];

    tester.view.physicalSize = const Size(674, 850);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.35)),
          child: Scaffold(body: PlayersPage(controller: controller)),
        ),
      ),
    );

    await tester.tap(find.text('Ajouter un participant'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('burn out').last);
    await tester.pumpAndSettle();

    expect(find.text('burn'), findsOneWidget);
    expect(find.text('out'), findsOneWidget);
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

  testWidgets('collapsed mobile cart fits above Android system inset',
      (tester) async {
    final controller = _MemoryAppController()
      ..players = [
        Player(id: 'player-1', name: 'Alice Dupont', type: 'public'),
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
      ];
    controller
      ..selectPlayer(controller.players.first)
      ..addToCart(controller.articles.first);

    tester.view.physicalSize = const Size(393, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.only(bottom: 24),
            textScaler: TextScaler.linear(1.1),
          ),
          child: Scaffold(body: CaissePage(controller: controller)),
        ),
      ),
    );

    expect(find.text('PANIER (1)'), findsOneWidget);
    expect(find.text('ESP'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('collapsed mobile cart does not overflow when keyboard opens',
      (tester) async {
    final controller = _MemoryAppController()
      ..players = [
        Player(id: 'player-1', name: 'Alice Dupont', type: 'public'),
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
      ];
    controller
      ..selectPlayer(controller.players.first)
      ..addToCart(controller.articles.first);

    tester.view.physicalSize = const Size(393, 783);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);

    await tester.pumpWidget(
      MaterialApp(
        theme: caisseTheme(AppColors.accent),
        home: Scaffold(body: CaissePage(controller: controller)),
      ),
    );

    await tester
        .tap(find.widgetWithText(TextField, 'Rechercher un participant'));
    tester.view.viewInsets = const FakeViewPadding(bottom: 360);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('PANIER (1)'), findsOneWidget);
    expect(find.text('ESP'), findsNothing);
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

Sale _sale({required String id}) => Sale(
      id: id,
      playerId: 'player-1',
      playerName: 'Participant',
      playerType: 'public',
      tariff: 'public',
      items: [
        SaleItem(
          articleId: 'article-1',
          name: 'Eau',
          icon: '',
          type: 'standard',
          quantity: 1,
          price: 2,
          publicPrice: 2,
          memberPrice: 1.5,
        ),
      ],
      totalArticles: 2,
      donation: 0,
      payment: 'ESP',
      session: 'session-1',
      createdAt: DateTime(2026, 7, 18, 10),
    );

Map<String, dynamic> _validModernBackup() => {
      'version': 3,
      'data': {
        'sessions': [
          {
            'id': 'session-1',
            'name': 'Session test',
            'event_date': '2026-07-18T00:00:00',
            'status': 'open',
            'created_at': '2026-07-18T00:00:00',
          }
        ],
        'players': <Map<String, Object?>>[],
        'sessionPlayers': <Map<String, Object?>>[],
        'articleCategories': <Map<String, Object?>>[],
        'articles': <Map<String, Object?>>[],
        'sales': <Map<String, Object?>>[],
        'saleItems': <Map<String, Object?>>[],
        'mealOrders': <Map<String, Object?>>[],
        'stockMovements': <Map<String, Object?>>[],
        'cashCounts': <Map<String, Object?>>[],
        'cashCountLines': <Map<String, Object?>>[],
        'appSettings': <Map<String, Object?>>[],
      },
    };

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
