part of '../../main.dart';

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
  var eventsFetchStarted = false;
  final value = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        if (loadingEvents &&
            !eventsFetchStarted &&
            events.isEmpty &&
            helloAssoError.isEmpty) {
          eventsFetchStarted = true;
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
                        if (event != null) {
                          field.text = event.name;
                        }
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
      if (context.mounted) {
        snack(
            context,
            selectedEvent == null
                ? 'Nouvelle session active'
                : 'Session créée avec joueurs HelloAsso');
      }
    } catch (error) {
      if (context.mounted) snack(context, 'Création impossible : $error');
    }
  }
}

Future<void> showFirebaseSetupDialog(
    BuildContext context, AppController controller,
    {bool editProject = false}) async {
  final result = await showDialog<FirebaseSyncResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _FirebaseSetupDialog(
      controller: controller,
      editProject: editProject,
    ),
  );
  if (result != null && context.mounted) snack(context, result.message);
}

Future<void> showFirebaseHelpDialog(BuildContext context) async {
  final openGuide = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accent2),
          SizedBox(width: 10),
          Expanded(child: Text('À quoi sert Firebase ?')),
        ],
      ),
      content: SizedBox(
        width: min(MediaQuery.sizeOf(context).width - 48, 540),
        child: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Firebase est optionnel. Sans connexion, toutes les fonctions de caisse restent disponibles sur cet appareil.',
              ),
              SizedBox(height: 14),
              _HelpDialogItem(
                icon: Icons.sync,
                text:
                    'Synchroniser les données de caisse entre plusieurs appareils.',
              ),
              SizedBox(height: 10),
              _HelpDialogItem(
                icon: Icons.restore,
                text:
                    'Récupérer les données après une réinstallation ou sur un nouvel appareil.',
              ),
              SizedBox(height: 10),
              _HelpDialogItem(
                icon: Icons.lock_outline,
                text:
                    'Protéger chaque espace avec un compte email et mot de passe.',
              ),
              SizedBox(height: 14),
              Text(
                'Le tutoriel explique pas à pas comment créer le projet Firebase, activer Firestore et récupérer les codes Android ou Windows à coller dans l’application.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Fermer'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Ouvrir le tutoriel'),
        ),
      ],
    ),
  );

  if (openGuide != true || !context.mounted) return;
  try {
    await openExternalUrl(_firebaseSetupGuideUrl);
  } catch (error) {
    if (context.mounted) {
      snack(context, 'Impossible d’ouvrir le tutoriel : $error');
    }
  }
}

Future<void> showHelloAssoHelpDialog(BuildContext context,
    {bool mealsEnabled = true}) async {
  final openGuide = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.accent2),
          SizedBox(width: 10),
          Expanded(child: Text('À quoi sert HelloAsso ?')),
        ],
      ),
      content: SizedBox(
        width: min(MediaQuery.sizeOf(context).width - 48, 540),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                mealsEnabled
                    ? 'HelloAsso est optionnel. Sans connexion, les joueurs et les repas peuvent toujours être saisis manuellement.'
                    : 'HelloAsso est optionnel. Sans connexion, les joueurs peuvent toujours être saisis manuellement.',
              ),
              const SizedBox(height: 14),
              _HelpDialogItem(
                icon: Icons.event_available,
                text: 'Retrouver les événements publiés par l’association.',
              ),
              const SizedBox(height: 10),
              const _HelpDialogItem(
                icon: Icons.group_add_outlined,
                text: 'Importer les participants ayant réglé leur inscription.',
              ),
              if (mealsEnabled) ...[
                const SizedBox(height: 10),
                const _HelpDialogItem(
                  icon: Icons.restaurant_outlined,
                  text:
                      'Récupérer les informations utiles à la préparation des repas.',
                ),
              ],
              const SizedBox(height: 14),
              const Text(
                'Le tutoriel explique où trouver le nom public de l’association, le Client ID et le Client secret, puis comment les renseigner dans l’application.',
                style: TextStyle(color: AppColors.muted, height: 1.4),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Fermer'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.pop(context, true),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Ouvrir le tutoriel'),
        ),
      ],
    ),
  );

  if (openGuide != true || !context.mounted) return;
  try {
    await openExternalUrl(_helloAssoSetupGuideUrl);
  } catch (error) {
    if (context.mounted) {
      snack(context, 'Impossible d’ouvrir le tutoriel : $error');
    }
  }
}

