# Gestion des Entrées / Sorties — Application Flutter

Application de gestion des entrées (recettes) et sorties (dépenses) de
l'entreprise : CRUD complet, exports PDF mensuels/annuels, authentification,
et configuration de la base de données par adresse IP.

> Interface entièrement en **français** pour cette première version.
> Le code source (variables, commentaires) est en anglais/français mixte
> mais les textes et libellés que voit l'utilisateur, ainsi que les
> documents PDF générés, sont en français.

## Fonctionnalités

- **Authentification** :
  - Connexion par e-mail / mot de passe (rôles `admin` et `agent`).
  - **Inscription libre** (bouton "S'inscrire" depuis l'écran de connexion) : tout nouveau compte est créé avec le rôle `agent`.
  - **Connexion / inscription avec un compte Google** : si l'e-mail Google n'existe pas encore, un compte `agent` est créé automatiquement.
  - Seul un administrateur accède aux Paramètres.
- **CRUD des entrées** et **CRUD des sorties** (deux tables distinctes),
  avec filtrage par mois, catégories, mode de paiement.
- **Export PDF** :
  - Liste des entrées du mois
  - Liste des sorties du mois
  - Balance (solde) du mois ou de l'année
- **Onglet Paramètres** (admin uniquement) : modification de l'adresse
  IP / port / identifiants de la base de données, avec bouton
  "Tester la connexion" avant enregistrement — permet de brancher
  l'application sur différentes bases de données sans recompiler.

## Structure du projet

```
lib/
  main.dart                     Point d'entrée + routes + protection des routes
  models/                       Modèles de données (User, Mouvement, DbSettings, Categorie)
  services/                     Accès base de données, authentification, PDF, paramètres
  providers/                    Gestion d'état (AuthProvider)
  screens/                      Écrans (login, dashboard, entrées, sorties, rapports, paramètres)
  widgets/                      Composants réutilisables (drawer, formulaires, liste)
  theme/                        Thème visuel de l'application
  utils/                        Constantes, validateurs, formatage
sql/
  schema.sql                    Script de création des tables MySQL/MariaDB
pubspec.yaml                    Dépendances Flutter
```

## Prérequis

- Flutter SDK ≥ 3.19 (Dart ≥ 3.0)
- Un serveur MySQL ou MariaDB accessible par IP (local ou distant)

## Installation

1. Installer les dépendances :
   ```bash
   flutter pub get
   ```

2. Créer la base de données à partir du script fourni :
   ```bash
   mysql -h <adresse_ip> -u <utilisateur> -p < sql/schema.sql
   ```
   Ce script crée les tables (`users`, `categories`, `entrees`, `sorties`)
   et un compte administrateur par défaut :
   - E-mail : `admin@entreprise.cm`
   - Mot de passe : `admin123`

   ⚠️ Changez ce mot de passe dès la première connexion.

   **Si votre base existe déjà** (créée avant l'ajout de l'inscription et
   de la connexion Google), exécutez plutôt le script de migration :
   ```bash
   mysql -h <adresse_ip> -u <utilisateur> -p gestion_finances < sql/migration_auth.sql
   ```
   Avec WAMP : ouvrez phpMyAdmin → sélectionnez la base `gestion_finances`
   → onglet **SQL** → collez le contenu de `sql/migration_auth.sql` → **Exécuter**.

3. Lancer l'application :
   ```bash
   flutter run
   ```

4. À la première ouverture, l'application utilise une configuration de
   base de données par défaut (`127.0.0.1:3306`). Connectez-vous, puis
   allez dans **Paramètres** pour saisir l'adresse IP réelle de votre
   base de données, tester la connexion, puis l'enregistrer.

## Notes techniques

- La connexion à la base de données est gérée par `DbService`
  (singleton), qui relit les paramètres enregistrés (`SettingsService`,
  basé sur `shared_preferences`) et rouvre automatiquement la connexion
  si l'adresse IP, le port ou les identifiants changent.
- Les mots de passe utilisateurs sont stockés sous forme de hash SHA-256
  (`AuthService`). Pour une mise en production, il est recommandé de
  passer à un hachage salé (bcrypt/argon2) via une API backend dédiée
  plutôt qu'une connexion directe de l'application à la base de données.
- Les PDF sont générés avec les packages `pdf` et `printing`, ce qui
  permet un aperçu, une impression ou un enregistrement direct depuis
  l'application (desktop, mobile ou web).

## Prochaines évolutions possibles

- Gestion des utilisateurs depuis l'interface (ajout/désactivation)
- Graphiques de tendance (entrées/sorties par mois)
- Traduction multilingue (l'app est actuellement figée en français)
- Passage à une API backend sécurisée plutôt qu'une connexion directe
  à MySQL depuis le client
