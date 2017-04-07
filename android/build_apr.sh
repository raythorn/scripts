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
[ ! -d "${APR_BUILD_LOG}" ] && mkdir -p ${APR_BUILD_LOG}

. ./android.sh

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

export CC="${ANDROID_TOOLCHAIN}/${CROSS_COMPILE}gcc"
export CFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CXXFLAGS="--sysroot=${ANDROID_SYSROOT}"
export CPP="${CC} -E"
export CPPFLAGS="-I${ANDROID_SYSROOT}/usr/include"

make clean &> ${APR_BUILD_LOG}/make_clean.log

./configure --host="arm-linux-androideabi" --prefix=${APR_BUILD} ac_cv_file__dev_zero=yes ac_cv_func_setpgrp_void=yes apr_cv_process_shared_works=yes apr_cv_mutex_robust_shared=yes apr_cv_tcp_nodelay_with_cork=yes ac_cv_sizeof_struct_iovec=8 apr_cv_mutex_recursive=yes ac_cv_func_fdatasync=no 

make
make install

unset CC
unset CFLAGS
unset CXXFLAGS
unset CPP
unset CPPFLAGS

popd

echo "Done"
