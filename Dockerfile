# -----------------------------------------------------------------------------
# LBAW Laravel Application Dockerfile
#
# Builds a production-ready container with:
# - PHP 8.3 FPM (Laravel runtime)
# - Nginx (web server)
# - PostgreSQL support (pdo_pgsql extension)
# - Composer (dependency manager)
#
# Copies Laravel source and configuration files into the container.
# Entrypoint script starts php-fpm and nginx.
# -----------------------------------------------------------------------------
    
FROM php:8.3-fpm

# Install system dependencies and required PHP extensions
# - nginx: web server
# - libpq-dev: PostgreSQL client libraries (needed for pdo_pgsql)
# - ca-certificates: enable HTTPS in PHP/cURL
# Also remove default nginx site to avoid conflicts.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       nginx \
       libpq-dev \
       ca-certificates \
       zip \
       unzip \
       git \
    && docker-php-ext-install pdo_pgsql \
    && rm -rf /var/lib/apt/lists/* \
    && rm -f /etc/nginx/sites-enabled/default

# Install Composer from its official image
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

# Set the working directory for the application code
WORKDIR /var/www

# Install PHP dependencies inside the container
COPY composer.json composer.lock ./
RUN composer install --optimize-autoloader --prefer-dist --no-progress --no-interaction --no-scripts

# Copy application source into the image (owned by www-data)
COPY --chown=www-data:www-data . .

# Copy configuration files into container
# - PHP overrides (php.ini)
# - Nginx site config
# - Production .env for Laravel
# - Entrypoint script to launch php-fpm + nginx
COPY ./etc/php/php.ini /usr/local/etc/php/conf.d/php.ini
COPY ./etc/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY .env.production /var/www/.env
COPY docker_run.sh /docker_run.sh

# Ensure entrypoint script is executable
RUN chmod +x /docker_run.sh

# Expose HTTP port
EXPOSE 80

# Entrypoint: run php-fpm in background + nginx in foreground
CMD ["/docker_run.sh"]