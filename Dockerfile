FROM alpine:3.23

# Build metadata arguments
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

# OCI annotations
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.title="PHP-FPM 8.5 & Nginx on Alpine Linux"
LABEL org.opencontainers.image.description="Lightweight container with Nginx 1.28 & PHP 8.5 based on Alpine Linux."

# Setup document root
WORKDIR /var/www/html

# Install packages and remove default server definition
RUN apk add --no-cache \
  curl \
  nginx \
  php85 \
  php85-bcmath \
  php85-curl \
  php85-dom \
  php85-fileinfo \
  php85-fpm \
  php85-gd \
  php85-intl \
  php85-mbstring \
  php85-mysqli \
  php85-pdo \
  php85-pdo_mysql \
  php85-openssl \
  php85-pcntl \
  php85-phar \
  php85-session \
  php85-tokenizer \
  php85-sodium \
  php85-xml \
  php85-xmlreader \
  php85-xmlwriter \
  php85-redis \
  php85-zip \
  libzip \
  supervisor

# Create alias to php
RUN ln -s /usr/bin/php85 /usr/bin/php

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure nginx - http
COPY config/nginx.conf /etc/nginx/nginx.conf
# Configure nginx - default server
COPY config/conf.d /etc/nginx/conf.d/

# Configure PHP-FPM
ENV PHP_INI_DIR=/etc/php85
COPY config/fpm-pool.conf ${PHP_INI_DIR}/php-fpm.d/www.conf
COPY config/php.ini ${PHP_INI_DIR}/conf.d/custom.ini

# Configure supervisord
COPY config/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Make sure files/folders needed by the processes are accessable when they run under the nobody user
RUN chown -R nobody:nobody /var/www/html /run /var/lib/nginx /var/log/nginx

# Switch to use a non-root user from here on
USER nobody

# Add application
COPY --chown=nobody src/ /var/www/html/

# Expose the port nginx is reachable on
EXPOSE 8080

# Let supervisord start nginx & php-fpm
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Configure a healthcheck to validate that everything is up&running
HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1:8080/fpm-ping || exit 1
