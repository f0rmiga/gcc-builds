# GCC Builds

This repository contains the definitions and scripts to build optimized toolchains for x86_64, armv7
and aarch64 (aka arm64 and armv8) architectures. The build process has been unified to create both
GCC binaries and sysroots in a single, efficient compilation pipeline.

## Building the Toolchains

Use the `build.sh` script to build the sysroots and GCC binaries using Docker. The current
restriction is that the container must run in x86_64. The sysroots for other architectures are built
using cross-compilation from x86_64.

### Using the Build Script

#### Building the Toolchains

For the default host (`x86_64`)

```shell
./build.sh 14.3.0 x86_64 .
./build.sh 14.3.0 armv7 .
./build.sh 14.3.0 aarch64 .
```

##### Building for Different Hosts

```shell
./build.sh 14.3.0 x86_64 . aarch64 # Build an aarch64 gcc that can target x86_64.
./build.sh 14.3.0 x86_64 . x86_64  # Build an x86_64 gcc that can target x86_64.
./build.sh 14.3.0 x86_64 .         # Shorthand for the above.
```

#### Output

The build process generates optimized toolchain archives:
- `gcc-toolchain-14.3.0-x86_64.tar.xz`
- `gcc-toolchain-14.3.0-armv7.tar.xz`
- `gcc-toolchain-14.3.0-aarch64.tar.xz`

These archives contain both the GCC binaries and the corresponding sysroot, providing a complete
hermetic toolchain for each target architecture.

If you have [specified a host](#building-for-different-hosts) other than the default `x86_64`, the
archive names will be keyed by host:

- `gcc-toolchain-14.3.0-x86_64-host-aarch64.tar.xz`
- `gcc-toolchain-14.3.0-armv7-host-aarch64.tar.xz`
- `gcc-toolchain-14.3.0-aarch64-host-aarch64.tar.xz`

## Linkers

Each toolchain ships with multiple linkers:

- `ld` / `ld.bfd` and `ld.gold` from binutils (GNU ld is the default).
- `ld.lld` from [LLD](https://lld.llvm.org/), built from source as part of the same pipeline.

LLD is built from the LLVM sources alongside GCC and binutils. Because LLD is a single,
inherently cross-target linker, one x86_64 host build links for every supported target. To use it
instead of GNU ld, pass `-fuse-ld=lld` to the compiler:

```shell
gcc -fuse-ld=lld -o hello hello.c
```
