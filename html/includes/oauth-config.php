<?php
// Load .env file
$envFile = __DIR__ . '/.env';
if (file_exists($envFile)) {
    $lines = file($envFile, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    foreach ($lines as $line) {
        if (str_starts_with(trim($line), '#')) continue;
        [$key, $value] = explode('=', $line, 2);
        $_ENV[trim($key)] = trim($value);
    }
}

define('MICROSOFT_CLIENT_ID',     $_ENV['MICROSOFT_CLIENT_ID']);
define('MICROSOFT_CLIENT_SECRET', $_ENV['MICROSOFT_CLIENT_SECRET']);
define('MICROSOFT_REDIRECT_URI',  $_ENV['MICROSOFT_REDIRECT_URI']);
define('MICROSOFT_TENANT',        $_ENV['MICROSOFT_TENANT']);

define('GOOGLE_CLIENT_ID',        $_ENV['GOOGLE_CLIENT_ID']);
define('GOOGLE_CLIENT_SECRET',    $_ENV['GOOGLE_CLIENT_SECRET']);
define('GOOGLE_REDIRECT_URI',     $_ENV['GOOGLE_REDIRECT_URI']);
