#!/bin/bash

CURL_PKG="curl-7.53.1.tar.gz"

if [ $# -gt 1 ]; then
	echo "Usage: $0 [version]"
	exit 1
fi

if [ $# -eq 1 ];then
    CURL_PKG="curl-$1.tar.gz"
fi

CURL_SRC=${CURL_PKG//.tar*/}
CURL_BUILD=${PWD}/build
CURL_BUILD_LOG=${CURL_BUILD}/log
CURL_URL="https://curl.haxx.se/download/${CURL_PKG}"

if [ ! -n `which curl` ];then
    echo "curl not found, please install"
    exit 1
fi

if [ ! -f "${CURL_PKG}" ];then
    echo "Download curl package..."
    curl -Lk $CURL_URL -o $CURL_PKG && exit 1
    if [ $? -ne 0 ];then
        echo "Fetch ${CURL_PKG} fail!"
        exit 1
    fi
fi

[ ! -d "${CURL_SRC}" ] && tar -xzvf ${CURL_PKG}
[ ! -d "${CURL_BUILD_LOG}" ] && mkdir -p ${CURL_BUILD_LOG}

. ./android.sh

pushd .
cd ${CURL_SRC}

export CC="${ANDROID_TOOLCHAIN}/${CROSS_COMPILE}gcc"
export CFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CXXFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CPP="${CC} -E"
export CPPFLAGS="-I${ANDROID_SYSROOT}/usr/include"

make clean &> ${CURL_BUILD_LOG}/make_clean.log

./configure --host="arm-linux-androideabi" --prefix="${CURL_BUILD}" --enable-shared --enable-static --disable-manual --enable-ipv6 --with-ssl="${CURL_BUILD}"

make
make install

unset CC
unset CFLAGS
unset CXXFLAGS
unset CPP
unset CPPFLAGS

popd

echo "Done"
