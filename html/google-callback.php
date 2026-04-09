<?php
session_start();
error_reporting(E_ALL);
ini_set('display_errors', 1);

require_once 'includes/dbconnection.php';
require_once 'includes/oauth-config.php';
require_once 'vendor/autoload.php';

$provider = new League\OAuth2\Client\Provider\Google([
    'clientId'     => GOOGLE_CLIENT_ID,
    'clientSecret' => GOOGLE_CLIENT_SECRET,
    'redirectUri'  => GOOGLE_REDIRECT_URI,
]);

// Step 1: No code yet — redirect user to Google login
if (!isset($_GET['code'])) {
    $authUrl = $provider->getAuthorizationUrl([
        'scope' => ['openid', 'profile', 'email'],
    ]);
    $_SESSION['oauth2state'] = $provider->getState();
    header('Location: ' . $authUrl);
    exit;
}

// Step 2: Validate state to prevent CSRF
if (empty($_GET['state']) || $_GET['state'] !== $_SESSION['oauth2state']) {
    unset($_SESSION['oauth2state']);
    exit('Invalid OAuth state. Please try again.');
}
unset($_SESSION['oauth2state']);

// Step 3: Exchange code for access token
try {
    $token = $provider->getAccessToken('authorization_code', [
        'code' => $_GET['code'],
    ]);
} catch (Exception $e) {
    exit('Failed to get access token: ' . $e->getMessage());
}

// Step 4: Get user profile from Google
try {
    $googleUser = $provider->getResourceOwner($token);
} catch (Exception $e) {
    exit('Failed to get user profile: ' . $e->getMessage());
}

$oauthId  = $googleUser->getId();
$email    = $googleUser->getEmail()    ?? '';
$fullName = $googleUser->getName()     ?? '';
$photoUrl = $googleUser->getAvatar()   ?? null;

if (empty($email)) {
    exit('Could not retrieve email from Google account.');
}

// Step 5: Save profile photo locally
$photoPath = null;
if ($photoUrl) {
    try {
        $photoDir = __DIR__ . '/images/oauth/';
        if (!is_dir($photoDir)) {
            mkdir($photoDir, 0755, true);
        }
        $photoFilename = 'google_' . $oauthId . '.jpg';
        $photoData = file_get_contents($photoUrl);
        if ($photoData !== false) {
            file_put_contents($photoDir . $photoFilename, $photoData);
            $photoPath = 'images/oauth/' . $photoFilename;
        }
    } catch (Exception $e) {
        $photoPath = null;
    }
}

// Step 6: Check if user already exists by oauth_id or email
$stmt = $dbh->prepare("SELECT ID FROM tbluser WHERE oauth_id = :oid OR Email = :email LIMIT 1");
$stmt->execute([':oid' => $oauthId, ':email' => $email]);
$existing = $stmt->fetch(PDO::FETCH_OBJ);

if ($existing) {
    // Returning user — update profile data (sync on re-login)
    $upd = $dbh->prepare("UPDATE tbluser SET
        FullName       = COALESCE(NULLIF(:name, ''), FullName),
        ProfilePhoto   = COALESCE(:photo,            ProfilePhoto),
        oauth_id       = :oid,
        oauth_provider = 'google'
        WHERE ID = :id");
    $upd->execute([
        ':name'  => $fullName,
        ':photo' => $photoPath,
        ':oid'   => $oauthId,
        ':id'    => $existing->ID,
    ]);
    $_SESSION['hbmsuid'] = $existing->ID;
    $_SESSION['login']   = $email;
} else {
    // New user — auto-register
    $ins = $dbh->prepare("INSERT INTO tbluser (FullName, Email, Password, oauth_provider, oauth_id, ProfilePhoto)
                          VALUES (:name, :email, '', 'google', :oid, :photo)");
    $ins->execute([
        ':name'  => $fullName,
        ':email' => $email,
        ':oid'   => $oauthId,
        ':photo' => $photoPath,
    ]);
    $_SESSION['hbmsuid'] = $dbh->lastInsertId();
    $_SESSION['login']   = $email;
}

header('Location: index.php');
exit;