class _HelpDialogItem extends StatelessWidget {
  const _HelpDialogItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.accent),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    );
  }
}

class _FirebaseSetupDialog extends StatefulWidget {
  const _FirebaseSetupDialog({
    required this.controller,
    required this.editProject,
  });

  final AppController controller;
  final bool editProject;

  @override
  State<_FirebaseSetupDialog> createState() => _FirebaseSetupDialogState();
}

class _FirebaseSetupDialogState extends State<_FirebaseSetupDialog> {
  final configuration = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  late final TextEditingController apiKey;
  late final TextEditingController appId;
  late final TextEditingController messagingSenderId;
  late final TextEditingController projectId;
  late final TextEditingController authDomain;
  late final TextEditingController storageBucket;
  late final TextEditingController measurementId;
  late FirebaseSettings settings;
  late bool editingProject;
  bool manualEntry = false;
  bool obscurePassword = true;
  bool loading = false;
  String? error;

  @override
  void initState() {
    super.initState();
    settings = widget.controller.firebaseSettings;
    editingProject = widget.editProject || !settings.isConfigured;
    apiKey = TextEditingController(text: settings.apiKey);
    appId = TextEditingController(text: settings.appId);
    messagingSenderId = TextEditingController(text: settings.messagingSenderId);
    projectId = TextEditingController(text: settings.projectId);
    authDomain = TextEditingController(text: settings.authDomain);
    storageBucket = TextEditingController(text: settings.storageBucket);
    measurementId = TextEditingController(text: settings.measurementId);
  }

  @override
  void dispose() {
    configuration.dispose();
    email.dispose();
    password.dispose();
    apiKey.dispose();
    appId.dispose();
    messagingSenderId.dispose();
    projectId.dispose();
    authDomain.dispose();
    storageBucket.dispose();
    measurementId.dispose();
    super.dispose();
  }

  FirebaseSettings _enteredSettings() {
    if (!manualEntry) return parseFirebaseSettings(configuration.text);
    return FirebaseSettings(
      apiKey: apiKey.text,
      appId: appId.text,
      messagingSenderId: messagingSenderId.text,
      projectId: projectId.text,
      authDomain: authDomain.text,
      storageBucket: storageBucket.text,
      measurementId: measurementId.text,
    );
  }

