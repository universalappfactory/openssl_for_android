#!/bin/bash -e

WORK_PATH=$(cd "$(dirname "$0")";pwd)
ANDROID_NDK_PATH=${WORK_PATH}/android-ndk-r21
OPENSSL_SOURCES_PATH=${WORK_PATH}/openssl-3.4.0
ANDROID_TARGET_API=$1
ANDROID_TARGET_ABI=$2
OUTPUT_PATH=${WORK_PATH}/openssl-3.4.0_${ANDROID_TARGET_ABI}

OPENSSL_TMP_FOLDER=/tmp/openssl_${ANDROID_TARGET_ABI}
mkdir -p ${OPENSSL_TMP_FOLDER}
cp -r ${OPENSSL_SOURCES_PATH}/* ${OPENSSL_TMP_FOLDER}

function build_library {
    mkdir -p ${OUTPUT_PATH}
    make SHLIB_EXT=-1.1.so && make install
    rm -rf ${OPENSSL_TMP_FOLDER}
    rm -rf ${OUTPUT_PATH}/bin
    rm -rf ${OUTPUT_PATH}/share
    rm -rf ${OUTPUT_PATH}/ssl
    rm -rf ${OUTPUT_PATH}/lib/engines*
    rm -rf ${OUTPUT_PATH}/lib/pkgconfig
    rm -rf ${OUTPUT_PATH}/lib/ossl-modules
    echo "Build completed! Check output libraries in ${OUTPUT_PATH}"
}

cd ${OPENSSL_TMP_FOLDER}

sed -i 's/.*-mandroid.*//' Configurations/15-android.conf
patch -p1 -N <<EOP
--- old/Configurations/unix-Makefile.tmpl   2018-09-11 14:48:19.000000000 +0200
+++ new/Configurations/unix-Makefile.tmpl   2018-10-18 09:06:27.282007245 +0200
@@ -43,12 +43,17 @@
      # will return the name from shlib(\$libname) with any SO version number
      # removed.  On some systems, they may therefore return the exact same
      # string.
-     sub shlib {
+     sub shlib_simple {
          my \$lib = shift;
          return () if \$disabled{shared} || \$lib =~ /\\.a$/;
-         return \$unified_info{sharednames}->{\$lib}. \$shlibvariant. '\$(SHLIB_EXT)';
+
+         if (windowsdll()) {
+             return \$lib . '\$(SHLIB_EXT_IMPORT)';
+         }
+         return \$lib .  '\$(SHLIB_EXT_SIMPLE)';
      }
-     sub shlib_simple {
+     
+   sub shlib {
          my \$lib = shift;
          return () if \$disabled{shared} || \$lib =~ /\\.a$/;

EOP

if [ "$ANDROID_TARGET_ABI" == "armeabi-v7a" ]
then
    export ANDROID_NDK_ROOT=${ANDROID_NDK_PATH}
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-clang/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-clang/prebuilt/linux-x86_64/bin:$PATH
    # cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-arm -D__ANDROID_API__=${ANDROID_TARGET_API} no-tests --prefix=${OUTPUT_PATH}
    build_library

elif [ "$ANDROID_TARGET_ABI" == "arm64-v8a" ]
then
    export ANDROID_NDK_ROOT=${ANDROID_NDK_PATH}
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-clang/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-clang/prebuilt/linux-x86_64/bin:$PATH
    # cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-arm64 -D__ANDROID_API__=${ANDROID_TARGET_API} no-tests --prefix=${OUTPUT_PATH}
    build_library

elif [ "$ANDROID_TARGET_ABI" == "x86" ]
then
    export ANDROID_NDK_ROOT=${ANDROID_NDK_PATH}
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-clang/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-clang/prebuilt/linux-x86_64/bin:$PATH
    # cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-x86 -D__ANDROID_API__=${ANDROID_TARGET_API} no-tests --prefix=${OUTPUT_PATH}
    build_library

elif [ "$ANDROID_TARGET_ABI" == "x86_64" ]
then
    export ANDROID_NDK_ROOT=${ANDROID_NDK_PATH}
    PATH=$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/arm-linux-androideabi-clang/prebuilt/linux-x86_64/bin:$ANDROID_NDK_ROOT/toolchains/aarch64-linux-android-clang/prebuilt/linux-x86_64/bin:$PATH
    # cd ${OPENSSL_TMP_FOLDER}
    ./Configure android-x86_64 -D__ANDROID_API__=${ANDROID_TARGET_API} no-tests --prefix=${OUTPUT_PATH}
    build_library

else
    echo "Unsupported target ABI: $ANDROID_TARGET_ABI"
    exit 1
fi
