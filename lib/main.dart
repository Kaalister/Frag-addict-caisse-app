import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as sqflite_ffi;

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqflite_ffi.sqfliteFfiInit();
    databaseFactory = sqflite_ffi.databaseFactoryFfi;
  }
  await FirebaseBootstrap.initialize();
  runApp(const CaisseAirsoftApp());
}

class FirebaseBootstrap {
  static bool initialized = false;
  static String? error;

  static Future<void> initialize() async {
    try {
      final options = DefaultFirebaseOptions.currentPlatform;
      if (_isPlaceholder(options)) {
        error = 'Configuration Firebase à compléter';
        return;
      }
      await Firebase.initializeApp(options: options);
      initialized = true;
    } catch (exception) {
      error = '$exception';
    }
  }

  static bool _isPlaceholder(FirebaseOptions options) {
    return options.apiKey.contains('REPLACE_ME') ||
        options.appId.contains('REPLACE_ME') ||
        options.projectId.contains('REPLACE_ME');
  }
}

class AppColors {
  static const bg = Color(0xFF0D0D0D);
  static const surface = Color(0xFF161616);
  static const surface2 = Color(0xFF1E1E1E);
  static const border = Color(0xFF2A2A2A);
  static const accent = Color(0xFFC8F135);
  static const accent2 = Color(0xFF35C8F1);
  static const danger = Color(0xFFF13535);
  static const warn = Color(0xFFF1A035);
  static const text = Color(0xFFF0F0F0);
  static const muted = Color(0xFF8B8B8B);
  static const cash = Color(0xFF4CAF50);
  static const paypal = Color(0xFF1565C0);
  static const sumup = Color(0xFF7B1FA2);
}

class VisualIdentity {
  static const name = 'Frags Addicts Tactical POS';
  static const mood = 'noir carbone, vert traceur, cyan instrumentation';
  static const radius = 8.0;
}

class CaisseAirsoftApp extends StatelessWidget {
  const CaisseAirsoftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Caisse Airsoft',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          secondary: AppColors.accent2,
          surface: AppColors.surface,
          error: AppColors.danger,
        ),
        useMaterial3: true,
        cardTheme: CardThemeData(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(VisualIdentity.radius),
            side: const BorderSide(color: AppColors.border),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface2,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.accent),
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          indicatorColor: AppColors.accent,
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Colors.black);
            }
            return const IconThemeData(color: AppColors.muted);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 12);
            }
            return const TextStyle(color: AppColors.muted, fontSize: 12);
          }),
        ),
        navigationRailTheme: const NavigationRailThemeData(
          indicatorColor: AppColors.accent,
          selectedIconTheme: IconThemeData(color: Colors.black),
          unselectedIconTheme: IconThemeData(color: AppColors.muted),
          selectedLabelTextStyle:
              TextStyle(color: AppColors.accent, fontWeight: FontWeight.w800),
          unselectedLabelTextStyle: TextStyle(color: AppColors.muted),
        ),
      ),
      home: const RootShell(),
    );
  }
}

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

  Map<String, dynamic> toJson() => {
        'organizationSlug': organizationSlug,
        'clientId': clientId,
        'clientSecret': clientSecret,
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

class HelloAssoClient {
  HelloAssoClient(this.settings);

  final HelloAssoSettings settings;
  String? _token;
  DateTime? _tokenExpiresAt;

  Future<String> _accessToken() async {
    if (_token != null &&
        _tokenExpiresAt != null &&
        DateTime.now()
            .isBefore(_tokenExpiresAt!.subtract(const Duration(minutes: 2)))) {
      return _token!;
    }
    final response = await http.post(
      Uri.parse('${settings.authBaseUrl}/oauth2/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'grant_type': 'client_credentials',
        'client_id': settings.clientId,
        'client_secret': settings.clientSecret,
      },
    );
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Connexion HelloAsso refusée (${response.statusCode})');
    }
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    _token = '${data['access_token']}';
    final expiresIn = int.tryParse('${data['expires_in'] ?? 1800}') ?? 1800;
    _tokenExpiresAt = DateTime.now().add(Duration(seconds: expiresIn));
    return _token!;
  }

  Future<List<dynamic>> _getPaged(Uri firstUri) async {
    final token = await _accessToken();
    final rows = <dynamic>[];
    Uri uri = firstUri;
    for (var page = 0; page < 20; page++) {
      final response = await http.get(uri, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json'
      });
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception('Erreur HelloAsso (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final pageRows = (data['data'] ?? data['items'] ?? []) as List;
      rows.addAll(pageRows);
      final continuationToken =
          '${(data['pagination'] as Map?)?['continuationToken'] ?? ''}';
      if (continuationToken.isEmpty) break;
      uri = firstUri.replace(queryParameters: {
        ...firstUri.queryParameters,
        'continuationToken': continuationToken
      });
    }
    return rows;
  }

  Future<List<HelloAssoEvent>> fetchEvents() async {
    final uri = Uri.parse(
            '${settings.apiBaseUrl}/organizations/${Uri.encodeComponent(settings.organizationSlug)}/forms')
        .replace(queryParameters: {
      'formTypes': 'Event',
      'pageSize': '100',
    });
    final rows = await _getPaged(uri);
    return rows
        .map((entry) {
          final map = Map<String, dynamic>.from(entry as Map);
          final formSlug = '${map['formSlug'] ?? map['slug'] ?? ''}';
          final name = '${map['title'] ?? map['name'] ?? formSlug}';
          return HelloAssoEvent(
            id: '${map['id'] ?? ''}',
            formSlug: formSlug,
            formType: '${map['formType'] ?? 'Event'}',
            name: name,
            url:
                '${map['url'] ?? map['publicUrl'] ?? map['widgetFullUrl'] ?? _defaultEventUrl(formSlug)}',
          );
        })
        .where((event) => event.formSlug.isNotEmpty)
        .toList();
  }

  Future<List<HelloAssoRegistrant>> fetchPaidOrderPayers(
      HelloAssoEvent event) async {
    final uri = Uri.parse(
            '${settings.apiBaseUrl}/organizations/${Uri.encodeComponent(settings.organizationSlug)}/forms/${event.formType}/${Uri.encodeComponent(event.formSlug)}/orders')
        .replace(queryParameters: {
      'withDetails': 'true',
      'pageSize': '100',
    });
    final rows = await _getPaged(uri);
    final byEmail = <String, HelloAssoRegistrant>{};
    for (final entry in rows) {
      final map = Map<String, dynamic>.from(entry as Map);
      final state = '${map['state'] ?? map['orderState'] ?? ''}'.toLowerCase();
      if (state.contains('cancel') ||
          state.contains('refund') ||
          state.contains('refused')) continue;
      final payer =
          Map<String, dynamic>.from((map['payer'] as Map?) ?? const {});
      final email = '${payer['email'] ?? ''}'.trim().toLowerCase();
      final firstName =
          '${payer['firstName'] ?? payer['firstname'] ?? ''}'.trim();
      final lastName = '${payer['lastName'] ?? payer['lastname'] ?? ''}'.trim();
      if (email.isEmpty && firstName.isEmpty && lastName.isEmpty) continue;
      final key = email.isNotEmpty
          ? email
          : _playerNameFromParts(firstName, lastName, makeId('helloasso'));
      byEmail[key] = HelloAssoRegistrant(
        firstName: firstName,
        lastName: lastName,
        email: email,
        helloassoUserId: '${payer['id'] ?? payer['userId'] ?? ''}',
      );
    }
    return byEmail.values.toList()
      ..sort((a, b) => _playerNameFromParts(a.firstName, a.lastName, a.email)
          .compareTo(_playerNameFromParts(b.firstName, b.lastName, b.email)));
  }

  String _defaultEventUrl(String formSlug) {
    return settings.isSandbox
        ? 'https://www.helloasso-sandbox.com/associations/${settings.organizationSlug}/evenements/$formSlug'
        : 'https://www.helloasso.com/associations/${settings.organizationSlug}/evenements/$formSlug';
  }
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
          bbAuto: 700,
          gasAuto: .15),
    ];

