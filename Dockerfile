#必须使用官方镜像
FROM php:8.1.27-fpm

ARG CONTAINER_PACKAGE_URL=mirrors.tuna.tsinghua.edu.cn
ARG NGINX_CONF=nginx.conf
ARG FASTCGI_PHP=fastcgi-php.conf
ARG FASTCGI_PARAMS=fastcgi_params
ARG PHP_INI=php.ini
ARG PHP_FPM_CONF=php-fpm.conf


ARG TZ=Asia/Shanghai


RUN  sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources \
    && sed -i 's/snapshot.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources


# 设置时区
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# install nginx
RUN apt-get update && apt-get install -y nginx \
    && rm -rf /var/cache/apt/* /tmp/* /usr/share/man /var/lib/apt/lists/*


ADD extensions/install-php-extensions-v2.2.5 /usr/local/bin/
RUN mv  /usr/local/bin/install-php-extensions-v2.2.5 /usr/local/bin/install-php-extensions
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync



COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/bin/


#安装composer
RUN curl -o /usr/bin/composer https://mirrors.aliyun.com/composer/composer.phar \
    && chmod +x /usr/bin/composer
ENV COMPOSER_HOME=/tmp/composer
RUN composer config -g repos.packagist composer https://mirrors.cloud.tencent.com/composer/


RUN install-php-extensions \
          bcmath \
          bz2 \
          calendar \
          exif \
          intl \
          ldap \
          memcached \
          mysqli \
          opcache \
          pdo_mysql \
          pdo_pgsql \
          pgsql \
          redis \
          soap \
          xsl \
          zip \
          sockets \
          swoole \
          memcached \
          mcrypt \
          iconv \
          mbstring \
          intl \
          mysqli \
          gd

RUN apt-get update && apt-get install protobuf-compiler libprotobuf-dev zlib1g-dev -y
RUN pecl install grpc
RUN docker-php-ext-enable grpc
#####nginx配置文件#####

RUN rm -rf /etc/nginx/nginx.conf \
    && rm -rf /etc/nginx/conf.d/default.conf \
    && rm -rf /etc/nginx/fastcgi-php.conf \
    && rm -rf /etc/nginx/fastcgi_params \
    && rm -rf /etc/nginx/conf.d

RUN mkdir /etc/nginx/conf.d

ADD ${NGINX_CONF} /etc/nginx/
ADD ${FASTCGI_PHP} /etc/nginx/
ADD ${FASTCGI_PARAMS} /etc/nginx/

#####copy example.conf###########
COPY conf.d/  /etc/nginx/conf.d
RUN mkdir /ssl
COPY ssl /ssl

#######################

#####php-fpm配置########


ADD ${PHP_INI} /usr/local/etc/php/php.ini
#ADD ${PHP_FPM_CONF} /usr/local/etc/php-fpm.d/


#######################
# php image's www-data user uid & gid are 82, change them to 1000 (primary user)
#RUN apt-get install  shadow && usermod -u 1000 www-data && groupmod -g 1000 www-data
##############
################copy 脚本##########
COPY entrypoint.sh /

####开放端口
EXPOSE 80
EXPOSE 9000
EXPOSE 443
EXPOSE 9501

COPY www /www
WORKDIR /www
RUN apt-get update && apt-get install -y dumb-init
RUN apt-get install procps strace tcpdump telnet lsof curl iproute2 -y
ENTRYPOINT ["dumb-init", "--"]
###执行脚本
CMD ["sh","/entrypoint.sh"]

