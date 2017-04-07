#!/bin/bash

MXML_PKG="mxml-2.10.tar.gz"

if [ $# -gt 1 ];then
    echo "Usage: $0 [version]"
    exit 1
fi

if [ $# -eq 1 ];then
    MXML_PKG="mxml-$1.tar.gz"
fi

MXML_SRC=${MXML_PKG//.tar*/}
MXML_BUILD=${PWD}/build
MXML_BUILD_LOG=${MXML_BUILD}/log
MXML_VER=${MXML_SRC#*-}
MXML_URL="https://github.com/michaelrsweet/mxml/releases/download/release-${MXML_VER}/${MXML_PKG}"

if [ ! -n `which curl` ];then
    echo "curl not found, please install!"
    exit 1
fi

if [ ! -f "${MXML_PKG}" ];then
    echo "Fetch minixml from ${MXML_URL}"
    curl -Lk ${MXML_URL} -o ${MXML_PKG}
    if [ $? -ne 0 ];then
        echo "Fetch ${MXML_PKG} fail!"
        exit 1
    fi
fi

[ ! -d "${MXML_SRC}" ] && tar -xzvf ${MXML_PKG}
[ ! -d "${MXML_BUILD_LOG}" ] && mkdir -p ${MXML_BUILD_LOG}

. ./android.sh

pushd .
cd ${MXML_SRC}

export CC="${ANDROID_TOOLCHAIN}/${CROSS_COMPILE}gcc"
export AR="${ANDROID_TOOLCHAIN}/${CROSS_COMPILE}ar"
export RANLIB="${ANDROID_TOOLCHAIN}/${CROSS_COMPILE}ranlib"
export CFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CXXFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CPP="${CC} -E"
export CPPFLAGS="-I${ANDROID_SYSROOT}/usr/include"

make clean &> ${MXML_BUILD_LOG}/make_clean.log

./configure --host="arm-linux-androideabi" --disable-shared --prefix=${MXML_BUILD} 

make libmxml.a
make install-libmxml.a

unset CC
unset CFLAGS
unset CXXFLAGS
unset CPP
unset CPPFLAGS

popd

echo "Done"
