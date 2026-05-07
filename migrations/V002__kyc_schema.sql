-- =============================================================================
-- Migration V002 — KYC schema
-- =============================================================================
-- Depends on: V001 (tbluser must have the OAuth columns already)
-- Baseline  : tbluser has no KYC columns; no KYC tables exist
-- Result    : tbluser gains kyc_status / kyc_verified_at / kyc_expiry_date;
--             three new tables are created for KYC records, audit log, and
--             booking risk flags.
--
-- SAFE TO RE-RUN: column additions are guarded by information_schema checks
--                 (MySQL 8.0 does not support ALTER TABLE ADD COLUMN IF NOT EXISTS)
-- =============================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- ---------------------------------------------------------------------------
-- 1. tbluser — add KYC status columns (MySQL 8.0 compatible guards)
-- ---------------------------------------------------------------------------

-- 1a. kyc_status
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'kyc_status'
);
SET @sql := IF(@col = 0,
  "ALTER TABLE `tbluser` ADD COLUMN `kyc_status` ENUM('unverified','pending','verified','rejected','expired') NOT NULL DEFAULT 'unverified' AFTER `ProfilePhoto`",
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1b. kyc_verified_at
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'kyc_verified_at'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE `tbluser` ADD COLUMN `kyc_verified_at` TIMESTAMP NULL DEFAULT NULL AFTER `kyc_status`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- 1c. kyc_expiry_date
SET @col := (
  SELECT COUNT(*) FROM information_schema.COLUMNS
  WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'tbluser' AND COLUMN_NAME = 'kyc_expiry_date'
);
SET @sql := IF(@col = 0,
  'ALTER TABLE `tbluser` ADD COLUMN `kyc_expiry_date` DATE NULL DEFAULT NULL AFTER `kyc_verified_at`',
  'SELECT 1'
);
PREPARE stmt FROM @sql; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- ---------------------------------------------------------------------------
-- 2. tbl_kyc_records — versioned, encrypted passport MRZ fields per attempt
--    Rows are NEVER deleted; old records are marked is_current=FALSE.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tbl_kyc_records` (
  `ID`                   INT          NOT NULL AUTO_INCREMENT,
  `user_id`              INT          NOT NULL,
  `version`              INT          NOT NULL DEFAULT 1,
  `is_current`           TINYINT(1)   NOT NULL DEFAULT 0,
  `document_type`        VARCHAR(10)  COLLATE utf8mb4_general_ci DEFAULT NULL,
  -- AES-256-GCM ciphertext stored as binary
  `full_name_encrypted`  VARBINARY(512)  DEFAULT NULL,
  `nationality`          VARCHAR(3)   COLLATE utf8mb4_general_ci DEFAULT NULL,
  `date_of_birth_enc`    VARBINARY(128)  DEFAULT NULL,
  `document_number_enc`  VARBINARY(128)  DEFAULT NULL,
  -- HMAC-SHA256 blind index for duplicate-passport detection (no plaintext stored)
  `document_number_hash` VARCHAR(64)  COLLATE utf8mb4_general_ci NOT NULL,
  `expiry_date`          DATE         DEFAULT NULL,
  `gender`               CHAR(1)      COLLATE utf8mb4_general_ci DEFAULT NULL,
  `issuing_country`      VARCHAR(3)   COLLATE utf8mb4_general_ci DEFAULT NULL,
  `verification_status`  ENUM('pending','verified','rejected','expired','superseded')
                                      NOT NULL DEFAULT 'pending',
  `verification_method`  VARCHAR(50)  COLLATE utf8mb4_general_ci DEFAULT NULL,
  `verified_at`          TIMESTAMP    NULL DEFAULT NULL,
  `verified_by`          VARCHAR(50)  COLLATE utf8mb4_general_ci DEFAULT NULL,
  `rejection_reason`     VARCHAR(500) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `mrz_checksum_valid`   TINYINT(1)   NOT NULL DEFAULT 0,
  `name_match_score`     DECIMAL(5,2) DEFAULT NULL,
  `created_at`           TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at`           TIMESTAMP    NULL DEFAULT NULL ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `idx_doc_hash`     (`document_number_hash`),
  KEY `idx_user_current` (`user_id`, `is_current`),
  CONSTRAINT `fk_kyc_records_user` FOREIGN KEY (`user_id`) REFERENCES `tbluser` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  COMMENT='Encrypted passport MRZ data — versioned, never deleted';

-- ---------------------------------------------------------------------------
-- 3. tbl_kyc_audit_log — immutable compliance audit trail
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tbl_kyc_audit_log` (
  `ID`         INT          NOT NULL AUTO_INCREMENT,
  `user_id`    INT          NOT NULL,
  `action`     VARCHAR(100) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `details`    TEXT         COLLATE utf8mb4_general_ci,
  `ip_address` VARCHAR(45)  COLLATE utf8mb4_general_ci DEFAULT NULL,
  `user_agent` VARCHAR(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at` TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `idx_audit_user` (`user_id`),
  CONSTRAINT `fk_kyc_audit_user` FOREIGN KEY (`user_id`) REFERENCES `tbluser` (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  COMMENT='Immutable audit log of all KYC events';

-- ---------------------------------------------------------------------------
-- 4. tbl_booking_risk_flags — automated risk flags evaluated at booking time
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS `tbl_booking_risk_flags` (
  `ID`          INT          NOT NULL AUTO_INCREMENT,
  `booking_id`  INT          NOT NULL,
  `user_id`     INT          NOT NULL,
  `risk_reason` VARCHAR(255) COLLATE utf8mb4_general_ci DEFAULT NULL,
  `created_at`  TIMESTAMP    NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`ID`),
  KEY `idx_risk_booking` (`booking_id`),
  KEY `idx_risk_user`    (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci
  COMMENT='Risk flags computed from KYC data at booking time';

SET FOREIGN_KEY_CHECKS = 1;

-- End of V002
