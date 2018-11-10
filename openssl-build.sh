#!/bin/bash

#  Created by FangYuan Gui on 13.01.16.
#  Copyright 2011 FangYuan Gui. All rights reserved.
#
#  Licensed under the Apache License

set -u

# 压缩文件名（必须是 .tar 压缩格式，不然无法解压缩）
OPENSSL_COMPRESSED_FN="openssl-1.0.2o.tar"
#echo "${OPENSSL_COMPRESSED_FN}"

# 解压缩后的文件名（即去掉压缩后缀 .tar*）
OPENSSL_SRC_DIR=${OPENSSL_COMPRESSED_FN//.tar*/}
#echo "${OPENSSL_SRC_DIR}"

# ${PWD}：当前所在文件目录
# 编译目录
OPENSSL_BUILD_DIR=${PWD}/${OPENSSL_SRC_DIR}-build
#echo "${OPENSSL_BUILD_DIR}"

# 编译目录下的log日志目录
OPENSSL_BUILD_LOG_DIR=${OPENSSL_BUILD_DIR}/log
#echo "${OPENSSL_BUILD_LOG_DIR}"

# 编译目录下最后生成通用库的目录
OPENSSL_BUILD_UNIVERSAL_DIR=${OPENSSL_BUILD_DIR}/universal
#echo "${OPENSSL_BUILD_UNIVERSAL_DIR}"

# 通用库目录下的lib目录
OPENSSL_UNIVERSAL_LIB_DIR=${OPENSSL_BUILD_UNIVERSAL_DIR}/lib
#echo "${OPENSSL_UNIVERSAL_LIB_DIR}"


# 删除解压缩后的文件
rm -rf ${OPENSSL_SRC_DIR}
rm -rf ${OPENSSL_BUILD_DIR}

# 解压缩tar文件，失败则退出
tar xfz ${OPENSSL_COMPRESSED_FN} || exit 1

# 创建目录
if [ ! -d "${OPENSSL_BUILD_UNIVERSAL_DIR}" ]; then
mkdir -p "${OPENSSL_BUILD_UNIVERSAL_DIR}"
fi

if [ ! -d "${OPENSSL_BUILD_LOG_DIR}" ]; then
mkdir "${OPENSSL_BUILD_LOG_DIR}"
fi

if [ ! -d "${OPENSSL_UNIVERSAL_LIB_DIR}" ]; then
mkdir "${OPENSSL_UNIVERSAL_LIB_DIR}"
fi


pushd .
# 进入OPENSSL_SRC_DIR目录
cd ${OPENSSL_SRC_DIR}

# 查找 clang 编译器 目录
# /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
CLANG=$(xcrun --find clang)

# 查找 iPhone SDK 目录
# /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS10.1.sdk
IPHONE_OS_SDK_PATH=$(xcrun -sdk iphoneos --show-sdk-path)

# IPHONE_OS_SDK_PATH 目录中 SDKs 的上级目录
# /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer
IPHONE_OS_CROSS_TOP=${IPHONE_OS_SDK_PATH//\/SDKs*/}

# IPHONE_OS_SDK_PATH 目录中最后一级目录
# iPhoneOS10.1.sdk
IPHONE_OS_CROSS_SDK=${IPHONE_OS_SDK_PATH##*/}

# iPhone 模拟器 sdk 目录
# /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneSimulator10.1.sdk
IPHONE_SIMULATOR_SDK_PATH=$(xcrun -sdk iphonesimulator --show-sdk-path)

# IPHONE_SIMULATOR_SDK_PATH 目录中 SDKs 的上级目录
# /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer
IPHONE_SIMULATOR_CROSS_TOP=${IPHONE_SIMULATOR_SDK_PATH//\/SDKs*/}

# IPHONE_SIMULATOR_SDK_PATH 目录中最后一级目录
# iPhoneSimulator10.1.sdk
IPHONE_SIMULATOR_CROSS_SDK=${IPHONE_SIMULATOR_SDK_PATH##*/}


# 需要编译的架构平台列表
ARCH_LIST=("armv7" "armv7s" "arm64" "i386" "x86_64")
# 需要编译的平台数量
ARCH_COUNT=${#ARCH_LIST[@]}
# 各架构sdk所在的目录
CROSS_TOP_LIST=(${IPHONE_OS_CROSS_TOP} ${IPHONE_OS_CROSS_TOP} ${IPHONE_OS_CROSS_TOP} ${IPHONE_SIMULATOR_CROSS_TOP} ${IPHONE_SIMULATOR_CROSS_TOP})

# 各架构sdk名
CROSS_SDK_LIST=(${IPHONE_OS_CROSS_SDK} ${IPHONE_OS_CROSS_SDK} ${IPHONE_OS_CROSS_SDK} ${IPHONE_SIMULATOR_CROSS_SDK} ${IPHONE_SIMULATOR_CROSS_SDK})

# 编译配置
config_make()
{
# 接收第一个参数
ARCH=$1;
# 接收第二个参数，导入配置文件
export CROSS_TOP=$2
# 接收第三个参数，导入配置文件
export CROSS_SDK=$3

# -miphoneos-version-min选项指定最小支持的iOS版本；
# -fembed-bitcode选项开启bitcode的支持，去掉就不支持bitcode
export CC="${CLANG} -arch ${ARCH} -miphoneos-version-min=8.0 -fembed-bitcode"
# export CC="${CLANG} -arch ${ARCH} -miphoneos-version-min=8.0"

make clean &> ${OPENSSL_BUILD_LOG_DIR}/make_clean.log


# 配置编译条件
echo "configure for ${ARCH}..."
if [ "x86_64" == ${ARCH} ]; then
# 编译x86_64平台的openssl，Configure时需要指定no-asm选项，否则会报错；
./Configure iphoneos-cross --prefix=${OPENSSL_BUILD_DIR}/${ARCH} no-asm &> ${OPENSSL_BUILD_LOG_DIR}/${ARCH}-conf.log
else
./Configure iphoneos-cross --prefix=${OPENSSL_BUILD_DIR}/${ARCH} &> ${OPENSSL_BUILD_LOG_DIR}/${ARCH}-conf.log
fi


# 编译
echo "build for ${ARCH}..."
make &> ${OPENSSL_BUILD_LOG_DIR}/${ARCH}-make.log
make install_sw &> ${OPENSSL_BUILD_LOG_DIR}/${ARCH}-make-install.log

# unset命令用于删除已定义的shell变量（包括环境变量）和shell函数。unset命令不能够删除具有只读属性的shell变量和环境变量。
unset CC
unset CROSS_SDK
unset CROSS_TOP

echo -e "\n"
}

# 执行config_make()函数，进行配置与编译
# 传入三个参数${ARCH_LIST[i]} ${CROSS_TOP_LIST[i]} ${CROSS_SDK_LIST[i]}
for ((i=0; i < ${ARCH_COUNT}; i++))
do
config_make ${ARCH_LIST[i]} ${CROSS_TOP_LIST[i]} ${CROSS_SDK_LIST[i]}
done

# 创建lib库
create_lib()
{
LIB_SRC=lib/$1
LIB_DST=${OPENSSL_UNIVERSAL_LIB_DIR}/$1
LIB_PATHS=( ${ARCH_LIST[@]/#/${OPENSSL_BUILD_DIR}/} )
LIB_PATHS=( ${LIB_PATHS[@]/%//${LIB_SRC}} )
lipo ${LIB_PATHS[@]} -create -output ${LIB_DST}
}

create_lib "libssl.a"
create_lib "libcrypto.a"

cp -R ${OPENSSL_BUILD_DIR}/armv7/include ${OPENSSL_BUILD_UNIVERSAL_DIR}

popd

rm -rf ${OPENSSL_SRC_DIR}

echo "done."
