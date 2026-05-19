FROM php:8.2-fpm-alpine

# 1. Install system dependencies AND nginx
RUN apk add --no-cache \
    nginx \
    icu-dev \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    git

# 2. Install PHP extensions required by Symfony & MySQL
RUN docker-php-ext-install \
    intl \
    pdo \
    pdo_mysql \
    zip \
    opcache

# 3. Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# 4. Set working directory
WORKDIR /app

# 5. Copy application files
COPY . /app

# 6. Configure Nginx (Copies your custom configs into the container)
COPY nginx.conf /etc/nginx/nginx.conf
COPY nginx-main.conf /etc/nginx/conf.d/default.conf

# 7. Install Composer dependencies for production
ENV COMPOSER_ALLOW_SUPERUSER=1
ENV APP_ENV=prod
ENV APP_DEBUG=0
RUN composer config platform-check false \
    && composer install --no-dev --optimize-autoloader --no-scripts --ignore-platform-reqs \
    && composer dump-env prod

# 8. Symfony var/ is gitignored — create dirs before chown (required for Railway build)
RUN mkdir -p /var/run/nginx /app/var/cache /app/var/log /app/public \
    && chown -R www-data:www-data /app/var /app/public

# 9. Expose port 80 for web traffic (Railway will route to this)
EXPOSE 80

# 10. Set up the entrypoint script
RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]