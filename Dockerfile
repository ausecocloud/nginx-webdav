FROM alpine:3.16

ENV WEBDAV_HOME=/home/webdav \
    WEBDAV_PORT=8080 \
    WEBDAV_HOST=0.0.0.0 \
    WEBDAV_AUTH_USER_FILE=/tmp/.htpasswd \
    WEBDAV_UID=1000 \
    WEBDAV_USER=webdav \
    WEBDAV_GID=100 \
    WEBDAV_GROUP=users

# install ngin and required modules and tools
RUN apk add --update-cache \
      apache2-utils \
      gettext \
      nginx-mod-http-dav-ext \
      nginx-mod-http-headers-more \
      openssl3 \
 && rm -fr /var/cache/apk/*

# setup default webdav user
RUN adduser -SDH -u ${WEBDAV_UID} -G ${WEBDAV_GROUP} ${WEBDAV_USER}

# Install nginx config files
COPY files/nginx-template/ /etc/nginx-template/

# Install startup script
COPY files/entrypoint.sh /entrypoint.sh

# variant 1 ... fix permissions to start up nginx as user
RUN chmod o+rx /var/lib/nginx

# variant 2 ... add user/group and set group directive in nginx.conf
#RUN addgroup -g 1000 -S webdav \
# && adduser -S -D -H -G 1000 -u 1000 webdav

USER ${WEBDAV_USER}

CMD ["/entrypoint.sh"]
