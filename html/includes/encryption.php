<?php
/**
 * Encrypts a field using AES-256-GCM
 */
function encryptField($data) {
    if (empty($data)) return null;
    
    $key = getenv('KYC_ENCRYPTION_KEY') ?: 'HBMS_SUPER_SECRET_KEY_123';
    // Ensure key is exactly 32 bytes for AES-256
    $key = hash('sha256', $key, true);
    
    $cipher = "aes-256-gcm";
    $ivlen = openssl_cipher_iv_length($cipher);
    $iv = openssl_random_pseudo_bytes($ivlen);
    
    $ciphertext = openssl_encrypt($data, $cipher, $key, $options=OPENSSL_RAW_DATA, $iv, $tag);
    
    // Prepend IV and Tag to the ciphertext so we can decrypt it later
    return $iv . $tag . $ciphertext;
}

/**
 * Computes a deterministic "blind index" (hash) for a field
 * This allows us to search for duplicate passport numbers without decrypting them.
 */
function computeBlindIndex($data) {
    if (empty($data)) return null;
    
    $key = getenv('KYC_ENCRYPTION_KEY') ?: 'HBMS_SUPER_SECRET_KEY_123';
    // Use HMAC with SHA-256 to create a blind index
    return hash_hmac('sha256', strtoupper(trim($data)), $key);
}
?>
