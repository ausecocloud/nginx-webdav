#!/bin/sh

# set some defaults
export WEBDAV_HOME="${WEBDAV_HOME:=/home/webdav}"
export WEBDAV_PORT="${WEBDAV_PORT:=8080}"
export WEBDAV_HOST="${WEBDAV_HOST:=0.0.0.0}"
export WEBDAV_MAX_SIZE="${WEBDAV_MAX_SIZE:=2G}"
export WEBDAV_AUTH_USER_FILE="${WEBDAV_AUTH_USER_FILE:=/tmp/nginx/.htpasswd}"
export WEBDAV_USER_NAME="${WEBDAV_USER_NAME:=webdav}"

export WEBDAV_UID="${WEBDAV_UID:=1000}"
export WEBDAV_GID="${WEBDAV_GID:=100}"
export WEBDAV_USER="${WEBDAV_USER:=webdav}"
export WEBDAV_GROUP="${WEBDAV_GROUP:=users}"


# check variable
# TODO: here we generate a new password, but never show it to anyone
export WEBDAV_TOKEN="${WEBDAV_TOKEN:=$(openssl3 rand 32 -base64)}"
if [ -z "${WEBDAV_TOKEN}" ] ; then
    echo "ERROR: WEBDAV_TOKEN empty."
    exit 1
fi

if [ "$(id -u)" == "0" ] ; then
    # We are running as root, check to drop privileges
    # check WEBDAV_GID
    GROUP=$(getent group "${WEBDAV_GID}" | awk -F ':' '{ print $1 }')
    if [ -z "${GROUP}" ] ; then
        # create group
        addgroup -g "${WEBDAV_GID}" -S "${WEBDAV_GROUP}" || exit 2
    else
        # use existing group name
        WEBDAV_GROUP="${GROUP}"
    fi

    # check user exists
    USER=$(getent passwd "${WEBDAV_UID}" | awk -F ':' '{print $1}')
    if [ -z "${USER}" ] ; then
        # create user
        adduser -SDH -u "${WEBDAV_UID}" -G "${WEBDAV_GROUP}" "${WEBDAV_USER}" || exit 3
    else
        # use existing user
        WEBDAV_USER="${USER}"
    fi

fi

# create config location to use
mkdir -p /tmp/nginx/http.d
# template out nginx config with env vars
cat /etc/nginx-template/nginx.conf | envsubst "$(printf '${%s} ' $(env | grep WEBDAV_ | cut -d'=' -f1))"  > /tmp/nginx/nginx.conf
cat /etc/nginx-template/http.d/default.conf | envsubst "$(printf '${%s} ' $(env | grep WEBDAV_ | cut -d'=' -f1))"  > /tmp/nginx/http.d/default.conf

# generate password file
# token as username empty password
echo "${WEBDAV_TOKEN}:$(openssl3 passwd -apr1 '')" > "${WEBDAV_AUTH_USER_FILE}"
# user webdav:<token>
htpasswd -nb "${WEBDAV_USER_NAME}" "${WEBDAV_TOKEN}" >> "${WEBDAV_AUTH_USER_FILE}"

# start nginx
exec nginx -g 'daemon off;' -e '/dev/stderr'
