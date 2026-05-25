part of '../../main.dart';

class Article {
  Article({
    required this.id,
    required this.category,
    required this.type,
    required this.icon,
    required this.name,
    required this.price,
    required this.memberPrice,
    required this.stock,
    required this.threshold,
    this.bbAuto = 0,
    this.gasAuto = 0,
  });

  final String id;
  String category;
  String type;
  String icon;
  String name;
  double price;
  double memberPrice;
  int stock;
  int threshold;
  double bbAuto;
  double gasAuto;

  bool get isLocation => type == 'location';
  bool get tracksStock => !isLocation && threshold > 0;

  double priceFor(bool member) =>
      member && memberPrice > 0 ? memberPrice : price;

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'type': type,
        'icon': icon,
        'name': name,
        'price': price,
        'memberPrice': memberPrice,
        'stock': stock,
        'threshold': threshold,
        'bbAuto': bbAuto,
        'gasAuto': gasAuto,
      };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
        id: '${json['id'] ?? DateTime.now().microsecondsSinceEpoch}',
        category: '${json['category'] ?? json['cat'] ?? 'DIVERS'}',
        type: '${json['type'] ?? 'standard'}',
        icon: '${json['icon'] ?? '📦'}',
        name: '${json['name'] ?? json['nom'] ?? 'Article'}',
        price: (json['price'] ?? json['prix'] ?? 0).toDouble(),
        memberPrice: (json['memberPrice'] ?? json['prixM'] ?? 0).toDouble(),
        stock: (json['stock'] ?? 0).round(),
        threshold: (json['threshold'] ?? json['seuil'] ?? 0).round(),
        bbAuto: (json['bbAuto'] ?? 0).toDouble(),
        gasAuto: (json['gasAuto'] ?? 0).toDouble(),
      );
}

String makeId([String prefix = 'id']) =>
    '$prefix-${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

String stableCategoryId(String category) {
  final normalized = category
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
  return normalized.isEmpty ? 'divers' : normalized;
}

String normalizedCategoryName(String category) => category.trim().toUpperCase();

List<String> defaultArticleCategories() => [
      'BOISSONS',
      'SNACKING',
      'MUNITIONS',
      'REPAS',
      'GOODIES',
      'LOCATION',
      'DIVERS',
    ];

class SessionRecord {
  SessionRecord({
    required this.id,
    required this.name,
    required this.eventDate,
    this.status = 'open',
    this.notes = '',
    this.helloassoFormSlug = '',
    this.helloassoFormType = '',
    this.helloassoEventName = '',
    this.helloassoEventUrl = '',
    this.helloassoEventId = '',
    this.helloassoSyncedAt,
    DateTime? createdAt,
    this.closedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  DateTime eventDate;
  String status;
  String notes;
  String helloassoFormSlug;
  String helloassoFormType;
  String helloassoEventName;
  String helloassoEventUrl;
  String helloassoEventId;
  DateTime? helloassoSyncedAt;
  DateTime createdAt;
  DateTime? closedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'eventDate': eventDate.toIso8601String(),
        'status': status,
        'notes': notes,
        'helloassoFormSlug': helloassoFormSlug,
        'helloassoFormType': helloassoFormType,
        'helloassoEventName': helloassoEventName,
        'helloassoEventUrl': helloassoEventUrl,
        'helloassoEventId': helloassoEventId,
        'helloassoSyncedAt': helloassoSyncedAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'closedAt': closedAt?.toIso8601String(),
      };

  factory SessionRecord.fromJson(Map<String, dynamic> json) => SessionRecord(
        id: '${json['id'] ?? makeId('session')}',
        name: '${json['name'] ?? json['session'] ?? 'Partie'}',
        eventDate: DateTime.tryParse(
                '${json['eventDate'] ?? json['event_date'] ?? ''}') ??
            DateTime.now(),
        status: '${json['status'] ?? 'open'}',
        notes: '${json['notes'] ?? ''}',
        helloassoFormSlug:
            '${json['helloassoFormSlug'] ?? json['helloasso_form_slug'] ?? ''}',
        helloassoFormType:
            '${json['helloassoFormType'] ?? json['helloasso_form_type'] ?? ''}',
        helloassoEventName:
            '${json['helloassoEventName'] ?? json['helloasso_event_name'] ?? ''}',
        helloassoEventUrl:
            '${json['helloassoEventUrl'] ?? json['helloasso_event_url'] ?? ''}',
        helloassoEventId:
            '${json['helloassoEventId'] ?? json['helloasso_event_id'] ?? ''}',
        helloassoSyncedAt: DateTime.tryParse(
            '${json['helloassoSyncedAt'] ?? json['helloasso_synced_at'] ?? ''}'),
        createdAt: DateTime.tryParse(
                '${json['createdAt'] ?? json['created_at'] ?? ''}') ??
            DateTime.now(),
        closedAt:
            DateTime.tryParse('${json['closedAt'] ?? json['closed_at'] ?? ''}'),
      );
}

class Player {
  Player({
    required this.id,
    required this.name,
    required this.type,
    this.firstName = '',
    this.lastName = '',
    this.email = '',
    this.helloassoUserId = '',
  });

