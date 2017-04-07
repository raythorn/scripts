#!/bin/bash

APR_PKG="apr-util-1.5.4.tar.gz"

if [ $# -gt 1 ];then
    echo "Usage: $0 [version]"
    exit 1
fi

if [ $# -eq 1 ];then
    APR_PKG="apr-util-$1.tar.gz"
fi

APR_SRC=${APR_PKG//.tar*/}
APR_BUILD=${PWD}/build
APR_BUILD_LOG=${APR_BUILD}/log
APR_URL="http://mirrors.tuna.tsinghua.edu.cn/apache//apr/${APR_PKG}"

if [ ! -f "${APR_PKG}" ];then
    echo "Fetch apr util package..."
    curl -Lk ${APR_URL} -o ${APR_PKG}
    if [ $? -ne 0 ];then
        echo "Fetch ${APR_PKG} fail!"
        exit 1
    fi
fi

[ ! -d "${APR_SRC}" ] && tar -xzvf ${APR_PKG}
[ ! -d "${APR_BUILD_LOG}" ] && mkdir -p ${APR_BUILD_LOG}

. ./android.sh

pushd .
cd ${APR_SRC}

export CC="${ANDROID_TOOLCHAIN}/${CROSS_COMPILE}gcc"
export CFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CXXFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CPP="${CC} -E"
export CPPFLAGS="-I${ANDROID_SYSROOT}/usr/include"

make clean &> ${APR_BUILD_LOG}/make_clean.log


./configure --host="arm-linux-androideabi" --prefix=${APR_BUILD} --with-apr=${APR_BUILD}

make
make install

unset CC
unset CFLAGS
unset CXXFLAGS
unset CPP
unset CPPFLAGS

popd

echo "Done"
