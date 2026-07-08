#!/bin/bash

# Copyright (c) Joby Aviation 2022
# Original authors: Thulio Ferraz Assis (thulio@aspect.dev), Aspect.dev
#
# Copyright (c) Thulio Ferraz Assis 2024-2025
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit -o nounset -o pipefail

readonly host_arch="${HOST_ARCH:-x86_64}"
case "${host_arch}" in
    x86_64)  host_triplet="x86_64-linux-gnu"  ;;
    aarch64) host_triplet="aarch64-linux-gnu"  ;;
    *)       >&2 echo "ERROR: Unsupported HOST_ARCH '${host_arch}'. Supported: x86_64, aarch64"; exit 1 ;;
esac

args=(
    --with-pic
)

if [[ "${ARCH}" == "aarch64" ]]; then
    readonly target="aarch64-linux"
    args+=(
        --build=x86_64-linux-gnu
        --target="${target}"
    )
    if [[ "${IS_GCC_BUILD:-}" == "1" ]]; then
        args+=(--host="${host_triplet}")
        readonly toolchain_root="/opt/gcc/${host_arch}"
        readonly toolchain_prefix="${toolchain_root}/bin/${host_arch}-linux"
    else
        args+=(--host="${target}")
        readonly toolchain_root="/opt/gcc/aarch64"
        readonly toolchain_prefix="${toolchain_root}/bin/aarch64-linux"
    fi
elif [[ "${ARCH}" == "armv7" ]]; then
    readonly target="arm-linux-gnueabihf"
    args+=(
        --build=x86_64-linux-gnu
        --target="${target}"
        --with-arch=armv7-a
        --with-fpu=vfpv3-d16
        --with-float=hard
        --with-mode=arm
    )
    if [[ "${IS_GCC_BUILD:-}" == "1" ]]; then
        args+=(--host="${host_triplet}")
        readonly toolchain_root="/opt/gcc/${host_arch}"
        readonly toolchain_prefix="${toolchain_root}/bin/${host_arch}-linux"
    else
        args+=(--host="${target}")
        readonly toolchain_root="/opt/gcc/armv7"
        readonly toolchain_prefix="${toolchain_root}/bin/arm-linux-gnueabihf"
    fi
elif [[ "${ARCH}" == "x86_64" ]]; then
    readonly target="x86_64-linux"
    args+=(
        --build=x86_64-linux-gnu
        --target="${target}"
    )
    if [[ "${IS_GCC_BUILD:-}" == "1" ]]; then
        args+=(--host="${host_triplet}")
        readonly toolchain_root="/opt/gcc/${host_arch}"
        readonly toolchain_prefix="${toolchain_root}/bin/${host_arch}-linux"
    else
        args+=(--host="${target}")
        readonly toolchain_root="/opt/gcc/x86_64"
        readonly toolchain_prefix="${toolchain_root}/bin/x86_64-linux"
    fi
fi

export AR="${toolchain_prefix}-ar"
export AS="${toolchain_prefix}-as"
export CC="${toolchain_prefix}-gcc"
export CPP="${toolchain_prefix}-cpp"
export CXX="${toolchain_prefix}-g++"
export LD="${toolchain_prefix}-ld"
export NM="${toolchain_prefix}-nm"
export OBJCOPY="${toolchain_prefix}-objcopy"
export OBJDUMP="${toolchain_prefix}-objdump"
export RANLIB="${toolchain_prefix}-ranlib"
export READELF="${toolchain_prefix}-readelf"
export STRIP="${toolchain_prefix}-strip"

args+=("${@}")

# Canadian cross (build != host): GCC's configure cannot use the just-built compiler to
# build the target libraries, and its fallback resolution is unsafe — when build == target
# (e.g. an x86_64-targeting toolchain hosted on aarch64) it accepts the build machine's
# unprefixed 'cc' (the distro compiler, wrong version) because no '${target}-cc' name
# exists anywhere. Pin every target compiler to the same-version cross toolchain instead.
if [[ "${IS_GCC_BUILD:-}" == "1" && "${host_arch}" != "x86_64" \
        && -d /opt/gcc/same_version_cross ]]; then
    readonly cross_bin="/opt/gcc/same_version_cross/bin"
    args+=(
        GCC_FOR_TARGET="${cross_bin}/${target}-gcc"
        CC_FOR_TARGET="${cross_bin}/${target}-gcc"
        CXX_FOR_TARGET="${cross_bin}/${target}-g++"
        RAW_CXX_FOR_TARGET="${cross_bin}/${target}-g++"
        GFORTRAN_FOR_TARGET="${cross_bin}/${target}-gfortran"
    )
fi

readonly common_flags=(
    -O2
    -falign-functions=32
    -ffunction-sections
    -fdata-sections
)

# Host-side binaries (IS_GCC_BUILD) running on a non-x86_64 host must link libgcc/libstdc++
# statically to stay hermetic. Target-side artifacts (glibc, libX11, ...) must not vary with
# HOST_ARCH, so this never applies to them.
cross_ldflags=""
if [[ "${IS_GCC_BUILD:-}" == "1" && "${host_arch}" != "x86_64" ]]; then
    cross_ldflags="-static-libgcc -static-libstdc++"
fi
readonly cross_ldflags

args+=(
    CFLAGS="${common_flags[*]}"
    CXXFLAGS="${common_flags[*]}"
    LDFLAGS="-Wl,-z,max-page-size=0x1000 -Wl,--strip-all -Wl,--as-needed ${cross_ldflags}"
)

../configure "${args[@]}" 1> >(tee configure.stdout) 2> >(>&2 tee configure.stderr)
