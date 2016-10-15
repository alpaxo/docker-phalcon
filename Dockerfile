FROM        php:7.0-fpm
MAINTAINER  Alexey Kreelo <alexey@kreelo.net>
WORKDIR     /

ENV DEBIAN_FRONTEND noninteractive
ENV PHALCON_VERSION=3.0.1

# Uncomment for local build and testing
# RUN  echo 'Acquire::http { Proxy "http://172.17.0.1:3142"; };' >> /etc/apt/apt.conf.d/01proxy
# ENV http_proxy http://172.17.0.1:3142/

# Update system packages ######################################################
RUN apt-get -y update && apt-get -y upgrade

RUN apt-get install -y --fix-missing --no-install-recommends \
    apt-utils tzdata git re2c libpcre3-dev gcc make autoconf automake \
    libtool bison build-essential

# Clone PhalconPHP and Memcache repos #########################################
RUN cd /tmp && git clone https://github.com/phalcon/cphalcon.git
RUN cd /tmp && git clone https://github.com/php-memcached-dev/php-memcached

#
RUN apt-get install -y --fix-missing --no-install-recommends libcurl3-dev \
    libmcrypt-dev libpng-dev libgmp-dev libicu-dev libmemcached-dev

# Install common extensions ###################################################
RUN docker-php-ext-install curl gd gettext mcrypt pdo pdo_mysql iconv intl mbstring

# Install imagick
RUN apt-get install -y --fix-missing --no-install-recommends libmagickwand-dev libmagickcore-dev
RUN pecl install imagick
RUN /bin/echo 'extension=imagick.so' > /usr/local/etc/php/conf.d/imagick.ini

# RUN pecl install memcached (incompatible with php7)
RUN cd /tmp/php-memcached && git checkout php7 && git pull && phpize && ./configure && make && make install
RUN /bin/echo 'extension=memcached.so' > /usr/local/etc/php/conf.d/memcached.ini

RUN cd /tmp/cphalcon && git checkout v${PHALCON_VERSION} && cd build && ./install
RUN /bin/echo 'extension=phalcon.so' > /usr/local/etc/php/conf.d/phalcon.ini

# Purge dev libs ##############################################################
RUN cd /tmp && rm -rf /tmp/*
RUN apt-get -yq purge apt-utils git libpcre3-dev gcc make autoconf automake
RUN apt-get -yq autoremove && apt-get clean

# Expose port and run fpm
EXPOSE 9000
CMD ["php-fpm"]