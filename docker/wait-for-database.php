<?php

$url = getenv('DATABASE_URL');
if ($url === false || $url === '') {
    exit(0);
}

$parts = parse_url($url);
if ($parts === false || !isset($parts['host'])) {
    fwrite(STDERR, "Invalid DATABASE_URL\n");
    exit(1);
}

$host = $parts['host'];
$port = $parts['port'] ?? 3306;
$dbname = ltrim($parts['path'] ?? '', '/');
$user = $parts['user'] ?? '';
$pass = $parts['pass'] ?? '';

echo "Connecting to database at {$host}:{$port}...\n";

$dsn = "mysql:host={$host};port={$port};dbname={$dbname};charset=utf8mb4";

try {
    new PDO($dsn, $user, $pass, [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_TIMEOUT => 5,
    ]);
    echo "Database connection OK.\n";
    exit(0);
} catch (Throwable $e) {
    fwrite(STDERR, $e->getMessage() . "\n");
    exit(1);
}
