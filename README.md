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

```shell
./build.sh 14.3.0 x86_64 .
./build.sh 14.3.0 armv7 .
./build.sh 14.3.0 aarch64 .
```

#### Output

The build process generates optimized toolchain archives:
- `gcc-toolchain-14.3.0-x86_64.tar.xz`
- `gcc-toolchain-14.3.0-armv7.tar.xz` 
- `gcc-toolchain-14.3.0-aarch64.tar.xz`

These archives contain both the GCC binaries and the corresponding sysroot, providing a complete
hermetic toolchain for each target architecture.