class LocalDatabase {
  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    final dbPath =
        path.join(await getDatabasesPath(), 'frags_addicts_caisse.db');
    _db = await openDatabase(dbPath,
        version: 4, onCreate: _create, onUpgrade: _upgrade);
    return _db!;
  }

  Future<void> _create(Database db, int version) async {
    await db.execute('''
      CREATE TABLE app_settings (
        key TEXT PRIMARY KEY,
        value TEXT,
        updated_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        event_date TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'open',
        notes TEXT,
        helloasso_form_slug TEXT,
        helloasso_form_type TEXT,
        helloasso_event_name TEXT,
        helloasso_event_url TEXT,
        helloasso_event_id TEXT,
        helloasso_synced_at TEXT,
        created_at TEXT NOT NULL,
        closed_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE players (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        first_name TEXT,
        last_name TEXT,
        email TEXT,
        helloasso_user_id TEXT,
        type TEXT NOT NULL DEFAULT 'public',
        created_at TEXT NOT NULL,
        updated_at TEXT,
        deleted_at TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE session_players (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        player_id TEXT,
        name_snapshot TEXT NOT NULL,
        type_snapshot TEXT NOT NULL,
        created_at TEXT NOT NULL,
        UNIQUE(session_id, player_id),
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE article_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE articles (
        id TEXT PRIMARY KEY,
        category_id TEXT,
        name TEXT NOT NULL,
        type TEXT NOT NULL DEFAULT 'standard',
        icon TEXT,
        price_public REAL NOT NULL DEFAULT 0,
        price_member REAL NOT NULL DEFAULT 0,
        stock_current INTEGER NOT NULL DEFAULT 0,
        stock_alert_threshold INTEGER NOT NULL DEFAULT 0,
        bb_auto_quantity REAL NOT NULL DEFAULT 0,
        gas_auto_quantity REAL NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1,
        sort_order INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        FOREIGN KEY (category_id) REFERENCES article_categories(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sales (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        session_player_id TEXT,
        player_id TEXT,
        player_name_snapshot TEXT NOT NULL,
        player_type_snapshot TEXT NOT NULL,
        tariff_applied TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        status TEXT NOT NULL DEFAULT 'active',
        total_articles REAL NOT NULL DEFAULT 0,
        donation_amount REAL NOT NULL DEFAULT 0,
        total_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        cancelled_at TEXT,
        cancellation_reason TEXT,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (session_player_id) REFERENCES session_players(id) ON DELETE SET NULL,
        FOREIGN KEY (player_id) REFERENCES players(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE sale_items (
        id TEXT PRIMARY KEY,
        sale_id TEXT NOT NULL,
        article_id TEXT,
        article_name_snapshot TEXT NOT NULL,
        article_category_snapshot TEXT,
        article_type_snapshot TEXT NOT NULL,
        icon_snapshot TEXT,
        quantity INTEGER NOT NULL,
        unit_price REAL NOT NULL,
        price_public_snapshot REAL NOT NULL,
        price_member_snapshot REAL NOT NULL,
        line_total REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE stock_movements (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        article_id TEXT NOT NULL,
        sale_id TEXT,
        movement_type TEXT NOT NULL,
        quantity_delta REAL NOT NULL,
        stock_before REAL NOT NULL,
        stock_after REAL NOT NULL,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE,
        FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE cash_counts (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        kind TEXT NOT NULL,
        total_amount REAL NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT,
        UNIQUE(session_id, kind),
        FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE cash_count_lines (
        id TEXT PRIMARY KEY,
        cash_count_id TEXT NOT NULL,
        denomination REAL NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        line_total REAL NOT NULL DEFAULT 0,
        UNIQUE(cash_count_id, denomination),
        FOREIGN KEY (cash_count_id) REFERENCES cash_counts(id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> _upgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion >= 2) {
      if (oldVersion < 3) await _upgradeToV3(db);
      if (oldVersion < 4) await _upgradeToV4(db);
      return;
    }
    final now = DateTime.now().toIso8601String();
    final sessionId = makeId('session');
    var sessionName = 'Partie migrée';
    final oldPlayers = <Map<String, Object?>>[];
    final oldArticles = <Map<String, Object?>>[];
    final oldSales = <Map<String, Object?>>[];
    final oldSaleItems = <Map<String, Object?>>[];
    final oldCashLines = <Map<String, Object?>>[];

    try {
      final setting = await db.query('app_settings',
          columns: ['value'],
          where: 'key = ?',
          whereArgs: ['session'],
          limit: 1);
      if (setting.isNotEmpty &&
          '${setting.first['value'] ?? ''}'.trim().isNotEmpty) {
        sessionName = '${setting.first['value']}';
      }
      oldPlayers.addAll(await db.query('players', where: 'deleted_at IS NULL'));
      oldArticles.addAll(await db.query('articles',
          where: 'is_active = 1', orderBy: 'sort_order ASC'));
      oldSales.addAll(await db.query('sales',
          where: "status = 'active'", orderBy: 'created_at ASC'));
      oldSaleItems.addAll(await db.query('sale_items', orderBy: 'id ASC'));
      oldCashLines.addAll(await db.query('cash_count_lines'));
    } catch (_) {
      // Best-effort migration: if the old schema is inconsistent, recreate a clean v2 database.
    }

    await _dropAll(db);
    await _create(db, newVersion);

    await db.insert('sessions', {
      'id': sessionId,
      'name': sessionName,
      'event_date': DateTime.now().toIso8601String(),
      'status': 'open',
      'notes': '',
      'created_at': now,
    });
    await db.insert('app_settings',
        {'key': 'active_session_id', 'value': sessionId, 'updated_at': now});

    for (final row in oldPlayers) {
      final playerId = '${row['id'] ?? makeId('player')}';
      await db.insert('players', {
        'id': playerId,
        'name': row['name'],
        'type': row['type'],
        'created_at': row['created_at'] ?? now,
        'updated_at': now,
        'deleted_at': row['deleted_at'],
      });
      await db.insert('session_players', {
        'id': makeId('session-player'),
        'session_id': sessionId,
        'player_id': playerId,
        'name_snapshot': row['name'],
        'type_snapshot': row['type'],
        'created_at': now,
      });
    }

    for (var i = 0; i < oldArticles.length; i++) {
      final row = oldArticles[i];
      final categoryName = '${row['category'] ?? 'DIVERS'}';
      final categoryId = stableCategoryId(categoryName);
      await db.insert('article_categories',
          {'id': categoryId, 'name': categoryName, 'sort_order': i},
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await db.insert('articles', {
        'id': row['id'],
        'category_id': categoryId,
        'name': row['name'],
        'type': row['type'],
        'icon': row['icon'],
        'price_public': row['price_public'],
        'price_member': row['price_member'],
        'stock_current': row['stock_current'],
        'stock_alert_threshold': row['stock_alert_threshold'],
        'bb_auto_quantity': row['bb_auto_quantity'],
        'gas_auto_quantity': row['gas_auto_quantity'],
        'is_active': row['is_active'],
        'sort_order': row['sort_order'] ?? i,
        'created_at': row['created_at'] ?? now,
        'updated_at': row['updated_at'] ?? now,
      });
    }

    for (final row in oldSales) {
      final saleId = '${row['id'] ?? makeId('sale')}';
      await db.insert('sales', {
        'id': saleId,
        'session_id': sessionId,
        'player_id': row['player_id'] == null ? null : '${row['player_id']}',
        'player_name_snapshot': row['player_name_snapshot'],
        'player_type_snapshot': row['player_type_snapshot'],
        'tariff_applied': row['tariff_applied'],
        'payment_method': row['payment_method'],
        'status': row['status'] ?? 'active',
        'total_articles': row['total_articles'],
        'donation_amount': row['donation_amount'],
        'total_amount': row['total_amount'],
        'created_at': row['created_at'] ?? now,
        'cancelled_at': row['cancelled_at'],
        'cancellation_reason': row['cancellation_reason'],
      });
    }

    for (final row in oldSaleItems) {
      await db.insert('sale_items', {
        'id': makeId('sale-item'),
        'sale_id': '${row['sale_id']}',
        'article_id': row['article_id'],
        'article_name_snapshot': row['article_name_snapshot'],
        'article_category_snapshot': null,
        'article_type_snapshot': row['article_type_snapshot'],
        'icon_snapshot': row['icon_snapshot'],
        'quantity': row['quantity'],
        'unit_price': row['unit_price'],
        'price_public_snapshot': row['price_public_snapshot'],
        'price_member_snapshot': row['price_member_snapshot'],
        'line_total': row['line_total'],
      });
    }

    await _migrateCashLines(db, sessionId, 'start', oldCashLines, now);
    await _migrateCashLines(db, sessionId, 'end', oldCashLines, now);
  }

  Future<void> _upgradeToV3(Database db) async {
    await _safeAddColumn(db, 'players', 'first_name TEXT');
    await _safeAddColumn(db, 'players', 'last_name TEXT');
    await _safeAddColumn(db, 'players', 'email TEXT');
    await _safeAddColumn(db, 'players', 'helloasso_user_id TEXT');
  }

  Future<void> _upgradeToV4(Database db) async {
    await _safeAddColumn(db, 'sessions', 'helloasso_form_slug TEXT');
    await _safeAddColumn(db, 'sessions', 'helloasso_form_type TEXT');
    await _safeAddColumn(db, 'sessions', 'helloasso_event_name TEXT');
    await _safeAddColumn(db, 'sessions', 'helloasso_event_url TEXT');
    await _safeAddColumn(db, 'sessions', 'helloasso_event_id TEXT');
    await _safeAddColumn(db, 'sessions', 'helloasso_synced_at TEXT');
  }

  Future<void> _safeAddColumn(
      Database db, String table, String columnDefinition) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $columnDefinition');
    } catch (_) {
      // Column already exists or table is being recreated by an older migration.
    }
  }

  Future<void> _dropAll(Database db) async {
    for (final table in [
      'cash_count_lines',
      'cash_counts',
      'stock_movements',
      'sale_items',
      'sales',
      'session_players',
      'articles',
      'article_categories',
      'players',
      'sessions',
      'app_settings',
    ]) {
      await db.execute('DROP TABLE IF EXISTS $table');
    }
  }

  Future<void> _migrateCashLines(Database db, String sessionId, String kind,
      List<Map<String, Object?>> oldCashLines, String now) async {
    final countId = makeId('cash-count');
    var total = 0.0;
    final lines = oldCashLines
        .where((row) => '${row['cash_count_kind']}' == kind)
        .toList();
    for (final line in lines) {
      total += (line['line_total'] as num?)?.toDouble() ?? 0;
    }
    await db.insert('cash_counts', {
      'id': countId,
      'session_id': sessionId,
      'kind': kind,
      'total_amount': total,
      'created_at': now,
      'updated_at': now
    });
    for (final line in lines) {
      final denomination = (line['denomination'] as num?)?.toDouble() ?? 0;
      final quantity = (line['quantity'] as num?)?.round() ?? 0;
      await db.insert('cash_count_lines', {
        'id': makeId('cash-line'),
        'cash_count_id': countId,
        'denomination': denomination,
        'quantity': quantity,
        'line_total': denomination * quantity,
      });
    }
  }

  Future<String?> loadActiveSessionId() async {
    final db = await database;
    final rows = await db.query('app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['active_session_id'],
        limit: 1);
    return rows.isEmpty ? null : '${rows.first['value'] ?? ''}';
  }

  Future<HelloAssoSettings> loadHelloAssoSettings() async {
    final db = await database;
    final rows = await db.query('app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['helloasso_settings'],
        limit: 1);
    if (rows.isEmpty || rows.first['value'] == null)
      return const HelloAssoSettings();
    try {
      return HelloAssoSettings.fromJson(Map<String, dynamic>.from(
          jsonDecode('${rows.first['value']}') as Map));
    } catch (_) {
      return const HelloAssoSettings();
    }
  }

  Future<DateTime?> loadLocalUpdatedAt() async {
    final db = await database;
    final rows = await db.query('app_settings',
        columns: ['value'],
        where: 'key = ?',
        whereArgs: ['local_updated_at'],
        limit: 1);
    if (rows.isEmpty) return null;
    return DateTime.tryParse('${rows.first['value'] ?? ''}');
  }

  Future<void> saveSyncMetadata(DateTime syncedAt) async {
    final db = await database;
    final value = syncedAt.toIso8601String();
    await db.insert('app_settings',
        {'key': 'firebase_last_synced_at', 'value': value, 'updated_at': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveHelloAssoSettings(HelloAssoSettings settings) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      'app_settings',
      {
        'key': 'helloasso_settings',
        'value': jsonEncode(settings.toJson()),
        'updated_at': now
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert('app_settings',
        {'key': 'local_updated_at', 'value': now, 'updated_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> setActiveSessionId(String sessionId) async {
    final db = await database;
    await db.insert(
        'app_settings',
        {
          'key': 'active_session_id',
          'value': sessionId,
          'updated_at': DateTime.now().toIso8601String()
        },
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<SessionRecord>> loadSessions() async {
    final db = await database;
    final rows =
        await db.query('sessions', orderBy: 'event_date DESC, created_at DESC');
    return rows.map(_sessionFromRow).toList();
  }

  SessionRecord _sessionFromRow(Map<String, Object?> row) => SessionRecord(
        id: '${row['id']}',
        name: '${row['name']}',
        eventDate: DateTime.tryParse('${row['event_date']}') ?? DateTime.now(),
        status: '${row['status'] ?? 'open'}',
        notes: '${row['notes'] ?? ''}',
        helloassoFormSlug: '${row['helloasso_form_slug'] ?? ''}',
        helloassoFormType: '${row['helloasso_form_type'] ?? ''}',
        helloassoEventName: '${row['helloasso_event_name'] ?? ''}',
        helloassoEventUrl: '${row['helloasso_event_url'] ?? ''}',
        helloassoEventId: '${row['helloasso_event_id'] ?? ''}',
        helloassoSyncedAt:
            DateTime.tryParse('${row['helloasso_synced_at'] ?? ''}'),
        createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
        closedAt: DateTime.tryParse('${row['closed_at'] ?? ''}'),
      );

  Future<SessionRecord> createSession(String name,
      {HelloAssoEvent? helloassoEvent, DateTime? helloassoSyncedAt}) async {
    final db = await database;
    final now = DateTime.now();
    final session = SessionRecord(
      id: makeId('session'),
      name: name.trim().isEmpty ? 'Nouvelle partie' : name.trim(),
      eventDate: now,
      createdAt: now,
      helloassoFormSlug: helloassoEvent?.formSlug ?? '',
      helloassoFormType: helloassoEvent?.formType ?? '',
      helloassoEventName: helloassoEvent?.name ?? '',
      helloassoEventUrl: helloassoEvent?.url ?? '',
      helloassoEventId: helloassoEvent?.id ?? '',
      helloassoSyncedAt: helloassoSyncedAt,
    );
    await db.insert('sessions', {
      'id': session.id,
      'name': session.name,
      'event_date': session.eventDate.toIso8601String(),
      'status': session.status,
      'notes': session.notes,
      'helloasso_form_slug': session.helloassoFormSlug,
      'helloasso_form_type': session.helloassoFormType,
      'helloasso_event_name': session.helloassoEventName,
      'helloasso_event_url': session.helloassoEventUrl,
      'helloasso_event_id': session.helloassoEventId,
      'helloasso_synced_at': session.helloassoSyncedAt?.toIso8601String(),
      'created_at': session.createdAt.toIso8601String(),
      'closed_at': session.closedAt?.toIso8601String(),
    });
    await setActiveSessionId(session.id);
    return session;
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.transaction((txn) async {
      final saleRows = await txn.query('sales',
          columns: ['id'], where: 'session_id = ?', whereArgs: [sessionId]);
      for (final saleId in saleRows.map((row) => '${row['id']}')) {
        await txn
            .delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      }
      final cashRows = await txn.query('cash_counts',
          columns: ['id'], where: 'session_id = ?', whereArgs: [sessionId]);
      for (final cashId in cashRows.map((row) => '${row['id']}')) {
        await txn.delete('cash_count_lines',
            where: 'cash_count_id = ?', whereArgs: [cashId]);
      }
      await txn.delete('stock_movements',
          where: 'session_id = ?', whereArgs: [sessionId]);
      await txn
          .delete('sales', where: 'session_id = ?', whereArgs: [sessionId]);
      await txn.delete('session_players',
          where: 'session_id = ?', whereArgs: [sessionId]);
      await txn.delete('cash_counts',
          where: 'session_id = ?', whereArgs: [sessionId]);
      await txn.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
      await txn.delete('app_settings',
          where: 'key = ? AND value = ?',
          whereArgs: ['active_session_id', sessionId]);
    });
  }

  Future<List<Player>> loadAllPlayers() async {
    final db = await database;
    final rows = await db.query('players',
        where: 'deleted_at IS NULL', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(_playerFromRow).toList();
  }

  Future<List<Player>> loadPlayers(String sessionId) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT sp.player_id AS id, sp.name_snapshot AS name, sp.type_snapshot AS type
      FROM session_players sp
      WHERE sp.session_id = ?
      ORDER BY sp.name_snapshot COLLATE NOCASE ASC
    ''', [sessionId]);
    return rows.map(_playerFromRow).toList();
  }

  Player _playerFromRow(Map<String, Object?> row) {
    return Player(
      id: '${row['id']}',
      name: '${row['name']}',
      type: '${row['type']}',
      firstName: '${row['first_name'] ?? ''}',
      lastName: '${row['last_name'] ?? ''}',
      email: '${row['email'] ?? ''}'.trim().toLowerCase(),
      helloassoUserId: '${row['helloasso_user_id'] ?? ''}',
    );
  }

  Future<List<Article>> loadArticles() async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT a.*, COALESCE(c.name, 'DIVERS') AS category_name
      FROM articles a
      LEFT JOIN article_categories c ON c.id = a.category_id
      WHERE a.is_active = 1
      ORDER BY a.sort_order ASC, c.name ASC, a.name ASC
    ''');
    return rows
        .map((row) => Article(
              id: '${row['id']}',
              category: '${row['category_name']}',
              type: '${row['type']}',
              icon: '${row['icon'] ?? '📦'}',
              name: '${row['name']}',
              price: (row['price_public'] as num).toDouble(),
              memberPrice: (row['price_member'] as num).toDouble(),
              stock: (row['stock_current'] as num).round(),
              threshold: (row['stock_alert_threshold'] as num).round(),
              bbAuto: (row['bb_auto_quantity'] as num).toDouble(),
              gasAuto: (row['gas_auto_quantity'] as num).toDouble(),
            ))
        .toList();
  }

  Future<List<Sale>> loadSales(String sessionId) async {
    final db = await database;
    final rows = await db.query('sales',
        where: "session_id = ? AND status = 'active'",
        whereArgs: [sessionId],
        orderBy: 'created_at ASC');
    final result = <Sale>[];
    for (final row in rows) {
      final saleId = '${row['id']}';
      final itemRows = await db.query('sale_items',
          where: 'sale_id = ?', whereArgs: [saleId], orderBy: 'id ASC');
      result.add(Sale(
        id: saleId,
        playerId: '${row['player_id'] ?? ''}',
        playerName: '${row['player_name_snapshot']}',
        playerType: '${row['player_type_snapshot']}',
        tariff: '${row['tariff_applied']}',
        items: itemRows
            .map((item) => SaleItem(
                  articleId:
                      '${item['article_id'] ?? item['article_name_snapshot']}',
                  name: '${item['article_name_snapshot']}',
                  icon: '${item['icon_snapshot'] ?? '📦'}',
                  type: '${item['article_type_snapshot']}',
                  quantity: (item['quantity'] as num).round(),
                  price: (item['unit_price'] as num).toDouble(),
                  publicPrice:
                      (item['price_public_snapshot'] as num).toDouble(),
                  memberPrice:
                      (item['price_member_snapshot'] as num).toDouble(),
                ))
            .toList(),
        totalArticles: (row['total_articles'] as num).toDouble(),
        donation: (row['donation_amount'] as num).toDouble(),
        payment: '${row['payment_method']}',
        session: sessionId,
        createdAt: DateTime.tryParse('${row['created_at']}') ?? DateTime.now(),
      ));
    }
    return result;
  }

  Future<Map<String, int>> loadCash(String sessionId, String kind) async {
    final db = await database;
    final rows = await db.rawQuery('''
      SELECT ccl.denomination, ccl.quantity
      FROM cash_count_lines ccl
      INNER JOIN cash_counts cc ON cc.id = ccl.cash_count_id
      WHERE cc.session_id = ? AND cc.kind = ?
    ''', [sessionId, kind]);
    return {
      for (final row in rows)
        (row['denomination'] as num).toDouble().toString():
            (row['quantity'] as num).round(),
    };
  }

  Future<void> saveAll(AppController state) async {
    final db = await database;
    final now = DateTime.now().toIso8601String();
    final session = state.activeSession;
    if (session == null) return;
    await db.transaction((txn) async {
      await txn.insert(
          'sessions',
          {
            'id': session.id,
            'name': session.name,
            'event_date': session.eventDate.toIso8601String(),
            'status': session.status,
            'notes': session.notes,
            'helloasso_form_slug': session.helloassoFormSlug,
            'helloasso_form_type': session.helloassoFormType,
            'helloasso_event_name': session.helloassoEventName,
            'helloasso_event_url': session.helloassoEventUrl,
            'helloasso_event_id': session.helloassoEventId,
            'helloasso_synced_at': session.helloassoSyncedAt?.toIso8601String(),
            'created_at': session.createdAt.toIso8601String(),
            'closed_at': session.closedAt?.toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('app_settings',
          {'key': 'active_session_id', 'value': session.id, 'updated_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.insert('app_settings',
          {'key': 'local_updated_at', 'value': now, 'updated_at': now},
          conflictAlgorithm: ConflictAlgorithm.replace);

      final uniqueAllPlayers = <String, Player>{
        for (final player in [...state.allPlayers, ...state.players])
          if (player.id.trim().isNotEmpty) player.id: player,
      }.values.toList();
      for (final player in uniqueAllPlayers) {
        await txn.insert(
            'players',
            {
              'id': player.id,
              'name': player.name,
              'first_name': player.firstName,
              'last_name': player.lastName,
              'email': player.email.trim().toLowerCase(),
              'helloasso_user_id': player.helloassoUserId,
              'type': player.type,
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.delete('session_players',
          where: 'session_id = ?', whereArgs: [session.id]);
      final uniqueSessionPlayers = <String, Player>{
        for (final player in state.players)
          if (player.id.trim().isNotEmpty) player.id: player,
      }.values.toList();
      for (final player in uniqueSessionPlayers) {
        await txn.insert(
            'session_players',
            {
              'id': makeId('session-player'),
              'session_id': session.id,
              'player_id': player.id,
              'name_snapshot': player.name,
              'type_snapshot': player.type,
              'created_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await txn.update('articles', {'is_active': 0, 'updated_at': now});
      for (var i = 0; i < state.articles.length; i++) {
        final article = state.articles[i];
        final categoryId = stableCategoryId(article.category);
        await txn.insert('article_categories',
            {'id': categoryId, 'name': article.category, 'sort_order': i},
            conflictAlgorithm: ConflictAlgorithm.ignore);
        await txn.insert(
            'articles',
            {
              'id': article.id,
              'category_id': categoryId,
              'name': article.name,
              'type': article.type,
              'icon': article.icon,
              'price_public': article.price,
              'price_member': article.memberPrice,
              'stock_current': article.stock,
              'stock_alert_threshold': article.threshold,
              'bb_auto_quantity': article.bbAuto,
              'gas_auto_quantity': article.gasAuto,
              'is_active': 1,
              'sort_order': i,
              'created_at': now,
              'updated_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      }

      final saleRows = await txn.query('sales',
          columns: ['id'], where: 'session_id = ?', whereArgs: [session.id]);
      final saleIds = saleRows.map((row) => '${row['id']}').toList();
      for (final saleId in saleIds) {
        await txn
            .delete('sale_items', where: 'sale_id = ?', whereArgs: [saleId]);
      }
      await txn
          .delete('sales', where: 'session_id = ?', whereArgs: [session.id]);

      for (final sale in state.sales) {
        await txn.insert('sales', {
          'id': sale.id,
          'session_id': session.id,
          'player_id': sale.playerId,
          'player_name_snapshot': sale.playerName,
          'player_type_snapshot': sale.playerType,
          'tariff_applied': sale.tariff,
          'payment_method': sale.payment,
          'status': 'active',
          'total_articles': sale.totalArticles,
          'donation_amount': sale.donation,
          'total_amount': sale.total,
          'created_at': sale.createdAt.toIso8601String(),
        });
        for (final item in sale.items) {
          await txn.insert('sale_items', {
            'id': makeId('sale-item'),
            'sale_id': sale.id,
            'article_id': item.articleId,
            'article_name_snapshot': item.name,
            'article_category_snapshot': state.articles
                .where((a) => a.id == item.articleId)
                .firstOrNull
                ?.category,
            'article_type_snapshot': item.type,
            'icon_snapshot': item.icon,
            'quantity': item.quantity,
            'unit_price': item.price,
            'price_public_snapshot': item.publicPrice,
            'price_member_snapshot': item.memberPrice,
            'line_total': item.price * item.quantity,
          });
        }
      }

      final cashRows = await txn.query('cash_counts',
          columns: ['id'], where: 'session_id = ?', whereArgs: [session.id]);
      for (final cashId in cashRows.map((row) => '${row['id']}')) {
        await txn.delete('cash_count_lines',
            where: 'cash_count_id = ?', whereArgs: [cashId]);
      }
      await txn.delete('cash_counts',
          where: 'session_id = ?', whereArgs: [session.id]);
      await _insertCash(txn, session.id, 'start', state.cashStart,
          state.cashTotal('start'), now);
      await _insertCash(
          txn, session.id, 'end', state.cashEnd, state.cashTotal('end'), now);
    });
  }

  Future<void> _insertCash(Transaction txn, String sessionId, String kind,
      Map<String, int> values, double total, String now) async {
    final cashCountId = makeId('cash-count');
    await txn.insert('cash_counts', {
      'id': cashCountId,
      'session_id': sessionId,
      'kind': kind,
      'total_amount': total,
      'created_at': now,
      'updated_at': now
    });
    for (final entry in values.entries) {
      final denomination = double.tryParse(entry.key) ?? 0;
      await txn.insert('cash_count_lines', {
        'id': makeId('cash-line'),
        'cash_count_id': cashCountId,
        'denomination': denomination,
        'quantity': entry.value,
        'line_total': denomination * entry.value,
      });
    }
  }

  Future<Map<String, dynamic>> exportAll() async {
    final db = await database;
    return {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'identity': VisualIdentity.name,
      'data': {
        'sessions': await db.query('sessions'),
        'players': await db.query('players'),
        'sessionPlayers': await db.query('session_players'),
        'articleCategories': await db.query('article_categories'),
        'articles': await db.query('articles'),
        'sales': await db.query('sales'),
        'saleItems': await db.query('sale_items'),
        'stockMovements': await db.query('stock_movements'),
        'cashCounts': await db.query('cash_counts'),
        'cashCountLines': await db.query('cash_count_lines'),
        'appSettings': await db.query('app_settings'),
      },
    };
  }

  Future<void> replaceFromExport(Map<String, dynamic> payload) async {
    final data = Map<String, dynamic>.from(payload['data'] as Map? ?? {});
    final db = await database;
    await db.transaction((txn) async {
      for (final table in [
        'cash_count_lines',
        'cash_counts',
        'stock_movements',
        'sale_items',
        'sales',
        'session_players',
        'articles',
        'article_categories',
        'players',
        'sessions',
        'app_settings'
      ]) {
        await txn.delete(table);
      }
      Future<void> insertRows(String table, String key) async {
        for (final row in (data[key] as List? ?? const [])) {
          await txn.insert(table, Map<String, Object?>.from(row as Map),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }

      await insertRows('sessions', 'sessions');
      await insertRows('players', 'players');
      await insertRows('session_players', 'sessionPlayers');
      await insertRows('article_categories', 'articleCategories');
      await insertRows('articles', 'articles');
      await insertRows('sales', 'sales');
      await insertRows('sale_items', 'saleItems');
      await insertRows('stock_movements', 'stockMovements');
      await insertRows('cash_counts', 'cashCounts');
      await insertRows('cash_count_lines', 'cashCountLines');
      await insertRows('app_settings', 'appSettings');
    });
  }
}

enum FirebaseSyncAction { disabled, noUser, pushed, pulled, unchanged, error }

class FirebaseSyncResult {
  const FirebaseSyncResult(this.action, this.message, {this.syncedAt});

  final FirebaseSyncAction action;
  final String message;
  final DateTime? syncedAt;
}

class FirebaseSyncService {
  FirebaseSyncService();

  DocumentReference<Map<String, dynamic>> get _snapshotRef =>
      FirebaseFirestore.instance
          .collection('organizations')
          .doc('frags-addicts')
          .collection('snapshots')
          .doc('caisse-main');

  bool get isAvailable =>
      FirebaseBootstrap.initialized &&
      FirebaseAuth.instance.currentUser != null;

  Future<FirebaseSyncResult> synchronize(LocalDatabase database) async {
    if (!FirebaseBootstrap.initialized) {
      return FirebaseSyncResult(FirebaseSyncAction.disabled,
          FirebaseBootstrap.error ?? 'Firebase non configuré');
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const FirebaseSyncResult(
          FirebaseSyncAction.noUser, 'Connexion Firebase requise');
    }
    try {
      final remote = await _snapshotRef.get();
      final localUpdatedAt = await database.loadLocalUpdatedAt();
      if (remote.exists) {
        final data = remote.data() ?? const <String, dynamic>{};
        final remoteUpdatedAt = _remoteUpdatedAt(data);
        if (remoteUpdatedAt != null &&
            (localUpdatedAt == null ||
                remoteUpdatedAt.isAfter(localUpdatedAt))) {
          final payload =
              Map<String, dynamic>.from(data['payload'] as Map? ?? const {});
          if (payload.isNotEmpty) {
            await database.replaceFromExport(payload);
            await database.saveSyncMetadata(remoteUpdatedAt);
            return FirebaseSyncResult(
                FirebaseSyncAction.pulled, 'Données Firebase récupérées',
                syncedAt: remoteUpdatedAt);
          }
        }
        if (localUpdatedAt == null ||
            (remoteUpdatedAt != null &&
                !localUpdatedAt.isAfter(remoteUpdatedAt))) {
          final syncedAt = remoteUpdatedAt ?? DateTime.now();
          await database.saveSyncMetadata(syncedAt);
          return FirebaseSyncResult(
              FirebaseSyncAction.unchanged, 'Données déjà synchronisées',
              syncedAt: syncedAt);
        }
      } else if (localUpdatedAt == null) {
        return const FirebaseSyncResult(
            FirebaseSyncAction.unchanged, 'Aucune donnée à synchroniser');
      }

      final payload = await database.exportAll();
      final updatedAt = localUpdatedAt;
      await _snapshotRef.set({
        'payload': _jsonSafe(payload),
        'updatedAt': updatedAt.toIso8601String(),
        'updatedAtMillis': updatedAt.millisecondsSinceEpoch,
        'updatedBy': user.email ?? user.uid,
      });
      await database.saveSyncMetadata(updatedAt);
      return FirebaseSyncResult(
          FirebaseSyncAction.pushed, 'Données envoyées vers Firebase',
          syncedAt: updatedAt);
    } catch (exception) {
      return FirebaseSyncResult(
          FirebaseSyncAction.error, _friendlySyncError(exception));
    }
  }

  DateTime? _remoteUpdatedAt(Map<String, dynamic> data) {
    final millis = data['updatedAtMillis'];
    if (millis is num)
      return DateTime.fromMillisecondsSinceEpoch(millis.round());
    return DateTime.tryParse('${data['updatedAt'] ?? ''}');
  }

  Object _jsonSafe(Object value) {
    return jsonDecode(jsonEncode(value)) as Object;
  }

  String _friendlySyncError(Object exception) {
    if (exception is FirebaseException &&
        exception.code == 'permission-denied') {
      return 'Accès Firestore refusé. Vérifie les règles dans Firebase Console.';
    }
    if (exception is FirebaseException) {
      return 'Synchronisation Firebase impossible (${exception.code})';
    }
    return 'Synchronisation Firebase impossible';
  }
}

class AppController extends ChangeNotifier {
  final LocalDatabase _database = LocalDatabase();
  final FirebaseSyncService _syncService = FirebaseSyncService();

  bool loading = true;
  bool syncing = false;
  String syncStatus = FirebaseBootstrap.initialized
      ? 'Firebase prêt'
      : (FirebaseBootstrap.error ?? 'Firebase non configuré');
  DateTime? lastSyncedAt;
  int tab = 0;
  SessionRecord? activeSession;
  List<SessionRecord> sessions = [];
  String categoryFilter = 'TOUS';
  bool forceMemberTariff = false;
  double donation = 0;
  String? selectedPlayerId;
  HelloAssoSettings helloAssoSettings = const HelloAssoSettings();
  List<Player> allPlayers = [];
  List<Player> players = [];
  List<Article> articles = defaultArticles();
  List<Sale> sales = [];
  Map<String, List<Sale>> salesBySession = {};
  List<CartItem> cart = [];
  Map<String, int> cashStart = {};
  Map<String, int> cashEnd = {};
  bool _suspendAutoSync = false;

  String get session => activeSession?.name ?? '';
  String get firebaseUserLabel =>
      FirebaseAuth.instance.currentUser?.email ??
      FirebaseAuth.instance.currentUser?.uid ??
      '';
  bool get firebaseAvailable => _syncService.isAvailable;
  Player? get selectedPlayer =>
      players.where((p) => p.id == selectedPlayerId).firstOrNull;
  bool get memberTariff =>
      forceMemberTariff || (selectedPlayer?.isMember ?? false);
  double get cartArticlesTotal =>
      cart.fold(0, (sum, item) => sum + item.price * item.quantity);
  double get cartTotal => cartArticlesTotal + donation;
  int get cartCount => cart.fold(0, (sum, item) => sum + item.quantity);
  bool get hasPendingPayment => cart.isNotEmpty || donation > 0;
  bool get canCheckout => selectedPlayer != null && hasPendingPayment;
  List<String> get categories => [
        'TOUS',
        ...{for (final a in articles) a.category}
      ];
  List<Article> get visibleArticles => categoryFilter == 'TOUS'
      ? articles
      : articles.where((a) => a.category == categoryFilter).toList();

  Future<void> load() async {
    _suspendAutoSync = true;
    try {
      sessions = await _database.loadSessions();
      var activeSessionId = await _database.loadActiveSessionId();
      if (sessions.isEmpty) {
        final created = await _database.createSession('Nouvelle partie');
        sessions = [created];
        activeSessionId = created.id;
      }
      activeSession =
          sessions.where((s) => s.id == activeSessionId).firstOrNull ??
              sessions.first;
      if (activeSessionId != activeSession!.id) {
        await _database.setActiveSessionId(activeSession!.id);
      }
      helloAssoSettings = await _database.loadHelloAssoSettings();
      allPlayers = await _database.loadAllPlayers();
      players = await _database.loadPlayers(activeSession!.id);
      final storedArticles = await _database.loadArticles();
      articles = storedArticles.isEmpty ? defaultArticles() : storedArticles;
      sales = await _database.loadSales(activeSession!.id);
      await refreshSessionSales();
      cashStart = await _database.loadCash(activeSession!.id, 'start');
      cashEnd = await _database.loadCash(activeSession!.id, 'end');
      if (storedArticles.isEmpty) {
        await persist();
      }
    } catch (_) {
      articles = defaultArticles();
      syncStatus = 'Chargement local en mode dégradé';
    }
    _suspendAutoSync = false;
    loading = false;
    notifyListeners();
    if (_syncService.isAvailable) {
      await syncNow(reloadAfterPull: false);
    }
  }

  Future<void> persist() async {
    await _database.saveAll(this);
    _cacheActiveSessionSales();
    if (!_suspendAutoSync && _syncService.isAvailable) {
      final result = await _syncService.synchronize(_database);
      _applySyncResult(result);
      notifyListeners();
    }
  }

  Future<FirebaseSyncResult> syncNow({bool reloadAfterPull = true}) async {
    if (!_syncService.isAvailable) {
      final result = FirebaseSyncResult(FirebaseSyncAction.disabled,
          FirebaseBootstrap.error ?? 'Connexion Firebase requise');
      _applySyncResult(result);
      notifyListeners();
      return result;
    }
    syncing = true;
    syncStatus = 'Synchronisation en cours';
    notifyListeners();
    final result = await _syncService.synchronize(_database);
    _applySyncResult(result);
    if (reloadAfterPull && result.action == FirebaseSyncAction.pulled) {
      sessions = await _database.loadSessions();
      final activeSessionId = await _database.loadActiveSessionId();
      activeSession =
          sessions.where((s) => s.id == activeSessionId).firstOrNull ??
              sessions.firstOrNull;
      allPlayers = await _database.loadAllPlayers();
      final storedArticles = await _database.loadArticles();
      articles = storedArticles.isEmpty ? defaultArticles() : storedArticles;
      helloAssoSettings = await _database.loadHelloAssoSettings();
      await _loadActiveSessionState();
      await refreshSessionSales();
    }
    syncing = false;
    notifyListeners();
    return result;
  }

  void _applySyncResult(FirebaseSyncResult result) {
    syncStatus = result.message;
    if (result.syncedAt != null) lastSyncedAt = result.syncedAt;
  }

  Future<void> disconnectFirebase() async {
    if (FirebaseBootstrap.initialized) {
      await FirebaseAuth.instance.signOut();
    }
    syncStatus = 'Connexion Firebase requise';
    notifyListeners();
  }

  Future<void> refreshSessionSales() async {
    salesBySession = {
      for (final session in sessions)
        session.id: await _database.loadSales(session.id),
    };
    _cacheActiveSessionSales();
  }

  List<Sale> salesForSession(String sessionId) {
    return salesBySession[sessionId] ??
        (activeSession?.id == sessionId ? sales : const <Sale>[]);
  }

  void _cacheActiveSessionSales() {
    final sessionId = activeSession?.id;
    if (sessionId == null) return;
    salesBySession[sessionId] = List<Sale>.of(sales);
  }

  Future<void> importBackup(Map<String, dynamic> payload) async {
    if ((payload['version'] as num?)?.round() == 2 && payload['data'] is Map) {
      await _database.replaceFromExport(payload);
      await load();
      return;
    }
    final state =
        Map<String, dynamic>.from(payload['state'] as Map? ?? payload);
    final importedArticles = ((state['articles'] ?? []) as List)
        .map((entry) =>
            Article.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
    if (importedArticles.isEmpty) {
      throw const FormatException('Aucun article trouvé dans la sauvegarde');
    }
    final importedSession = SessionRecord(
      id: makeId('session'),
      name: '${state['session'] ?? 'Partie importée'}',
      eventDate: DateTime.now(),
    );
    activeSession = importedSession;
    sessions = [importedSession];
    players = ((state['players'] ?? []) as List)
        .map(
            (entry) => Player.fromJson(Map<String, dynamic>.from(entry as Map)))
        .toList();
    allPlayers = [...players];
    articles = importedArticles;
    sales = ((state['sales'] ?? []) as List).map((entry) {
      final sale = Sale.fromJson(Map<String, dynamic>.from(entry as Map));
      return Sale(
        id: sale.id,
        playerId: sale.playerId,
        playerName: sale.playerName,
        playerType: sale.playerType,
        tariff: sale.tariff,
        items: sale.items,
        totalArticles: sale.totalArticles,
        donation: sale.donation,
        payment: sale.payment,
        session: importedSession.id,
        createdAt: sale.createdAt,
      );
    }).toList();
    salesBySession = {importedSession.id: List<Sale>.of(sales)};
    cashStart = _parseCashMap(state['cashStart']);
    cashEnd = _parseCashMap(state['cashEnd']);
    cart.clear();
    donation = 0;
    selectedPlayerId = null;
    forceMemberTariff = false;
    categoryFilter = 'TOUS';
    await persist();
    notifyListeners();
  }

  Map<String, int> _parseCashMap(Object? value) {
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        '${entry.key}': int.tryParse('${entry.value}') ?? 0,
    };
  }

  void setTab(int value) {
    tab = value;
    notifyListeners();
  }

  Future<void> setSession(String value) async {
    final current = activeSession;
    if (current == null) return;
    current.name = value.trim().isEmpty ? 'Partie' : value.trim();
    sessions = sessions.map((s) => s.id == current.id ? current : s).toList();
    notifyListeners();
    await persist();
  }

  Future<void> saveHelloAssoSettings(HelloAssoSettings settings) async {
    helloAssoSettings = settings;
    notifyListeners();
    await _database.saveHelloAssoSettings(settings);
    if (_syncService.isAvailable) {
      final result = await _syncService.synchronize(_database);
      _applySyncResult(result);
      notifyListeners();
    }
  }

  Future<void> testHelloAssoConnection() async {
    if (!helloAssoSettings.isConfigured)
      throw Exception('Configuration HelloAsso incomplète');
    await HelloAssoClient(helloAssoSettings).fetchEvents();
  }

  Future<List<HelloAssoEvent>> fetchHelloAssoEvents() async {
    if (!helloAssoSettings.isConfigured) return const [];
    return HelloAssoClient(helloAssoSettings).fetchEvents();
  }

  Future<void> createSession(String name,
      {HelloAssoEvent? helloassoEvent}) async {
    await persist();
    final registrants = helloassoEvent == null
        ? const <HelloAssoRegistrant>[]
        : await HelloAssoClient(helloAssoSettings)
            .fetchPaidOrderPayers(helloassoEvent);
    final syncedAt = helloassoEvent == null ? null : DateTime.now();
    final created = await _database.createSession(
      name.trim().isEmpty ? (helloassoEvent?.name ?? 'Nouvelle partie') : name,
      helloassoEvent: helloassoEvent,
      helloassoSyncedAt: syncedAt,
    );
    sessions = await _database.loadSessions();
    activeSession = created;
    players = [];
    for (final registrant in registrants) {
      _attachHelloAssoRegistrant(registrant);
    }
    sales = [];
    salesBySession[created.id] = [];
    cashStart = {};
    cashEnd = {};
    cart.clear();
    donation = 0;
    selectedPlayerId = null;
    forceMemberTariff = false;
    categoryFilter = 'TOUS';
    notifyListeners();
    await persist();
  }

  void _attachHelloAssoRegistrant(HelloAssoRegistrant registrant) {
    final cleanEmail = registrant.email.trim().toLowerCase();
    final cleanName = _playerNameFromParts(
        registrant.firstName,
        registrant.lastName,
        cleanEmail.isEmpty ? 'Participant HelloAsso' : cleanEmail);
    final existing = cleanEmail.isNotEmpty
        ? allPlayers
            .where((p) => p.email.trim().toLowerCase() == cleanEmail)
            .firstOrNull
        : allPlayers
            .where((p) => p.name.toLowerCase() == cleanName.toLowerCase())
            .firstOrNull;
    final player = existing ??
        Player(id: makeId('player'), name: cleanName, type: 'public');
    player.firstName = registrant.firstName.trim();
    player.lastName = registrant.lastName.trim();
    player.email = cleanEmail;
    player.helloassoUserId = registrant.helloassoUserId;
    player.name = cleanName;
    if (existing == null) allPlayers.add(player);
    if (!players.any((p) => p.id == player.id)) players.add(player);
  }

  Future<void> switchSession(String sessionId) async {
    await persist();
    await _database.setActiveSessionId(sessionId);
    sessions = await _database.loadSessions();
    activeSession = sessions.where((s) => s.id == sessionId).firstOrNull ??
        sessions.firstOrNull;
    await _loadActiveSessionState();
    notifyListeners();
  }

  Future<void> deleteCurrentSession() async {
    final sessionId = activeSession?.id;
    if (sessionId == null) return;
    await _database.deleteSession(sessionId);
    salesBySession.remove(sessionId);
    sessions = await _database.loadSessions();
    if (sessions.isEmpty) {
      final created = await _database.createSession('Nouvelle partie');
      sessions = [created];
      activeSession = created;
    } else {
      activeSession = sessions.first;
      await _database.setActiveSessionId(activeSession!.id);
    }
    await _loadActiveSessionState();
    notifyListeners();
  }

  Future<void> _loadActiveSessionState() async {
    if (activeSession == null) return;
    players = await _database.loadPlayers(activeSession!.id);
    sales = await _database.loadSales(activeSession!.id);
    _cacheActiveSessionSales();
    cashStart = await _database.loadCash(activeSession!.id, 'start');
    cashEnd = await _database.loadCash(activeSession!.id, 'end');
    cart.clear();
    donation = 0;
    selectedPlayerId = null;
    forceMemberTariff = false;
    categoryFilter = 'TOUS';
  }

  Future<void> addPlayer(
      {required String firstName,
      required String lastName,
      required String email,
      required String type}) async {
    final cleanFirstName = firstName.trim();
    final cleanLastName = lastName.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanName = _playerNameFromParts(cleanFirstName, cleanLastName,
        cleanEmail.isEmpty ? 'Joueur' : cleanEmail);
    final existing = cleanEmail.isNotEmpty
        ? allPlayers
            .where((p) => p.email.trim().toLowerCase() == cleanEmail)
            .firstOrNull
        : allPlayers
            .where((p) => p.name.toLowerCase() == cleanName.toLowerCase())
            .firstOrNull;
    final player =
        existing ?? Player(id: makeId('player'), name: cleanName, type: type);
    player.name = cleanName;
    player.firstName = cleanFirstName;
    player.lastName = cleanLastName;
    player.email = cleanEmail;
    player.type = type;
    if (existing == null) allPlayers.add(player);
    if (!players.any((p) => p.id == player.id)) players.add(player);
    players.sort((a, b) => a.name.compareTo(b.name));
    allPlayers.sort((a, b) => a.name.compareTo(b.name));
    notifyListeners();
    await persist();
  }

  Future<void> updatePlayer(Player player,
      {required String firstName,
      required String lastName,
      required String email,
      required String type}) async {
    player.firstName = firstName.trim();
    player.lastName = lastName.trim();
    player.email = email.trim().toLowerCase();
    player.name = _playerNameFromParts(player.firstName, player.lastName,
        player.email.isEmpty ? player.name : player.email);
    player.type = type;
    final global = allPlayers.where((p) => p.id == player.id).firstOrNull;
    if (global != null) {
      global.name = player.name;
      global.firstName = player.firstName;
      global.lastName = player.lastName;
      global.email = player.email;
      global.type = player.type;
    }
    for (final sale in sales.where((s) => s.playerId == player.id)) {
      sale.playerName = player.name;
    }
    notifyListeners();
    await persist();
  }

  Future<void> removePlayer(Player player) async {
    players.removeWhere((p) => p.id == player.id);
    if (selectedPlayerId == player.id) selectedPlayerId = null;
    notifyListeners();
    await persist();
  }

  void selectPlayer(Player player) {
    selectedPlayerId = player.id;
    forceMemberTariff = false;
    for (final item in cart) {
      final article = articles.firstWhere((a) => a.id == item.articleId);
      item.price = article.priceFor(memberTariff);
    }
    notifyListeners();
  }

  void toggleMemberTariff() {
    forceMemberTariff = !forceMemberTariff;
    for (final item in cart) {
      final article = articles.firstWhere((a) => a.id == item.articleId);
      item.price = article.priceFor(memberTariff);
    }
    notifyListeners();
  }

  void setCategory(String category) {
    categoryFilter = category;
    notifyListeners();
  }

  void addToCart(Article article) {
    if (selectedPlayerId == null) return;
    final price = article.priceFor(memberTariff);
    final existing = cart.where((i) => i.articleId == article.id).firstOrNull;
    if (existing == null) {
      cart.add(CartItem(articleId: article.id, quantity: 1, price: price));
    } else {
      existing.quantity += 1;
      existing.price = price;
    }
    notifyListeners();
  }

  void changeCartQuantity(String articleId, int delta) {
    final item = cart.where((i) => i.articleId == articleId).firstOrNull;
    if (item == null) return;
    item.quantity += delta;
    if (item.quantity <= 0) cart.remove(item);
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    donation = 0;
    notifyListeners();
  }

  void setDonation(double value) {
    donation = max(0, value);
    notifyListeners();
  }

  Future<void> checkout(String payment) async {
    final player = selectedPlayer;
    if (player == null || !hasPendingPayment) return;
    final saleItems = <SaleItem>[];
    for (final item in cart) {
      final article = articles.firstWhere((a) => a.id == item.articleId);
      saleItems.add(SaleItem(
        articleId: article.id,
        name: article.name,
        icon: article.icon,
        type: article.type,
        quantity: item.quantity,
        price: item.price,
        publicPrice: article.price,
        memberPrice: article.memberPrice,
      ));
      _decrementStock(article, item.quantity);
    }
    sales.add(Sale(
      id: makeId('sale'),
      playerId: player.id,
      playerName: player.name,
      playerType: player.type,
      tariff: memberTariff ? 'adherent' : 'public',
      items: saleItems,
      totalArticles: cartArticlesTotal,
      donation: donation,
      payment: payment,
      session: activeSession?.id ?? '',
      createdAt: DateTime.now(),
    ));
    cart.clear();
    donation = 0;
    notifyListeners();
    await persist();
  }

  void _decrementStock(Article article, int quantity) {
    if (article.type == 'standard') {
      article.stock = max(0, article.stock - quantity);
      return;
    }
    if (article.bbAuto > 0) {
      final bb = articles
          .where((a) => a.name.toLowerCase().contains('bille'))
          .firstOrNull;
      if (bb != null)
        bb.stock = max(0, bb.stock - (article.bbAuto * quantity).round());
    }
    if (article.gasAuto > 0) {
      final gas = articles
          .where((a) => a.name.toLowerCase().contains('gaz'))
          .firstOrNull;
      if (gas != null)
        gas.stock = max(0, gas.stock - (article.gasAuto * quantity).round());
    }
  }

  void _restoreStock(Sale sale) {
    for (final item in sale.items) {
      final article = articles
          .where((a) => a.id == item.articleId || a.name == item.name)
          .firstOrNull;
      if (article == null) continue;
      if (article.type == 'standard') {
        article.stock += item.quantity;
      } else {
        if (article.bbAuto > 0) {
          final bb = articles
              .where((a) => a.name.toLowerCase().contains('bille'))
              .firstOrNull;
          if (bb != null) bb.stock += (article.bbAuto * item.quantity).round();
        }
        if (article.gasAuto > 0) {
          final gas = articles
              .where((a) => a.name.toLowerCase().contains('gaz'))
              .firstOrNull;
          if (gas != null)
            gas.stock += (article.gasAuto * item.quantity).round();
        }
      }
    }
  }

  Future<void> cancelSale(Sale sale) async {
    _restoreStock(sale);
    sales.removeWhere((s) => s.id == sale.id);
    notifyListeners();
    await persist();
  }

  Future<void> upsertArticle(Article article, {Article? replacing}) async {
    if (replacing == null) {
      articles.add(article);
    } else {
      final index = articles.indexOf(replacing);
      articles[index] = article;
    }
    notifyListeners();
    await persist();
  }

  Future<void> deleteArticle(Article article) async {
    articles.remove(article);
    cart.removeWhere((item) => item.articleId == article.id);
    notifyListeners();
    await persist();
  }

  Future<void> resetSales() async {
    sales.clear();
    cart.clear();
    donation = 0;
    notifyListeners();
    await persist();
  }

  Future<void> resetAll() async {
    players.clear();
    sales.clear();
    cart.clear();
    donation = 0;
    selectedPlayerId = null;
    notifyListeners();
    await persist();
  }

  Future<void> resetStock() async {
    for (final article in articles) {
      article.stock = 0;
    }
    notifyListeners();
    await persist();
  }

  Future<void> updateCash(String kind, double value, int quantity) async {
    final key = value.toString();
    final map = kind == 'start' ? cashStart : cashEnd;
    map[key] = max(0, quantity);
    notifyListeners();
    await persist();
  }

  double cashTotal(String kind) {
    final map = kind == 'start' ? cashStart : cashEnd;
    return denominations.fold(
        0, (sum, d) => sum + d * (map[d.toString()] ?? 0));
  }

  Map<String, double> paymentTotals() {
    final result = {'ESP': 0.0, 'PayPal': 0.0, 'SumUp': 0.0};
    for (final sale in sales) {
      result[sale.payment] = (result[sale.payment] ?? 0) + sale.total;
    }
    return result;
  }

  Map<String, dynamic> backupPayload() => {
        'version': 2,
        'exportedAt': DateTime.now().toIso8601String(),
        'identity': VisualIdentity.name,
        'state': {
          'activeSession': activeSession?.toJson(),
          'sessions': sessions.map((e) => e.toJson()).toList(),
          'players': allPlayers.map((e) => e.toJson()).toList(),
          'activeSessionPlayers': players.map((e) => e.toJson()).toList(),
          'articles': articles.map((e) => e.toJson()).toList(),
          'sales': sales.map((e) => e.toJson()).toList(),
          'cashStart': cashStart,
          'cashEnd': cashEnd,
        },
      };

  Future<Map<String, dynamic>> fullBackupPayload() async {
    await persist();
    return _database.exportAll();
  }
}

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final controller = AppController();

  @override
  void initState() {
    super.initState();
    controller.load();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final pages = [
          CaissePage(controller: controller),
          PlayersPage(controller: controller),
          CashAnalysisPage(controller: controller),
          KpiPage(controller: controller),
          BilanPage(controller: controller),
          HistoryPage(controller: controller),
          ArticlesPricePage(controller: controller),
          ConfigPage(controller: controller),
        ];
        return LayoutBuilder(
          builder: (context, constraints) {
            final tablet = constraints.maxWidth >= 900;
            final body = IndexedStack(index: controller.tab, children: pages);
            return Scaffold(
              appBar: AppBar(
                backgroundColor: AppColors.surface,
                titleSpacing: 12,
                title: Row(
                  children: [
                    const Icon(Icons.bolt, color: AppColors.accent),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'CAISSE AIRSOFT',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w900, letterSpacing: 1.4),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ActionChip(
                      avatar: const Icon(Icons.flag, size: 16),
                      label: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 170),
                        child: Text(
                            controller.session.isEmpty
                                ? 'PARTIE'
                                : controller.session,
                            overflow: TextOverflow.ellipsis),
                      ),
                      onPressed: () => _editSession(context),
                    ),
                  ],
                ),
                bottom: const PreferredSize(
                  preferredSize: Size.fromHeight(2),
                  child: ColoredBox(
                      color: AppColors.accent,
                      child: SizedBox(height: 2, width: double.infinity)),
                ),
              ),
              body: tablet
                  ? Row(
                      children: [
                        NavigationRail(
                          selectedIndex: controller.tab,
                          onDestinationSelected: controller.setTab,
                          backgroundColor: AppColors.surface,
                          indicatorColor: AppColors.accent,
                          labelType: NavigationRailLabelType.all,
                          destinations: const [
                            NavigationRailDestination(
                                icon: Icon(Icons.point_of_sale),
                                label: Text('Vente')),
                            NavigationRailDestination(
                                icon: Icon(Icons.groups),
                                label: Text('Joueurs')),
                            NavigationRailDestination(
                                icon: Icon(Icons.payments),
                                label: Text('Caisse')),
                            NavigationRailDestination(
                                icon: Icon(Icons.trending_up),
                                label: Text('Stats')),
                            NavigationRailDestination(
                                icon: Icon(Icons.bar_chart),
                                label: Text('Bilan')),
                            NavigationRailDestination(
                                icon: Icon(Icons.history),
                                label: Text('Historique')),
                            NavigationRailDestination(
                                icon: Icon(Icons.inventory_2),
                                label: Text('Articles')),
                            NavigationRailDestination(
                                icon: Icon(Icons.settings),
                                label: Text('Config')),
                          ],
                        ),
                        const VerticalDivider(
                            width: 1, color: AppColors.border),
                        Expanded(child: body),
                      ],
                    )
                  : body,
              bottomNavigationBar: tablet
                  ? null
                  : NavigationBar(
                      selectedIndex: controller.tab,
                      onDestinationSelected: controller.setTab,
                      backgroundColor: AppColors.surface,
                      indicatorColor: AppColors.accent,
                      destinations: const [
                        NavigationDestination(
                            icon: Icon(Icons.point_of_sale), label: 'Vente'),
                        NavigationDestination(
                            icon: Icon(Icons.groups), label: 'Joueurs'),
                        NavigationDestination(
                            icon: Icon(Icons.payments), label: 'Caisse'),
                        NavigationDestination(
                            icon: Icon(Icons.trending_up), label: 'Stats'),
                        NavigationDestination(
                            icon: Icon(Icons.bar_chart), label: 'Bilan'),
                        NavigationDestination(
                            icon: Icon(Icons.history), label: 'Historique'),
                        NavigationDestination(
                            icon: Icon(Icons.inventory_2), label: 'Articles'),
                        NavigationDestination(
                            icon: Icon(Icons.settings), label: 'Config'),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  Future<void> _editSession(BuildContext context) async {
    final field = TextEditingController(text: controller.session);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nom de la partie'),
        content: TextField(
            controller: field,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Ex: Dimanche CQB')),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, field.text),
              child: const Text('Valider')),
        ],
      ),
    );
    if (value != null) await controller.setSession(value);
  }
}

class TacticalCard extends StatelessWidget {
  const TacticalCard(
      {required this.child,
      this.padding = const EdgeInsets.all(12),
      this.borderColor,
      super.key});

  final Widget child;
  final EdgeInsets padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(VisualIdentity.radius),
        border: Border.all(color: borderColor ?? AppColors.border),
      ),
      child: child,
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {this.trailing, super.key});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Text(text.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2)),
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

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
              maxCrossAxisExtent: 150,
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
                      Text(price == 0 ? 'Libre' : money(price),
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w900)),
                      if (controller.memberTariff && article.memberPrice > 0)
                        const Text('ADHÉRENT',
                            style: TextStyle(
                                color: AppColors.accent2,
                                fontSize: 11,
                                fontWeight: FontWeight.w700)),
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
    final hasWarning = controller.cart.any((item) {
      final article =
          controller.articles.firstWhere((a) => a.id == item.articleId);
      return article.tracksStock && article.stock < item.quantity;
    });
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
          if (hasWarning)
            const TacticalCard(
              borderColor: AppColors.warn,
              padding: EdgeInsets.all(8),
              child: Text('Stock insuffisant pour certains articles',
                  style: TextStyle(color: AppColors.warn)),
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
    await controller.checkout(payment);
    if (context.mounted) snack(context, 'Vente validée en $payment');
  }
}

class PlayersPage extends StatelessWidget {
  const PlayersPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Sale>>{};
    for (final sale in controller.sales) {
      grouped.putIfAbsent(sale.playerId, () => []).add(sale);
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value
          .fold<double>(0, (s, v) => s + v.total)
          .compareTo(a.value.fold<double>(0, (s, v) => s + v.total)));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionTitle('Historique par joueur'),
        if (entries.isEmpty)
          const TacticalCard(
              child: Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Aucune vente enregistrée')))),
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TacticalCard(
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                title: Text(entry.value.first.playerName,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                subtitle: Text('${entry.value.length} vente(s)'),
                trailing: Text(
                    money(entry.value.fold<double>(0, (s, v) => s + v.total)),
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w900)),
                children: [
                  for (final sale in entry.value.reversed)
                    ListTile(
                      dense: true,
                      title: Text(
                          sale.items
                              .map((i) => '${i.quantity}x ${i.name}')
                              .join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                          '${timeLabel(sale.createdAt)} - ${dateLabel(sale.createdAt)} - ${sale.payment}${sale.donation > 0 ? ' - don ${money(sale.donation)}' : ''}'),
                      trailing: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(money(sale.total),
                              style: const TextStyle(color: AppColors.accent)),
                          IconButton(
                            tooltip: 'Annuler',
                            onPressed: () async {
                              final ok = await confirm(context,
                                  'Annuler cette vente et restaurer le stock ?');
                              if (ok) await controller.cancelSale(sale);
                            },
                            icon:
                                const Icon(Icons.undo, color: AppColors.danger),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class BilanPage extends StatelessWidget {
  const BilanPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final totals = controller.paymentTotals();
    final donations =
        controller.sales.fold<double>(0, (sum, sale) => sum + sale.donation);
    final total = totals.values.fold<double>(0, (sum, value) => sum + value);
    final sold = <String, ({int quantity, double total})>{};
    for (final sale in controller.sales) {
      for (final item in sale.items) {
        final current = sold[item.name] ?? (quantity: 0, total: 0.0);
        sold[item.name] = (
          quantity: current.quantity + item.quantity,
          total: current.total + item.price * item.quantity
        );
      }
    }
    final soldEntries = sold.entries.toList()
      ..sort((a, b) => b.value.total.compareTo(a.value.total));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionTitle('Bilan de la journée',
            trailing: IconButton.filledTonal(
                onPressed: () => copyBackup(context, controller),
                icon: const Icon(Icons.copy_all))),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.65,
          children: [
            MetricCard(
                label: 'Espèces',
                value: money(totals['ESP'] ?? 0),
                color: AppColors.cash),
            MetricCard(
                label: 'PayPal',
                value: money(totals['PayPal'] ?? 0),
                color: AppColors.paypal),
            MetricCard(
                label: 'SumUp',
                value: money(totals['SumUp'] ?? 0),
                color: AppColors.sumup),
            MetricCard(
                label: 'Total',
                value: money(total),
                color: AppColors.accent,
                caption: '${controller.sales.length} vente(s)'),
            MetricCard(
                label: 'Dons',
                value: money(donations),
                color: AppColors.accent2),
          ],
        ),
        const SectionTitle('Stock vendu'),
        TacticalCard(
          child: Column(
            children: [
              for (final entry in soldEntries)
                ListTile(
                  dense: true,
                  title: Text(entry.key),
                  subtitle: Text('${entry.value.quantity} unité(s)'),
                  trailing: Text(money(entry.value.total),
                      style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w900)),
                ),
              if (soldEntries.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Aucun article vendu')),
            ],
          ),
        ),
      ],
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard(
      {required this.label,
      required this.value,
      required this.color,
      this.caption,
      super.key});

  final String label;
  final String value;
  final String? caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      borderColor: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.muted, fontSize: 12, letterSpacing: 1.6)),
          const SizedBox(height: 4),
          FittedBox(
              child: Text(value,
                  style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 24))),
          if (caption != null)
            Text(caption!,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      ),
    );
  }
}

class CashAnalysisPage extends StatelessWidget {
  const CashAnalysisPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final start = controller.cashTotal('start');
    final end = controller.cashTotal('end');
    final cashSales = controller.paymentTotals()['ESP'] ?? 0;
    final theoretical = start + cashSales;
    final gap = end - theoretical;
    final analysisCard = TacticalCard(
      borderColor: AppColors.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('ANALYSE',
              style: TextStyle(
                  color: AppColors.muted,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          AnalysisRow(label: 'Fond début', value: money(start)),
          AnalysisRow(
              label: '+ Ventes ESP',
              value: money(cashSales),
              color: AppColors.cash),
          AnalysisRow(label: '= Théorique', value: money(theoretical)),
          AnalysisRow(label: 'Fond fin réel', value: money(end)),
          const Divider(color: AppColors.border),
          AnalysisRow(
              label: 'Écart',
              value: money(gap),
              color: gap.abs() < .01 ? AppColors.cash : AppColors.danger,
              large: true),
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 1100;
        final startCard = SizedBox(
            height: wide ? 620 : 540,
            child: CashCountCard(
                title: 'Fond début',
                kind: 'start',
                total: start,
                controller: controller));
        final endCard = SizedBox(
            height: wide ? 620 : 540,
            child: CashCountCard(
                title: 'Fond fin',
                kind: 'end',
                total: end,
                controller: controller));
        return ListView(
          padding: const EdgeInsets.all(12),
          children: [
            const SectionTitle('Caisse espèces'),
            if (wide)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: startCard),
                  const SizedBox(width: 10),
                  Expanded(child: endCard),
                  const SizedBox(width: 10),
                  SizedBox(width: 330, child: analysisCard),
                ],
              )
            else ...[
              analysisCard,
              const SizedBox(height: 10),
              startCard,
              const SizedBox(height: 10),
              endCard,
            ],
          ],
        );
      },
    );
  }
}

class AnalysisRow extends StatelessWidget {
  const AnalysisRow(
      {required this.label,
      required this.value,
      this.color,
      this.large = false,
      super.key});

  final String label;
  final String value;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const Spacer(),
          Text(value,
              style: TextStyle(
                  color: color ?? AppColors.text,
                  fontWeight: FontWeight.w900,
                  fontSize: large ? 22 : 15)),
        ],
      ),
    );
  }
}

class CashCountCard extends StatelessWidget {
  const CashCountCard(
      {required this.title,
      required this.kind,
      required this.total,
      required this.controller,
      super.key});

  final String title;
  final String kind;
  final double total;
  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final map = kind == 'start' ? controller.cashStart : controller.cashEnd;
    return TacticalCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title.toUpperCase(),
                  style: const TextStyle(
                      color: AppColors.muted,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800)),
              const Spacer(),
              Text(money(total),
                  style: const TextStyle(
                      color: AppColors.accent, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 520
                    ? 3
                    : constraints.maxWidth >= 340
                        ? 2
                        : 1;
                return GridView.builder(
                  itemCount: denominations.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisExtent: 78,
                    crossAxisSpacing: 6,
                    mainAxisSpacing: 6,
                  ),
                  itemBuilder: (context, index) {
                    final value = denominations[index];
                    final key = value.toString();
                    final qty = map[key] ?? 0;
                    final label = value >= 1
                        ? '${value.round()} €'
                        : '${(value * 100).round()} cts';
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                          color: AppColors.surface2,
                          border: Border.all(color: AppColors.border),
                          borderRadius: BorderRadius.circular(6)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(label,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800))),
                              Text(qty > 0 ? money(value * qty) : '-',
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800)),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              SizedBox.square(
                                dimension: 30,
                                child: IconButton.filledTonal(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => controller.updateCash(
                                      kind, value, qty - 1),
                                  icon: const Icon(Icons.remove, size: 16),
                                ),
                              ),
                              Expanded(
                                child: Center(
                                  child: FittedBox(
                                    child: Text('$qty',
                                        style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900)),
                                  ),
                                ),
                              ),
                              SizedBox.square(
                                dimension: 30,
                                child: IconButton.filledTonal(
                                  padding: EdgeInsets.zero,
                                  onPressed: () => controller.updateCash(
                                      kind, value, qty + 1),
                                  icon: const Icon(Icons.add, size: 16),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class KpiPage extends StatelessWidget {
  const KpiPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final rows = kpiRows(controller);
    final totalCA = rows.fold<double>(0, (sum, row) => sum + row.ca);
    final ruptures = rows.where((r) => r.article.stock == 0).length;
    final alertes = rows
        .where((r) =>
            r.article.stock > 0 && r.article.stock <= r.article.threshold)
        .length;
    rows.sort((a, b) {
      final aScore = a.article.stock == 0
          ? 3
          : a.article.stock <= a.article.threshold
              ? 2
              : 1;
      final bScore = b.article.stock == 0
          ? 3
          : b.article.stock <= b.article.threshold
              ? 2
              : 1;
      if (aScore != bScore) return bScore.compareTo(aScore);
      return b.rotation.compareTo(a.rotation);
    });
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionTitle('Stats achats & stock'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: MediaQuery.sizeOf(context).width > 700 ? 4 : 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.65,
          children: [
            MetricCard(
                label: 'Ruptures',
                value: '$ruptures',
                color: ruptures > 0 ? AppColors.danger : AppColors.cash),
            MetricCard(
                label: 'En alerte',
                value: '$alertes',
                color: alertes > 0 ? AppColors.warn : AppColors.cash),
            MetricCard(
                label: 'CA total',
                value: money(totalCA),
                color: AppColors.accent),
            MetricCard(
                label: 'À réappro',
                value: '${rows.where((r) => r.suggestion > 0).length}',
                color: AppColors.accent2),
          ],
        ),
        const SizedBox(height: 10),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TacticalCard(
              borderColor: row.article.stock == 0
                  ? AppColors.danger
                  : row.article.stock <= row.article.threshold
                      ? AppColors.warn
                      : AppColors.border,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(row.article.icon,
                          style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(row.article.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900))),
                      Text(
                          row.article.stock == 0
                              ? 'RUPTURE'
                              : row.article.stock <= row.article.threshold
                                  ? 'ALERTE'
                                  : 'OK',
                          style: TextStyle(
                              color: row.article.stock == 0
                                  ? AppColors.danger
                                  : row.article.stock <= row.article.threshold
                                      ? AppColors.warn
                                      : AppColors.cash,
                              fontWeight: FontWeight.w900)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                      value: row.rotation.clamp(0, 1),
                      color: row.rotation > .7
                          ? AppColors.accent
                          : row.rotation > .4
                              ? AppColors.warn
                              : AppColors.danger,
                      backgroundColor: AppColors.border),
                  const SizedBox(height: 8),
                  Text(
                      'Vendu ${row.sold} · CA ${money(row.ca)} · stock ${row.stockRest}/${row.stockInitial} · suggestion achat >= ${row.suggestion}'),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class KpiRow {
  KpiRow(this.article, this.sold, this.ca, this.stockRest, this.stockInitial,
      this.rotation, this.suggestion);
  final Article article;
  final int sold;
  final double ca;
  final int stockRest;
  final int stockInitial;
  final double rotation;
  final int suggestion;
}

List<KpiRow> kpiRows(AppController controller) {
  final sold = <String, ({int quantity, double ca})>{};
  final days = <String>{};
  for (final sale in controller.sales) {
    days.add(dateLabel(sale.createdAt));
    for (final item in sale.items) {
      final current = sold[item.articleId] ?? (quantity: 0, ca: 0.0);
      sold[item.articleId] = (
        quantity: current.quantity + item.quantity,
        ca: current.ca + item.quantity * item.price
      );
    }
  }
  final dayCount = max(1, days.length);
  return controller.articles
      .where((a) => a.type == 'standard' && a.threshold > 0)
      .map((a) {
    final s = sold[a.id] ?? (quantity: 0, ca: 0.0);
    final initial = a.stock + s.quantity;
    final rotation = initial == 0 ? 0.0 : s.quantity / initial;
    final suggestion =
        s.quantity > 0 ? ((s.quantity / dayCount) * 1.3).ceil() : 0;
    return KpiRow(a, s.quantity, s.ca, a.stock, initial, rotation, suggestion);
  }).toList();
}

class ArticlesPricePage extends StatelessWidget {
  const ArticlesPricePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.articles
        .map((article) => article.category)
        .toSet()
        .toList()
      ..sort();
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionTitle('Articles & Prix'),
        ConfigSection(
          title: 'Articles & prix',
          trailing: FilledButton.icon(
            onPressed: () => showArticleDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final category in categories) ...[
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 9, 10, 5),
                  color: AppColors.bg,
                  child: Text(
                    category,
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2),
                  ),
                ),
                for (final article
                    in controller.articles.where((a) => a.category == category))
                  ConfigArticleRow(
                    article: article,
                    onEdit: () => showArticleDialog(context, controller,
                        article: article),
                    onDelete: () async {
                      if (await confirm(context, 'Supprimer ${article.name} ?'))
                        await controller.deleteArticle(article);
                    },
                  ),
              ],
              if (controller.articles.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Aucun article configuré')),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: FilledButton.icon(
            onPressed: () {
              controller.persist();
              snack(context, 'Configuration enregistrée');
            },
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ),
      ],
    );
  }
}

class ConfigPage extends StatelessWidget {
  const ConfigPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionTitle('Configuration'),
        const SectionTitle('Firebase'),
        ConfigActionZone(
          borderColor:
              controller.firebaseAvailable ? AppColors.accent : AppColors.warn,
          title: controller.firebaseAvailable
              ? 'Synchronisation active'
              : 'Synchronisation inactive',
          description: controller.firebaseAvailable
              ? '${controller.firebaseUserLabel} · ${controller.syncStatus}${controller.lastSyncedAt == null ? '' : ' · ${dateLabel(controller.lastSyncedAt!)} ${timeLabel(controller.lastSyncedAt!)}'}'
              : (FirebaseBootstrap.error ??
                  'Connecte-toi avec un compte Firebase pour synchroniser Android et Windows.'),
          action: Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: controller.firebaseAvailable && !controller.syncing
                    ? () async {
                        final result = await controller.syncNow();
                        if (context.mounted) snack(context, result.message);
                      }
                    : null,
                icon: controller.syncing
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.sync),
                label: const Text('Synchroniser'),
              ),
              if (FirebaseBootstrap.initialized &&
                  FirebaseAuth.instance.currentUser == null)
                const Chip(
                  avatar: Icon(Icons.login, size: 16),
                  label: Text('Connexion ci-dessous'),
                  visualDensity: VisualDensity.compact,
                ),
              if (FirebaseBootstrap.initialized &&
                  FirebaseAuth.instance.currentUser != null)
                OutlinedButton.icon(
                  onPressed: () async {
                    await controller.disconnectFirebase();
                    if (context.mounted) snack(context, 'Firebase déconnecté');
                  },
                  icon: const Icon(Icons.logout),
                  label: const Text('Déconnexion'),
                ),
            ],
          ),
        ),
        if (FirebaseBootstrap.initialized &&
            FirebaseAuth.instance.currentUser == null) ...[
          const SizedBox(height: 8),
          FirebaseLoginPanel(controller: controller),
        ],
        const SectionTitle('HelloAsso'),
        ConfigActionZone(
          borderColor: controller.helloAssoSettings.isConfigured
              ? AppColors.accent
              : AppColors.warn,
          title: controller.helloAssoSettings.isConfigured
              ? 'Connexion configurée'
              : 'Connexion non configurée',
          description: controller.helloAssoSettings.isConfigured
              ? '${controller.helloAssoSettings.organizationSlug} · ${controller.helloAssoSettings.environment == 'sandbox' ? 'Sandbox' : 'Production'}'
              : 'Renseigne les clés API pour importer les évènements et les joueurs inscrits.',
          action: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    showHelloAssoSettingsDialog(context, controller),
                icon: const Icon(Icons.settings),
                label: const Text('Configurer'),
              ),
              FilledButton.tonalIcon(
                onPressed: controller.helloAssoSettings.isConfigured
                    ? () async {
                        try {
                          await controller.testHelloAssoConnection();
                          if (context.mounted)
                            snack(context, 'Connexion HelloAsso OK');
                        } catch (error) {
                          if (context.mounted)
                            snack(context,
                                'Connexion HelloAsso impossible : $error');
                        }
                      }
                    : null,
                icon: const Icon(Icons.cloud_sync),
                label: const Text('Tester'),
              ),
            ],
          ),
        ),
        const SectionTitle('Sauvegarde & restauration'),
        ConfigActionZone(
          borderColor: AppColors.accent2,
          title: 'Exporter mes données',
          description:
              'Enregistre un JSON complet dans Downloads avec toutes les sessions, joueurs, ventes, articles et fonds de caisse.',
          action: FilledButton.tonalIcon(
            onPressed: () => copyBackup(context, controller),
            icon: const Icon(Icons.download),
            label: const Text('Exporter'),
          ),
        ),
        const SizedBox(height: 8),
        ConfigActionZone(
          borderColor: AppColors.accent2,
          title: 'Restaurer depuis un fichier',
          description:
              'Importe un JSON de sauvegarde et remplace les données locales.',
          action: OutlinedButton.icon(
            onPressed: () => importBackupFromFile(context, controller),
            icon: const Icon(Icons.upload_file),
            label: const Text('Restaurer'),
          ),
        ),
        const SectionTitle('Remise à zéro'),
        ConfigActionZone(
          borderColor: AppColors.danger,
          title: 'Reset ventes',
          description:
              'Efface les ventes. Joueurs, articles et stock actuel sont conservés.',
          action: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (await confirm(context, 'Effacer toutes les ventes ?'))
                await controller.resetSales();
            },
            child: const Text('Reset ventes'),
          ),
        ),
        const SizedBox(height: 8),
        ConfigActionZone(
          borderColor: AppColors.danger,
          title: 'Reset complet',
          description:
              'Efface ventes et joueurs. Les articles restent configurés.',
          action: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (await confirm(context, 'Effacer ventes et joueurs ?'))
                await controller.resetAll();
            },
            child: const Text('Reset complet'),
          ),
        ),
        const SizedBox(height: 8),
        ConfigActionZone(
          borderColor: AppColors.danger,
          title: 'Supprimer session courante',
          description:
              'Efface la partie active avec ses ventes, joueurs présents et comptages. La session la plus récente restante devient active.',
          action: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              final name =
                  controller.activeSession?.name ?? 'la session courante';
              if (await confirm(context,
                  'Supprimer "$name" ? Cette action est définitive.')) {
                await controller.deleteCurrentSession();
                if (context.mounted) snack(context, 'Session supprimée');
              }
            },
            child: const Text('Supprimer session'),
          ),
        ),
        const SizedBox(height: 8),
        ConfigActionZone(
          borderColor: AppColors.danger,
          title: 'Reset stock',
          description: 'Remet tous les stocks à zéro.',
          action: FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () async {
              if (await confirm(context, 'Remettre tous les stocks à zéro ?'))
                await controller.resetStock();
            },
            child: const Text('Reset stock'),
          ),
        ),
      ],
    );
  }
}

class FirebaseLoginPanel extends StatefulWidget {
  const FirebaseLoginPanel({required this.controller, super.key});

  final AppController controller;

  @override
  State<FirebaseLoginPanel> createState() => _FirebaseLoginPanelState();
}

class _FirebaseLoginPanelState extends State<FirebaseLoginPanel> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool obscurePassword = true;
  String? error;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (loading) return;
    setState(() {
      loading = true;
      error = null;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
      final result = await widget.controller.syncNow();
      if (mounted) snack(context, result.message);
    } on FirebaseAuthException catch (exception) {
      if (mounted) setState(() => error = exception.message ?? exception.code);
    } catch (exception) {
      if (mounted) setState(() => error = '$exception');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TacticalCard(
      borderColor: error == null ? AppColors.border : AppColors.danger,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 720;
          final emailField = TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
                labelText: 'Email Firebase', prefixIcon: Icon(Icons.mail)),
          );
          final passwordField = TextField(
            controller: passwordController,
            obscureText: obscurePassword,
            onSubmitted: (_) => _signIn(),
            decoration: InputDecoration(
              labelText: 'Mot de passe',
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                tooltip: obscurePassword ? 'Afficher' : 'Masquer',
                onPressed: () =>
                    setState(() => obscurePassword = !obscurePassword),
                icon: Icon(
                    obscurePassword ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  children: [
                    Expanded(child: emailField),
                    const SizedBox(width: 8),
                    Expanded(child: passwordField),
                  ],
                )
              else ...[
                emailField,
                const SizedBox(height: 8),
                passwordField,
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.danger)),
              ],
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: loading ? null : _signIn,
                  icon: loading
                      ? const SizedBox.square(
                          dimension: 18,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.login),
                  label: const Text('Connecter et synchroniser'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class HistoryPage extends StatelessWidget {
  const HistoryPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final activeId = controller.activeSession?.id;
    final sessions = [...controller.sessions]
      ..sort((a, b) => b.eventDate.compareTo(a.eventDate));
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionTitle(
          'Historique des parties',
          trailing: FilledButton.icon(
            onPressed: () => showCreateSessionDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Nouvelle session'),
          ),
        ),
        if (sessions.isEmpty)
          const TacticalCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Aucune session enregistrée'),
              ),
            ),
          ),
        for (final session in sessions)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: TacticalCard(
              borderColor:
                  session.id == activeId ? AppColors.accent : AppColors.border,
              child: Builder(
                builder: (context) {
                  final sessionSales = controller.salesForSession(session.id);
                  final total = sessionSales.fold<double>(
                      0, (sum, sale) => sum + sale.total);
                  return ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(top: 4),
                    leading: Icon(
                      session.id == activeId
                          ? Icons.radio_button_checked
                          : Icons.history,
                      color: session.id == activeId
                          ? AppColors.accent
                          : AppColors.muted,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                            child: Text(session.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900))),
                        if (session.id == activeId)
                          const Chip(
                              label: Text('Active'),
                              visualDensity: VisualDensity.compact),
                      ],
                    ),
                    subtitle: Text(
                        '${dateLabel(session.eventDate)} · ${sessionSales.length} vente(s) · ${money(total)}'),
                    trailing: session.id == activeId
                        ? null
                        : OutlinedButton.icon(
                            onPressed: () async {
                              await controller.switchSession(session.id);
                              if (context.mounted)
                                snack(context, 'Session chargée');
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Ouvrir'),
                          ),
                    children: [
                      if (session.helloassoEventUrl.isNotEmpty)
                        ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          leading:
                              const Icon(Icons.link, color: AppColors.accent2),
                          title: Text(session.helloassoEventName.isEmpty
                              ? 'Évènement HelloAsso'
                              : session.helloassoEventName),
                          subtitle: Text(session.helloassoEventUrl,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                      if (sessionSales.isEmpty)
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 0, 8, 10),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Aucune vente sur cette session',
                                style: TextStyle(color: AppColors.muted)),
                          ),
                        )
                      else
                        for (final sale in sessionSales.reversed)
                          ListTile(
                            dense: true,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 8),
                            title: Text(
                              sale.items
                                  .map((item) =>
                                      '${item.quantity}x ${item.name}')
                                  .join(' · '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                                '${sale.playerName} · ${timeLabel(sale.createdAt)} · ${sale.payment}${sale.donation > 0 ? ' · don ${money(sale.donation)}' : ''}'),
                            trailing: Text(money(sale.total),
                                style: const TextStyle(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w900)),
                          ),
                    ],
                  );
                },
              ),
            ),
          ),
      ],
    );
  }
}

class ConfigSection extends StatelessWidget {
  const ConfigSection(
      {required this.title, required this.child, this.trailing, super.key});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            color: AppColors.surface2,
            child: Row(
              children: [
                Expanded(
                    child: Text(title.toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 12))),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class ConfigArticleRow extends StatelessWidget {
  const ConfigArticleRow(
      {required this.article,
      required this.onEdit,
      required this.onDelete,
      super.key});

  final Article article;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final stockColor = article.isLocation
        ? AppColors.muted
        : article.stock == 0 && article.threshold > 0
            ? AppColors.danger
            : article.stock <= article.threshold && article.threshold > 0
                ? AppColors.warn
                : AppColors.text;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        final nameWidth = wide
            ? max(260.0, constraints.maxWidth * 0.34)
            : constraints.maxWidth - 20;
        final categoryWidth = wide
            ? max(190.0, constraints.maxWidth * 0.24)
            : constraints.maxWidth - 20;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              ConfigCell(
                  width: 48,
                  onTap: onEdit,
                  child: Center(
                      child: Text(article.icon,
                          style: const TextStyle(fontSize: 18)))),
              ConfigCell(
                width: nameWidth,
                onTap: onEdit,
                child: Text(article.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
              ConfigCell(
                width: categoryWidth,
                onTap: onEdit,
                child: Text(article.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              ),
              ConfigCell(
                width: 76,
                onTap: onEdit,
                child: Text(article.isLocation ? 'LOC' : 'STD',
                    style: const TextStyle(
                        color: AppColors.accent2,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
              ConfigCell(
                width: 82,
                onTap: onEdit,
                alignment: Alignment.centerRight,
                child: Text(article.price > 0 ? money(article.price) : 'Libre',
                    style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
              ConfigCell(
                width: 82,
                onTap: onEdit,
                alignment: Alignment.centerRight,
                child: Text(
                    article.memberPrice > 0 ? money(article.memberPrice) : '-',
                    style: const TextStyle(
                        color: AppColors.accent2,
                        fontWeight: FontWeight.w900,
                        fontSize: 12)),
              ),
              ConfigCell(
                width: 64,
                onTap: onEdit,
                alignment: Alignment.center,
                child: Text(article.isLocation ? '∞' : '${article.stock}',
                    style: TextStyle(
                        color: stockColor, fontWeight: FontWeight.w900)),
              ),
              SizedBox.square(
                dimension: 34,
                child: OutlinedButton(
                  onPressed: onDelete,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  child: const Icon(Icons.close, size: 18),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class ConfigCell extends StatelessWidget {
  const ConfigCell(
      {required this.width,
      required this.child,
      this.onTap,
      this.alignment = Alignment.centerLeft,
      super.key});

  final double width;
  final Widget child;
  final VoidCallback? onTap;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 34,
      child: Material(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          borderRadius: BorderRadius.circular(4),
          onTap: onTap,
          child: Container(
            alignment: alignment,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(4)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ConfigActionZone extends StatelessWidget {
  const ConfigActionZone(
      {required this.borderColor,
      required this.title,
      required this.description,
      required this.action,
      super.key});

  final Color borderColor;
  final String title;
  final String description;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 620;
        final descriptionText = Text(
          description,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
              color: AppColors.muted, fontSize: 13, height: 1.35),
        );
        final textColumn = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
            const SizedBox(height: 3),
            descriptionText,
          ],
        );
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(10),
          ),
          child: compact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    textColumn,
                    const SizedBox(height: 10),
                    Align(alignment: Alignment.centerLeft, child: action),
                  ],
                )
              : Row(
                  children: [
                    Expanded(child: textColumn),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 0,
                      child: Align(
                          alignment: Alignment.centerRight, child: action),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

Future<void> showPlayerDialog(BuildContext context, AppController controller,
    {Player? player}) async {
  final splitName = player == null
      ? (firstName: '', lastName: '')
      : splitPlayerName(player.firstName.isEmpty && player.lastName.isEmpty
          ? player.name
          : '${player.firstName} ${player.lastName}');
  final firstName = TextEditingController(
      text: player?.firstName.isNotEmpty == true
          ? player!.firstName
          : splitName.firstName);
  final lastName = TextEditingController(
      text: player?.lastName.isNotEmpty == true
          ? player!.lastName
          : splitName.lastName);
  final email = TextEditingController(text: player?.email ?? '');
  var type = player?.type ?? 'public';
  String? selectedExistingId;
  final existingPlayers = player == null
      ? controller.allPlayers
          .where((candidate) =>
              !controller.players.any((current) => current.id == candidate.id))
          .toList()
      : <Player>[];
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(player == null ? 'Nouveau joueur' : 'Modifier joueur'),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(context).width - 48, 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (existingPlayers.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    initialValue: selectedExistingId,
                    decoration:
                        const InputDecoration(labelText: 'Joueur existant'),
                    hint: const Text('Sélectionner un ancien joueur'),
                    items: [
                      for (final existing in existingPlayers)
                        DropdownMenuItem(
                          value: existing.id,
                          child: Text(existing.name,
                              overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (value) {
                      final existing = existingPlayers
                          .where((candidate) => candidate.id == value)
                          .firstOrNull;
                      if (existing == null) return;
                      setState(() {
                        selectedExistingId = existing.id;
                        final parts = splitPlayerName(
                            existing.firstName.isEmpty &&
                                    existing.lastName.isEmpty
                                ? existing.name
                                : '${existing.firstName} ${existing.lastName}');
                        firstName.text = existing.firstName.isNotEmpty
                            ? existing.firstName
                            : parts.firstName;
                        lastName.text = existing.lastName.isNotEmpty
                            ? existing.lastName
                            : parts.lastName;
                        email.text = existing.email;
                        type = existing.type;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                        child: TextField(
                            controller: firstName,
                            autofocus: true,
                            decoration:
                                const InputDecoration(labelText: 'Prénom'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: lastName,
                            decoration:
                                const InputDecoration(labelText: 'Nom'))),
                  ],
                ),
                const SizedBox(height: 10),
                TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email')),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'public',
                        label: Text('Public'),
                        icon: Icon(Icons.person)),
                    ButtonSegment(
                        value: 'membre',
                        label: Text('Adhérent'),
                        icon: Icon(Icons.verified_user)),
                  ],
                  selected: {type},
                  onSelectionChanged: (value) =>
                      setState(() => type = value.first),
                ),
              ],
            ),
          ),
        ),
        actions: [
          if (player != null)
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Supprimer')),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer')),
        ],
      ),
    ),
  );
  if (ok == true &&
      (firstName.text.trim().isNotEmpty ||
          lastName.text.trim().isNotEmpty ||
          email.text.trim().isNotEmpty)) {
    if (player == null) {
      await controller.addPlayer(
          firstName: firstName.text,
          lastName: lastName.text,
          email: email.text,
          type: type);
    } else {
      await controller.updatePlayer(player,
          firstName: firstName.text,
          lastName: lastName.text,
          email: email.text,
          type: type);
    }
  } else if (ok == false &&
      player != null &&
      context.mounted &&
      await confirm(context, 'Supprimer ${player.name} ?')) {
    await controller.removePlayer(player);
  }
}

Future<void> showCreateSessionDialog(
    BuildContext context, AppController controller) async {
  final field =
      TextEditingController(text: 'Partie ${dateLabel(DateTime.now())}');
  var loadingEvents = controller.helloAssoSettings.isConfigured;
  var helloAssoError = '';
  var selectedEventEnabled = false;
  HelloAssoEvent? selectedEvent;
  var events = <HelloAssoEvent>[];
  final value = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        if (loadingEvents && events.isEmpty && helloAssoError.isEmpty) {
          controller.fetchHelloAssoEvents().then((loaded) {
            if (!context.mounted) return;
            setState(() {
              events = loaded;
              loadingEvents = false;
            });
          }).catchError((error) {
            if (!context.mounted) return;
            setState(() {
              helloAssoError = '$error';
              loadingEvents = false;
            });
          });
        }
        return AlertDialog(
          title: const Text('Nouvelle session'),
          content: SizedBox(
            width: min(MediaQuery.sizeOf(context).width - 48, 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: field,
                    autofocus: true,
                    decoration:
                        const InputDecoration(labelText: 'Nom de la partie')),
                if (controller.helloAssoSettings.isConfigured) ...[
                  const SizedBox(height: 12),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: selectedEventEnabled,
                    onChanged: events.isEmpty
                        ? null
                        : (value) =>
                            setState(() => selectedEventEnabled = value),
                    title: const Text('Lier un évènement HelloAsso'),
                  ),
                  if (loadingEvents) const LinearProgressIndicator(),
                  if (helloAssoError.isNotEmpty)
                    Text('HelloAsso : $helloAssoError',
                        style: const TextStyle(color: AppColors.warn)),
                  if (selectedEventEnabled)
                    DropdownButtonFormField<HelloAssoEvent>(
                      initialValue: selectedEvent,
                      decoration: const InputDecoration(labelText: 'Évènement'),
                      items: [
                        for (final event in events)
                          DropdownMenuItem(
                              value: event,
                              child: Text(event.name,
                                  overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (event) => setState(() {
                        selectedEvent = event;
                        if (event != null) field.text = event.name;
                      }),
                    ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(context, field.text),
                child: const Text('Créer')),
          ],
        );
      },
    ),
  );
  if (value != null) {
    try {
      await controller.createSession(value,
          helloassoEvent: selectedEventEnabled ? selectedEvent : null);
      if (context.mounted)
        snack(
            context,
            selectedEvent == null
                ? 'Nouvelle session active'
                : 'Session créée avec joueurs HelloAsso');
    } catch (error) {
      if (context.mounted) snack(context, 'Création impossible : $error');
    }
  }
}

Future<void> showHelloAssoSettingsDialog(
    BuildContext context, AppController controller) async {
  final current = controller.helloAssoSettings;
  final organizationSlug =
      TextEditingController(text: current.organizationSlug);
  final clientId = TextEditingController(text: current.clientId);
  final clientSecret = TextEditingController(text: current.clientSecret);
  var environment = current.environment;
  var showClientSecret = false;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Configuration HelloAsso'),
        content: SizedBox(
          width: min(MediaQuery.sizeOf(context).width - 48, 560),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: organizationSlug,
                    decoration:
                        const InputDecoration(labelText: 'Organization slug')),
                const SizedBox(height: 10),
                TextField(
                    controller: clientId,
                    decoration: const InputDecoration(labelText: 'Client ID')),
                const SizedBox(height: 10),
                TextField(
                  controller: clientSecret,
                  obscureText: !showClientSecret,
                  decoration: InputDecoration(
                    labelText: 'Client secret',
                    suffixIcon: IconButton(
                      tooltip: showClientSecret
                          ? 'Masquer le secret'
                          : 'Afficher le secret',
                      onPressed: () =>
                          setState(() => showClientSecret = !showClientSecret),
                      icon: Icon(showClientSecret
                          ? Icons.visibility_off
                          : Icons.visibility),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                        value: 'production', label: Text('Production')),
                    ButtonSegment(value: 'sandbox', label: Text('Sandbox')),
                  ],
                  selected: {environment},
                  onSelectionChanged: (value) =>
                      setState(() => environment = value.first),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Enregistrer')),
        ],
      ),
    ),
  );
  if (ok == true) {
    await controller.saveHelloAssoSettings(HelloAssoSettings(
      organizationSlug: organizationSlug.text.trim(),
      clientId: clientId.text.trim(),
      clientSecret: clientSecret.text.trim(),
      environment: environment,
    ));
    if (context.mounted) snack(context, 'Configuration HelloAsso enregistrée');
  }
}

Future<void> showSessionPicker(
    BuildContext context, AppController controller) async {
  final selected = await showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Changer de session'),
      content: SizedBox(
        width: 420,
        child: controller.sessions.isEmpty
            ? const Text('Aucune session disponible')
            : ListView.separated(
                shrinkWrap: true,
                itemCount: controller.sessions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final session = controller.sessions[index];
                  final active = controller.activeSession?.id == session.id;
                  return ListTile(
                    leading: Icon(
                        active
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: active ? AppColors.accent : AppColors.muted),
                    title: Text(session.name),
                    subtitle: Text(dateLabel(session.eventDate)),
                    onTap: () => Navigator.pop(context, session.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler')),
      ],
    ),
  );
  if (selected != null && selected != controller.activeSession?.id) {
    await controller.switchSession(selected);
    if (context.mounted) snack(context, 'Session chargée');
  }
}

Future<void> showArticleDialog(BuildContext context, AppController controller,
    {Article? article}) async {
  final icon = TextEditingController(text: article?.icon ?? '📦');
  final name = TextEditingController(text: article?.name ?? '');
  final price = TextEditingController(text: article?.price.toString() ?? '');
  final memberPrice =
      TextEditingController(text: article?.memberPrice.toString() ?? '');
  final stock = TextEditingController(text: article?.stock.toString() ?? '0');
  final threshold =
      TextEditingController(text: article?.threshold.toString() ?? '5');
  final bbAuto = TextEditingController(text: article?.bbAuto.toString() ?? '0');
  final gasAuto =
      TextEditingController(text: article?.gasAuto.toString() ?? '0');
  final categoryOptions = <String>[
    'BOISSONS',
    'SNACKING',
    'MUNITIONS',
    'REPAS',
    'GOODIES',
    'LOCATION',
    'DIVERS',
    ...controller.articles.map((a) => a.category),
  ]
      .map((category) => category.trim().toUpperCase())
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) {
      if (a == 'LOCATION') return 1;
      if (b == 'LOCATION') return -1;
      if (a == 'DIVERS') return 1;
      if (b == 'DIVERS') return -1;
      return a.compareTo(b);
    });
  var category =
      (article?.category ?? categoryOptions.first).trim().toUpperCase();
  if (!categoryOptions.contains(category)) categoryOptions.add(category);
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final type = category == 'LOCATION' ? 'location' : 'standard';
        return AlertDialog(
          title: Text(article == null ? 'Nouvel article' : 'Modifier article'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(children: [
                  SizedBox(
                      width: 76,
                      child: TextField(
                          controller: icon,
                          decoration:
                              const InputDecoration(labelText: 'Icône'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: name,
                          decoration: const InputDecoration(labelText: 'Nom'))),
                ]),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: [
                    for (final option in categoryOptions)
                      DropdownMenuItem(
                        value: option,
                        child: Text(option),
                      ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => category = value);
                  },
                ),
                const SizedBox(height: 10),
                TacticalCard(
                  borderColor:
                      type == 'location' ? AppColors.sumup : AppColors.border,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                  child: Row(
                    children: [
                      Icon(
                          type == 'location'
                              ? Icons.assignment_return
                              : Icons.inventory_2,
                          color: type == 'location'
                              ? AppColors.sumup
                              : AppColors.muted),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          type == 'location'
                              ? 'Type automatique : location'
                              : 'Type automatique : standard',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                      child: TextField(
                          controller: price,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Prix public'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: TextField(
                          controller: memberPrice,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                              labelText: 'Prix adhérent'))),
                ]),
                const SizedBox(height: 10),
                if (type == 'standard')
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: stock,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Stock'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: threshold,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Seuil'))),
                  ])
                else
                  Row(children: [
                    Expanded(
                        child: TextField(
                            controller: bbAuto,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Billes auto'))),
                    const SizedBox(width: 8),
                    Expanded(
                        child: TextField(
                            controller: gasAuto,
                            keyboardType: TextInputType.number,
                            decoration:
                                const InputDecoration(labelText: 'Gaz auto'))),
                  ]),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Enregistrer')),
          ],
        );
      },
    ),
  );
  if (ok == true && name.text.trim().isNotEmpty) {
    final type = category == 'LOCATION' ? 'location' : 'standard';
    await controller.upsertArticle(
      Article(
        id: article?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        category: category,
        type: type,
        icon: icon.text.trim().isEmpty ? '📦' : icon.text.trim(),
        name: name.text.trim(),
        price: double.tryParse(price.text.replaceAll(',', '.')) ?? 0,
        memberPrice:
            double.tryParse(memberPrice.text.replaceAll(',', '.')) ?? 0,
        stock: type == 'standard' ? int.tryParse(stock.text) ?? 0 : 0,
        threshold: type == 'standard' ? int.tryParse(threshold.text) ?? 0 : 0,
        bbAuto: type == 'location'
            ? double.tryParse(bbAuto.text.replaceAll(',', '.')) ?? 0
            : 0,
        gasAuto: type == 'location'
            ? double.tryParse(gasAuto.text.replaceAll(',', '.')) ?? 0
            : 0,
      ),
      replacing: article,
    );
  }
}

Future<void> showCashDialog(
    BuildContext context, AppController controller) async {
  final given = TextEditingController();
  double paid = 0;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        paid = double.tryParse(given.text.replaceAll(',', '.')) ?? 0;
        final change = max(0.0, paid - controller.cartTotal);
        return AlertDialog(
          title: const Text('Rendu monnaie'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MetricCard(
                  label: 'À payer',
                  value: money(controller.cartTotal),
                  color: AppColors.accent),
              const SizedBox(height: 10),
              TextField(
                controller: given,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Montant donné'),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              if (paid > 0 && paid < controller.cartTotal)
                Text('Manque ${money(controller.cartTotal - paid)}',
                    style: const TextStyle(color: AppColors.danger)),
              if (paid >= controller.cartTotal)
                Text(
                    change < .01
                        ? 'Compte exact'
                        : 'Rendu: ${money(change)}\n${changeBreakdown(change).join(' · ')}',
                    style: const TextStyle(
                        color: AppColors.accent, fontWeight: FontWeight.w900)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
              onPressed: paid >= controller.cartTotal && controller.canCheckout
                  ? () async {
                      await controller.checkout('ESP');
                      if (context.mounted) Navigator.pop(context);
                    }
                  : null,
              child: const Text('Valider ESP'),
            ),
          ],
        );
      },
    ),
  );
}

List<String> changeBreakdown(double change) {
  var cents = (change * 100).round();
  final chips = <String>[];
  for (final denom in denominations) {
    final value = (denom * 100).round();
    final count = cents ~/ value;
    if (count > 0) {
      chips.add(
          '$count x ${denom >= 1 ? '${denom.round()}€' : '${(denom * 100).round()}c'}');
      cents -= count * value;
    }
  }
  return chips;
}

Future<void> copyBackup(BuildContext context, AppController controller) async {
  try {
    final payload = await controller.fullBackupPayload();
    final content = const JsonEncoder.withIndent('  ').convert(payload);
    final timestamp =
        DateTime.now().toIso8601String().replaceAll(RegExp(r'[:.]'), '-');
    final fileName = 'frags-addicts-export-$timestamp.json';
    final savedFile = await _fileImportChannel.invokeMapMethod<String, String>(
      'saveJsonBackup',
      {'name': fileName, 'content': content},
    );
    final name = savedFile?['name'] ?? fileName;
    if (context.mounted)
      snack(context, 'Export enregistré dans Downloads : $name');
  } on PlatformException catch (error) {
    if (context.mounted)
      snack(context, 'Export impossible : ${error.message ?? error.code}');
  } catch (error) {
    if (context.mounted) snack(context, 'Export impossible : $error');
  }
}

const _fileImportChannel = MethodChannel('frags_addicts/file_import');

Future<void> importBackupFromFile(
    BuildContext context, AppController controller) async {
  try {
    final file = await _fileImportChannel
        .invokeMapMethod<String, String>('pickJsonBackup');
    if (file == null) return;

    final content = file['content'];
    final name = file['name'] ?? 'sauvegarde.json';
    if (content == null || content.trim().isEmpty) {
      throw const FormatException('Fichier vide ou illisible');
    }

    final payload = jsonDecode(content);
    if (payload is! Map<String, dynamic>) {
      throw const FormatException('Format JSON invalide');
    }
    if (!context.mounted) return;
    final ok = await confirm(context,
        'Restaurer $name ? Toutes les données locales seront remplacées.');
    if (!ok) return;
    await controller.importBackup(payload);
    if (context.mounted) snack(context, 'Sauvegarde restaurée');
  } on PlatformException catch (error) {
    if (context.mounted)
      snack(context, 'Import impossible : ${error.message ?? error.code}');
  } catch (error) {
    if (context.mounted) snack(context, 'Import impossible : $error');
  }
}

Future<bool> confirm(BuildContext context, String message) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirmation'),
          content: Text(message),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirmer')),
          ],
        ),
      ) ??
      false;
}

void snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating));
}

extension FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) return iterator.current;
    return null;
  }
}
