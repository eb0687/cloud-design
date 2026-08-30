#!/bin/sh
set -eu

mkdir -p /etc/rabbitmq

cat > /etc/rabbitmq/rabbitmq.conf <<EOF
listeners.tcp.default = 5672
prometheus.tcp.port = 15692
default_user = ${RABBITMQ_DEFAULT_USER}
default_pass = ${RABBITMQ_DEFAULT_PASS}
loopback_users.guest = false
EOF

rabbitmq-plugins enable --offline rabbitmq_prometheus
exec rabbitmq-server
