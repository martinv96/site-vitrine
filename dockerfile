# Étape 1 : builder (composer + node)
FROM node:20 AS node-builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY tailwind.config.js ./
COPY postcss.config.js ./
COPY assets ./assets

RUN npm run build

# Étape 2 : builder PHP (composer, Symfony)
FROM php:8.3-fpm

# Installer les extensions PHP nécessaires
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libicu-dev libonig-dev libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-install intl zip pdo pdo_mysql opcache \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# Installer Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Copier le reste du projet
COPY . .

# Copier le build Tailwind depuis node-builder
COPY --from=node-builder /app/public/build public/build

# Changer les permissions (si besoin)
RUN chown -R www-data:www-data /var/www/html/var /var/www/html/public/build

# Étape 3 : installer nginx
RUN apt-get install -y nginx

# Config Nginx
COPY ./docker/nginx.conf /etc/nginx/sites-enabled/default

# Exposer les ports
EXPOSE 80

# Commande pour démarrer PHP-FPM + nginx
CMD service php8.3-fpm start && nginx -g 'daemon off;'
