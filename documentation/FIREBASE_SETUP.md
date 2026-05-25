# Configuration Firebase

L'app est prête pour Firebase Auth + Cloud Firestore, mais les identifiants du projet doivent être générés depuis Firebase.

## 1. Créer le projet Firebase

1. Créer un projet dans la console Firebase.
2. Activer Authentication > Sign-in method > Email/Password.
3. Créer au moins un utilisateur email/mot de passe.
4. Activer Firestore Database.

## 2. Brancher Android et Windows

Depuis la racine du projet :

```sh
dart pub global activate flutterfire_cli
flutterfire configure --platforms=android,windows
```

Sélectionner le projet Firebase créé. Cette commande remplacera `lib/firebase_options.dart` par les vraies clés.

L'app Android utilise le package :

```txt
com.fragsaddicts.caisse
```

## 3. Règles Firestore

Pour une première version privée, utiliser des règles strictes avec authentification obligatoire :

```txt
rules_version = '2';

service cloud.firestore {
  match /databases/{database}/documents {
    match /organizations/frags-addicts/users/{userId}/snapshots/{snapshotId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;
    }
  }
}
```

## 4. Modèle de synchronisation

L'app synchronise manuellement un snapshot complet SQLite par utilisateur dans :

```txt
organizations/frags-addicts/users/{uid}/snapshots/caisse-main
```

Si le snapshot distant est plus recent, l'app demande confirmation et exporte
une copie de securite locale avant toute restauration. Le secret HelloAsso
n'est ni exporte ni synchronise.
