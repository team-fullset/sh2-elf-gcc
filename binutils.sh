#!/bin/bash

VERSION="2.45"
ARCHIVE="binutils-${VERSION}.tar.bz2"
URL="https://ftp.gnu.org/gnu/binutils/${ARCHIVE}"
SHA512SUM=""
DIR="binutils-${VERSION}"

if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root"
    exit 1
fi

mkdir -p ${BUILD_DIR}/${DIR}
cd ${DOWNLOAD_DIR}

if ! [ -f "${ARCHIVE}" ]; then
    curl -LO ${URL}
fi

if ! [ -d "${SRC_DIR}/${DIR}" ]; then
    if [ -n "${SHA512SUM}" ]; then
        if [ $(shasum -a 512 ${ARCHIVE} | awk '{print $1}') != ${SHA512SUM} ]; then
            echo "SHA512SUM verification of ${ARCHIVE} failed!"
            exit 1
        fi
    fi
    tar jxf ${ARCHIVE} -C ${SRC_DIR}
fi

cd ${BUILD_DIR}/${DIR}

${SRC_DIR}/${DIR}/configure     --prefix=${INSTALL_DIR} \
                                --build=${BUILD_MACH} \
                                --host=${HOST_MACH} \
                                --target=${TARGET} \
                                --disable-werror \
                                --disable-nls \
                                --enable-libssp \
                                --enable-lto \
                                --with-system-zlib \
                                --program-prefix=${PROGRAM_PREFIX} \
                                --with-multilib-list=m2

make -j${NUM_PROC} 2>&1 | tee build.log
MAKE_EXIT=${PIPESTATUS[0]}

if [ ${MAKE_EXIT} -ne 0 ]; then
    echo "Binutils build failed (exit code ${MAKE_EXIT})"
    exit 1
fi

make install -j${NUM_PROC}
