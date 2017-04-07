#!/bin/bash

OPENSSL_PKG="openssl-1.1.0e.tar.gz"

if [ $# -gt 1 ]; then
	echo "Usage: $0 [version]"
	exit 1
fi

if [ $# -eq 1 ]; then
	OPENSSL_PKG="openssl-$1.tar.gz"
fi

OPENSSL_SRC=${OPENSSL_PKG//.tar*/}
OPENSSL_BUILD=${PWD}/build
OPENSSL_SSL=${PWD}/build/ssl
OPENSSL_BUILD_LOG=${OPENSSL_BUILD}/log
OPENSSL_URL="https://www.openssl.org/source/${OPENSSL_PKG}"


if [ ! -n `which curl` ];then
    echo "curl not found, please install"
    exit 1
fi

if [ ! -f ${OPENSSL_PKG} ];then
	echo "Fetch openssl package..."
	curl -Lk ${OPENSSL_URL} -o ${OPENSSL_PKG} 
    if [ $? -ne 0 ];then
        echo "Fetch ${OPENSSL_PKG} fail!"
        exit 1
    fi
fi

[ ! -d "${OPENSSL_SRC}" ] && tar -zxvf ${OPENSSL_PKG}
[ ! -d "${OPENSSL_BUILD_LOG}" ] && mkdir -p ${OPENSSL_BUILD_LOG}

pushd .
cd ${OPENSSL_SRC}
. ../android.sh
make distclean
./config shared no-ssl3 no-comp no-hw no-engine --openssldir=${OPENSSL_SSL} --prefix=${OPENSSL_BUILD}
make depend
make all
make install CC=$ANDROID_TOOLCHAIN/arm-linux-androideabi-gcc RANLIB=$ANDROID_TOOLCHAIN/arm-linux-androideabi-ranlib

echo "Done"
