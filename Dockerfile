# Étape 1 : dépendances (sans les outils de dev)
FROM composer:2 AS vendor
WORKDIR /app
COPY composer.json composer.lock* ./
RUN composer install --no-dev --no-interaction --prefer-dist --optimize-autoloader

# Étape 2 : image finale
FROM php:8.3-apache
WORKDIR /var/www/html

COPY --from=vendor /app/vendor ./vendor
COPY src/ ./src/

# Si votre point d'entrée (index.php) est dans src/, servez ce dossier :
ENV APACHE_DOCUMENT_ROOT=/var/www/html/src
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

USER www-data
EXPOSE 80