-- Migration V003: Making things a bit cleaner
-- Just a quick update to tighten some constraints we missed earlier.

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

-- 1. Turning auth_method into an ENUM. 
-- It's better than a string because it stops us from accidentally typing 'Local' or 'Gogle'.
-- Valid options are: local (password), oauth (social), or both (linked).

ALTER TABLE `tbluser`
  MODIFY COLUMN `auth_method`
    ENUM('local', 'oauth', 'both')
    NOT NULL
    DEFAULT 'local';

-- 2. Cleaning up after ourselves.
-- We're adding "ON DELETE CASCADE" to the OAuth links table.
-- This means if we delete a user, we don't have to manually delete their social links too.

-- We check if the foreign key is already there before we try to mess with it.
SET @fk_exists := (
  SELECT COUNT(*)
  FROM information_schema.KEY_COLUMN_USAGE
  WHERE TABLE_SCHEMA    = DATABASE()
    AND TABLE_NAME      = 'tbl_oauth_links'
    AND CONSTRAINT_NAME = 'fk_oauth_links_user'
    AND REFERENCED_TABLE_NAME IS NOT NULL
);

SET @drop_fk := IF(@fk_exists > 0, 'ALTER TABLE `tbl_oauth_links` DROP FOREIGN KEY `fk_oauth_links_user`','SELECT 1');
PREPARE stmt FROM @drop_fk; EXECUTE stmt; DEALLOCATE PREPARE stmt;

-- Now add it back with the CASCADE rule.
ALTER TABLE `tbl_oauth_links`
  ADD CONSTRAINT `fk_oauth_links_user`
    FOREIGN KEY (`UserID`)
    REFERENCES `tbluser` (`ID`)
    ON DELETE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;
