-- Migration V001: Getting OAuth Ready
-- This script sets up the user table for social logins (Google/Microsoft).
-- We're adding columns to track how users log in and store their profile info.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- Adding columns to tbluser. 
-- Since MySQL 8 doesn't have "ADD COLUMN IF NOT EXISTS", we use this little trick
-- with information_schema to make sure we don't try to add them twice.

-- 1. How the user logs in (local, oauth, or both)
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'auth_method');
SET @sql := IF(@col = 0, "ALTER TABLE `tbluser` ADD COLUMN `auth_method` VARCHAR(20) NOT NULL DEFAULT 'local' AFTER `Password`","SELECT 1");
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 2. Which provider (google/microsoft)
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'oauth_provider');
SET @sql := IF(@col = 0, 'ALTER TABLE `tbluser` ADD COLUMN `oauth_provider` VARCHAR(20) DEFAULT NULL AFTER `auth_method`','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 3. Their unique ID from the provider
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'oauth_id');
SET @sql := IF(@col = 0, 'ALTER TABLE `tbluser` ADD COLUMN `oauth_id` VARCHAR(255) DEFAULT NULL AFTER `oauth_provider`','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 4. Date of Birth (useful for KYC later)
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'DateOfBirth');
SET @sql := IF(@col = 0, 'ALTER TABLE `tbluser` ADD COLUMN `DateOfBirth` DATE DEFAULT NULL AFTER `oauth_id`','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 5. Profile picture URL from social media
SET @col := (SELECT COUNT(*) FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'ProfilePhoto');
SET @sql := IF(@col = 0, 'ALTER TABLE `tbluser` ADD COLUMN `ProfilePhoto` VARCHAR(500) DEFAULT NULL AFTER `DateOfBirth`','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Add indexes so searches are faster
SET @idx := (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND INDEX_NAME = 'idx_tbluser_email');
SET @sql := IF(@idx = 0, 'ALTER TABLE `tbluser` ADD KEY `idx_tbluser_email` (`Email`)','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @idx := (SELECT COUNT(*) FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND INDEX_NAME = 'idx_tbluser_oauth');
SET @sql := IF(@idx = 0, 'ALTER TABLE `tbluser` ADD KEY `idx_tbluser_oauth` (`oauth_provider`, `oauth_id`)','SELECT 1');
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Table to link external accounts to our users
CREATE TABLE IF NOT EXISTS `tbl_oauth_links` (
  `ID`             INT          NOT NULL AUTO_INCREMENT,
  `UserID`         INT          NOT NULL,
  `Provider`       VARCHAR(20)  NOT NULL,
  `ProviderUserID` VARCHAR(255) NOT NULL,
  `ProviderEmail`  VARCHAR(200) DEFAULT NULL,
  `EmailVerified`  TINYINT(1)   NOT NULL DEFAULT '0',
  `LinkedAt`       TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `uniq_user_provider` (`UserID`, `Provider`),
  KEY `idx_provider_lookup` (`Provider`, `ProviderUserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tokens for when an OAuth user wants to set a local password
CREATE TABLE IF NOT EXISTS `tbl_password_set_tokens` (
  `ID`        INT      NOT NULL AUTO_INCREMENT,
  `Token`     CHAR(64) NOT NULL,
  `UserID`    INT      NOT NULL,
  `ExpiresAt` DATETIME NOT NULL,
  `UsedAt`    DATETIME DEFAULT NULL,
  `CreatedAt` TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Token` (`Token`),
  KEY `idx_user` (`UserID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Tokens for verifying email before linking accounts
CREATE TABLE IF NOT EXISTS `tbl_email_verifications` (
  `ID`             INT          NOT NULL AUTO_INCREMENT,
  `Token`          CHAR(64)     NOT NULL,
  `UserID`         INT          NOT NULL,
  `Provider`       VARCHAR(20)  NOT NULL,
  `ProviderUserID` VARCHAR(255) NOT NULL,
  `ProviderEmail`  VARCHAR(200) NOT NULL,
  `EmailVerified`  TINYINT(1)   NOT NULL DEFAULT '0',
  `FullName`       VARCHAR(200) DEFAULT NULL,
  `PhotoPath`      VARCHAR(500) DEFAULT NULL,
  `DateOfBirth`    DATE         DEFAULT NULL,
  `ExpiresAt`      DATETIME     NOT NULL,
  `UsedAt`         DATETIME     DEFAULT NULL,
  `CreatedAt`      TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Token` (`Token`),
  KEY `idx_user_provider` (`UserID`, `Provider`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

SET FOREIGN_KEY_CHECKS = 1;
