#!/bin/bash

#  Automatic build script for libassuan
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 30.01.11.
#  Copyright 2010 Felix Schulze. All rights reserved.
#  Copyright 2012 Jahn Bertsch. All rights reserverd.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here
#
SDKVERSION="7.1"
VERSION="2.1.1"
#
###########################################################################
#  No changes required beyond this point
CURRENTPATH=`pwd`
ARCHS="i386 x86_64 armv7 armv7s arm64"
NAME=libassuan
DEVELOPER=`xcode-select -print-path`

set -e
if [ ! -e ${NAME}-${VERSION}.tar.bz2 ]; then
echo "Downloading ${NAME}-${VERSION}.tar.bz2"
curl -O ftp://ftp.gnupg.org/gcrypt/${NAME}/${NAME}-${VERSION}.tar.bz2
echo
else
echo "Using ${NAME}-${VERSION}.tar.bz2"
fi

mkdir -p bin
mkdir -p lib
mkdir -p src

for ARCH in ${ARCHS}
do
if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
then
PLATFORM="iPhoneSimulator"
else
PLATFORM="iPhoneOS"
fi

rm -rf src/${NAME}-${VERSION}
tar zxf ${NAME}-${VERSION}.tar.bz2 -C src
cd src/${NAME}-${VERSION}

echo "Building ${NAME} for ${PLATFORM} ${SDKVERSION} ${ARCH}"

export BUILD_DEVROOT="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
export BUILD_SDKROOT="${BUILD_DEVROOT}/SDKs/${PLATFORM}${SDKVERSION}.sdk"
export LD=${BUILD_DEVROOT}/usr/bin/ld
export CC=${DEVELOPER}/usr/bin/gcc
export CXX=${DEVELOPER}/usr/bin/g++
if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]];
then
export AR=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ar
export AS=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/as
export NM=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/nm
export RANLIB=${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/ranlib
else
export AR=${BUILD_DEVROOT}/usr/bin/ar
export AS=${BUILD_DEVROOT}/usr/bin/as
export NM=${BUILD_DEVROOT}/usr/bin/nm
export RANLIB=${DEVROOT}/usr/bin/ranlib
fi
export LDFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -L${CURRENTPATH}/lib -miphoneos-version-min=7.0"
export CFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -I${CURRENTPATH}/include -miphoneos-version-min=7.0"
export CXXFLAGS="-arch ${ARCH} -pipe -no-cpp-precomp -isysroot ${BUILD_SDKROOT} -I${CURRENTPATH}/include -miphoneos-version-min=7.0"

HOST=${ARCH}
if [ "${ARCH}" == "arm64" ];
then
HOST="aarch64"
fi

mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-${NAME}-${VERSION}.log"

echo "Follow the build log with: tail -f ${LOG}"
echo "Please stand by..."

./configure --host=${HOST}-apple-darwin --prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --with-libgpg-error-prefix="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" --disable-shared >> "${LOG}" 2>&1

make >> "${LOG}" 2>&1
make install >> "${LOG}" 2>&1
cd ${CURRENTPATH}
rm -rf src/${NAME}-${VERSION}

done

echo "Build library..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/lib/libassuan.a ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-x86_64.sdk/lib/libassuan.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7.sdk/lib/libassuan.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-armv7s.sdk/lib/libassuan.a ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-arm64.sdk/lib/libassuan.a -output ${CURRENTPATH}/lib/libassuan.a

mkdir -p ${CURRENTPATH}/include/${NAME}
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-i386.sdk/include/assuan.h ${CURRENTPATH}/include/libassuan
echo "Static libary available at lib/${NAME}.a"
