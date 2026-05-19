FROM php:8.2-fpm-alpine

RUN apk add --no-cache \
    icu-dev \
    libpq-dev \
    libzip-dev \
    zip \
    unzip \
    git

RUN docker-php-ext-install \
    intl \
    pdo \
    pdo_mysql \
    zip \
    opcache

COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /app

COPY . /app

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer config platform-check false \
    && composer install --no-dev --optimize-autoloader --no-scripts --ignore-platform-reqs

RUN mkdir -p /app/var /app/public

RUN chown -R www-data:www-data /app/var /app/public

EXPOSE 9000

RUN chmod +x /app/entrypoint.sh
ENTRYPOINT ["/app/entrypoint.sh"]
