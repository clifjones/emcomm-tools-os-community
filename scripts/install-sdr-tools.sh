#!/bin/bash
#
# Author  : Gaston Gonzalez
# Author  : William McKeehan
# Date    : 4 June 2025
# Updated : 5 October 2025
# Purpose : Install SDR tools
set -e

et-log "Installing SDR tools..."
. ./env.sh

APP=rtl-sdr
REPO=https://github.com/osmocom/rtl-sdr
REPO_SRC_DIR="${ET_SRC_DIR}/${APP}"

[[ ! -e ${ET_SRC_DIR} ]] && mkdir ${ET_SRC_DIR}

CWD_DIR=`pwd`

et-log "Installing ${APP} build dependencies..."
apt purge ^librtlsdr -y
rm -rvf /usr/lib/librtlsdr* /usr/include/rtl-sdr* /usr/local/lib/librtlsdr* /usr/local/include/rtl-sdr* /usr/local/include/rtl_* /usr/local/bin/rtl_*

apt-get install \
    libusb-1.0-0-dev \
    git \
    cmake \
    pkg-config \
    debhelper \
    -y

et-log "Cloning ${APP} repository..."
if [[ ! -e ${REPO_SRC_DIR} ]]; then
  mkdir ${REPO_SRC_DIR} 
  cd ${REPO_SRC_DIR} && git clone ${REPO} src
fi

cd ${REPO_SRC_DIR}/src

et-log "Building ${APP}..."
if [[ ! -e build ]]; then
  mkdir build
fi

cd build
cmake ../ -DINSTALL_UDEV_RULES=ON
make
make install
ldconfig

echo 'blacklist dvb_usb_rtl28xxu' | tee --append /etc/modprobe.d/blacklist-dvb_usb_rtl28xxu.conf

cd ..
dpkg-buildpackage -b --no-sign
cd ..

dpkg -i librtlsdr0_*
dpkg -i librtlsdr-dev_*

cd ${CWD_DIR}
