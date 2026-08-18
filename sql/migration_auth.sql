-- À exécuter UNE SEULE FOIS si votre base `gestion_finances` existe déjà
-- (créée avant l'ajout de l'inscription libre et de la connexion Google).
-- Sur phpMyAdmin (WAMP) : onglet SQL de la base gestion_finances, coller et exécuter.

USE gestion_finances;

ALTER TABLE users
  MODIFY password_hash VARCHAR(255) NULL,
  ADD COLUMN auth_provider ENUM('local', 'google') NOT NULL DEFAULT 'local' AFTER role,
  ADD COLUMN google_id VARCHAR(255) NULL UNIQUE AFTER auth_provider,
  ADD COLUMN photo_url VARCHAR(500) NULL AFTER google_id;
