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

# Global ARG needed so HOST_ARCH can be used in FROM instructions (stage selectors).
# This allows us to conditionally depend on either a single gcc build (if HOST_ARCH=x86_64),
# or a Canadian Cross build (using a bootstrapped gcc to cross-bootstrap gcc for another host).
ARG HOST_ARCH=x86_64

FROM ubuntu:22.04 AS base_image

WORKDIR /bin
SHELL ["/bin/bash", "-c"]

WORKDIR /
RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --yes \
                bison \
                bzip2 \
                curl \
                dpkg-dev \
                file \
                gawk \
                gettext \
                less \
                libz-dev \
                m4 \
                make \
                pkg-config \
                python3 \
                rsync \
                texinfo \
                xsltproc \
                xz-utils \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

####################################################################################################
# Download steps
####################################################################################################

FROM base_image AS kernel_download
WORKDIR /downloads/kernel
RUN curl --fail-early --location https://github.com/torvalds/linux/archive/refs/tags/v4.9.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -

FROM base_image AS glibc_download
ARG GLIBC_VERSION=2.28
WORKDIR /downloads/glibc
RUN curl --fail-early --location https://ftp.gnu.org/gnu/glibc/glibc-${GLIBC_VERSION}.tar.xz \
        | tar --xz --extract --strip-components=1 --file -

FROM base_image AS gcc_download
ARG GCC_VERSION
WORKDIR /downloads/gcc
RUN curl --fail-early --location https://ftp.gnu.org/gnu/gcc/gcc-${GCC_VERSION}/gcc-${GCC_VERSION}.tar.xz \
        | tar --xz --extract --strip-components=1 --file -
RUN ./contrib/download_prerequisites

FROM base_image AS util-macros_download
WORKDIR /downloads/util-macros
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/util/util-macros-1.17.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS xproto_download
WORKDIR /downloads/xproto
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/proto/xproto-7.0.23.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS xextproto_download
WORKDIR /downloads/xextproto
RUN curl --fail-early --location https://www.x.org/releases/individual/proto/xextproto-7.3.0.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS kbproto_download
WORKDIR /downloads/kbproto
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/proto/kbproto-1.0.6.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS inputproto_download
WORKDIR /downloads/inputproto
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/proto/inputproto-2.2.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS xcb-proto_download
WORKDIR /downloads/xcb-proto
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/xcb/xcb-proto-1.7.1.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS libXau_download
WORKDIR /downloads/libXau
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/lib/libXau-1.0.7.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS xtrans_download
WORKDIR /downloads/xtrans
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/lib/xtrans-1.2.7.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS libxcb_download
WORKDIR /downloads/libxcb
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/xcb/libxcb-1.8.1.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS libpthread-stubs_download
WORKDIR /downloads/libpthread-stubs
RUN curl --fail-early --location https://www.x.org/releases/individual/xcb/libpthread-stubs-0.4.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS libX11_download
WORKDIR /downloads/libX11
RUN curl --fail-early --location https://www.x.org/releases/X11R7.7/src/lib/libX11-1.5.0.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS binutils_download
WORKDIR /downloads/binutils
RUN curl --fail-early --location https://ftp.gnu.org/gnu/binutils/binutils-2.46.0.tar.xz \
        | tar --xz --extract --strip-components=1 --file -
FROM base_image AS llvm_download
ARG LLVM_VERSION=22.1.7
WORKDIR /downloads/llvm
RUN curl --fail-early --location https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz \
        | tar --xz --extract --strip-components=1 --file - \
                "llvm-project-${LLVM_VERSION}.src/cmake" \
                "llvm-project-${LLVM_VERSION}.src/third-party" \
                "llvm-project-${LLVM_VERSION}.src/libunwind/include" \
                "llvm-project-${LLVM_VERSION}.src/llvm" \
                "llvm-project-${LLVM_VERSION}.src/lld"
FROM base_image AS zlib_download
ARG ZLIB_VERSION=1.3.1
WORKDIR /downloads/zlib
RUN curl --fail-early --location https://github.com/madler/zlib/releases/download/v${ZLIB_VERSION}/zlib-${ZLIB_VERSION}.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS zstd_download
ARG ZSTD_VERSION=1.5.6
WORKDIR /downloads/zstd
RUN curl --fail-early --location https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz \
        | tar --gzip --extract --strip-components=1 --file -
