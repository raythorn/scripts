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
CURL_BUILD_UNIVERSAL=${CURL_BUILD}/universal
CURL_UNIVERSAL_LIB=${CURL_BUILD_UNIVERSAL}/lib
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
[ ! -d "${CURL_BUILD_UNIVERSAL}" ] && mkdir -p ${CURL_BUILD_UNIVERSAL}
[ ! -d "${CURL_BUILD_LOG}" ] && mkdir -p ${CURL_BUILD_LOG}
[ ! -d "${CURL_UNIVERSAL_LIB}" ] && mkdir -p ${CURL_UNIVERSAL_LIB}

pushd .
cd ${CURL_SRC}

CLANG=$(xcrun -f clang)
#GCC=$(xcrun -f gcc)
GCC=/usr/bin/llvm-gcc

IPHONEOS_SDK=$(xcrun -sdk iphoneos --show-sdk-path)
SIMULATOR_SDK=$(xcrun -sdk iphonesimulator --show-sdk-path)

ARCHS=("armv7" "armv7s" "arm64" "i386" "x86_64")
ARCH_COUNT=${#ARCHS[@]}
HOSTS=("armv7-apple-darwin" "armv7s-apple-darwin" "arm-apple-darwin"  "i386-apple-darwin" "x86_64-apple-darwin")
CROSS_SDKS=(${IPHONEOS_SDK} ${IPHONEOS_SDK} ${IPHONEOS_SDK} ${SIMULATOR_SDK} ${SIMULATOR_SDK})

config_make()
{
ARCH=$1
HOST_VAL=$2
IOS_SDK=$3

export CC="${GCC}"
export CFLAGS="-mios-version-min=7.0 -arch ${ARCH} -isysroot ${IOS_SDK}"

make clean &> ${CURL_BUILD_LOG}/make_clean.log

echo "Configure for ${ARCH}..."

./configure --host=${HOST_VAL} --prefix=${CURL_BUILD}/${ARCH} --disable-shared --enable-static --disable-manual --enable-ipv6 --with-zlib="${IOS_SDK}/user" --with-ssl="${CURL_BUILD}/universal"

echo "Build for ${ARCH}..."

make
make install

unset CC
unset CFLAGS

echo -e "\n"
}

for ((i=0; i < ${ARCH_COUNT}; i++))
do
config_make ${ARCHS[i]} ${HOSTS[i]} ${CROSS_SDKS[i]} 
done


LIB_SRC=lib/libcurl.a
LIB_DST=${CURL_UNIVERSAL_LIB}/libcurl.a
LIB_PATHS=(${ARCHS[@]/#/${CURL_BUILD}/})
LIB_PATHS=(${LIB_PATHS[@]/%//${LIB_SRC}})

lipo ${LIB_PATHS[@]} -create -output ${LIB_DST}


cp -a ${CURL_BUILD}/arm64/include ${CURL_BUILD_UNIVERSAL}
cp ${CURL_BUILD}/arm64/include/curl/curlbuild.h ${CURL_BUILD_UNIVERSAL}/curl/curlbuild-64.h
echo -e "#if defined(__LP64__) && __LP64__ \n#include \"curlbuild-64.h\" \n#else \n#include \"curlbuild-32.h\" \n#endif" &> ${CURL_BUILD_UNIVERSAL_DIR}/curl/curlbuild.h

popd

echo "Done"
