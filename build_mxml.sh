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
MXML_BUILD_UNIVERSAL=${MXML_BUILD}/universal
MXML_UNIVERSAL_LIB=${MXML_BUILD_UNIVERSAL}/lib
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
[ ! -d "${MXML_BUILD_UNIVERSAL}" ] && mkdir -p ${MXML_BUILD_UNIVERSAL}
[ ! -d "${MXML_BUILD_LOG}" ] && mkdir -p ${MXML_BUILD_LOG}
[ ! -d "${MXML_UNIVERSAL_LIB}" ] && mkdir -p ${MXML_UNIVERSAL_LIB}

pushd .
cd ${MXML_SRC}

CLANG=$(xcrun -f clang)
GCC=$(xcrun -f gcc)
LD=$(xcrun -f ld)

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
export AR=$(xcrun -f ar)
export CFLAGS="-mios-version-min=7.0 -arch ${ARCH} -isysroot ${IOS_SDK}"
export LDFLAGS="-arch ${ARCH} -isysroot ${IOS_SDK}"

make clean &> ${MXML_BUILD_LOG}/make_clean.log

echo "Configure for ${ARCH}..."

./configure --host=${HOST_VAL} --prefix=${MXML_BUILD}/${ARCH}  --disable-shared

echo "Build for ${ARCH}..."

make
make install-libmxml.a

unset CC
unset CFLAGS

echo -e "\n"
}

for ((i=0; i < ${ARCH_COUNT}; i++))
do
config_make ${ARCHS[i]} ${HOSTS[i]} ${CROSS_SDKS[i]} 
done

LIB_SRC=lib/libmxml.a
LIB_DST=${MXML_UNIVERSAL_LIB}/libmxml.a
LIB_PATHS=(${ARCHS[@]/#/${MXML_BUILD}/})
LIB_PATHS=(${LIB_PATHS[@]/%//${LIB_SRC}})

lipo ${LIB_PATHS[@]} -create -output ${LIB_DST}


cp -a ${MXML_BUILD}/arm64/include ${MXML_BUILD_UNIVERSAL}

popd

echo "Done"