FROM base_image AS patchelf_download
WORKDIR /downloads/patchelf
# patchelf runs on the build machine (not on HOST_ARCH), and it can edit ELF files of any
# architecture, so it must match the machine performing the build.
RUN curl --fail-early --location https://github.com/NixOS/patchelf/releases/download/0.18.0/patchelf-0.18.0-$(uname -m).tar.gz \
        | tar --gz --extract --strip-components=1 --file -

FROM base_image AS build_image

ARG BOOTSTRAP_GCC_VERSION=14.3.0
ARG BOOTSTRAP_RELEASE=22052026
ARG BOOTSTRAP_BASE_URL=https://github.com/f0rmiga/gcc-builds/releases/download

WORKDIR /opt/gcc/aarch64
RUN curl --fail-early --location ${BOOTSTRAP_BASE_URL}/${BOOTSTRAP_RELEASE}/gcc-toolchain-${BOOTSTRAP_GCC_VERSION}-aarch64.tar.xz \
        | tar --xz --extract --file -
WORKDIR /opt/gcc/armv7
RUN curl --fail-early --location ${BOOTSTRAP_BASE_URL}/${BOOTSTRAP_RELEASE}/gcc-toolchain-${BOOTSTRAP_GCC_VERSION}-armv7.tar.xz \
        | tar --xz --extract --file -
WORKDIR /opt/gcc/armv7/bin
RUN --mount=source=create_symlinks.sh,target=/usr/bin/create_symlinks.sh create_symlinks.sh arm-linux-gnueabihf- arm-linux-
WORKDIR /opt/gcc/x86_64
RUN curl --fail-early --location ${BOOTSTRAP_BASE_URL}/${BOOTSTRAP_RELEASE}/gcc-toolchain-${BOOTSTRAP_GCC_VERSION}-x86_64.tar.xz \
        | tar --xz --extract --file -
WORKDIR /opt/gcc/x86_64/bin
RUN --mount=source=create_symlinks.sh,target=/usr/bin/create_symlinks.sh create_symlinks.sh "" x86_64-linux-
WORKDIR /

####################################################################################################
# Setup steps
####################################################################################################

ARG ARCH
ENV ARCH="${ARCH}"
RUN if [ -z "${ARCH}" ]; then >&2 echo "Missing ARCH argument"; exit 1; fi

ARG HOST_ARCH
ENV HOST_ARCH="${HOST_ARCH}"
RUN case "${HOST_ARCH}" in \
        x86_64|aarch64) ;; \
        *) >&2 echo "Unsupported HOST_ARCH '${HOST_ARCH}'. Supported: x86_64, aarch64"; exit 1 ;; \
    esac
RUN rm --force /lib/cpp \
        && if [ "${ARCH}" = "armv7" ]; then \
                ln --symbolic /opt/gcc/armv7/bin/arm-linux-gnueabihf-cpp /lib/cpp; \
        else \
                ln --symbolic "/opt/gcc/${ARCH}/bin/${ARCH}-linux-cpp" /lib/cpp; \
        fi

ENV PATH="/opt/gcc/x86_64/bin:/opt/gcc/${ARCH}/bin:${PATH}"

####################################################################################################
# Build steps
####################################################################################################

FROM build_image AS kernel
COPY --from=kernel_download /downloads/kernel /build/kernel
WORKDIR /build/kernel
RUN --mount=source=build_kernel.sh,target=/usr/bin/build_kernel.sh build_kernel.sh

FROM build_image AS glibc
COPY --from=kernel /var/install/kernel /var/install/kernel
COPY --from=glibc_download /downloads/glibc /build/glibc
WORKDIR /build/glibc/build
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        --enable-kernel=4.9 \
        --disable-werror \
        --prefix=/usr \
        --with-headers=/var/install/kernel/usr/include \
        --with-tls \
        libc_cv_slibdir=/lib \
        || (cat config.log && exit 1)
RUN make all --jobs $(nproc)
RUN make DESTDIR=/var/install/glibc install

# gcc_x86_64: always builds the x86_64-hosted cross-compiler at the requested GCC version,
# regardless of the top-level HOST_ARCH. For x86_64 builds this IS the final product.
# For aarch64 builds it is the same-version intermediate for the Canadian cross, ensuring
# libgcc/libstdc++ are compiled by a matching compiler rather than the bootstrap.
FROM build_image AS gcc_x86_64
COPY --from=gcc_download /downloads/gcc /build/gcc
WORKDIR /build/gcc/build
COPY --from=kernel /var/install/kernel /var/install/gcc/sysroot
COPY --from=glibc /var/install/glibc /var/install/gcc/sysroot
ENV HOST_ARCH=x86_64
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh IS_GCC_BUILD=1 configure.sh \
        --disable-bootstrap \
        --enable-default-pie \
        --enable-languages=c,c++,fortran,lto \
        --disable-multilib \
        --prefix=/var/install/gcc \
        --enable-libstdcxx-threads \
        --with-linker-hash-style=gnu \
        --with-build-sysroot=/var/install/gcc/sysroot \
        --with-sysroot=/RELOCATABLE_SYSROOT \
        || (cat config.log && exit 1)
