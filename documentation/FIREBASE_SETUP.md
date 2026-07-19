# Configuration Firebase

Ce document est la reference technique pour brancher l'application a Firebase.
Pour le guide complet destine a une association, consulter aussi
[`MISE_EN_PLACE.md`](MISE_EN_PLACE.md).

Firebase est optionnel. Sans Firebase, la caisse continue de fonctionner avec
sa base locale.

## 1. Comprendre les deux informations demandees

L'activation utilise deux elements differents :

- la **configuration du projet** (`firebaseConfig` ou `google-services.json`)
  indique a l'application quel projet Firebase utiliser ;
- le **compte utilisateur** (email et mot de passe) autorise l'acces aux
  donnees de ce projet.

La configuration du projet contient des identifiants techniques, mais pas le
mot de passe du compte. L'application regroupe les deux etapes dans un seul
parcours **Activer Firebase**.

Chaque association doit utiliser son propre projet Firebase. Pour la V1, il
est recommande de creer un seul compte utilisateur partage par les appareils
autorises de l'association.

## 2. Creer le projet Firebase

1. Ouvrir la [console Firebase](https://console.firebase.google.com/).
2. Cliquer sur **Ajouter un projet**.
3. Saisir un nom, par exemple `caisse-mon-association`.
4. Desactiver Google Analytics si l'association n'en a pas besoin.
5. Terminer la creation du projet.

Le nom visible et le `projectId` peuvent etre differents. Le `projectId` est
genere par Firebase et ne peut plus etre change apres la creation.

## 3. Activer Email/Mot de passe

1. Dans le menu Firebase, ouvrir **Security > Authentication**.
2. Cliquer sur **Commencer** si necessaire.
3. Ouvrir l'onglet **Sign-in method**.
4. Selectionner **Email/Password**.
5. Activer le premier interrupteur Email/Password puis enregistrer.

Documentation officielle :
[authentification Flutter par mot de passe](https://firebase.google.com/docs/auth/flutter/password-auth).

## 4. Creer le compte utilisateur

1. Ouvrir **Authentication > Users**.
2. Cliquer sur **Ajouter un utilisateur**.
3. Saisir l'email utilise par l'association.
4. Choisir un mot de passe fort et l'enregistrer dans un gestionnaire de mots
   de passe.

Tous les appareils qui doivent partager les memes donnees utilisent ce meme
compte. Deux comptes Firebase differents disposent de deux espaces de donnees
separes.

## 5. Creer Cloud Firestore

1. Ouvrir **Databases & Storage > Firestore Database**.
2. Cliquer sur **Creer une base de donnees**.
3. Choisir le mode production.
4. Choisir une region proche de l'association.
5. Conserver la base `(default)` puis terminer la creation.

## 6. Publier les regles Firestore

1. Dans Firestore Database, ouvrir l'onglet **Rules**.
2. Remplacer le contenu de l'editeur par les regles suivantes :

```txt
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /organizations/default/users/{userId}/snapshots/{snapshotId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId
                         && snapshotId in ['caisse-main', 'caisse-dev'];
    }
  }
}
```

3. Cliquer sur **Publier**.
4. Attendre une minute avant le premier essai si l'ancienne regle vient d'etre
   remplacee.

Le mot `default` dans `organizations/default/users` est une valeur litterale
utilisee par Tilly. Il ne faut pas le remplacer par le nom du projet Firebase
ou de l'association.

Ces regles refusent les utilisateurs non connectes, limitent chaque compte a
son propre chemin et autorisent uniquement les snapshots `caisse-main` et
`caisse-dev`. Elles correspondent au fichier
[`../firestore.rules`](../firestore.rules). Firebase permet aussi de les
publier avec la CLI.

Documentation officielle :
[regles de securite Cloud Firestore](https://firebase.google.com/docs/firestore/security/get-started).

## 7. Ajouter l'application Android

Cette etape est necessaire pour l'APK Android.

1. Revenir a la vue d'ensemble du projet.
2. Cliquer sur **Ajouter une application**, puis sur l'icone Android.
3. Saisir exactement ce package Android :

```txt
com.tilly.caisse
```

4. Choisir un surnom libre, par exemple `Caisse Android`.
5. Laisser le certificat SHA vide : il n'est pas necessaire pour la connexion
   Email/Mot de passe utilisee ici.
6. Cliquer sur **Enregistrer l'application**.
7. Cliquer sur **Telecharger google-services.json**.

Pour cette application precompilee, il ne faut pas ajouter ce fichier au code
ni modifier Gradle. Ouvrir `google-services.json` avec un editeur de texte,
selectionner tout son contenu et le copier. Le contenu sera colle directement
dans l'application de caisse.

Le fichier peut etre telecharge a nouveau depuis **Parametres du projet >
General > Vos applications > Caisse Android**.

Documentation officielle :
[ajouter Firebase a Android](https://firebase.google.com/docs/android/setup).

## 8. Ajouter l'application Windows

Firebase ne propose pas d'icone Windows dans ce parcours. La version Windows
utilise la configuration d'une application Web.

1. Revenir a la vue d'ensemble du projet.
2. Cliquer sur **Ajouter une application**, puis sur l'icone Web `</>`.
3. Choisir un surnom libre, par exemple `Caisse Windows`.
4. Ne pas activer Firebase Hosting.
5. Cliquer sur **Enregistrer l'application**.
6. Dans le code affiche, reperer le bloc commencant par :

```js
const firebaseConfig = {
  apiKey: "...",
  authDomain: "...",
  projectId: "...",
  storageBucket: "...",
  messagingSenderId: "...",
  appId: "..."
};
```

7. Copier le bloc complet `firebaseConfig`. Il n'est pas necessaire d'executer
   les commandes `npm` affichees par Firebase.

Le bloc est aussi disponible dans **Parametres du projet > General > Vos
applications > Caisse Windows > Configuration du SDK**.

Documentation officielle :
[ajouter Firebase a une application Web](https://firebase.google.com/docs/web/setup).

## 9. Activer Firebase dans la caisse

Utiliser la configuration correspondant a l'appareil :

- sur Android, copier le contenu complet de `google-services.json` ;
- sur Windows, copier le bloc `firebaseConfig` de l'application Web.

Dans la caisse :

1. Ouvrir **Config > Firebase**.
2. Cliquer sur **Activer Firebase**.
3. Cliquer sur **Coller**, ou coller manuellement la configuration.
4. Saisir l'email et le mot de passe crees dans Authentication.
5. Cliquer sur **Activer**.
6. Lorsque l'etat indique **Synchronisation active**, cliquer sur
   **Synchroniser**.

La saisie separee de `apiKey`, `appId`, `messagingSenderId`, `projectId`,
`authDomain`, `storageBucket` et `measurementId` reste accessible dans
**Options avancees**.

Les parametres du projet sont conserves dans le stockage securise de
l'appareil. Ils ne sont inclus ni dans les sauvegardes JSON ni dans la
synchronisation Firebase.

## 10. Verifier la premiere synchronisation

Apres avoir clique sur **Synchroniser** :

1. verifier que l'application affiche **Donnees envoyees vers Firebase** ou
   **Donnees deja synchronisees** ;
2. dans Firebase Console, ouvrir **Firestore Database > Data** ;
3. verifier la presence du chemin :

```txt
organizations/default/users/{uid}/snapshots/caisse-main
```

Les builds de developpement utilisent `caisse-dev` afin de ne pas melanger
leurs donnees avec une version publiee.

La synchronisation est manuelle. Tilly compare la date de la version locale et
de la version Firebase : elle envoie le snapshot local complet lorsqu'il est le
plus recent, ou propose de remplacer les donnees locales lorsque Firebase
contient une version plus recente. Les modifications ne sont pas fusionnees
ligne par ligne.

## 11. Ajouter un deuxieme appareil

1. Installer l'application sur le deuxieme appareil.
2. Recuperer la configuration correspondant a sa plateforme. Un appareil
   Android utilise l'application Firebase Android ; Windows utilise
   l'application Firebase Web.
3. Ouvrir **Config > Firebase > Activer Firebase**.
4. Coller la configuration et utiliser le meme compte email/mot de passe.
5. Cliquer sur **Synchroniser**.
6. Si Firebase contient des donnees plus recentes, confirmer la restauration.
   L'application cree d'abord une sauvegarde locale de securite.

Ne pas modifier les donnees sur deux appareils en meme temps. Synchroniser
avant de changer d'appareil, effectuer les modifications sur un seul appareil,
puis synchroniser de nouveau avant de reprendre sur l'autre.

## 12. Erreurs courantes

### Configuration non reconnue

Le texte colle est incomplet ou ne correspond pas a un bloc `firebaseConfig`
ou a un fichier `google-services.json` complet. Copier a nouveau la source
depuis les parametres du projet Firebase.

### Email ou mot de passe incorrect

Verifier que :

- Email/Password est active dans **Authentication > Sign-in method** ;
- l'utilisateur existe dans **Authentication > Users** ;
- le mot de passe utilise est celui de ce compte Firebase.

### Acces Firestore refuse

Verifier que les regles de la section 6 ont ete collees puis **publiees dans le
projet Firebase configure dans Tilly**, et non dans le projet de monitoring.
Le chemin doit contenir exactement `organizations/default/users` : `default`
ne doit pas etre remplace par le nom de l'association.

### Aucune donnee sur le deuxieme appareil

Verifier que le premier appareil a deja effectue une synchronisation, que les
deux appareils utilisent le meme compte utilisateur et que chacun utilise la
configuration Firebase correspondant a sa plateforme.

### Mauvais projet Firebase

Dans **Config > Firebase**, utiliser l'icone de configuration pour changer de
projet. La reconfiguration deconnecte le compte actuel et demande de se
connecter au nouveau projet.

## 13. Securite et sauvegardes

- Les identifiants contenus dans `firebaseConfig` et `google-services.json` ne
  sont pas des mots de passe, mais ils doivent rester limites aux personnes qui
  administrent l'installation.
- Le mot de passe Firebase doit rester confidentiel.
- Ne jamais utiliser des regles Firestore ouvertes avec `allow read, write: if
  true` en production.
- Effectuer une sauvegarde JSON avant une restauration ou une intervention
  importante.
- Le secret HelloAsso n'est ni exporte dans les sauvegardes JSON ni synchronise
  dans Firebase.