  Future<void> _activate() async {
    if (loading) return;
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => error = 'Renseigne l’email et le mot de passe du compte.');
      return;
    }
    setState(() {
      loading = true;
      error = null;
    });
    try {
      if (editingProject) {
        final enteredSettings = _enteredSettings();
        await widget.controller.saveFirebaseSettings(enteredSettings);
        settings = enteredSettings;
        editingProject = false;
      }
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final result = await widget.controller.connectFirebaseUser();
      if (mounted) Navigator.pop(context, result);
    } on FirebaseAuthException catch (exception) {
      if (mounted) setState(() => error = _firebaseAuthError(exception));
    } catch (exception) {
      if (mounted) {
        setState(() => error = '$exception'
            .replaceFirst('Bad state: ', '')
            .replaceFirst('FormatException: ', ''));
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Activer la synchronisation'),
      content: SizedBox(
        width: min(MediaQuery.sizeOf(context).width - 48, 620),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (editingProject) ...[
                const Text('1. Projet Firebase',
                    style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 8),
                if (!manualEntry)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: configuration,
                        minLines: 5,
                        maxLines: 9,
                        decoration: const InputDecoration(
                          labelText: 'Configuration à coller',
                          alignLabelWithHint: true,
                          hintText:
                              'Bloc firebaseConfig ou contenu de google-services.json',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: loading ? null : _pasteConfiguration,
                          icon: const Icon(Icons.content_paste),
                          label: const Text('Coller'),
                        ),
                      ),
                    ],
                  )
                else
                  _buildManualFields(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: loading
                        ? null
                        : () => setState(() => manualEntry = !manualEntry),
                    icon: Icon(manualEntry ? Icons.content_paste : Icons.tune),
                    label: Text(manualEntry
                        ? 'Revenir au collage'
                        : 'Options avancées'),
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    const Icon(Icons.cloud_done, color: AppColors.accent),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Projet ${settings.projectId}',
                          style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                    TextButton(
                      onPressed: loading
                          ? null
                          : () => setState(() => editingProject = true),
                      child: const Text('Changer'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              Text(
                  editingProject
                      ? '2. Compte utilisateur'
                      : 'Compte utilisateur',
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                    labelText: 'Email', prefixIcon: Icon(Icons.mail)),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: password,
                obscureText: obscurePassword,
                onSubmitted: (_) => _activate(),
                decoration: InputDecoration(
                  labelText: 'Mot de passe',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    tooltip: obscurePassword ? 'Afficher' : 'Masquer',
                    onPressed: () =>
                        setState(() => obscurePassword = !obscurePassword),
                    icon: Icon(obscurePassword
                        ? Icons.visibility
                        : Icons.visibility_off),
                  ),
                ),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: const TextStyle(color: AppColors.danger)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton.icon(
          onPressed: loading ? null : _activate,
          icon: loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.cloud_done),
          label: const Text('Activer'),
        ),
      ],
    );
  }

  Widget _buildManualFields() {
    return Column(
      children: [
        TextField(
            controller: apiKey,
            decoration: const InputDecoration(labelText: 'API key *')),
        const SizedBox(height: 8),
        TextField(
            controller: appId,
            decoration: const InputDecoration(labelText: 'App ID *')),
        const SizedBox(height: 8),
        TextField(
            controller: messagingSenderId,
            keyboardType: TextInputType.number,
            decoration:
                const InputDecoration(labelText: 'Messaging sender ID *')),
        const SizedBox(height: 8),
        TextField(
            controller: projectId,
            decoration: const InputDecoration(labelText: 'Project ID *')),
        const SizedBox(height: 8),
        TextField(
            controller: authDomain,
            decoration:
                const InputDecoration(labelText: 'Auth domain (optionnel)')),
        const SizedBox(height: 8),
        TextField(
            controller: storageBucket,
            decoration:
                const InputDecoration(labelText: 'Storage bucket (optionnel)')),
        const SizedBox(height: 8),
        TextField(
            controller: measurementId,
            decoration:
                const InputDecoration(labelText: 'Measurement ID (optionnel)')),
      ],
    );
  }

  Future<void> _pasteConfiguration() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) {
      if (mounted) setState(() => error = 'Le presse-papiers est vide.');
      return;
    }
    configuration.text = text;
    if (mounted) setState(() => error = null);
  }
}