RUN grep -rl '/RELOCATABLE_SYSROOT' . | xargs sed -i 's|/RELOCATABLE_SYSROOT|$(exec_prefix)/sysroot|g'
RUN make --jobs $(nproc) all-gcc
RUN make install-gcc
ENV PATH="/var/install/gcc/bin:${PATH}"
RUN make --jobs $(nproc)
RUN make install

FROM build_image AS binutils_base
COPY --from=binutils_download /downloads/binutils /build/binutils
WORKDIR /build/binutils/build
COPY --from=kernel /var/install/kernel /var/install/gcc/sysroot
COPY --from=glibc /var/install/glibc /var/install/gcc/sysroot

# binutils_x86_64: always x86_64-hosted. For x86_64 builds this is the final product; for
# aarch64 builds it provides the same-version cross assembler and linker consumed by the
# Canadian cross (gcc_aarch64).
FROM binutils_base AS binutils_x86_64
ENV HOST_ARCH=x86_64
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh IS_GCC_BUILD=1 configure.sh \
        --enable-64-bit-bfd \
        --enable-default-pie \
        --enable-gold \
        --enable-plugins \
        --disable-shared \
        --enable-static \
        --with-static-standard-libraries \
        --enable-threads \
        --prefix=/var/install/binutils \
        --with-build-sysroot=/var/install/gcc/sysroot \
        --with-lib-path=/var/install/glibc/usr/lib \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install

# gcc_aarch64: Canadian cross. Uses
# - gcc_x86_64 as the compiler and
# - binutils_x86_64 as the cross-assembler and linker
# to build a gcc that runs on aarch64.
FROM build_image AS gcc_aarch64
COPY --from=gcc_x86_64 /var/install/gcc /opt/gcc/same_version_cross
COPY --from=binutils_x86_64 /var/install/binutils /opt/gcc/same_version_cross
COPY --from=gcc_download /downloads/gcc /build/gcc
WORKDIR /build/gcc/build
COPY --from=kernel /var/install/kernel /var/install/gcc/sysroot
COPY --from=glibc /var/install/glibc /var/install/gcc/sysroot
# The same-version cross toolchain comes first in PATH so that the ${target}-prefixed
# binutils and any tool not explicitly pinned resolve to it instead of the bootstrap
# toolchain in /opt/gcc. The target compilers (*_FOR_TARGET) are pinned to absolute paths
# under /opt/gcc/same_version_cross by configure.sh, and the host-side compilers are
# unaffected: configure.sh exports those as absolute paths too.
ENV PATH="/opt/gcc/same_version_cross/bin:${PATH}"
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh \
    IS_GCC_BUILD=1 configure.sh \
        --disable-bootstrap \
        --enable-default-pie \
        --enable-languages=c,c++,fortran,lto \
        --disable-multilib \
        --prefix=/var/install/gcc \
        --enable-libstdcxx-threads \
        --with-linker-hash-style=gnu \
        --with-build-sysroot=/var/install/gcc/sysroot \
        --with-sysroot=/RELOCATABLE_SYSROOT \
        || (cat config.log && exit 1)
RUN grep -rl '/RELOCATABLE_SYSROOT' . | xargs sed -i 's|/RELOCATABLE_SYSROOT|$(exec_prefix)/sysroot|g'
RUN make --jobs $(nproc) all-gcc
RUN make install-gcc
RUN make --jobs $(nproc)
RUN make install


# binutils_aarch64: cross-compiled with the bootstrap toolchain so it runs on aarch64.
# Note that we need everything to be statically linked to support cross-compilation
# For instance:
#  - `--with-static-standard-libraries`, which should be turned on when we're building GCC: https://sourceware.org/legacy-ml/gdb-cvs/2019-08/msg00123.html
#  - `--disable-gprofng`, because it links against dynamic stdlibs regardless of the value of the flag above.
FROM binutils_base AS binutils_aarch64
ENV HOST_ARCH=aarch64
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh IS_GCC_BUILD=1 configure.sh \
        --enable-64-bit-bfd \
        --enable-default-pie \
        --enable-gold \
        --enable-plugins \
        --disable-shared \
        --enable-static \
        --with-static-standard-libraries \
        --enable-threads \
        --disable-gprofng \
        --prefix=/var/install/binutils \
        --with-build-sysroot=/var/install/gcc/sysroot \
        --with-lib-path=/var/install/glibc/usr/lib \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install

