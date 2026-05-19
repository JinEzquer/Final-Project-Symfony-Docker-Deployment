#!/bin/sh
set -e

APP_ENV="${APP_ENV:-prod}"

wait_for_database() {
    if [ -z "$DATABASE_URL" ]; then
        echo "DATABASE_URL is not set — skipping database wait."
        return 0
    fi

    attempt=1
    max_attempts=60
    while [ "$attempt" -le "$max_attempts" ]; do
        if php /app/docker/wait-for-database.php; then
            return 0
        fi
        if [ $((attempt % 10)) -eq 0 ]; then
            echo "Still waiting for database (attempt ${attempt}/${max_attempts})..."
        else
            echo "Database not ready (attempt ${attempt}/${max_attempts}), retrying in 3s..."
        fi
        sleep 3
        attempt=$((attempt + 1))
    done

    echo "ERROR: Could not connect to the database after ${max_attempts} attempts."
    echo "Check on Railway:"
    echo "  1. MySQL service is Running (green)."
    echo "  2. Web service DATABASE_URL uses: \${{MySQL.MYSQL_URL}}"
    echo "     (service name must match your MySQL service — e.g. MySQL or mysql)"
    echo "  3. Or set: \${{MySQL.MYSQL_URL}}?serverVersion=8.0.32&charset=utf8mb4"
    echo "  4. Redeploy MySQL first, then the web service."
    exit 1
}

run_migrations() {
    attempt=1
    max_attempts=10
    while [ "$attempt" -le "$max_attempts" ]; do
        if php bin/console doctrine:migrations:migrate --no-interaction --allow-no-migration --env="$APP_ENV"; then
            return 0
        fi
        echo "Migrations failed (attempt ${attempt}/${max_attempts}), retrying in 5s..."
        sleep 5
        attempt=$((attempt + 1))
    done
    exit 1
}

wait_for_database

echo "Running Symfony Production Optimizations..."
php bin/console cache:clear --env="$APP_ENV" --no-debug
php bin/console cache:warmup --env="$APP_ENV"

echo "Compiling frontend assets..."
php bin/console importmap:install --env="$APP_ENV"
php bin/console asset-map:compile --env="$APP_ENV"

echo "Running Database Migrations..."
run_migrations

echo "Starting PHP-FPM..."
if command -v nginx >/dev/null 2>&1; then
    php-fpm -D
    echo "Starting Nginx..."
    exec nginx -g "daemon off;"
else
    exec php-fpm -F
fi
