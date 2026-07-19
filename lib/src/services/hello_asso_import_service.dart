import '../domain/models.dart';
import '../utils/iterable_extensions.dart';
import 'hello_asso_client.dart';

class HelloAssoImportService {
  Future<List<HelloAssoEvent>> fetchEvents(HelloAssoSettings settings) {
    if (!settings.isConfigured) return Future.value(const []);
    return HelloAssoClient(settings).fetchEvents();
  }

  Future<List<HelloAssoRegistrant>> fetchRegistrants(
      HelloAssoSettings settings, HelloAssoEvent event) {
    return HelloAssoClient(settings).fetchPaidOrderPayers(event);
  }

  Player attachRegistrant({
    required HelloAssoRegistrant registrant,
    required List<Player> allPlayers,
    required List<Player> sessionPlayers,
  }) {
    final cleanEmail = registrant.email.trim().toLowerCase();
    final cleanName = playerNameFromParts(
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
    if (!sessionPlayers.any((p) => p.id == player.id)) {
      sessionPlayers.add(player);
    }
    return player;
  }
}
