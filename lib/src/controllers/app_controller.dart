part of '../../main.dart';

class AppController extends ChangeNotifier {
  final LocalDatabase _database = LocalDatabase();
  final FirebaseSyncService _syncService = FirebaseSyncService();
  final SecureSettingsService _secureSettings = SecureSettingsService();

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
  List<String> articleCategories = defaultArticleCategories();
  List<Sale> sales = [];
  Map<String, List<Sale>> salesBySession = {};
  List<MealOrder> meals = [];
  List<StockMovement> stockMovements = [];
  List<CartItem> cart = [];
  List<StockMovement> pendingStockMovements = [];
  Map<String, int> cashStart = {};
  Map<String, int> cashEnd = {};

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
      cart.fold(0, (total, item) => total + item.price * item.quantity);
  double get cartTotal => cartArticlesTotal + donation;
  int get cartCount => cart.fold(0, (total, item) => total + item.quantity);
  bool get hasPendingPayment => cart.isNotEmpty || donation > 0;
  bool get canCheckout =>
      selectedPlayer != null && hasPendingPayment && cartStockShortages.isEmpty;
  List<StockShortage> get cartStockShortages =>
      _stockShortages(_cartStockRequirements());
  List<String> get categories => ['TOUS', ...articleCategories];
  List<Article> get visibleArticles => categoryFilter == 'TOUS'
      ? articles
      : articles.where((a) => a.category == categoryFilter).toList();
  List<Article> get mealArticles =>
      articles.where((article) => article.category == 'REPAS').toList();
  List<Article> get drinkArticles =>
      articles.where((article) => article.category == 'BOISSONS').toList();
  List<Article> get snackArticles =>
      articles.where((article) => article.category == 'SNACKING').toList();

  Future<void> load() async {
    try {
      await _database.setUserScope(FirebaseAuth.instance.currentUser?.uid);
      await _loadLocalState();
    } catch (_) {
      articles = defaultArticles();
      articleCategories = defaultArticleCategories();
      syncStatus = 'Chargement local en mode dégradé';
    }
    loading = false;
    notifyListeners();
  }

  Future<void> _loadLocalState() async {
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
    final storedHelloAssoSettings = await _database.loadHelloAssoSettings();
    helloAssoSettings =
        await _secureSettings.loadHelloAssoSettings(storedHelloAssoSettings);
    if (storedHelloAssoSettings.clientSecret.trim().isNotEmpty) {
      await _database.saveHelloAssoSettings(
          storedHelloAssoSettings.withoutSecret(),
          markUpdated: false);
    }
    allPlayers = await _database.loadAllPlayers();
    players = await _database.loadPlayers(activeSession!.id);
    final storedArticles = await _database.loadArticles();
    articles = storedArticles.isEmpty ? defaultArticles() : storedArticles;
    final storedCategories = await _database.loadArticleCategories();
    _setArticleCategories(storedCategories.isEmpty
        ? defaultArticleCategories()
        : storedCategories);
    sales = await _database.loadSales(activeSession!.id);
    meals = await _database.loadMeals(activeSession!.id);
    stockMovements = await _database.loadStockMovements(activeSession!.id);
    await refreshSessionSales();
    cashStart = await _database.loadCash(activeSession!.id, 'start');
    cashEnd = await _database.loadCash(activeSession!.id, 'end');
    cart.clear();
    donation = 0;
    selectedPlayerId = null;
    forceMemberTariff = false;
    categoryFilter = 'TOUS';
    if (storedArticles.isEmpty) {
      await persist(markUpdated: false);
    }
  }

  Future<void> persist({bool markUpdated = true}) async {
    await _database.saveAll(this, markUpdated: markUpdated);
    _cacheActiveSessionSales();
    if (markUpdated && _syncService.isAvailable) {
      syncStatus = 'Modifications locales non synchronisees';
    }
  }

