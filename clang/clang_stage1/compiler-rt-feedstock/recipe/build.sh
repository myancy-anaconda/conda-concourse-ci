if [[ "$target_platform" == "osx-64" ]]; then
    EXTRA_CMAKE_ARGS="-DDARWIN_osx_ARCHS=x86_64 -DCOMPILER_RT_ENABLE_IOS=Off"
    EXTRA_CMAKE_ARGS="$EXTRA_CMAKE_ARGS -DDARWIN_macosx_CACHED_SYSROOT=${CONDA_BUILD_SYSROOT} -DCMAKE_LIBTOOL=$LIBTOOL"
fi

# Prep build
cp -R "${PREFIX}/lib/cmake/llvm" "${PREFIX}/lib/cmake/modules/"

mkdir build
cd build

INSTALL_PREFIX=${PREFIX}/lib/clang/${PKG_VERSION}

cmake \
    -G "Unix Makefiles" \
    -DCOMPILER_RT_STANDALONE_BUILD:BOOL=ON \
    -DCMAKE_BUILD_TYPE="Release" \
    -DCMAKE_PREFIX_PATH:PATH="${PREFIX}" \
    -DCMAKE_INSTALL_PREFIX:PATH="${INSTALL_PREFIX}" \
    -DCMAKE_RUNTIME_OUTPUT_DIRECTORY:PATH="${INSTALL_PREFIX}/lib" \
    -DCMAKE_ARCHIVE_OUTPUT_DIRECTORY:PATH="${INSTALL_PREFIX}/lib" \
    -DCMAKE_MODULE_PATH:PATH="${PREFIX}/lib/cmake" \
    -DLLVM_CONFIG_PATH:PATH="${PREFIX}/bin/llvm-config" \
    -DPYTHON_EXECUTABLE:PATH="${BUILD_PREFIX}/bin/python" \
    -DCLANG_DEFAULT_CXX_STDLIB:STRING=libc++ \
    -DCOMPILER_RT_USE_BUILTINS_LIBRARY:BOOL=ON \
    -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
  -DCMAKE_FIND_FRAMEWORK=LAST \
  -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=10.11 \
  -DCMAKE_OSX_SYSROOT:STRING="$(xcrun --show-sdk-path)" \
  -DCMAKE_SKIP_INSTALL_RPATH:BOOL=NO \
  -DCMAKE_SKIP_RPATH:BOOL=NO \
  -DCLANG_DEFAULT_CXX_STDLIB:STRING=libc++ \
  -DLIBCLANG_BUILD_STATIC:BOOL=ON \
  -DLIBCXX_ABI_UNSTABLE:BOOL=ON \
  -DLIBCXX_CONFIGURE_IDE:BOOL=ON \
  -DLIBCXXABI_ENABLE_ASSERTIONS:BOOL=OFF \
  -DLIBCXXABI_SYSROOT:STRING="$(xcrun --show-sdk-path)" \
  -DLIBCXXABI_USE_LLVM_UNWINDER:BOOL=OFF \
    -DCMAKE_LINKER="$LD" \
    ${EXTRA_CMAKE_ARGS} \
    "${SRC_DIR}"

# Build step
make -j$CPU_COUNT VERBOSE=1

# Install step
make install -j$CPU_COUNT

# Clean up after build
rm -rf "${PREFIX}/lib/cmake/modules"
