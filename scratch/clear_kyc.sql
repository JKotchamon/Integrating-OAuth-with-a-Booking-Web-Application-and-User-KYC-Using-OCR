SET FOREIGN_KEY_CHECKS = 0;

-- Clear KYC Tables
TRUNCATE TABLE tbl_kyc_records;
TRUNCATE TABLE tbl_kyc_audit_log;

-- Reset User Statuses
UPDATE tbluser SET 
    kyc_status = 'unverified', 
    kyc_verified_at = NULL, 
    kyc_expiry_date = NULL;

SET FOREIGN_KEY_CHECKS = 1;
