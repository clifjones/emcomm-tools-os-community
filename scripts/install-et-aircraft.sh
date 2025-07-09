#!/bin/bash
# Author  : Gaston Gonzalez
# Date    : 9 July 2025
# Purpose : Install et-aircraft-app
set -e
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
trap 'et-log "\"${last_command}\" command failed with exit code $?."' ERR

. ./env.sh

APP=et-aircraft-app
VERSION=1.0.0
DOWNLOAD_FILE="${APP}_${VERSION}_amd64.deb"

et-log "Installing ${APP} ${VERSION}..."

if [[ ! -e ${ET_DIST_DIR}/${DOWNLOAD_FILE} ]]; then

  URL="https://github.com/thetechprepper/et-aircraft-app/releases/download/${VERSION}/${DOWNLOAD_FILE}"

  et-log "Downloading ${APP}: ${URL}"
  curl -s -L -o ${DOWNLOAD_FILE} --fail ${URL}

  mv ${DOWNLOAD_FILE} ${ET_DIST_DIR}
fi

DEBIAN_FRONTEND=noninteractive dpkg -i "${ET_DIST_DIR}/${DOWNLOAD_FILE}" 
