FROM alpine:3.21

RUN apk add --no-cache rabbitmq-server

COPY docker/rabbit-queue/entrypoint.sh /usr/local/bin/rabbitmq-entrypoint
RUN chmod +x /usr/local/bin/rabbitmq-entrypoint

EXPOSE 5672
ENTRYPOINT ["rabbitmq-entrypoint"]
