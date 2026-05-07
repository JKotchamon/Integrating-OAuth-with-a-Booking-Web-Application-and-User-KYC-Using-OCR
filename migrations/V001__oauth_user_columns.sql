-- =============================================================================
-- Migration V001 — OAuth user columns + support tables
-- =============================================================================
-- Baseline: hbms_backup.sql  (tbluser has only 6 columns — no OAuth fields)
-- Result  : tbluser gains auth_method, oauth_provider, oauth_id, DateOfBirth,
--           ProfilePhoto; three new tables are created for OAuth linking, set-
--           password tokens, and email/account-link verification tokens.
--
-- SAFE TO RE-RUN: column additions are guarded by information_schema checks
--                 (MySQL 8.0 does not support ALTER TABLE ADD COLUMN IF NOT EXISTS)
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- Helper: add a column only if it doesn't already exist
-- Usage: execute a prepared statement that checks information_schema first
-- ---------------------------------------------------------------------------

-- 1a. auth_method
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'auth_method'
);
SET @sql := IF(@col = 0,
  "ALTER TABLE `tbluser` ADD COLUMN `auth_method` VARCHAR(20) COLLATE utf8mb4_general_ci NOT NULL DEFAULT 'local' AFTER `Password`",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1b. oauth_provider
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'oauth_provider'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE `tbluser` ADD COLUMN `oauth_provider` VARCHAR(20) COLLATE utf8mb4_general_ci DEFAULT NULL AFTER `auth_method`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1c. oauth_id
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'oauth_id'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE `tbluser` ADD COLUMN `oauth_id` VARCHAR(255) COLLATE utf8mb4_general_ci DEFAULT NULL AFTER `oauth_provider`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1d. DateOfBirth
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'DateOfBirth'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE `tbluser` ADD COLUMN `DateOfBirth` DATE DEFAULT NULL AFTER `oauth_id`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1e. ProfilePhoto
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'ProfilePhoto'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE `tbluser` ADD COLUMN `ProfilePhoto` VARCHAR(500) COLLATE utf8mb4_general_ci DEFAULT NULL AFTER `DateOfBirth`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. Indexes (guarded — MySQL errors on duplicate key names)
-- ---------------------------------------------------------------------------

SET @idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND INDEX_NAME = 'idx_tbluser_email'
);
SET @sql := IF(@idx = 0,
  'ALTER TABLE `tbluser` ADD KEY `idx_tbluser_email` (`Email`)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (
  SELECT COUNT(*) FROM information_schema.STATISTICS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND INDEX_NAME = 'idx_tbluser_oauth'
);
SET @sql := IF(@idx = 0,
  'ALTER TABLE `tbluser` ADD KEY `idx_tbluser_oauth` (`oauth_provider`, `oauth_id`)',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 3. tbl_oauth_links — one row per (user, provider) pair
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tbl_oauth_links` (
  `ID`             INT          NOT NULL AUTO_INCREMENT,
  `UserID`         INT          NOT NULL,
  `Provider`       VARCHAR(20)  COLLATE utf8mb4_general_ci NOT NULL,
  `ProviderUserID` VARCHAR(255) COLLATE utf8mb4_general_ci NOT NULL,
  `ProviderEmail`  VARCHAR(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `EmailVerified`  TINYINT(1)   NOT NULL DEFAULT '0',
  `LinkedAt`       TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uniq_user_provider` (`UserID`, `Provider`),
  KEY `idx_provider_lookup` (`Provider`, `ProviderUserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- 4. tbl_password_set_tokens — one-time tokens for OAuth → local password
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tbl_password_set_tokens` (
  `ID`        INT      NOT NULL AUTO_INCREMENT,
  `Token`     CHAR(64) COLLATE utf8mb4_general_ci NOT NULL,
  `UserID`    INT      NOT NULL,
  `ExpiresAt` DATETIME NOT NULL,
  `UsedAt`    DATETIME DEFAULT NULL,
  `CreatedAt` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Token` (`Token`),
  KEY `idx_user` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

-- ---------------------------------------------------------------------------
-- 5. tbl_email_verifications — consent tokens for Case 2 account linking
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tbl_email_verifications` (
  `ID`             INT          NOT NULL AUTO_INCREMENT,
  `Token`          CHAR(64)     COLLATE utf8mb4_general_ci NOT NULL,
  `UserID`         INT          NOT NULL,
  `Provider`       VARCHAR(20)  COLLATE utf8mb4_general_ci NOT NULL,
  `ProviderUserID` VARCHAR(255) COLLATE utf8mb4_general_ci NOT NULL,
  `ProviderEmail`  VARCHAR(200) COLLATE utf8mb4_general_ci NOT NULL,
  `EmailVerified`  TINYINT(1)   NOT NULL DEFAULT '0',
  `FullName`       VARCHAR(200) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `PhotoPath`      VARCHAR(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `DateOfBirth`    DATE                                    DEFAULT NULL,
  `ExpiresAt`      DATETIME NOT NULL,
  `UsedAt`         DATETIME DEFAULT NULL,
  `CreatedAt`      TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Token` (`Token`),
  KEY `idx_user_provider` (`UserID`, `Provider`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- End of V001
