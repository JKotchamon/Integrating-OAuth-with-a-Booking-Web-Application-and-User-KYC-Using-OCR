<?php
session_start();
require_once 'includes/auth_check.php';
require_once 'includes/dbconnection.php';
require_once 'includes/encryption.php';

$uid = $_SESSION['hbmsuid'];

// 1. Get OAuth name from tbluser
$q = $dbh->prepare('SELECT FullName FROM tbluser WHERE ID=:uid');
$q->execute([':uid' => $uid]);
$oauthName = trim($q->fetchColumn() ?? '');

// 2. Get confirmed OCR data from kyc-verify.php form
$passportName   = strtoupper(trim($_POST['passport_name']   ?? ''));
$passportDOB    = trim($_POST['passport_dob']    ?? '');
$passportNumber = strtoupper(trim($_POST['passport_number'] ?? ''));
$nationality    = trim($_POST['nationality']    ?? '');
$expiryDate     = trim($_POST['expiry_date']    ?? '');

// Basic sanity
if ($passportName === '' || $passportNumber === '') {
    header('Location: kyc-verify.php');
    exit;
}

// 3. 3-Tier Fuzzy Name Match (Levenshtein distance)
$oauthUpper = strtoupper($oauthName);
$maxLen     = max(strlen($oauthUpper), strlen($passportName));
$distance   = levenshtein($oauthUpper, $passportName);
$matchScore = ($maxLen > 0) ? (1 - $distance / $maxLen) * 100 : 0;

if ($matchScore >= 85) {
    // Tier 1: Auto-Approve
    $newStatus = 'verified';
    $mismatch  = null;
    $dbh->prepare('UPDATE tbluser SET FullName=:n WHERE ID=:uid')
        ->execute([':n' => $passportName, ':uid' => $uid]);
} elseif ($matchScore >= 40) {
    // Tier 2: Admin Review
    $newStatus = 'pending';
    $mismatch  = 'Score:' . round($matchScore, 1) . '% | OAuth:' . $oauthName . ' | Passport:' . $passportName;
} else {
    // Tier 3: Hard Block
    $newStatus = 'rejected';
    $mismatch  = 'HARD BLOCK Score:' . round($matchScore, 1) . '% | OAuth:' . $oauthName . ' | Passport:' . $passportName;
}

// 3.1 Age Check (Must be 18+)
if ($newStatus !== 'rejected' && !empty($passportDOB)) {
    $dob = new DateTime($passportDOB);
    $now = new DateTime();
    $age = $now->diff($dob)->y;
    if ($age < 18) {
        $newStatus = 'rejected';
        $mismatch = 'REJECTED: User is under 18 years old (Age: ' . $age . ')';
    }
}

// 4. Calculate KYC expiry
$twoYears  = date('Y-m-d', strtotime('+2 years'));
$kycExpiry = (!empty($expiryDate) && $expiryDate < $twoYears) ? $expiryDate : $twoYears;

// 5. Encrypt sensitive fields
$nameEnc   = encryptField($passportName);
$dobEnc    = encryptField($passportDOB);
$numEnc    = encryptField($passportNumber);
$blindHash = computeBlindIndex($passportNumber);

// 6. Handle Temporary Image Lifecycle
$sessionTempFile = 'uploads/kyc_temp/sess_' . session_id() . '.jpg';
$finalImagePath = null;

if ($newStatus === 'pending') {
    // Keep it for admin review
    $tempName = bin2hex(random_bytes(16)) . '.jpg';
    $finalPath = 'uploads/kyc_temp/' . $tempName;
    if (file_exists($sessionTempFile)) {
        rename($sessionTempFile, $finalPath);
        $finalImagePath = $tempName;
    }
} else {
    // Auto-verified or Hard Blocked -> Delete image immediately
    if (file_exists($sessionTempFile)) {
        unlink($sessionTempFile);
    }
}

// 7. Get version number
$vq = $dbh->prepare('SELECT MAX(version) FROM tbl_kyc_records WHERE user_id=:uid');
$vq->execute([':uid' => $uid]);
$ver = (int)($vq->fetchColumn() ?? 0) + 1;

// 8. Mark all previous records as not current
$dbh->prepare('UPDATE tbl_kyc_records SET is_current=0 WHERE user_id=:uid')
    ->execute([':uid' => $uid]);

// 9. Insert new versioned row
$log = $dbh->prepare(
    'INSERT INTO tbl_kyc_records (user_id,version,is_current,verification_status,
        full_name_encrypted,date_of_birth_enc,document_number_enc,
        document_number_hash,nationality,expiry_date,name_match_score,rejection_reason,temp_image_path)
     VALUES (:uid,:ver,1,:st,:pne,:dobe,:numenc,:hash,:nat,:exp,:score,:md,:ipath)'
);
$log->execute([
    ':uid'    => $uid,
    ':ver'    => $ver,
    ':st'     => $newStatus,
    ':pne'    => $nameEnc,
    ':dobe'   => $dobEnc,
    ':numenc' => $numEnc,
    ':hash'   => $blindHash,
    ':nat'    => $nationality,
    ':exp'    => !empty($expiryDate) ? $expiryDate : null,
    ':score'  => $matchScore,
    ':md'     => $mismatch,
    ':ipath'  => $finalImagePath,
]);

// 9. Update tbluser
$upd = $dbh->prepare(
    'UPDATE tbluser SET kyc_status=:s, kyc_verified_at=IF(:s="verified", NOW(), kyc_verified_at),
            kyc_expiry_date=:exp WHERE ID=:uid'
);
$upd->execute([':s' => $newStatus, ':exp' => $kycExpiry, ':uid' => $uid]);

header('Location: kyc-status.php');
exit;
?>
