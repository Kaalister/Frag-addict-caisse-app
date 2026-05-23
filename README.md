# Frags Addicts Caisse

Application Flutter inspirée de `documentation/Base/caisse_airsoft.html`. Elle reprend l'identité sombre, les accents vert tactique / cyan et les workflows caisse, joueurs, bilan, analyse espèces, KPI et configuration.

L'analyse fonctionnelle et graphique complète est dans `documentation/ANALYSE_HTML.md`.

## Lancer dans Android Studio

1. Installer Flutter et le plugin Flutter dans Android Studio.
2. Ouvrir ce dossier comme projet Flutter.
3. Lancer `flutter pub get`.
4. Sélectionner un émulateur ou un téléphone Android.
5. Lancer `lib/main.dart`.

Si Android Studio demande le chemin du SDK Flutter, renseigner le dossier d'installation Flutter. Le fichier `android/local.properties` sera généré localement.

## Structure

- `lib/main.dart` : application complète, modèles, état, pages et composants.
- `android/` : squelette Android pour Android Studio.
- `windows/` : cible Windows Flutter.
- `.github/workflows/` : génération automatique de l'app Windows et de l'installateur.
- `installer/` : script Inno Setup pour l'installateur Windows.
- `documentation/Base/caisse_airsoft.html` : source HTML d'origine conservée comme référence fonctionnelle.
- `a_supprimer/` : fichiers locaux/caches déplacés pendant le nettoyage, non versionnés.

## Fonctionnement

L'application stocke les données localement dans une base SQLite privée à l'appareil via `sqflite` :

- `players` : joueurs publics ou adhérents.
- `articles` : boissons, billes, snacks, locations, prix et stocks.
- `sales` et `sale_items` : ventes et lignes de vente avec snapshots des prix/noms.
- `cash_counts` et `cash_count_lines` : fond de caisse début/fin par coupure.
- `app_settings` : réglages simples comme le nom de session.

Les boutons de sauvegarde exportent toujours un JSON dans le presse-papiers pour garder une copie manuelle.

## Synchronisation Firebase

La base locale SQLite peut être synchronisée entre Android et Windows avec Firebase Auth email/mot de passe et Cloud Firestore. La configuration du projet Firebase est décrite dans `documentation/FIREBASE_SETUP.md`.

## Mises à jour GitHub

Les builds release Android et Windows vérifient au lancement la dernière Release GitHub du dépôt `Kaalister/Frag-addict-caisse-app`. Si le tag publié est supérieur à la version installée, l'application affiche un écran bloquant et envoie l'utilisateur vers l'APK Android ou l'installateur Windows attaché à la Release.

Flux de publication :

1. Créer un tag SemVer préfixé par `v`, par exemple `v1.0.1`.
2. Pousser le tag sur GitHub.
3. Le workflow `Build releases` compile l'APK Android et les artefacts Windows, puis les attache à la Release GitHub.
4. Les applications installées détectent automatiquement cette Release au prochain lancement.

Secrets GitHub Actions requis pour signer l'APK Android sans passer par le Play Store :

- `ANDROID_KEYSTORE_BASE64` : contenu base64 du fichier `android/app/frags-addicts-release.jks`.
- `ANDROID_STORE_PASSWORD` : mot de passe du keystore.
- `ANDROID_KEY_PASSWORD` : mot de passe de la clé.
- `ANDROID_KEY_ALIAS` : alias de la clé, par exemple `frags-addicts-release`.

Pour encoder le keystore local avant de le coller dans le secret GitHub :

```bash
base64 -i android/app/frags-addicts-release.jks | pbcopy
```

Android demandera éventuellement à l'utilisateur d'autoriser l'installation depuis le navigateur ou le gestionnaire de fichiers. C'est normal pour une distribution APK directe hors Play Store.

## Responsive

- Mobile : navigation basse, caisse en flux vertical avec joueurs, articles puis panier.
- Tablette : navigation latérale, caisse en trois panneaux joueurs / produits / panier.
- Les grilles utilisent des largeurs maximales et des ruptures de layout pour éviter les débordements.
