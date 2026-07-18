part of '../../main.dart';

class HelloAssoClient {
  HelloAssoClient(this.settings);

  static const _requestTimeout = Duration(seconds: 20);

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
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'grant_type': 'client_credentials',
        'client_id': settings.clientId,
        'client_secret': settings.clientSecret,
      },
    ).timeout(_requestTimeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'Connexion HelloAsso refusée (${response.statusCode}) en ${settings.isSandbox ? 'sandbox' : 'production'}${_errorDetails(response.body)}');
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
      }).timeout(_requestTimeout);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
            'Erreur HelloAsso (${response.statusCode})${_errorDetails(response.body)}');
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
    final itemRegistrants = await _fetchPaidItemUsers(event);
    if (itemRegistrants.isNotEmpty) return itemRegistrants;

    return _fetchPaidOrderPayers(event);
  }

  Future<List<HelloAssoRegistrant>> _fetchPaidItemUsers(
      HelloAssoEvent event) async {
    final uri = Uri.parse(
            '${settings.apiBaseUrl}/organizations/${Uri.encodeComponent(settings.organizationSlug)}/forms/${event.formType}/${Uri.encodeComponent(event.formSlug)}/items')
        .replace(queryParameters: {
      'withDetails': 'true',
      'pageSize': '100',
    });
    final rows = await _getPaged(uri);
    final byKey = <String, HelloAssoRegistrant>{};
    for (final entry in rows) {
      final map = Map<String, dynamic>.from(entry as Map);
      final state = '${map['state'] ?? ''}'.toLowerCase();
      if (state.contains('cancel')) continue;
      final user = Map<String, dynamic>.from((map['user'] as Map?) ?? const {});
      final firstName =
          '${user['firstName'] ?? user['firstname'] ?? ''}'.trim();
      final lastName = '${user['lastName'] ?? user['lastname'] ?? ''}'.trim();
      if (firstName.isEmpty && lastName.isEmpty) continue;
      final email = _emailFromCustomFields(map);
      final mealLabel = _mealLabelFromItem(map);
      final itemId = '${map['id'] ?? ''}';
      final key = email.isNotEmpty
          ? email
          : _playerNameFromParts(firstName, lastName,
              itemId.isEmpty ? makeId('helloasso') : itemId);
      final registrant = HelloAssoRegistrant(
        firstName: firstName,
        lastName: lastName,
        email: email,
        helloassoUserId: itemId,
        hasMeal: mealLabel.isNotEmpty,
        mealLabel: mealLabel,
      );
      final existing = byKey[key];
      if (existing == null || (!existing.hasMeal && registrant.hasMeal)) {
        byKey[key] = registrant;
      }
    }
    return _sortedRegistrants(byKey.values);
  }

  Future<List<HelloAssoRegistrant>> _fetchPaidOrderPayers(
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
          state.contains('refused')) {
        continue;
      }
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
    return _sortedRegistrants(byEmail.values);
  }

  List<HelloAssoRegistrant> _sortedRegistrants(
          Iterable<HelloAssoRegistrant> registrants) =>
      registrants.toList()
        ..sort((a, b) => _playerNameFromParts(a.firstName, a.lastName, a.email)
            .compareTo(_playerNameFromParts(b.firstName, b.lastName, b.email)));

  String _emailFromCustomFields(Map<String, dynamic> item) {
    final customFields = (item['customFields'] as List?) ?? const [];
    for (final field in customFields) {
      if (field is! Map) continue;
      final name = '${field['name'] ?? ''}'.toLowerCase();
      final answer = '${field['answer'] ?? ''}'.trim().toLowerCase();
      if ((name.contains('email') ||
              name.contains('mail') ||
              name.contains('courriel')) &&
          answer.contains('@')) {
        return answer;
      }
    }
    return '';
  }

  String _mealLabelFromItem(Map<String, dynamic> item) {
    final candidates = [
      '${item['name'] ?? ''}',
      '${item['tierDescription'] ?? ''}',
      '${item['comment'] ?? ''}',
    ];
    final options = (item['options'] as List?) ?? const [];
    for (final option in options) {
      if (option is! Map) continue;
      candidates.add('${option['name'] ?? ''}');
      candidates.add('${option['tierName'] ?? ''}');
    }
    return candidates.firstWhere((value) => _containsMeal(value),
        orElse: () => '');
  }

  bool _containsMeal(String value) {
    final normalized = value
        .toLowerCase()
        .replaceAll(RegExp('[éèêë]'), 'e')
        .replaceAll(RegExp('[àâä]'), 'a')
        .replaceAll(RegExp('[îï]'), 'i')
        .replaceAll(RegExp('[ôö]'), 'o')
        .replaceAll(RegExp('[ùûü]'), 'u');
    return normalized.contains('repas') || normalized.contains('meal');
  }

  String _defaultEventUrl(String formSlug) {
    return settings.isSandbox
        ? 'https://www.helloasso-sandbox.com/associations/${settings.organizationSlug}/evenements/$formSlug'
        : 'https://www.helloasso.com/associations/${settings.organizationSlug}/evenements/$formSlug';
  }

  String _errorDetails(String body) {
    if (body.trim().isEmpty) return '';
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final message =
            '${data['message'] ?? data['error_description'] ?? data['error'] ?? ''}'
                .trim();
        if (message.isNotEmpty) return ' : $message';
      }
    } catch (_) {
      final compact = body.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (compact.isNotEmpty) {
        return ' : ${compact.length > 160 ? '${compact.substring(0, 160)}...' : compact}';
      }
    }
    return '';
  }
}
