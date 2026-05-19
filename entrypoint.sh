#!/bin/sh
set -e

APP_ENV="${APP_ENV:-prod}"

if [ -n "$DATABASE_URL" ]; then
    echo "Waiting for database to become available..."
    until php -r '
        $url = getenv("DATABASE_URL");
        if (!$url) { exit(0); }
        $p = parse_url($url);
        $host = $p["host"] ?? "127.0.0.1";
        $port = $p["port"] ?? 3306;
        $s = @fsockopen($host, $port);
        if ($s) { fclose($s); exit(0); }
        exit(1);
    '; do
        sleep 2
    done
    echo "Database is ready."
fi

echo "Running Symfony Production Optimizations..."
php bin/console cache:clear --env="$APP_ENV" --no-debug
php bin/console cache:warmup --env="$APP_ENV"

echo "Compiling frontend assets..."
php bin/console importmap:install --env="$APP_ENV"
php bin/console asset-map:compile --env="$APP_ENV"

echo "Running Database Migrations..."
php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --env="$APP_ENV"

echo "Starting PHP-FPM..."
if command -v nginx >/dev/null 2>&1; then
    php-fpm -D
    echo "Starting Nginx..."
    exec nginx -g "daemon off;"
else
    exec php-fpm -F
fi