  final String id;
  String name;
  String type;
  String firstName;
  String lastName;
  String email;
  String helloassoUserId;

  bool get isMember => type == 'membre';

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'helloassoUserId': helloassoUserId,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: '${json['id'] ?? makeId('player')}',
        name:
            '${json['name'] ?? json['nom'] ?? _playerNameFromParts('${json['firstName'] ?? ''}', '${json['lastName'] ?? ''}', 'Joueur')}',
        type: '${json['type'] ?? 'public'}',
        firstName: '${json['firstName'] ?? json['first_name'] ?? ''}',
        lastName: '${json['lastName'] ?? json['last_name'] ?? ''}',
        email: '${json['email'] ?? ''}'.trim().toLowerCase(),
        helloassoUserId:
            '${json['helloassoUserId'] ?? json['helloasso_user_id'] ?? ''}',
      );
}

String _playerNameFromParts(
    String firstName, String lastName, String fallback) {
  final fullName = [firstName.trim(), lastName.trim()]
      .where((part) => part.isNotEmpty)
      .join(' ');
  return fullName.isEmpty ? fallback.trim() : fullName;
}

({String firstName, String lastName}) splitPlayerName(String value) {
  final parts = value
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) return (firstName: '', lastName: '');
  if (parts.length == 1) return (firstName: parts.first, lastName: '');
  return (firstName: parts.first, lastName: parts.skip(1).join(' '));
}

class CartItem {
  CartItem(
      {required this.articleId, required this.quantity, required this.price});

  final String articleId;
  int quantity;
  double price;
}

class SaleItem {
  SaleItem({
    required this.articleId,
    required this.name,
    required this.icon,
    required this.type,
    required this.quantity,
    required this.price,
    required this.publicPrice,
    required this.memberPrice,
  });

  final String articleId;
  final String name;
  final String icon;
  final String type;
  final int quantity;
  final double price;
  final double publicPrice;
  final double memberPrice;

  Map<String, dynamic> toJson() => {
        'articleId': articleId,
        'name': name,
        'icon': icon,
        'type': type,
        'quantity': quantity,
        'price': price,
        'publicPrice': publicPrice,
        'memberPrice': memberPrice,
      };

  factory SaleItem.fromJson(Map<String, dynamic> json) => SaleItem(
        articleId: '${json['articleId'] ?? json['nom'] ?? json['name']}',
        name: '${json['name'] ?? json['nom'] ?? 'Article'}',
        icon: '${json['icon'] ?? '📦'}',
        type: '${json['type'] ?? 'standard'}',
        quantity: (json['quantity'] ?? json['qte'] ?? 1).round(),
        price: (json['price'] ?? json['prix'] ?? 0).toDouble(),
        publicPrice:
            (json['publicPrice'] ?? json['prixPublic'] ?? json['price'] ?? 0)
                .toDouble(),
        memberPrice: (json['memberPrice'] ?? json['prixM'] ?? 0).toDouble(),
      );
}

class Sale {
  Sale({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.playerType,
    required this.tariff,
    required this.items,
    required this.totalArticles,
    required this.donation,
    required this.payment,
    required this.session,
    required this.createdAt,
  });

  final String id;
  final String playerId;
  String playerName;
  final String playerType;
  final String tariff;
  final List<SaleItem> items;
  final double totalArticles;
  final double donation;
  final String payment;
  final String session;
  final DateTime createdAt;

  double get total => totalArticles + donation;