String _firebaseAuthError(FirebaseAuthException exception) {
  switch (exception.code) {
    case 'invalid-credential':
    case 'wrong-password':
    case 'user-not-found':
      return 'Email ou mot de passe incorrect.';
    case 'invalid-email':
      return 'Adresse email invalide.';
    case 'network-request-failed':
      return 'Connexion réseau impossible.';
    case 'too-many-requests':
      return 'Trop de tentatives. Réessaie plus tard.';
    default:
      return exception.message ?? exception.code;
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

Future<void> showCategoryDialog(BuildContext context, AppController controller,
    {String? category}) async {
  final name = TextEditingController(text: category ?? '');
  String? error;
  final value = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(
            category == null ? 'Nouvelle catégorie' : 'Modifier catégorie'),
        content: TextField(
          controller: name,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: InputDecoration(
              labelText: 'Nom de la catégorie', errorText: error),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler')),
          FilledButton(
            onPressed: () {
              final normalized = normalizedCategoryName(name.text);
              if (normalized.isEmpty) {
                setState(() => error = 'Saisissez un nom de catégorie');
                return;
              }
              if (controller.containsArticleCategory(normalized,
                  except: category)) {
                setState(() => error = 'Cette catégorie existe déjà');
                return;
              }
              Navigator.pop(context, normalized);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    ),
  );
  if (value == null || value == category) return;
  if (category == null) {
    await controller.addArticleCategory(value);
    if (context.mounted) snack(context, 'Catégorie ajoutée');
  } else {
    await controller.renameArticleCategory(category, value);
    if (context.mounted) snack(context, 'Catégorie modifiée');
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
  final categoryOptions = <String>[...controller.activeArticleCategories]
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
  if (categoryOptions.isEmpty) categoryOptions.add('DIVERS');
  var category =
      (article?.category ?? categoryOptions.first).trim().toUpperCase();
  if (!categoryOptions.contains(category)) categoryOptions.add(category);
  var type =
      article?.type ?? (category == 'LOCATION' ? 'location' : 'standard');
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        return AlertDialog(
          title: Text(article == null ? 'Nouvel article' : 'Modifier article'),
          content: SizedBox(
            width: min(MediaQuery.sizeOf(context).width - 48, 720),
            child: SingleChildScrollView(
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
                            decoration:
                                const InputDecoration(labelText: 'Nom'))),
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
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration:
                        const InputDecoration(labelText: 'Type d’article'),
                    items: const [
                      DropdownMenuItem(
                          value: 'standard', child: Text('Article en stock')),
                      DropdownMenuItem(
                          value: 'location', child: Text('Location')),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() => type = value);
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
                                ? 'Location : aucune sortie de stock automatique'
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
                            decoration: const InputDecoration(
                                labelText: 'Prix public'))),
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
                    const Text(
                      'Une location reste facturable mais ne modifie jamais le stock.',
                      style: TextStyle(color: AppColors.muted),
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
        );
      },
    ),
  );
  if (ok == true && name.text.trim().isNotEmpty) {
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
        bbAuto: 0,
        gasAuto: 0,
      ),
      replacing: article,
    );
  }
}

Future<void> showAssociationConsumptionDialog(
    BuildContext context, AppController controller) async {
  final availableArticles =
      controller.articles.where((article) => article.tracksStock).toList();
  if (availableArticles.isEmpty) {
    snack(context, 'Aucun article avec stock disponible');
    return;
  }
  var articleId = availableArticles.first.id;
  final quantity = TextEditingController(text: '1');
  final note = TextEditingController();
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) {
        final article =
            availableArticles.where((entry) => entry.id == articleId).first;
        return AlertDialog(
          title: const Text('Sortie stock association'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Cette sortie n'est ni une vente ni un paiement.",
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: articleId,
                decoration: const InputDecoration(labelText: 'Article'),
                items: [
                  for (final entry in availableArticles)
                    DropdownMenuItem(
                      value: entry.id,
                      child: Text('${entry.name} (stock ${entry.stock})'),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => articleId = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: quantity,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Quantité',
                    helperText: 'Disponible : ${article.stock}'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: note,
                decoration:
                    const InputDecoration(labelText: 'Motif (optionnel)'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Valider la sortie')),
          ],
        );
      },
    ),
  );
  if (ok != true) return;
  final article =
      availableArticles.where((entry) => entry.id == articleId).first;
  try {
    await controller.consumeStockForAssociation(
      article,
      int.tryParse(quantity.text.trim()) ?? 0,
      note: note.text,
    );
    if (context.mounted) snack(context, 'Sortie association enregistrée');
  } on StateError catch (error) {
    if (context.mounted) snack(context, '$error');
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
                      try {
                        await controller.checkout('ESP');
                        if (context.mounted) Navigator.pop(context);
                      } on StateError catch (error) {
                        if (context.mounted) snack(context, '$error');
                      }
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
