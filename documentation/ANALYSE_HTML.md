# Analyse de `Base/caisse_airsoft.html`

## Fonctionnalités identifiées

- Caisse tactile avec sélection joueur, grille articles, catégories et panier.
- Joueurs publics ou adhérents, avec tarif adhérent automatique ou forcé depuis le panier.
- Gestion des ventes par ESP, PayPal et SumUp.
- Don libre ajouté au panier et tracé dans les bilans.
- Calcul du rendu monnaie en espèces avec proposition de coupures.
- Gestion du stock, alertes stock bas, rupture et consommation automatique billes/gaz sur les locations.
- Historique par joueur, ventes groupées, annulation de vente avec restauration du stock.
- Bilan de journée par paiement, total général, stock vendu et dons.
- Analyse de caisse espèces avec fond début, fond fin, théorique et écart.
- KPI achats/stock : ruptures, alertes, CA, rotation, suggestion de réapprovisionnement.
- Configuration articles : ajout, édition, suppression, prix public/adhérent, stock, seuil, type standard/location.
- Sauvegarde/restauration JSON, resets ventes/joueurs/stock.
- Exports HTML d'origine : XLSX et PDF pour bilan, joueurs, caisse et KPI.

## Style graphique du HTML

- Ambiance sombre opérationnelle : fond noir `#0d0d0d`, surfaces `#161616` / `#1e1e1e`, bordures fines `#2a2a2a`.
- Accent principal vert traceur `#c8f135` pour actions, totaux et états actifs.
- Accent secondaire cyan `#35c8f1` pour adhérent, dons et éléments analytiques.
- Rouge danger `#f13535`, orange alerte `#f1a035`, vert paiement espèces, bleu PayPal, violet SumUp.
- Typographie condensée, uppercase, très lisible en contexte terrain.
- Interface dense, tactile, en panneaux : joueurs, produits, panier, bilans.
- Cartes à rayon court, pas de grandes illustrations ni de style marketing.

## Identité visuelle définie

Nom : **Tilly**

Positionnement : caisse mobile/tablette pour événement airsoft, lisible en extérieur, rapide à manipuler, pensée pour éviter les erreurs de stock et de paiement.

Principes :

- Noir carbone pour réduire la fatigue visuelle.
- Vert traceur pour les actions primaires, totaux et sélection.
- Cyan instrumentation pour adhérents, dons et aide à la décision.
- Rouge/orange uniquement pour les risques : rupture, stock bas, annulation.
- Composants compacts, arrondis courts, bordures visibles, hiérarchie typographique forte.
- Navigation mobile en barre basse, navigation tablette en rail latéral.

## Traduction Flutter

Le projet Flutter reprend les pages principales :

- `Caisse` : joueurs, catégories, produits, panier, dons, paiements et rendu monnaie.
- `Joueurs` : historique par joueur et annulation/restauration de vente.
- `Bilan` : totaux par paiement, dons, stock vendu, export JSON presse-papiers.
- `Analyse` : comptage espèces début/fin et écart de caisse.
- `KPI` : ruptures, alertes, CA, rotation et suggestions de réapprovisionnement.
- `Config` : édition articles, resets et sauvegarde.

Différence assumée : les exports XLSX/PDF du HTML sont remplacés pour l'instant par un export JSON dans le presse-papiers, sans plugin lourd. Les écrans et la logique métier sont prêts à être étendus avec `pdf`, `printing` ou génération XLSX Flutter si nécessaire.

## Base locale implémentée

La persistance applicative est maintenant une base SQLite locale via `sqflite`. Le fichier `.db` est dans le stockage privé de l'application Android, donc il suit l'appareil ou l'émulateur utilisé.

Tables principales :

- `players`
- `articles`
- `sales`
- `sale_items`
- `stock_movements`
- `cash_counts`
- `cash_count_lines`
- `app_settings`

Le panier reste volontairement en mémoire : il représente une vente en cours, pas encore validée.
