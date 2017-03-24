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
OPENSSL_BUILD_LOG=${OPENSSL_BUILD}/log
OPENSSL_BUILD_UNIVERSAL=${OPENSSL_BUILD}/universal
OPENSSL_UNIVERSAL_LIB=${OPENSSL_BUILD_UNIVERSAL}/lib
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
[ ! -d "${OPENSSL_BUILD_UNIVERSAL}" ] && mkdir -p ${OPENSSL_BUILD_UNIVERSAL}
[ ! -d "${OPENSSL_BUILD_LOG}" ] && mkdir -p ${OPENSSL_BUILD_LOG}
[ ! -d "${OPENSSL_UNIVERSAL_LIB}" ] && mkdir -p ${OPENSSL_UNIVERSAL_LIB}

pushd .
cd ${OPENSSL_SRC}

CLANG=$(xcrun -f clang)

IPHONEOS_SDK=$(xcrun -sdk iphoneos --show-sdk-path)
IPHONEOS_CROSS_TOP=${IPHONEOS_SDK//\/SDKs*/}
IPHONEOS_CROSS_SDK=${IPHONEOS_SDK##*/}

SIMULATOR_SDK=$(xcrun -sdk iphonesimulator --show-sdk-path)
SIMULATOR_CROSS_TOP=${SIMULATOR_SDK//\/SDKs*/}
SIMULATOR_CROSS_SDK=${SIMULATOR_SDK##*/}

ARCHS=("armv7" "armv7s" "arm64" "i386" "x86_64")
ARCH_COUNT=${#ARCHS[@]}
CROSS_SDKS=(${IPHONEOS_CROSS_SDK} ${IPHONEOS_CROSS_SDK} ${IPHONEOS_CROSS_SDK} ${SIMULATOR_CROSS_SDK} ${SIMULATOR_CROSS_SDK})
CROSS_TOPS=(${IPHONEOS_CROSS_TOP} ${IPHONEOS_CROSS_TOP} ${IPHONEOS_CROSS_TOP} ${SIMULATOR_CROSS_TOP} ${SIMULATOR_CROSS_TOP})

config_make()
{
ARCH=$1
export CROSS_TOP=$2
export CROSS_SDK=$3
export CC="${CLANG} -arch ${ARCH} -miphoneos-version-min=6.0"

make clean &> ${OPENSSL_BUILD_LOG}/make_clean.log

echo "Configure for ${ARCH}..."

if [ "x86_64" = ${ARCH} ];then
	./Configure iphoneos-cross --prefix=${OPENSSL_BUILD}/${ARCH} no-asm
else
	./Configure iphoneos-cross --prefix=${OPENSSL_BUILD}/${ARCH}
fi

echo "Build for ${ARCH}..."

make 
make install_sw

unset CC
unset CROSS_SDK
unset CROSS_TOP

echo -e "\n"
}

for ((i=0; i < ${ARCH_COUNT}; i++))
do
	config_make ${ARCHS[i]} ${CROSS_TOPS[i]} ${CROSS_SDKS[i]}
done

create_lib()
{
LIB_SRC=lib/$1
LIB_DST=${OPENSSL_UNIVERSAL_LIB}/$1
LIB_PATHS=(${ARCHS[@]/#/${OPENSSL_BUILD}/})
LIB_PATHS=(${LIB_PATHS[@]/%//${LIB_SRC}})
lipo ${LIB_PATHS[@]} -create -output ${LIB_DST}
}

create_lib "libssl.a"
create_lib "libcrypto.a"

create_dylib()
{
LIB_SRC=lib/$1
LIB_DST=${OPENSSL_UNIVERSAL_LIB}/$1
LIB_PATHS=(${ARCHS[@]/#/${OPENSSL_BUILD}/})
LIB_PATHS=(${LIB_PATHS[@]/%//${LIB_SRC}})
lipo ${LIB_PATHS[@]} -create -output ${LIB_DST}
}

cp -R ${OPENSSL_BUILD}/arm64/include ${OPENSSL_BUILD_UNIVERSAL}

popd

echo "Done"
