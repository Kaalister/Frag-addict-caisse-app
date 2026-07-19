import 'package:tilly/src/domain/models.dart';

abstract interface class PersistableAppState {
  SessionRecord? get activeSession;
  AppSettings get appSettings;
  List<Player> get allPlayers;
  List<Player> get players;
  List<String> get articleCategories;
  List<Article> get articles;
  List<Sale> get sales;
  List<MealOrder> get meals;
  List<StockMovement> get pendingStockMovements;
  Map<String, int> get cashStart;
  Map<String, int> get cashEnd;

  double cashTotal(String kind);
}
