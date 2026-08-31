-- À exécuter dans ton interface SQL (ex: phpMyAdmin)
USE gestion_finances;

-- 1. Rajouter un identifiant unique (optionnel mais recommandé) pour lier le compte Google
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id VARCHAR(255) NULL UNIQUE;

-- 2. Autoriser les mots de passe à être NULS (pour les comptes créés via Google)
ALTER TABLE users MODIFY COLUMN password_hash VARCHAR(255) NULL;

-- 3. Autoriser les valeurs enum pour auth_provider (s'il s'agit d'un ENUM et non d'un VARCHAR)
-- Si ton auth_provider est déjà un VARCHAR, cette ligne est facultative mais ne fera pas de mal.
ALTER TABLE users MODIFY COLUMN auth_provider VARCHAR(50) NOT NULL DEFAULT 'local';
