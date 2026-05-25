part of '../../../main.dart';

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
        SectionTitle(
          'Historique par joueur',
          trailing: entries.isEmpty
              ? null
              : FilledButton.tonalIcon(
                  onPressed: () => exportPlayersPdf(context, controller),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('PDF'),
                ),
        ),
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
