#!/bin/sh


nginx -g 'daemon off;' & pid2="$!" # 启动第二个业务进程并记录 pid
echo "nginx started with pid $pid2"


php-fpm -F & pid1="$!" # 启动第一个业务进程并记录 pid
echo "php-fpm started with pid $pid1"


handle_sigterm() {
  echo "[INFO] Received SIGTERM"
  kill -SIGTERM $pid1 $pid2 # 传递 SIGTERM 给业务进程
  wait $pid1 $pid2 # 等待所有业务进程完全终止
}
trap handle_sigterm SIGTERM # 捕获 SIGTERM 信号并回调 handle_sigterm 函数

wait # 等待回调执行完，主进程再退出