  Map<String, dynamic> toJson() => {
        'id': id,
        'playerId': playerId,
        'playerName': playerName,
        'playerType': playerType,
        'tariff': tariff,
        'items': items.map((e) => e.toJson()).toList(),
        'totalArticles': totalArticles,
        'donation': donation,
        'payment': payment,
        'session': session,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Sale.fromJson(Map<String, dynamic> json) => Sale(
        id: '${json['id'] ?? makeId('sale')}',
        playerId: '${json['playerId'] ?? json['joueurId'] ?? ''}',
        playerName: '${json['playerName'] ?? json['joueurNom'] ?? 'Joueur'}',
        playerType: '${json['playerType'] ?? json['joueurType'] ?? 'public'}',
        tariff: '${json['tariff'] ?? json['tarif'] ?? 'public'}',
        items: ((json['items'] ?? []) as List)
            .map((e) => SaleItem.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        totalArticles: (json['totalArticles'] ?? 0).toDouble(),
        donation: (json['donation'] ?? json['don'] ?? 0).toDouble(),
        payment: '${json['payment'] ?? json['paiement'] ?? 'ESP'}',
        session: '${json['session'] ?? ''}',
        createdAt:
            DateTime.tryParse('${json['createdAt'] ?? ''}') ?? DateTime.now(),
      );
}

class StockMovement {
  StockMovement({
    required this.id,
    required this.sessionId,
    required this.articleId,
    required this.movementType,
    required this.quantityDelta,
    required this.stockBefore,
    required this.stockAfter,
    required this.reason,
    required this.createdAt,
    this.saleId,
  });

  final String id;
  final String sessionId;
  final String articleId;
  final String? saleId;
  final String movementType;
  final int quantityDelta;
  final int stockBefore;
  final int stockAfter;
  final String reason;
  final DateTime createdAt;
}

class StockShortage {
  const StockShortage({
    required this.article,
    required this.requiredQuantity,
    required this.availableQuantity,
  });

  final Article article;
  final int requiredQuantity;
  final int availableQuantity;

  String get message =>
      '${article.name} : $requiredQuantity requis, $availableQuantity disponible(s)';
}

class MealOrder {
  MealOrder({
    required this.id,
    required this.playerId,
    required this.playerName,
    required this.playerType,
    required this.source,
    required this.status,
    required this.mealArticleId,
    required this.formula,
    required this.createdAt,
    this.saleId = '',
    this.payment = '',
    this.drinkArticleId = '',
    this.snackArticleId = '',
    List<String>? options,
    this.note = '',
    this.preparedAt,
    this.servedAt,
    DateTime? updatedAt,
  })  : options = options ?? [],
        updatedAt = updatedAt ?? createdAt;

  final String id;
  final String playerId;
  String playerName;
  final String playerType;
  final String source;
  String status;
  String saleId;
  final String payment;
  String mealArticleId;
  String drinkArticleId;
  String snackArticleId;
  String formula;
  List<String> options;
  String note;
  final DateTime createdAt;
  DateTime? preparedAt;
  DateTime? servedAt;
  DateTime updatedAt;

  bool get consumesStock => status == 'prepared' || status == 'served';
  bool get isOnsite => source == 'onsite';
  Map<String, int> get stockItems {
    final result = <String, int>{};
    for (final articleId in [
      mealArticleId,
      drinkArticleId,
      snackArticleId,
    ]) {
      if (articleId.isNotEmpty) {
        result[articleId] = (result[articleId] ?? 0) + 1;
      }
    }
    return result;
  }

  MealOrder copyWith({
    String? status,
    String? saleId,
    String? mealArticleId,
    String? drinkArticleId,
    String? snackArticleId,
    String? formula,
    List<String>? options,
    String? note,
    DateTime? preparedAt,
    DateTime? servedAt,
    DateTime? updatedAt,
  }) =>
      MealOrder(
        id: id,
        playerId: playerId,
        playerName: playerName,
        playerType: playerType,
        source: source,
        status: status ?? this.status,
        saleId: saleId ?? this.saleId,
        payment: payment,
        mealArticleId: mealArticleId ?? this.mealArticleId,
        drinkArticleId: drinkArticleId ?? this.drinkArticleId,
        snackArticleId: snackArticleId ?? this.snackArticleId,
        formula: formula ?? this.formula,
        options: options ?? List<String>.of(this.options),
        note: note ?? this.note,
        createdAt: createdAt,
        preparedAt: preparedAt ?? this.preparedAt,
        servedAt: servedAt ?? this.servedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

const denominations = <double>[
  500,
  200,
  100,
  50,
  20,
  10,
  5,
  2,
  1,
  .5,
  .2,
  .1,
  .05,
  .02,
  .01
];

String money(num value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';

String dateLabel(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

String timeLabel(DateTime date) {
  final h = date.hour.toString().padLeft(2, '0');
  final m = date.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

class HelloAssoSettings {
  const HelloAssoSettings({
    this.organizationSlug = '',
    this.clientId = '',
    this.clientSecret = '',
    this.environment = 'production',
  });

  final String organizationSlug;
  final String clientId;
  final String clientSecret;
  final String environment;

  bool get isConfigured =>
      organizationSlug.trim().isNotEmpty &&
      clientId.trim().isNotEmpty &&
      clientSecret.trim().isNotEmpty;
  bool get isSandbox => environment == 'sandbox';
  String get authBaseUrl => isSandbox
      ? 'https://api.helloasso-sandbox.com'
      : 'https://api.helloasso.com';
  String get apiBaseUrl => '$authBaseUrl/v5';

  HelloAssoSettings withoutSecret() => HelloAssoSettings(
        organizationSlug: organizationSlug,
        clientId: clientId,
        environment: environment,
      );

  HelloAssoSettings withSecret(String value) => HelloAssoSettings(
        organizationSlug: organizationSlug,
        clientId: clientId,
        clientSecret: value,
        environment: environment,
      );

  Map<String, dynamic> toJson({bool includeSecret = true}) => {
        'organizationSlug': organizationSlug,
        'clientId': clientId,
        if (includeSecret) 'clientSecret': clientSecret,
        'environment': environment,
      };

  factory HelloAssoSettings.fromJson(Map<String, dynamic> json) =>
      HelloAssoSettings(
        organizationSlug: '${json['organizationSlug'] ?? ''}',
        clientId: '${json['clientId'] ?? ''}',
        clientSecret: '${json['clientSecret'] ?? ''}',
        environment: '${json['environment'] ?? 'production'}' == 'sandbox'
            ? 'sandbox'
            : 'production',
      );
}

class HelloAssoEvent {
  const HelloAssoEvent({
    required this.name,
    required this.formSlug,
    required this.url,
    this.formType = 'Event',
    this.id = '',
  });

  final String name;
  final String formSlug;
  final String formType;
  final String url;
  final String id;
}

class HelloAssoRegistrant {
  const HelloAssoRegistrant({
    required this.firstName,
    required this.lastName,
    required this.email,
    this.helloassoUserId = '',
  });

  final String firstName;
  final String lastName;
  final String email;
  final String helloassoUserId;
}

List<Article> defaultArticles() => [
      Article(
          id: 'coca',
          category: 'BOISSONS',
          type: 'standard',
          icon: '🥤',
          name: 'Coca / Pepsi',
          price: 2,
          memberPrice: 1.8,
          stock: 24,
          threshold: 6),
      Article(
          id: 'eau',
          category: 'BOISSONS',
          type: 'standard',
          icon: '💧',
          name: 'Eau',
          price: 1,
          memberPrice: .8,
          stock: 24,
          threshold: 6),
      Article(
          id: 'jus',
          category: 'BOISSONS',
          type: 'standard',
          icon: '🧃',
          name: 'Jus / IceTea',
          price: 2,
          memberPrice: 1.8,
          stock: 12,
          threshold: 4),
      Article(
          id: 'monster-mango',
          category: 'BOISSONS',
          type: 'standard',
          icon: '🟡',
          name: 'Monster Mango',
          price: 2.5,
          memberPrice: 2,
          stock: 6,
          threshold: 2),
      Article(
          id: 'monster-noir',
          category: 'BOISSONS',
          type: 'standard',
          icon: '⚫',
          name: 'Monster Noir',
          price: 2.5,
          memberPrice: 2,
          stock: 6,
          threshold: 2),
      Article(
          id: 'snacks',
          category: 'SNACKING',
          type: 'standard',
          icon: '🍟',
          name: 'Snacks / Chips',
          price: 1.5,
          memberPrice: 1.5,
          stock: 20,
          threshold: 5),
      Article(
          id: 'billes',
          category: 'MUNITIONS',
          type: 'standard',
          icon: '⚙️',
          name: 'Billes (sachet)',
          price: 3,
          memberPrice: 2.5,
          stock: 30,
          threshold: 5),
      Article(
          id: 'gaz',
          category: 'MUNITIONS',
          type: 'standard',
          icon: '🔵',
          name: 'Gaz',
          price: 5,
          memberPrice: 4,
          stock: 10,
          threshold: 2),
      Article(
          id: 'repas',
          category: 'REPAS',
          type: 'standard',
          icon: '🍔',
          name: 'Repas',
          price: 10,
          memberPrice: 9,
          stock: 20,
          threshold: 5),
      Article(
          id: 'patch',
          category: 'GOODIES',
          type: 'standard',
          icon: '🎖️',
          name: 'Patch',
          price: 5,
          memberPrice: 4,
          stock: 50,
          threshold: 10),
      Article(
          id: 'porte-cle',
          category: 'GOODIES',
          type: 'standard',
          icon: '🔑',
          name: 'Porte-clés',
          price: 3,
          memberPrice: 2.5,
          stock: 30,
          threshold: 5),
      Article(
          id: 'divers',
          category: 'GOODIES',
          type: 'standard',
          icon: '📦',
          name: 'Divers',
          price: 0,
          memberPrice: 0,
          stock: 0,
          threshold: 0),
      Article(
          id: 'location',
          category: 'LOCATION',
          type: 'location',
          icon: '🎯',
          name: 'Location réplique',
          price: 15,
          memberPrice: 12,
          stock: 0,
          threshold: 0,
          bbAuto: 0,
          gasAuto: 0),
    ];
