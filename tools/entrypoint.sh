#!/bin/env bash

echo "Starting http-web4humans server"
echo ""


if [ -z "${OWNER_PASSWORD}" ]; then
	echo "OWNER_PASSWORD is required"
	exit 1
fi
export OWNER_PASSWORD="$OWNER_PASSWORD"

if [ -z "${PORT}" ]; then
	echo "PORT is required" >&2
	exit 1
fi
export PORT="$PORT"

if [ -z "${WORKERS}" ]; then
	echo "WORKERS? ${WORKERS}"
	echo "WORKERS is required" >&2
	exit 1
fi
export WORKERS="${WORKERS}"

if [ -z "$APP_ENV" ]; then
	export APP_ENV="production"
else
	export APP_ENV="$APP_ENV"
fi


export HOME_DIR="$PWD"


echo "OWNER_PASSWORD = ${OWNER_PASSWORD}"
echo "PORT           = ${PORT}"
echo "WORKERS        = ${WORKERS}"
echo "APP_ENV        = ${APP_ENV}"
echo "HOME_DIR       = ${HOME_DIR}"


bundle exec puma --no-config --port "${PORT}" --workers "{$WORKERS}"
