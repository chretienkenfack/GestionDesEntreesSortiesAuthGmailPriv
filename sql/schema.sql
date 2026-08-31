-- Schéma de référence pour l'application de gestion des entrées / sorties
-- À exécuter sur chaque instance MySQL/MariaDB que l'application doit pouvoir cibler
-- (via l'onglet Paramètres -> adresse IP de la base de données).

CREATE DATABASE IF NOT EXISTS gestion_finances CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestion_finances;

CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(150) NOT NULL,
  email VARCHAR(150) NOT NULL UNIQUE,
  password_hash VARCHAR(255) NULL,
  role ENUM('admin', 'agent') NOT NULL DEFAULT 'agent',
  auth_provider VARCHAR(20) NOT NULL DEFAULT 'local',
  google_id VARCHAR(255) NULL UNIQUE,
  photo_url VARCHAR(500) NULL,
  actif TINYINT(1) NOT NULL DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS categories (
  id INT AUTO_INCREMENT PRIMARY KEY,
  nom VARCHAR(100) NOT NULL,
  type ENUM('entree', 'sortie') NOT NULL
);

CREATE TABLE IF NOT EXISTS entrees (
  id INT AUTO_INCREMENT PRIMARY KEY,
  date_operation DATE NOT NULL,
  montant DECIMAL(14,2) NOT NULL,
  categorie_id INT NULL,
  description VARCHAR(255),
  mode_paiement ENUM('espece','virement','cheque','mobile_money','autre') NOT NULL DEFAULT 'espece',
  user_id INT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE IF NOT EXISTS sorties (
  id INT AUTO_INCREMENT PRIMARY KEY,
  date_operation DATE NOT NULL,
  montant DECIMAL(14,2) NOT NULL,
  categorie_id INT NULL,
  description VARCHAR(255),
  mode_paiement ENUM('espece','virement','cheque','mobile_money','autre') NOT NULL DEFAULT 'espece',
  user_id INT NOT NULL,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (categorie_id) REFERENCES categories(id) ON DELETE SET NULL,
  FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Catégories de base
INSERT INTO categories (nom, type) VALUES
  ('Vente de produits', 'entree'),
  ('Prestation de service', 'entree'),
  ('Autre recette', 'entree'),
  ('Loyer', 'sortie'),
  ('Salaires', 'sortie'),
  ('Fournitures', 'sortie'),
  ('Transport', 'sortie'),
  ('Autre dépense', 'sortie');

-- Compte admin par défaut : email admin@entreprise.cm / mot de passe "admin123"
-- (le hash correspond à SHA-256("admin123") -- à changer immédiatement après la première connexion)
INSERT INTO users (nom, email, password_hash, role) VALUES
  ('Administrateur', 'admin@entreprise.cm', '240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a', 'admin');