  Future<FirebaseSyncResult> syncNow({
    bool reloadAfterPull = true,
    bool allowRemotePull = false,
  }) async {
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
    final result =
        await _syncService.synchronize(_database, allowPull: allowRemotePull);
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
      final storedCategories = await _database.loadArticleCategories();
      _setArticleCategories(storedCategories.isEmpty
          ? defaultArticleCategories()
          : storedCategories);
      final storedHelloAssoSettings = await _database.loadHelloAssoSettings();
      helloAssoSettings =
          await _secureSettings.loadHelloAssoSettings(storedHelloAssoSettings);
      await _loadActiveSessionState();
      await refreshSessionSales();
    }
    syncing = false;
    notifyListeners();
    return result;
  }

  Future<FirebaseSyncResult> connectFirebaseUser() async {
    if (!FirebaseBootstrap.initialized) {
      final result = FirebaseSyncResult(FirebaseSyncAction.disabled,
          FirebaseBootstrap.error ?? 'Firebase non configuré');
      _applySyncResult(result);
      notifyListeners();
      return result;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      const result = FirebaseSyncResult(
          FirebaseSyncAction.noUser, 'Connexion Firebase requise');
      _applySyncResult(result);
      notifyListeners();
      return result;
    }

    syncing = true;
    syncStatus = 'Chargement du compte Firebase';
    notifyListeners();

    try {
      Map<String, dynamic>? seedPayload;
      if (!_database.isScopedTo(user.uid) &&
          !(await _database.hasOnlyBootstrapData())) {
        seedPayload = await _database.exportAll();
      }

      var remoteExists = true;
      try {
        remoteExists = await _syncService.hasRemoteSnapshot();
      } catch (_) {
        remoteExists = true;
      }
      await _database.setUserScope(user.uid);

      await _loadLocalState();
      if (seedPayload != null &&
          !remoteExists &&
          await _database.hasOnlyBootstrapData()) {
        await _database.replaceFromExport(seedPayload);
        await _database.markLocalUpdated();
        await _loadLocalState();
      }
      const result = FirebaseSyncResult(FirebaseSyncAction.unchanged,
          'Compte connecte. Utilise Synchroniser pour transferer les donnees.');
      _applySyncResult(result);
      return result;
    } finally {
      syncing = false;
      notifyListeners();
    }
  }

  void _applySyncResult(FirebaseSyncResult result) {
    syncStatus = result.message;
    if (result.syncedAt != null) lastSyncedAt = result.syncedAt;
  }

  Future<void> disconnectFirebase() async {
    if (FirebaseBootstrap.initialized) {
      await FirebaseAuth.instance.signOut();
    }
    await _database.setUserScope(null);
    await _loadLocalState();
    lastSyncedAt = null;
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
    final version = (payload['version'] as num?)?.round();
    if (version != null && version >= 2 && payload['data'] is Map) {
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
    _setArticleCategories(((state['articleCategories'] as List?) ?? const [])
        .map((category) => '$category'));
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
    meals = [];
    stockMovements = [];
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

  void _setArticleCategories(Iterable<String> storedCategories) {
    for (final article in articles) {
      final normalized = normalizedCategoryName(article.category);
      article.category = normalized.isEmpty ? 'DIVERS' : normalized;
    }
    final names = <String>{
      for (final category in storedCategories)
        if (normalizedCategoryName(category).isNotEmpty)
          normalizedCategoryName(category),
      for (final article in articles)
        if (normalizedCategoryName(article.category).isNotEmpty)
          normalizedCategoryName(article.category),
    }.toList()
      ..sort();
    articleCategories = names.isEmpty ? defaultArticleCategories() : names;
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
    await _secureSettings.saveHelloAssoSecret(settings.clientSecret);
    await _database.saveHelloAssoSettings(settings.withoutSecret());
    if (_syncService.isAvailable) {
      syncStatus = 'Modifications locales non synchronisees';
      notifyListeners();
    }
  }

  Future<void> testHelloAssoConnection() async {
    if (!helloAssoSettings.isConfigured) {
      throw Exception('Configuration HelloAsso incomplète');
    }
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
    meals = [];
    for (final registrant in registrants) {
      final player = _attachHelloAssoRegistrant(registrant);
      if (registrant.hasMeal) {
        _attachHelloAssoMeal(player, registrant);
      }
    }
    sales = [];
    stockMovements = [];
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

  Player _attachHelloAssoRegistrant(HelloAssoRegistrant registrant) {
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
    return player;
  }

  void _attachHelloAssoMeal(Player player, HelloAssoRegistrant registrant) {
    final mealArticle = mealArticles.firstOrNull;
    if (mealArticle == null) return;
    final now = DateTime.now();
    final mealLabel = registrant.mealLabel.trim();
    meals.add(MealOrder(
      id: makeId('meal'),
      playerId: player.id,
      playerName: player.name,
      playerType: player.type,
      source: 'helloasso',
      status: 'planned',
      mealArticleId: mealArticle.id,
      drinkArticleId: drinkArticles.firstOrNull?.id ?? '',
      snackArticleId: snackArticles.firstOrNull?.id ?? '',
      formula: 'Standard',
      options: const [],
      note: mealLabel.isEmpty ? '' : 'HelloAsso : $mealLabel',
      createdAt: now,
      updatedAt: now,
    ));
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
    await _database.markLocalUpdated();
    if (_syncService.isAvailable) {
      syncStatus = 'Modifications locales non synchronisees';
    }
    notifyListeners();
  }

  Future<void> _loadActiveSessionState() async {
    if (activeSession == null) return;
    players = await _database.loadPlayers(activeSession!.id);
    sales = await _database.loadSales(activeSession!.id);
    meals = await _database.loadMeals(activeSession!.id);
    stockMovements = await _database.loadStockMovements(activeSession!.id);
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
    for (final meal in meals.where((order) => order.playerId == player.id)) {
      meal.playerName = player.name;
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
    final shortages = cartStockShortages;
    if (shortages.isNotEmpty) {
      throw StateError(
          'Stock insuffisant : ${shortages.map((item) => item.message).join(' ; ')}');
    }
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
    }
    final sale = Sale(
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
    );
    for (final entry in _cartStockRequirements().entries) {
      _applyStockDelta(
        entry.key,
        -entry.value,
        movementType: 'sale',
        saleId: sale.id,
        reason: 'Vente ${sale.id}',
      );
    }
    sales.add(sale);
    cart.clear();
    donation = 0;
    notifyListeners();
    await persist();
  }

  Future<void> createMeal({
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
  }) async {
    final now = DateTime.now();
    final saleId = source == 'onsite' ? makeId('sale') : '';
    final meal = MealOrder(
      id: makeId('meal'),
      playerId: player.id,
      playerName: player.name,
      playerType: player.type,
      source: source,
      status: status,
      saleId: saleId,
      payment: payment,
      mealArticleId: mealArticleId,
      drinkArticleId: drinkArticleId,
      snackArticleId: snackArticleId,
      formula: formula,
      options: List<String>.of(options),
      note: note.trim(),
      createdAt: now,
      preparedAt: status == 'prepared' || status == 'served' ? now : null,
      servedAt: status == 'served' ? now : null,
      updatedAt: now,
    );
    _applyMealStockTransition(null, meal);
    if (meal.isOnsite) {
      sales.add(_saleForMeal(meal, player));
    }
    meals.add(meal);
    notifyListeners();
    await persist();
  }

  Future<void> updateMeal(MealOrder current, MealOrder updated) async {
    _applyMealStockTransition(current, updated);
    final index = meals.indexWhere((meal) => meal.id == current.id);
    if (index < 0) return;
    meals[index] = updated;
    if (updated.isOnsite && updated.saleId.isNotEmpty) {
      final saleIndex = sales.indexWhere((sale) => sale.id == updated.saleId);
      final player =
          players.where((entry) => entry.id == updated.playerId).firstOrNull;
      if (saleIndex >= 0 && player != null) {
        sales[saleIndex] = _saleForMeal(updated, player,
            createdAt: sales[saleIndex].createdAt);
      }
    }
    notifyListeners();
    await persist();
  }

  Future<void> prepareMeal(MealOrder meal) async {
    if (meal.status != 'planned') return;
    await updateMeal(
        meal,
        meal.copyWith(
          status: 'prepared',
          preparedAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ));
  }

  Future<void> serveMeal(MealOrder meal) async {
    if (meal.status == 'cancelled' || meal.status == 'served') return;
    final now = DateTime.now();
    await updateMeal(
        meal,
        meal.copyWith(
          status: 'served',
          preparedAt: meal.preparedAt ?? now,
          servedAt: now,
          updatedAt: now,
        ));
  }

  Future<void> cancelMeal(MealOrder meal) async {
    if (meal.status == 'cancelled') return;
    final cancelled = meal.copyWith(
        status: 'cancelled', saleId: '', updatedAt: DateTime.now());
    _applyMealStockTransition(meal, cancelled);
    final index = meals.indexWhere((entry) => entry.id == meal.id);
    if (index >= 0) meals[index] = cancelled;
    if (meal.saleId.isNotEmpty) {
      sales.removeWhere((sale) => sale.id == meal.saleId);
    }
    notifyListeners();
    await persist();
  }

  Sale _saleForMeal(MealOrder meal, Player player, {DateTime? createdAt}) {
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
      session: activeSession?.id ?? '',
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  void _applyMealStockTransition(MealOrder? previous, MealOrder next) {
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
    for (final id in ids) {
      final article = articles.where((entry) => entry.id == id).firstOrNull;
      if (article == null) continue;
      final delta = (oldItems[id] ?? 0) - (newItems[id] ?? 0);
      _applyStockDelta(
        article,
        delta,
        movementType: 'meal',
        saleId: next.saleId.isEmpty ? null : next.saleId,
        reason: 'Repas ${next.id}',
      );
    }
  }

  Map<Article, int> _cartStockRequirements() {
    final result = <Article, int>{};
    for (final item in cart) {
      final article =
          articles.where((entry) => entry.id == item.articleId).firstOrNull;
      if (article == null) continue;
      _mergeRequirements(result, _articleConsumption(article, item.quantity));
    }
    return result;
  }

  Map<Article, int> _saleStockRequirements(Sale sale) {
    final result = <Article, int>{};
    for (final item in sale.items) {
      final article = articles
          .where(
              (entry) => entry.id == item.articleId || entry.name == item.name)
          .firstOrNull;
      if (article != null) {
        _mergeRequirements(result, _articleConsumption(article, item.quantity));
      }
    }
    return result;
  }

  Map<Article, int> _articleConsumption(Article article, int quantity) {
    final result = <Article, int>{};
    if (article.tracksStock) result[article] = quantity;
    return result;
  }

  void _mergeRequirements(Map<Article, int> target, Map<Article, int> added) {
    for (final entry in added.entries) {
      target[entry.key] = (target[entry.key] ?? 0) + entry.value;
    }
  }

  List<StockShortage> _stockShortages(Map<Article, int> requirements) {
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

  void _applyStockDelta(
    Article article,
    int delta, {
    required String movementType,
    required String reason,
    String? saleId,
  }) {
    if (delta == 0) return;
    final before = article.stock;
    final after = before + delta;
    if (after < 0) {
      throw StateError('Stock insuffisant pour ${article.name}');
    }
    article.stock = after;
    final sessionId = activeSession?.id;
    if (sessionId != null) {
      final movement = StockMovement(
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
      pendingStockMovements.add(movement);
      stockMovements.add(movement);
    }
  }

  Future<void> consumeStockForAssociation(
    Article article,
    int quantity, {
    String note = '',
  }) async {
    if (!article.tracksStock) {
      throw StateError('Cet article ne gere pas de stock consommable');
    }
    if (quantity <= 0) {
      throw StateError('La quantité doit être supérieure à zéro');
    }
    if (article.stock < quantity) {
      throw StateError(
          'Stock insuffisant : ${article.name} : $quantity requis, ${article.stock} disponible(s)');
    }
    final trimmedNote = note.trim();
    _applyStockDelta(
      article,
      -quantity,
      movementType: 'association',
      reason: trimmedNote.isEmpty
          ? 'Consommation association'
          : 'Consommation association : $trimmedNote',
    );
    notifyListeners();
    await persist();
  }

  void _restoreStock(Sale sale) {
    for (final entry in _saleStockRequirements(sale).entries) {
      _applyStockDelta(
        entry.key,
        entry.value,
        movementType: 'cancellation',
        reason: 'Annulation vente ${sale.id}',
      );
    }
  }

  Future<void> cancelSale(Sale sale) async {
    final meal = meals.where((order) => order.saleId == sale.id).firstOrNull;
    if (meal != null) {
      await cancelMeal(meal);
      return;
    }
    _restoreStock(sale);
    sales.removeWhere((s) => s.id == sale.id);
    notifyListeners();
    await persist();
  }

  Future<void> upsertArticle(Article article, {Article? replacing}) async {
    final normalized = normalizedCategoryName(article.category);
    final category = normalized.isEmpty ? 'DIVERS' : normalized;
    article.category = category;
    if (article.isLocation) {
      article
        ..stock = 0
        ..threshold = 0
        ..bbAuto = 0
        ..gasAuto = 0;
    }
    if (!articleCategories.contains(category)) {
      articleCategories.add(category);
      articleCategories.sort();
    }
    if (replacing == null) {
      articles.add(article);
    } else {
      final desiredStock = article.stock;
      article.stock = replacing.stock;
      _applyStockDelta(
        article,
        desiredStock - replacing.stock,
        movementType: 'adjustment',
        reason: 'Modification manuelle du stock',
      );
      final index = articles.indexOf(replacing);
      articles[index] = article;
    }
    notifyListeners();
    await persist();
  }

  bool containsArticleCategory(String category, {String? except}) {
    final normalized = normalizedCategoryName(category);
    return articleCategories.any((existing) =>
        existing != except &&
        (normalizedCategoryName(existing) == normalized ||
            stableCategoryId(existing) == stableCategoryId(normalized)));
  }

  Future<void> addArticleCategory(String category) async {
    final normalized = normalizedCategoryName(category);
    if (normalized.isEmpty || containsArticleCategory(normalized)) return;
    articleCategories.add(normalized);
    articleCategories.sort();
    notifyListeners();
    await persist();
  }

  Future<void> renameArticleCategory(String previous, String category) async {
    final normalized = normalizedCategoryName(category);
    if (normalized.isEmpty ||
        containsArticleCategory(normalized, except: previous)) {
      return;
    }
    final index = articleCategories.indexOf(previous);
    if (index < 0) return;
    articleCategories[index] = normalized;
    articleCategories.sort();
    for (final article in articles.where((a) => a.category == previous)) {
      article.category = normalized;
    }
    if (categoryFilter == previous) categoryFilter = normalized;
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
    for (final meal in meals) {
      meal.saleId = '';
    }
    cart.clear();
    donation = 0;
    notifyListeners();
    await persist();
  }

  Future<void> resetAll() async {
    players.clear();
    sales.clear();
    meals.clear();
    cart.clear();
    donation = 0;
    selectedPlayerId = null;
    notifyListeners();
    await persist();
  }

  Future<void> resetStock() async {
    for (final article in articles) {
      _applyStockDelta(
        article,
        -article.stock,
        movementType: 'adjustment',
        reason: 'Remise a zero du stock',
      );
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
        0, (total, d) => total + d * (map[d.toString()] ?? 0));
  }

  Map<String, double> paymentTotals() {
    final result = {'ESP': 0.0, 'PayPal': 0.0, 'SumUp': 0.0};
    for (final sale in sales) {
      result[sale.payment] = (result[sale.payment] ?? 0) + sale.total;
    }
    return result;
  }

  Map<String, dynamic> backupPayload() => {
        'version': 3,
        'exportedAt': DateTime.now().toIso8601String(),
        'identity': VisualIdentity.name,
        'state': {
          'activeSession': activeSession?.toJson(),
          'sessions': sessions.map((e) => e.toJson()).toList(),
          'players': allPlayers.map((e) => e.toJson()).toList(),
          'activeSessionPlayers': players.map((e) => e.toJson()).toList(),
          'articleCategories': articleCategories,
          'articles': articles.map((e) => e.toJson()).toList(),
          'sales': sales.map((e) => e.toJson()).toList(),
          'meals': meals
              .map((meal) => {
                    'id': meal.id,
                    'playerId': meal.playerId,
                    'playerName': meal.playerName,
                    'source': meal.source,
                    'status': meal.status,
                    'formula': meal.formula,
                    'mealArticleId': meal.mealArticleId,
                    'drinkArticleId': meal.drinkArticleId,
                    'snackArticleId': meal.snackArticleId,
                    'options': meal.options,
                    'note': meal.note,
                  })
              .toList(),
          'cashStart': cashStart,
          'cashEnd': cashEnd,
        },
      };

  Future<Map<String, dynamic>> fullBackupPayload() async {
    await persist(markUpdated: false);
    return _database.exportAll();
  }
}