# Pick the x86_64 or aarch64 variants for gcc and binutils based on HOST_ARCH.
# The interpolation below is resolved from the global ARG declared at the top of this file.
FROM gcc_${HOST_ARCH} AS gcc

FROM binutils_${HOST_ARCH} AS binutils

FROM build_image AS lld
COPY --from=llvm_download /downloads/llvm /build/llvm
RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --yes \
                cmake \
                ninja-build \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*
COPY --from=zlib_download /downloads/zlib /build/zlib
WORKDIR /build/zlib
RUN CC=/opt/gcc/${HOST_ARCH}/bin/${HOST_ARCH}-linux-gcc ./configure --static --prefix=/var/install/zlib \
        && make --jobs $(nproc) \
        && make install
COPY --from=zstd_download /downloads/zstd /build/zstd
WORKDIR /build/zstd/lib
RUN make --jobs $(nproc) \
        CC=/opt/gcc/${HOST_ARCH}/bin/${HOST_ARCH}-linux-gcc \
        PREFIX=/var/install/zstd \
        install-static install-includes
WORKDIR /build/llvm/build
RUN case "${ARCH}" in \
                x86_64) llvm_target=X86 ;; \
                armv7) llvm_target=ARM ;; \
                aarch64) llvm_target=AArch64 ;; \
                *) >&2 echo "Unsupported ARCH '${ARCH}' for LLVM_TARGETS_TO_BUILD"; exit 1 ;; \
        esac \
        && cmake -G Ninja \
        -S /build/llvm/llvm \
        -B . \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/var/install/lld \
        -DCMAKE_C_COMPILER=/opt/gcc/${HOST_ARCH}/bin/${HOST_ARCH}-linux-gcc \
        -DCMAKE_CXX_COMPILER=/opt/gcc/${HOST_ARCH}/bin/${HOST_ARCH}-linux-g++ \
        -DCMAKE_SYSTEM_NAME=Linux \
        -DCMAKE_SYSTEM_PROCESSOR=${HOST_ARCH} \
        -DLLVM_ENABLE_PROJECTS=lld \
        -DLLVM_TARGETS_TO_BUILD="${llvm_target}" \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_ENABLE_ZLIB=FORCE_ON \
        -DZLIB_INCLUDE_DIR=/var/install/zlib/include \
        -DZLIB_LIBRARY=/var/install/zlib/lib/libz.a \
        -DLLVM_ENABLE_ZSTD=FORCE_ON \
        -DLLVM_USE_STATIC_ZSTD=ON \
        -Dzstd_INCLUDE_DIR=/var/install/zstd/include \
        -Dzstd_LIBRARY=/var/install/zstd/lib/libzstd.a \
        -DLLVM_ENABLE_LIBXML2=OFF \
        -DLLVM_ENABLE_TERMINFO=OFF \
        -DLLVM_STATIC_LINK_CXX_STDLIB=ON \
        -DCMAKE_EXE_LINKER_FLAGS="-static-libgcc -static-libstdc++" \
        -DCMAKE_SYSROOT=/opt/gcc/${HOST_ARCH}/sysroot \
        -DCMAKE_FIND_ROOT_PATH="/opt/gcc/${HOST_ARCH}/" \
        -DCMAKE_FIND_ROOT_PATH_MODE_PROGRAM=NEVER \
        -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=ONLY \
        -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ONLY
RUN ninja lld
RUN ninja install-lld

####################################################################################################
# Extra libs
####################################################################################################

FROM build_image AS libX11
# Use the always-x86_64-hosted gcc here: this stage produces target-side sysroot libraries,
# so its output must not vary with HOST_ARCH — and with HOST_ARCH=aarch64 the selected `gcc`
# stage binaries could not execute on the x86_64 build machine anyway.
COPY --from=gcc_x86_64 /var/install/gcc /var/install/gcc
ENV PATH="/var/install/gcc/bin:${PATH}"

# Provides an up-to-date config.sub/config.guess that recognizes aarch64. The
# X11R7.7 (2012) sources built below ship versions too old to know about it,
# so each package overlays these from /usr/share/misc before configuring.
RUN apt-get update \
        && DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC apt-get install --yes \
                autotools-dev \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

