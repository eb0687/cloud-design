FROM alpine:3.21

RUN apk add --no-cache postgresql17 postgresql17-client su-exec

COPY docker/postgres/entrypoint.sh /usr/local/bin/postgres-entrypoint
RUN chmod +x /usr/local/bin/postgres-entrypoint

EXPOSE 5432
ENTRYPOINT ["postgres-entrypoint"]
