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

ENV APACHE_DOCUMENT_ROOT=/var/www/html/src
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' \
    /etc/apache2/sites-available/*.conf \
    /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

RUN echo "DirectoryIndex hello.php index.php index.html" > /etc/apache2/conf-available/zz-directory-index.conf \
    && a2enconf zz-directory-index \
    && echo "ServerName localhost" >> /etc/apache2/apache2.conf

EXPOSE 80