WORKDIR /build/util-macros/build
COPY --from=util-macros_download /downloads/util-macros /build/util-macros
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/util-macros/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/xproto/build
COPY --from=xproto_download /downloads/xproto /build/xproto
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/xproto/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/xextproto/build
COPY --from=xextproto_download /downloads/xextproto /build/xextproto
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/xextproto/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/kbproto/build
COPY --from=kbproto_download /downloads/kbproto /build/kbproto
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/kbproto/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/inputproto/build
COPY --from=inputproto_download /downloads/inputproto /build/inputproto
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/inputproto/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/xcb-proto/build
COPY --from=xcb-proto_download /downloads/xcb-proto /build/xcb-proto
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/xcb-proto/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/libXau/build
COPY --from=libXau_download /downloads/libXau /build/libXau
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/libXau/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/xtrans/build
COPY --from=xtrans_download /downloads/xtrans /build/xtrans
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/xtrans/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/libpthread-stubs/build
COPY --from=libpthread-stubs_download /downloads/libpthread-stubs /build/libpthread-stubs
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/libpthread-stubs/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/libxcb/build
COPY --from=libxcb_download /downloads/libxcb /build/libxcb
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/libxcb/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

WORKDIR /build/libX11/build
COPY --from=libX11_download /downloads/libX11 /build/libX11
RUN cp /usr/share/misc/config.sub /usr/share/misc/config.guess /build/libX11/
RUN --mount=source=configure.sh,target=/usr/bin/configure.sh configure.sh \
        || (cat config.log && exit 1)
RUN make --jobs $(nproc)
RUN make install
RUN make DESTDIR=/var/install/libX11 install

# Rename /var/install/libX11/usr/local to /var/install/libX11/usr, i.e. remove the "local" segment.
# We do this instead of setting the prefix to /usr to make the whole dependency resolution of the
# libX11 build simpler. We do not want to have /usr/local in the include and lib paths, as it is not
# part of the default include and lib paths of GCC.
RUN mv /var/install/libX11/usr/local /var/install/libX11/usr.tmp
RUN rm --recursive /var/install/libX11/usr
RUN mv /var/install/libX11/usr.tmp /var/install/libX11/usr

####################################################################################################
# Assemble final toolchain
####################################################################################################

FROM build_image AS toolchain

COPY --from=gcc /var/install/gcc /var/install/gcc
COPY --from=binutils /var/install/binutils /var/install/binutils
COPY --from=lld /var/install/lld /var/install/lld
COPY --from=libX11 /var/install/libX11 /var/install/libX11
RUN mkdir --parents /var/builds/toolchain \
        && rsync --archive /var/install/gcc/ /var/builds/toolchain/ \
        && rsync --archive /var/install/binutils/* /var/builds/toolchain/ \
        && rsync --archive /var/install/lld/* /var/builds/toolchain/ \
        && rsync --archive /var/install/libX11/* /var/builds/toolchain/sysroot/
RUN --mount=source=dedup,target=/usr/bin/dedup dedup /var/builds/toolchain

# We patch the shared libraries to set the rpath to $ORIGIN, so that during runtime the
# libraries are found in the same directory as the executable.
# Only real ELF files are patched: '*.so*' also matches linker scripts (e.g. glibc's libc.so)
# and symlinks. Failures are fatal, unlike `find -exec ... \;` which swallows them.
COPY --from=patchelf_download /downloads/patchelf /var/install/patchelf
RUN set -o errexit -o nounset -o pipefail \
        && while IFS= read -r -d '' elf; do \
                if file --brief "${elf}" | grep --quiet '^ELF'; then \
                        /var/install/patchelf/bin/patchelf --set-rpath '$ORIGIN/' "${elf}"; \
                fi; \
        done < <(find /var/builds/toolchain -name '*.so*' -type f -print0)

# Strip with the binutils matching HOST_ARCH: the shipped binaries are HOST_ARCH ELF files,
# which the build machine's own strip cannot process when HOST_ARCH differs from it.
RUN set -o errexit -o nounset -o pipefail \
        && strip_tool="/opt/gcc/${HOST_ARCH}/bin/${HOST_ARCH}-linux-strip" \
        && while IFS= read -r -d '' elf; do \
                if file --brief "${elf}" | grep --quiet '^ELF'; then \
                        "${strip_tool}" \
                            --strip-all \
                            --remove-section=.comment \
                            --remove-section=.note \
                            --remove-section=.eh_frame \
                            --remove-section=.eh_frame_hdr \
                            "${elf}"; \
                fi; \
        done < <(find /var/builds/toolchain/bin -type f -print0)
