FROM php:8.3-apache

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libxml2-dev \
    libonig-dev \
    libcurl4-openssl-dev \
    pdftk-java \
    msmtp \
    msmtp-mta \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
    mysqli \
    pdo_mysql \
    gd \
    zip \
    intl \
    soap \
    mbstring \
    curl \
    exif \
    bcmath \
    opcache

# Install Xdebug and Redis
RUN pecl install xdebug redis \
    && docker-php-ext-enable xdebug redis

# Enable Apache modules
RUN a2enmod rewrite ssl headers

# Configure msmtp for Mailpit
RUN echo "account default" > /etc/msmtprc && \
    echo "host mailpit" >> /etc/msmtprc && \
    echo "port 1025" >> /etc/msmtprc && \
    echo "tls off" >> /etc/msmtprc && \
    echo "auth off" >> /etc/msmtprc && \
    echo "from noreply@localhost" >> /etc/msmtprc && \
    chmod 644 /etc/msmtprc

# Copy sendmail wrapper script
COPY sendmail-wrapper.sh /usr/local/bin/sendmail-wrapper.sh
RUN chmod +x /usr/local/bin/sendmail-wrapper.sh

# Copy email cleanup script
COPY cleanup-emails.sh /usr/local/bin/cleanup-emails.sh
RUN chmod +x /usr/local/bin/cleanup-emails.sh

# Install cron and openssl
RUN apt-get update && apt-get install -y cron openssl && rm -rf /var/lib/apt/lists/*

# Add cron job to run cleanup every hour
RUN echo "0 * * * * /usr/local/bin/cleanup-emails.sh" | crontab -

# Copy and configure entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Configure PHP to use our wrapper (saves .eml AND sends to Mailpit)
RUN echo "sendmail_path=/usr/local/bin/sendmail-wrapper.sh" >> /usr/local/etc/php/conf.d/sendmail.ini

# Configure Xdebug
RUN echo "xdebug.mode=debug" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_host=host.docker.internal" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.log=/tmp/xdebug.log" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
    && echo "xdebug.idekey=PHPSTORM" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini

WORKDIR /var/www/htdocs

# Use entrypoint script (auto-generates SSL certs on first run)
CMD ["/usr/local/bin/entrypoint.sh"]
