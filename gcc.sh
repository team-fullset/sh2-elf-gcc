#!/bin/bash

VERSION="14.2.0"
ARCHIVE="gcc-${VERSION}.tar.xz"
URL="https://gcc.gnu.org/pub/gcc/releases/gcc-${VERSION}/${ARCHIVE}"
SHA512SUM=""
DIR="gcc-${VERSION}"

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
    tar xf ${ARCHIVE} -C ${SRC_DIR}
fi

cd ${SRC_DIR}/${DIR}
./contrib/download_prerequisites

cd ${BUILD_DIR}/${DIR}

${SRC_DIR}/${DIR}/configure --prefix=${INSTALL_DIR}                        \
                            --build=${BUILD_MACH}                       \
                            --host=${HOST_MACH}                         \
                            --target=${TARGET}                          \
                            --program-prefix=${PROGRAM_PREFIX} \
                            --with-multilib-list=m2 \
                            --with-cpu=m2 \
                            --with-newlib \
                            --with-gnu-ld \
                            --with-gnu-as \
                            --with-gcc \
                            --without-headers \
                            --without-included-gettext \
                            --enable-lto \
                            --enable-languages=c,c++ \
                            --disable-threads \
                            --disable-libmudflap \
                            --disable-libgomp \
                            --disable-nls \
                            --disable-werror \
                            --disable-libssp \
                            --disable-shared \
                            --disable-libgcj \
                            --disable-libstdcxx \
                            --with-system-zlib

make -j${NUM_PROC} all-gcc 2>&1 | tee build.log
MAKE_EXIT=${PIPESTATUS[0]}

if [ ${MAKE_EXIT} -ne 0 ]; then
    echo "GCC build failed (exit code ${MAKE_EXIT})"
    exit 1
fi

make install-gcc

# Generate libgcc's headers serially first. Building all-target-libgcc straight
# at -j runs libgcc's configure inside the same parallel graph, so a compile can
# start before libgcc_tm.h exists and the build dies with:
#   libgcc/unwind-dw2.c:29:10: fatal error: libgcc_tm.h: No such file or directory
# Splitting the configure out keeps the compiles parallel, which is where the
# time actually goes.
make configure-target-libgcc 2>&1 | tee -a build.log
CONFIGURE_EXIT=${PIPESTATUS[0]}

if [ ${CONFIGURE_EXIT} -ne 0 ]; then
    echo "libgcc configure failed (exit code ${CONFIGURE_EXIT})"
    exit 1
fi

make -j${NUM_PROC} all-target-libgcc 2>&1 | tee -a build.log
MAKE_EXIT=${PIPESTATUS[0]}

if [ ${MAKE_EXIT} -ne 0 ]; then
    echo "libgcc build failed (exit code ${MAKE_EXIT})"
    exit 1
fi

make install-target-libgcc
