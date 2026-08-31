-- Migration pour les bases existantes créées avant la suppression de Google Sign-In.
-- À exécuter UNE SEULE FOIS si votre base `gestion_finances` existe déjà.
-- Sur phpMyAdmin (WAMP/XAMPP) : onglet SQL de la base gestion_finances, coller et exécuter.

USE gestion_finances;

-- Suppression de la colonne google_id (plus utilisée)
ALTER TABLE users
  DROP COLUMN IF EXISTS google_id;

-- S'assurer que auth_provider existe (compatible avec les anciens schémas)
ALTER TABLE users
  MODIFY COLUMN auth_provider VARCHAR(20) NOT NULL DEFAULT 'local';

-- S'assurer que photo_url existe (reste utile pour un avatar local futur)
-- (rien à faire si la colonne est déjà présente)

-- Remettre password_hash à NOT NULL (les comptes Google avaient password_hash NULL)
-- ATTENTION : exécuter seulement si vous n'avez aucun compte Google dans la base.
-- ALTER TABLE users MODIFY password_hash VARCHAR(255) NOT NULL;
