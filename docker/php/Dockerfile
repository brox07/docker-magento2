# Start with a modern, official PHP-FPM image
FROM php:8.2-fpm

# Install system dependencies required for PHP extensions
RUN apt-get update && apt-get install -y \
    libfreetype-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libxslt-dev \
    libicu-dev \
    libonig-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy custom PHP config
COPY custom.ini /usr/local/etc/php/conf.d/docker-php-custom.ini

# Install Magento's required PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    gd \
    bcmath \
    intl \
    mbstring \
    opcache \
    pdo_mysql \
    soap \
    sockets \
    ftp \
    zip \
    xsl \
    sodium

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set the working directory
WORKDIR /var/www/html

# The www-data user is used by php-fpm by default.
# We ensure it exists and can write to the directory.
RUN chown -R www-data:www-data /var/www/html