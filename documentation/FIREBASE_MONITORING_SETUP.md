# Firebase monitoring developpeur

Ce Firebase est separe du Firebase configurable dans l'application.

- **Firebase monitoring developpeur** : Analytics et Crashlytics pour suivre
  l'usage, les utilisateurs actifs et les crashs de l'APK publie.
- **Firebase synchronisation utilisateur** : configuration saisie dans
  **Config > Firebase** par une association pour synchroniser ses donnees.

Les deux projets peuvent, et devraient, etre differents. Le monitoring est
configure au moment du build, pas depuis l'interface de l'application.

## Ce qui est active

- Firebase Analytics sur Android release.
- Firebase Crashlytics sur Android release.
- Collecte desactivee en debug par defaut pour ne pas polluer les metriques.
- Aucun monitoring Firebase sur Windows, car Analytics et Crashlytics ne sont
  pas disponibles pour cette cible dans ce projet.

## Creer le projet Firebase monitoring

1. Ouvrir https://console.firebase.google.com/.
2. Cliquer sur **Ajouter un projet**.
3. Nommer le projet, par exemple `tilly-monitoring`.
4. Activer Google Analytics pendant la creation du projet.
5. Une fois le projet cree, ouvrir **Vue d'ensemble du projet**.
6. Cliquer sur l'icone Android pour ajouter une application Android.
7. Renseigner exactement le package :

```txt
com.tilly.caisse
```

8. Choisir un surnom, par exemple `Tilly Android`.
9. Le SHA peut rester vide pour Analytics et Crashlytics.
10. Telecharger `google-services.json`.

Copier ensuite ce fichier dans le projet local :

```txt
android/app/google-services.json
```

Le fichier est ignore par git. Il contient des identifiants de projet, pas un
mot de passe, mais il reste lie au Firebase monitoring developpeur et ne doit
pas etre melange avec le Firebase de synchronisation utilisateur.

## Build local Android

Exemple de build release avec monitoring :

```bash
flutter build apk --release
```

Pour tester la collecte depuis un build debug, ajouter temporairement :

```bash
--dart-define=TILLY_MONITORING_DEBUG=true
```

Sans cette option, l'initialisation Firebase peut etre testee en debug, mais
Analytics et Crashlytics n'envoient pas de donnees.

## GitHub Actions

Le workflow de release Android lit les secrets suivants :

| Secret GitHub Actions | Contenu |
| --- | --- |
| `TILLY_MONITORING_GOOGLE_SERVICES_JSON_BASE64` | `google-services.json` du projet monitoring encode en base64 |

Dans GitHub :

1. Ouvrir le depot.
2. Aller dans **Settings > Secrets and variables > Actions**.
3. Cliquer sur **New repository secret**.
4. Ajouter le secret.
5. Publier une release via un tag `v...` comme d'habitude.

Sur macOS, la valeur du secret peut etre copiee avec :

```bash
base64 -i android/app/google-services.json | pbcopy
```

Si le secret n'est pas renseigne, le workflow Android release s'arrete avant
le build, car Analytics Android a besoin de ce fichier pour generer
`google_app_id`.

## Verification dans Firebase

### Analytics

1. Installer l'APK release sur un telephone.
2. Ouvrir l'application.
3. Dans Firebase Console, ouvrir **Analytics > Realtime**.
4. Verifier qu'un utilisateur actif apparait.

Les rapports Analytics complets peuvent mettre plusieurs heures a apparaitre.

### Crashlytics

1. Dans Firebase Console, ouvrir **Crashlytics**.
2. Suivre l'assistant d'activation si Firebase le demande.
3. Installer et ouvrir un APK release contenant les valeurs monitoring.
4. Les crashs reels remonteront dans ce tableau.

Crashlytics peut prendre quelques minutes avant d'afficher les premiers
evenements.

## Diagnostic des actions avant crash

L'application ajoute des breadcrumbs Crashlytics anonymes pour aider a
comprendre ce qui s'est passe avant un crash. Dans un rapport Crashlytics,
ouvrir le detail du crash puis consulter les **Logs** et les **Custom keys**.

Les informations utiles sont notamment :

- `current_tab` : dernier onglet ouvert (`sales`, `meals`, `players`, etc.) ;
- `last_action` : derniere action tracee ;
- logs `tab_opened`, `checkout_started`, `checkout_finished` ;
- logs `firebase_sync_requested`, `firebase_sync_finished` ;
- logs `backup_import_started`, `backup_export_started` ;
- logs `helloasso_events_fetch_started`, `session_create_started`.

Ces traces ne contiennent pas les noms, emails, details du panier, secrets API
ou contenu de sauvegarde. Elles servent uniquement a retrouver le contexte
technique d'un crash.
