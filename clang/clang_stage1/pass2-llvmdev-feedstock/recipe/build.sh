set -x

# Make osx work like linux.
sed -i.bak "s/NOT APPLE AND ARG_SONAME/ARG_SONAME/g" cmake/modules/AddLLVM.cmake
sed -i.bak "s/NOT APPLE AND NOT ARG_SONAME/NOT ARG_SONAME/g" cmake/modules/AddLLVM.cmake

mkdir build
cd build

export CMAKE_CXX_FLAGS="${CMAKE_CXX_FLAGS} -stdlib=libc++"
[[ $(uname) == Linux ]] && conditional_args="
      -DLLVM_USE_INTEL_JITEVENTS=ON
"

if [[$target_platform == osx-64 ]]; then
	conditional_args="
      -DCMAKE_OSX_ARCHITECTURES:STRING=x86_64 \
      -DCMAKE_FIND_FRAMEWORK=LAST
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
  \
  -DLIBCXX_ENABLE_ASSERTIONS:BOOL=OFF \
  -DLIBCXX_OVERRIDE_DARWIN_INSTALL:BOOL=ON \
  -DLIBCXX_SYSROOT:STRING="$(xcrun --show-sdk-path)" \
  -DLLDB_EXPORT_ALL_SYMBOLS:BOOL=ON \
  \
  -DLLVM_BUILD_EXTERNAL_COMPILER_RT:BOOL=ON \
  -DLLVM_BUILD_GLOBAL_ISEL:BOOL=ON \
  -DLLVM_BUILD_LLVM_C_DYLIB:BOOL=ON \
  -DLLVM_BUILD_LLVM_DYLIB:BOOL=ON \
  -DLLVM_CREATE_XCODE_TOOLCHAIN:BOOL=OFF \
  -DLLVM_ENABLE_ASSERTIONS:BOOL=OFF \
  -DLLVM_ENABLE_CXX1Y:BOOL=ON \
  -DLLVM_ENABLE_FFI:BOOL=OFF \
  -DLLVM_ENABLE_LIBCXX:BOOL=ON \
  -DLLVM_ENABLE_LIBCXXABI:BOOL=ON \
  -DLLVM_ENABLE_SPHINX:BOOL=OFF \
  -DLLVM_EXTERNALIZE_DEBUGINFO:BOOL=OFF
  -DLLVM_LINK_LLVM_DYLIB:BOOL=OFF \
  -DLLVM_OPTIMIZED_TABLEGEN:BOOL=ON \
  -DLLVM_PARALLEL_COMPILE_JOBS:STRING=8 \
  -DLLVM_PARALLEL_LINK_JOBS:STRING=8 \
  -DLLVM_TARGET_ARCH:STRING=host \
  -DLLVM_TARGETS_TO_BUILD:STRING=X86 \
  -DLLVM_TOOL_DSYMUTIL_BUILD:BOOL=ON \
  -DLLVM_USE_SPLIT_DWARF:BOOL=OFF \
  \
  -DLIBOMP_OSX_ARCHITECTURES:STRING=x86_64 \
  -DLIBOMP_USE_HWLOC:BOOL=ON \

  \
  -DPOLLY_ENABLE_GPGPU_CODEGEN:BOOL=ON
"
fi

cmake -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
      -DCMAKE_BUILD_TYPE=Release \
      -DLLVM_ENABLE_RTTI=ON \
      -DLLVM_INCLUDE_TESTS=ON \
      -DLLVM_INCLUDE_GO_TESTS=OFF \
      -DLLVM_INCLUDE_UTILS=ON \
      -DLLVM_INSTALL_UTILS=ON \
      -DLLVM_UTILS_INSTALL_DIR=libexec/llvm \
      -DLLVM_INCLUDE_DOCS=OFF \
      -DLLVM_INCLUDE_EXAMPLES=OFF \
      -DLLVM_ENABLE_TERMINFO=OFF \
      -DLLVM_ENABLE_LIBXML2=OFF \
      -DLLVM_ENABLE_ZLIB=ON \
      -DHAVE_LIBEDIT=OFF \
      -DLLVM_EXPERIMENTAL_TARGETS_TO_BUILD=WebAssembly \
      -DLLVM_BUILD_LLVM_DYLIB=yes \
      -DLLVM_LINK_LLVM_DYLIB=yes \
      ${conditional_args} ..

make -j${CPU_COUNT}

if [[ "${target_platform}" == "linux-64" || "${target_platform}" == "osx-64" ]]; then
    export TEST_CPU_FLAG="-mcpu=haswell"
else
    export TEST_CPU_FLAG=""
fi

bin/opt -S -vector-library=SVML $TEST_CPU_FLAG -O3 $RECIPE_DIR/numba-3016.ll | bin/FileCheck $RECIPE_DIR/numba-3016.ll || exit $?

#make -j${CPU_COUNT} check-llvm

cd ../test
../build/bin/llvm-lit -vv Transforms ExecutionEngine Analysis CodeGen/X86
