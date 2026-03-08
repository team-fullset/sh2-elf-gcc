#!/bin/bash

VERSION="4.1.0"
ARCHIVE="newlib-${VERSION}.tar.gz"
URL="https://sourceware.org/pub/newlib/${ARCHIVE}"
SHA512SUM="6a24b64bb8136e4cd9d21b8720a36f87a34397fd952520af66903e183455c5cf19bb0ee4607c12a05d139c6c59382263383cb62c461a839f969d23d3bc4b1d34"
DIR="newlib-${VERSION}"

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
    tar -zxf ${ARCHIVE} -C ${SRC_DIR}
fi

PREFIX=${PROGRAM_PREFIX}
export CC_FOR_TARGET=${PREFIX}gcc
export LD_FOR_TARGET=${PREFIX}ld
export AS_FOR_TARGET=${PREFIX}as
export AR_FOR_TARGET=${PREFIX}ar
export RANLIB_FOR_TARGET=${PREFIX}ranlib
export newlib_cflags="${newlib_cflags} -DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__"
export CFLAGS_FOR_TARGET="-DPREFER_SIZE_OVER_SPEED -D__OPTIMIZE_SIZE__ -Wno-implicit-function-declaration -Wno-int-conversion -Wno-implicit-int -Wno-return-type"

cd ${BUILD_DIR}/${DIR}

${SRC_DIR}/${DIR}/configure --prefix=${INSTALL_DIR} \
                            --build=${BUILD_MACH} \
                            --host=${HOST_MACH} \
                            --target=${TARGET} \
                            --program-prefix=${PREFIX} \
                            --enable-target-optspac \
                            --enable-libssp \
                            --enable-lto \
                            --enable-newlib-supplied-syscalls \
                            --disable-nls

make -j${NUM_PROC} 2>&1 | tee build.log
MAKE_EXIT=${PIPESTATUS[0]}

if [ ${MAKE_EXIT} -ne 0 ]; then
    echo "Newlib build failed (exit code ${MAKE_EXIT})"
    exit 1
fi

make install
