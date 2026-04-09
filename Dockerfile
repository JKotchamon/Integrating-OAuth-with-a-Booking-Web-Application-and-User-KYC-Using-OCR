FROM php:8.1-apache

# Install system dependencies and PDO MySQL
RUN apt-get update && apt-get install -y unzip git curl \
    && docker-php-ext-install pdo pdo_mysql

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Copy composer files and install dependencies
WORKDIR /var/www/html
COPY html/composer.json ./
RUN composer install --no-interaction --no-scripts

# Enable mod_rewrite
RUN a2enmod rewrite

# Set ServerName to suppress warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf
