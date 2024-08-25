#!/bin/env bash

OWNER_PASSWORD="${OWNER_PASSWORD:?The OWNER_PASSWORD is required}" APP_ENV="${APP_ENV:-production}" HOME_DIR="${PWD}" bundle exec puma
