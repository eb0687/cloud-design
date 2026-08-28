#!/bin/sh
set -eu

DATA_DIR=/var/lib/postgresql/data

mkdir -p "$DATA_DIR" /run/postgresql
chown -R postgres:postgres /var/lib/postgresql /run/postgresql

if [ ! -s "$DATA_DIR/PG_VERSION" ]; then
  su-exec postgres initdb -D "$DATA_DIR"
  su-exec postgres pg_ctl -D "$DATA_DIR" -o "-c listen_addresses='localhost'" -w start
  su-exec postgres psql --username postgres <<SQL
CREATE USER "$POSTGRES_USER" WITH PASSWORD '$POSTGRES_PASSWORD';
CREATE DATABASE "$POSTGRES_DB" OWNER "$POSTGRES_USER";
SQL
  su-exec postgres pg_ctl -D "$DATA_DIR" -m fast -w stop
fi

cat > "$DATA_DIR/postgresql.conf" <<EOF
listen_addresses = '*'
port = 5432
EOF

cat > "$DATA_DIR/pg_hba.conf" <<EOF
local all all trust
host all all 0.0.0.0/0 md5
EOF

exec su-exec postgres postgres -D "$DATA_DIR"
