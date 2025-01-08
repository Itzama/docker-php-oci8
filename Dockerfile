# Usamos la imagen oficial de PHP 7.2 con Apache
FROM php:7.2-apache

# Instalamos las dependencias necesarias para OCI8 y PDO_OCI
RUN apt-get update && apt-get install -y \
    unzip \
    libaio1 \
    libpng-dev \
    libjpeg-dev \
    libfreetype6-dev \
    gcc \
    make \
    autoconf \
    libc-dev \
    libssl-dev \
    && docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install gd \
    && docker-php-ext-install pdo pdo_mysql \
    && docker-php-ext-install mysqli \
    && docker-php-ext-enable mysqli

# Copiar la carpeta instantclient_12_1 directamente al contenedor
COPY ./instantclient_12_1 /opt/oracle/instantclient_12_1

# Crear los enlaces simbólicos requeridos para las librerías de Oracle
RUN ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so \
    && ln -s /opt/oracle/instantclient_12_1/libocci.so.12.1 /opt/oracle/instantclient_12_1/libocci.so

# Actualizamos la configuración de las librerías y las cargamos
RUN sh -c "echo /opt/oracle/instantclient_12_1 > /etc/ld.so.conf.d/oracle-instantclient.conf" \
    && ldconfig

# Configuramos las variables de entorno para Oracle Instant Client
ENV LD_LIBRARY_PATH /opt/oracle/instantclient_12_1
ENV ORACLE_HOME /opt/oracle/instantclient_12_1

# Instalamos las extensiones OCI8 y PDO_OCI utilizando docker-php-ext-install
RUN docker-php-ext-configure oci8 --with-oci8=instantclient,/opt/oracle/instantclient_12_1 \
    && docker-php-ext-install -j$(nproc) oci8

RUN docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_12_1 \
    && docker-php-ext-install pdo_oci

# Instalamos otras extensiones útiles
RUN docker-php-ext-install zip bcmath opcache pcntl \
    && docker-php-ext-install exif sockets

# Configuramos el directorio de trabajo dentro del contenedor
WORKDIR /var/www/html

# Copiamos los archivos del proyecto
COPY ./doix /var/www/html

# Establecemos permisos correctos
RUN chown -R www-data:www-data /var/www/html && chmod -R 755 /var/www/html

# Exponemos el puerto 80
EXPOSE 80

# Iniciamos Apache en modo foreground
CMD ["apache2-foreground"]
