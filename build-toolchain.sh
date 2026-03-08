#!/bin/bash

###################################################################
#Script Name    :   build-toolchain
#Description    :   build toolchain for the SuperH2
#Date           :   samedi, 4 avril 2020
#Args           :   Welcome to the next level!
#Author         :   Jacques Belosoukinski (kentosama)
#Email          :   kentosama@genku.net
# Modified for macOS support
###################################################################

BUILD_BINUTILS="yes"
BUILD_GCC_STAGE_1="yes"
BUILD_GCC_STAGE_2="yes"
BUILD_NEWLIB="yes"

# Check if user is root
if [ ${EUID} == 0 ]; then
    echo "Please don't run this script as root!"
    exit
fi

export ARCH=$(uname -m)
export TARGET="sh-elf"

# Detect OS for build/host machine triple
case "$(uname -s)" in
    Darwin)
        # Older config.sub doesn't know 'arm64', use 'aarch64'
        MACH_ARCH="${ARCH}"
        [[ "$MACH_ARCH" == "arm64" ]] && MACH_ARCH="aarch64"
        export BUILD_MACH="${MACH_ARCH}-apple-darwin$(uname -r)"
        export HOST_MACH="${MACH_ARCH}-apple-darwin$(uname -r)"
        export NUM_PROC=$(sysctl -n hw.ncpu)
        ;;
    *)
        export BUILD_MACH="${ARCH}-pc-linux-gnu"
        export HOST_MACH="${ARCH}-pc-linux-gnu"
        export NUM_PROC=$(nproc)
        ;;
esac

export PROGRAM_PREFIX="sh2-elf-"
export INSTALL_DIR="${INSTALL_DIR:-${PWD}/sh2-toolchain}"
export DOWNLOAD_DIR="${PWD}/download"
export ROOT_DIR="${PWD}"
export BUILD_DIR="${ROOT_DIR}/build"
export SRC_DIR="${ROOT_DIR}/source"

# Create main folders in the root
mkdir -p ${INSTALL_DIR}
mkdir -p ${BUILD_DIR}
mkdir -p ${SRC_DIR}
mkdir -p ${DOWNLOAD_DIR}

export PATH=$INSTALL_DIR/bin:$PATH

# Build binutils
if [ ${BUILD_BINUTILS} == "yes" ]; then
    ./binutils.sh
    if [ $? -ne 0 ]; then
        echo "Failed to build binutils, please check build.log"
        exit 1
    fi
fi

# Build GCC stage 1
if [ ${BUILD_GCC_STAGE_1} == "yes" ]; then
    ./gcc.sh
    if [ $? -ne 0 ]; then
        echo "Failed to build gcc stage 1, please check build.log"
        exit 1
    fi
fi

# Build newlib
if [ ${BUILD_NEWLIB} == "yes" ]; then
    ./newlib.sh
    if [ $? -ne 0 ]; then
        echo "Failed to build newlib, please check build.log"
        exit 1
    else
        # Build GCC stage 2 (with newlib)
        if [ ${BUILD_GCC_STAGE_2} == "yes" ]; then
            ./gcc.sh
            if [ $? -ne 0 ]; then
                echo "Failed to build gcc stage 2, please check build.log"
                exit 1
            fi
        fi
    fi
fi

echo "SH2 toolchain build complete: ${INSTALL_DIR}"
