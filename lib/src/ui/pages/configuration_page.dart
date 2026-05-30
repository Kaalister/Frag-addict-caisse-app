part of '../../../main.dart';

class ArticlesPricePage extends StatelessWidget {
  const ArticlesPricePage({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final categories = controller.articleCategories;
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionTitle('Articles & Prix'),
        ConfigSection(
          title: 'Catégories',
          trailing: OutlinedButton.icon(
            onPressed: () => showCategoryDialog(context, controller),
            icon: const Icon(Icons.add),
            label: const Text('Ajouter'),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final category in categories)
                  ActionChip(
                    avatar: const Icon(Icons.edit, size: 16),
                    label: Text(category),
                    onPressed: () => showCategoryDialog(context, controller,
                        category: category),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ConfigSection(
          title: 'Articles & prix',
          trailing: Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () =>
                    showAssociationConsumptionDialog(context, controller),
                icon: const Icon(Icons.inventory_2_outlined),
                label: const Text('Sortie asso'),
              ),
              OutlinedButton.icon(
                onPressed: () => showArticleDialog(context, controller),
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
              ),
            ],
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
                      if (await confirm(
                          context, 'Supprimer ${article.name} ?')) {
                        try {
                          await controller.deleteArticle(article);
                        } catch (error) {
                          if (context.mounted) {
                            final message = '$error'
                                .replaceFirst('Bad state: ', '')
                                .replaceFirst('Exception: ', '');
                            snack(context, message);
                          }
                        }
                      }
                    },
                  ),
                if (!controller.articles.any((a) => a.category == category))
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Text('Aucun article dans cette catégorie',
                        style: TextStyle(color: AppColors.muted)),
                  ),
              ],
              if (controller.articles.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text('Aucun article configuré')),
            ],
          ),
        ),
      ],
    );
  }
}

class ConfigPage extends StatelessWidget {
  const ConfigPage({
    required this.controller,
    required this.updateResult,
    required this.checkingUpdate,
    required this.onCheckUpdate,
    required this.onOpenUpdate,
    super.key,
  });

  final AppController controller;
  final AppUpdateResult? updateResult;
  final bool checkingUpdate;
  final VoidCallback onCheckUpdate;
  final Future<void> Function(AppUpdateInfo update) onOpenUpdate;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        const SectionTitle('Configuration'),
        const SectionTitle('Mises à jour'),
        ConfigActionZone(
          borderColor: updateResult?.requiresUpdate == true
              ? AppColors.warn
              : AppColors.accent2,
          title: _updateStatusTitle(),
          description: _updateStatusDescription(),
          action: Wrap(
            spacing: 8,
            children: [
              if (updateResult?.update != null)
                FilledButton.tonalIcon(
                  onPressed: () => onOpenUpdate(updateResult!.update!),
                  icon: const Icon(Icons.download),
                  label: Text(
                    Platform.isAndroid ? 'Télécharger APK' : 'Télécharger',
                  ),
                ),
              OutlinedButton.icon(
                onPressed: checkingUpdate ? null : onCheckUpdate,
                icon: checkingUpdate
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                label: const Text('Vérifier'),
              ),
            ],
          ),
        ),
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
                  'Connecte-toi avec un compte Firebase pour charger la caisse liée à cet utilisateur.'),
          action: Wrap(
            spacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: controller.firebaseAvailable && !controller.syncing
                    ? () => _syncFirebase(context)
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
                          if (context.mounted) {
                            snack(context, 'Connexion HelloAsso OK');
                          }
                        } catch (error) {
                          if (context.mounted) {
                            snack(context,
                                'Connexion HelloAsso impossible : $error');
                          }
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
              'Importe un JSON valide, apres creation automatique d une copie locale de securite.',
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
              if (await confirm(context, 'Effacer toutes les ventes ?')) {
                await controller.resetSales();
              }
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
              if (await confirm(context, 'Effacer ventes et joueurs ?')) {
                await controller.resetAll();
              }
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
              if (await confirm(context, 'Remettre tous les stocks à zéro ?')) {
                await controller.resetStock();
              }
            },
            child: const Text('Reset stock'),
          ),
        ),
      ],
    );
  }

  String _updateStatusTitle() {
    if (!kReleaseMode) return 'Mode développement';
    if (!AppUpdateService.supportedPlatform) return 'Plateforme non suivie';
    if (checkingUpdate && updateResult == null) return 'Vérification en cours';
    if (updateResult?.requiresUpdate == true) return 'Mise à jour disponible';
    if (updateResult?.error != null) return 'Vérification impossible';
    return 'Application à jour';
  }

  Future<void> _syncFirebase(BuildContext context) async {
    var result = await controller.syncNow();
    if (result.action == FirebaseSyncAction.remoteNewer && context.mounted) {
      final ok = await confirm(context,
          'Firebase contient des donnees plus recentes. Remplacer les donnees locales apres creation d une copie de securite ?');
      if (!ok) return;
      final recoveryFile = await saveRecoveryBackup(controller, 'firebase');
      result = await controller.syncNow(allowRemotePull: true);
      if (context.mounted && result.action == FirebaseSyncAction.pulled) {
        snack(context,
            '${result.message}. Copie precedente : ${recoveryFile['name']}');
        return;
      }
    }
    if (context.mounted) snack(context, result.message);
  }

  String _updateStatusDescription() {
    if (!kReleaseMode) {
      return 'Le contrôle forcé est actif uniquement dans les builds release. Version build : $_appBuildVersion.';
    }
    if (!AppUpdateService.supportedPlatform) {
      return 'Le contrôle GitHub est prévu pour Android et Windows.';
    }
    final update = updateResult?.update;
    if (update != null) {
      return 'Version $_appBuildVersion installée, version ${update.latestVersion} publiée sur GitHub. Fichier : ${update.assetName}. Une copie locale est créée avant le téléchargement.';
    }
    if (updateResult?.error != null) {
      return '${updateResult!.error} Version build : $_appBuildVersion.';
    }
    final latest = updateResult?.latestVersion;
    return latest == null
        ? 'Version build : $_appBuildVersion.'
        : 'Version build : $_appBuildVersion. Dernière version GitHub : $latest.';
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
      final result = await widget.controller.connectFirebaseUser();
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
                  label: const Text('Connecter'),
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
                      0, (total, sale) => total + sale.total);
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
                              if (context.mounted) {
                                snack(context, 'Session chargée');
                              }
                            },
                            icon: const Icon(Icons.login),
                            label: const Text('Ouvrir'),
                          ),
                    children: [
                      if (sessionSales.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FilledButton.tonalIcon(
                              onPressed: () =>
                                  exportBilanPdf(context, controller, session),
                              icon: const Icon(Icons.picture_as_pdf),
                              label: const Text('Bilan PDF'),
                            ),
                          ),
                        ),
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
