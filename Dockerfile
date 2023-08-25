# Cross-compilation builder for sidekick capable of cross-compiling for
# {darwin,linux}/{arm64,amd64}, windows/amd64 with CGO support.

# We need 23.04 as gcc-mingw with gcc-12 is only available on that.
FROM ubuntu:23.04

# Setup the env
ENV DEBIAN_FRONTEND=noninteractive

# Install the cross compilers.
# We need gcc-12 (assuming that our host is x86_64), gcc-12-aarch64, gcc-mingw-w64
# for linux/amd64, linux/arm64 and windows/amd64 respectively.
# We'll also need llvm-dev and clang for macos toolchains.
RUN apt-get update -y && \
    apt-get install -y automake autogen build-essential zlib1g-dev \
    gcc-12-aarch64-linux-gnu g++-12-aarch64-linux-gnu libc6-dev-arm64-cross \
    gcc-12-multilib g++-12-multilib gcc-mingw-w64 g++-mingw-w64 \
    clang llvm-dev \
    ca-certificates

# For static compilation for linux, we'll need musl. We will compile musl from
# source using the x86_64-linux-gnu and aarch64-linux-gnu cross-compilers.
WORKDIR /musl
RUN apt-get install -y wget && \
    wget https://musl.libc.org/releases/musl-1.2.4.tar.gz && \
    tar xvf musl-1.2.4.tar.gz && \
    cd musl-1.2.4 && \
    CC=x86_64-linux-gnu-gcc-12 ./configure --prefix=/usr/bin/musl-x86_64 && \
    make install -j$(nproc) && \
    make clean && \
    CC=aarch64-linux-gnu-gcc-12 ./configure --prefix=/usr/bin/musl-aarch64 && \
    make install -j$(nproc) && \
    make clean

# Prepare a macos cross-compiler and SDK. We are targetting macOS 11.1
# as the C libraries we are building do not require any higher targets, and
# that is what is tested with xgo (where the macOS part of this Dockerfile
# originates from).
RUN apt-get install -y cmake patch libssl-dev lzma-dev libxml2-dev bzip2 cpio zlib1g-dev git
WORKDIR /
# Make libxar known to the ld64 and cctools build
ENV LD_LIBRARY_PATH=/osxcross/target/lib
# Bear with me...
RUN wget https://github.com/phracker/MacOSX-SDKs/releases/download/11.0-11.1/MacOSX11.1.sdk.tar.xz && \
    tar xf MacOSX11.1.sdk.tar.xz && \
    rm -rf MacOSX11.1.sdk.tar.xz
# Patch the SDK
ADD patch.tar.xz MacOSX11.1.sdk/usr/include/c++
# Okay finally get a cross-compiler. But first, let's repackage the patched SDK.
RUN tar cf - MacOSX11.1.sdk | xz -c - > MacOSX11.1.sdk.tar.xz  && \
    rm -rf MacOSX11.1.sdk && \
    mkdir osxcross && cd osxcross && git init && \
    git remote add origin https://github.com/tpoechtrager/osxcross.git && \
    git fetch --depth 1 origin 0f87f567dfaf98460244471ad6c0f4311d62079c && \
    git checkout FETCH_HEAD && cd ../ && \
    mv MacOSX11.1.sdk.tar.xz /osxcross/tarballs/ && \
    OSX_VERSION_MIN=10.13 UNATTENDED=1 LD_LIBRARY_PATH=/osxcross/target/lib /osxcross/build.sh

# Sigh finally install Go.
RUN wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz && \
    rm go1.21.0.linux-amd64.tar.gz

# Add stuff to the PATH
ENV PATH /usr/local/go/bin:/osxcross/target/bin/:$PATH

# Install upx.
RUN git clone --depth=1 https://github.com/upx/upx -b v4.1.0 && \
    cd upx && \
    git submodule update --init && \
    cmake -Bbuild . && \
    cmake --build build -j$(nproc) && \
    cmake --install build && \
    cd .. && \
    rm -rf upx

ENTRYPOINT [ "/bin/bash" ]
