#!/bin/sh
nginx -g 'daemon off;' &
php-fpm -D             &

wait

