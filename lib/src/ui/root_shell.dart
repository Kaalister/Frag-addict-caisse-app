part of '../../main.dart';

class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  final controller = AppController();
  AppUpdateResult? updateResult;
  bool checkingUpdate = false;
  bool openingUpdate = false;
  String? updateActionError;

  @override
  void initState() {
    super.initState();
    controller.load();
    _checkForUpdate();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _checkForUpdate() async {
    if (!kReleaseMode || !AppUpdateService.supportedPlatform) {
      return;
    }
    setState(() {
      checkingUpdate = true;
      updateActionError = null;
    });
    final result = await AppUpdateService.check();
    if (!mounted) return;
    setState(() {
      updateResult = result;
      checkingUpdate = false;
    });
  }

  Future<void> _openUpdate(AppUpdateInfo update) async {
    if (openingUpdate) return;
    setState(() {
      openingUpdate = true;
      updateActionError = null;
    });
    try {
      await openExternalUrl(update.downloadUrl);
    } catch (error) {
      if (mounted) setState(() => updateActionError = '$error');
    } finally {
      if (mounted) setState(() => openingUpdate = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final requiredUpdate = updateResult?.update;
        if (requiredUpdate != null) {
          return UpdateRequiredScaffold(
            update: requiredUpdate,
            opening: openingUpdate,
            actionError: updateActionError,
            onDownload: () => _openUpdate(requiredUpdate),
            onRetry: _checkForUpdate,
          );
        }
        if (controller.loading) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }
        final pages = [
          CaissePage(controller: controller),
          MealsPage(controller: controller),
          PlayersPage(controller: controller),
          CashAnalysisPage(controller: controller),
          KpiPage(controller: controller),
          BilanPage(controller: controller),
          HistoryPage(controller: controller),
          ArticlesPricePage(controller: controller),
          ConfigPage(
            controller: controller,
            updateResult: updateResult,
            checkingUpdate: checkingUpdate,
            onCheckUpdate: _checkForUpdate,
            onOpenUpdate: _openUpdate,
          ),
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
                                icon: Icon(Icons.restaurant),
                                label: Text('Repas')),
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
                            icon: Icon(Icons.restaurant), label: 'Repas'),
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

class UpdateRequiredScaffold extends StatelessWidget {
  const UpdateRequiredScaffold({
    required this.update,
    required this.opening,
    required this.onDownload,
    required this.onRetry,
    this.actionError,
    super.key,
  });

  final AppUpdateInfo update;
  final bool opening;
  final String? actionError;
  final VoidCallback onDownload;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: TacticalCard(
                borderColor: AppColors.warn,
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(Icons.system_update,
                        color: AppColors.accent, size: 42),
                    const SizedBox(height: 14),
                    const Text(
                      'Mise à jour obligatoire',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Version installée : ${update.currentVersion}\n'
                      'Version disponible : ${update.latestVersion}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                    if (update.publishedAt != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Publiée le ${dateLabel(update.publishedAt!)} à ${timeLabel(update.publishedAt!)}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: opening ? null : onDownload,
                      icon: opening
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        Platform.isAndroid
                            ? 'Télécharger l’APK'
                            : 'Télécharger l’installateur',
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: opening ? null : onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Re-vérifier'),
                    ),
                    if (actionError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        actionError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.danger),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
