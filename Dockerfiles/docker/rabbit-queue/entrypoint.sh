#!/bin/sh
set -eu

mkdir -p /etc/rabbitmq

cat > /etc/rabbitmq/rabbitmq.conf <<EOF
listeners.tcp.default = 5672
default_user = ${RABBITMQ_DEFAULT_USER}
default_pass = ${RABBITMQ_DEFAULT_PASS}
loopback_users.guest = false
EOF

exec rabbitmq-server
