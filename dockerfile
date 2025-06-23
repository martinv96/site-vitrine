# Étape 1 : Builder Node (npm + tailwind + assets)
FROM node:20 AS node-builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY tailwind.config.js postcss.config.js ./
COPY assets ./assets

RUN npm run build

# Étape 2 : Builder PHP (composer + extensions + symfony)
FROM php:8.3-fpm

# Installer les dépendances système et extensions PHP nécessaires
RUN apt-get update && apt-get install -y \
    git unzip libzip-dev libicu-dev libonig-dev libpng-dev libjpeg-dev libfreetype6-dev nginx \
    && docker-php-ext-install intl zip pdo pdo_mysql opcache \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd

# Copier Composer depuis l'image officielle composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

# Copier les fichiers composer et installer les dépendances PHP
COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader

# Copier tout le reste du projet
COPY . .

# Copier le build tailwind depuis node-builder (public/build)
COPY --from=node-builder /app/public/build public/build

# Changer les permissions des dossiers de cache / build (Symfony)
RUN chown -R www-data:www-data var public/build

# Copier la config Nginx (tu dois avoir ce fichier dans ./docker/nginx.conf)
COPY ./docker/nginx.conf /etc/nginx/sites-enabled/default

# Exposer le port 80 pour le web
EXPOSE 80

# Lancer PHP-FPM et nginx ensemble
CMD service php8.3-fpm start && nginx -g 'daemon off;'
