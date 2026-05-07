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

## Responsive

- Mobile : navigation basse, caisse en flux vertical avec joueurs, articles puis panier.
- Tablette : navigation latérale, caisse en trois panneaux joueurs / produits / panier.
- Les grilles utilisent des largeurs maximales et des ruptures de layout pour éviter les débordements.
