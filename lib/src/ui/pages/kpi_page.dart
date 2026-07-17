part of '../../../main.dart';

class KpiPage extends StatelessWidget {
  const KpiPage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final rows = kpiRows(controller);
    final totalCA = rows.fold<double>(0, (total, row) => total + row.ca);
    final ruptures = rows.where((r) => r.article.stock == 0).length;
    final alertes = rows
        .where((r) =>
            r.article.stock > 0 && r.article.stock <= r.article.threshold)
        .length;
    rows.sort(_compareKpiRows);
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        SectionTitle(
          'Stats achats & stock',
          trailing: rows.isEmpty
              ? null
              : FilledButton.tonalIcon(
                  onPressed: () => exportKpiPdf(context, controller),
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Exporter'),
                ),
        ),
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
                  Text([
                    'Vendu ${row.sold}',
                    if (controller.mealsEnabled) 'Dans repas ${row.mealUsed}',
                    'Asso ${row.associationUsed}',
                    'Sorti ${row.outgoing}',
                    'CA ${money(row.ca)}',
                    'stock ${row.stockRest}/${row.stockInitial}',
                    'suggestion achat >= ${row.suggestion}',
                  ].join(' · ')),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class KpiRow {
  KpiRow(
      this.article,
      this.sold,
      this.mealUsed,
      this.associationUsed,
      this.outgoing,
      this.ca,
      this.stockRest,
      this.stockInitial,
      this.rotation,
      this.suggestion);
  final Article article;
  final int sold;
  final int mealUsed;
  final int associationUsed;
  final int outgoing;
  final double ca;
  final int stockRest;
  final int stockInitial;
  final double rotation;
  final int suggestion;
}

int _compareKpiRows(KpiRow a, KpiRow b) {
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
}

List<KpiRow> kpiRows(AppController controller, {List<Sale>? sales}) {
  final sold = <String, ({int quantity, double ca})>{};
  final stockSold = <String, int>{};
  final mealUsed = <String, int>{};
  final associationUsed = <String, int>{};
  final days = <String>{};
  final selectedSales = sales ?? controller.sales;
  final linkedMeals = controller.mealsEnabled
      ? {
          for (final meal in controller.meals)
            if (meal.saleId.isNotEmpty) meal.saleId: meal
        }
      : const <String, MealOrder>{};
  for (final sale in selectedSales) {
    days.add(dateLabel(sale.createdAt));
    for (final item in sale.items) {
      final current = sold[item.articleId] ?? (quantity: 0, ca: 0.0);
      sold[item.articleId] = (
        quantity: current.quantity + item.quantity,
        ca: current.ca + item.quantity * item.price
      );
      final linkedMeal = linkedMeals[sale.id];
      if (linkedMeal == null || linkedMeal.mealArticleId != item.articleId) {
        stockSold[item.articleId] =
            (stockSold[item.articleId] ?? 0) + item.quantity;
      }
    }
  }
  if (controller.mealsEnabled) {
    for (final meal in controller.meals.where((order) => order.consumesStock)) {
      days.add(dateLabel(meal.preparedAt ?? meal.createdAt));
      for (final entry in meal.stockItems.entries) {
        mealUsed[entry.key] = (mealUsed[entry.key] ?? 0) + entry.value;
      }
    }
  }
  for (final movement in controller.stockMovements.where((entry) =>
      entry.movementType == 'association' && entry.quantityDelta < 0)) {
    days.add(dateLabel(movement.createdAt));
    associationUsed[movement.articleId] =
        (associationUsed[movement.articleId] ?? 0) - movement.quantityDelta;
  }
  final dayCount = max(1, days.length);
  return controller.activeArticles
      .where((a) => a.type == 'standard' && a.threshold > 0)
      .map((a) {
    final s = sold[a.id] ?? (quantity: 0, ca: 0.0);
    final mealQuantity = mealUsed[a.id] ?? 0;
    final associationQuantity = associationUsed[a.id] ?? 0;
    final outgoing =
        (stockSold[a.id] ?? 0) + mealQuantity + associationQuantity;
    final initial = a.stock + outgoing;
    final rotation = initial == 0 ? 0.0 : outgoing / initial;
    final suggestion = outgoing > 0 ? ((outgoing / dayCount) * 1.3).ceil() : 0;
    return KpiRow(a, s.quantity, mealQuantity, associationQuantity, outgoing,
        s.ca, a.stock, initial, rotation, suggestion);
  }).toList();
}
