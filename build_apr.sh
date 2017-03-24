#!/bin/bash

APR_PKG="apr-1.5.2.tar.gz"

if [ $# -gt 1 ];then
    echo "Usage: $0 [version]"
    exit 1
fi

if [ $# -eq 1 ];then
    APR_PKG="apr-$1.tar.gz"
fi

APR_SRC=${APR_PKG//.tar*/}
APR_BUILD=${PWD}/build
APR_BUILD_LOG=${APR_BUILD}/log
APR_BUILD_UNIVERSAL=${APR_BUILD}/universal
APR_UNIVERSAL_LIB=${APR_BUILD_UNIVERSAL}/lib
APR_URL="http://mirrors.tuna.tsinghua.edu.cn/apache//apr/${APR_PKG}"

if [ ! -f "${APR_PKG}" ];then
    echo "Fetch apr package..."
    curl -Lk ${APR_URL} -o ${APR_PKG}
    if [ $? -ne 0 ];then
        echo "Fetch ${APR_PKG} fail!"
        exit 1
    fi
fi

[ ! -d "${APR_SRC}" ] && tar -zxvf ${APR_PKG}
[ ! -d "${APR_BUILD_UNIVERSAL}" ] && mkdir -p ${APR_BUILD_UNIVERSAL}
[ ! -d "${APR_BUILD_LOG}" ] && mkdir -p ${APR_BUILD_LOG}
[ ! -d "${APR_UNIVERSAL_LIB}" ] && mkdir -p ${APR_UNIVERSAL_LIB}

pushd .
cd ${APR_SRC}

[ ! -f "Makefile.in.bak" ] && cp Makefile.in Makefile.in.bak
sed -ig '/OBJECTS_gen_test_char/,/\$(LINK_PROG) \$(OBJECTS_gen_test_char)/'d Makefile.in
sed -ig '/tools\/gen_test_char.o tools\/gen_test_char.lo/'d Makefile.in
sed -ig 's/build\/apr_rules.out tools\/gen_test_char@EXEEXT@/build\/apr_rules.out/' Makefile.in
sed -ig 's/_Offsetof(p_type,field)/((long) (((char *) (\&(((p_type)NULL)->field))) - ((char *) NULL)))/' include/apr_general.h

cd tools
gcc -o gen_test_char gen_test_char.c
cd -

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

make clean &> ${APR_BUILD_LOG}/make_clean.log

echo "Configure for ${ARCH}..."

./configure --host=${HOST_VAL} --prefix=${APR_BUILD}/${ARCH} --disable-shared ac_cv_file__dev_zero=yes ac_cv_func_setpgrp_void=yes apr_cv_process_shared_works=yes apr_cv_mutex_robust_shared=yes apr_cv_tcp_nodelay_with_cork=yes ac_cv_sizeof_struct_iovec=8 apr_cv_mutex_recursive=yes ac_cv_func_fdatasync=no 

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

unset CC

LIB_SRC=lib/libapr-1.a
LIB_DST=${APR_UNIVERSAL_LIB}/libapr.a
LIB_PATHS=( ${ARCHS[@]/#/${APR_BUILD}/} )
LIB_PATHS=( ${LIB_PATHS[@]/%//lib/libapr-1.a} )
lipo ${LIB_PATHS[@]} -create -output ${APR_UNIVERSAL_LIB}/libapr.a


cp -a ${APR_BUILD}/arm64/include ${APR_BUILD_UNIVERSAL}

popd

echo "Done"
