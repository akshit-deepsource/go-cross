# `cross`

A Go 1.21.0 cross-compilation toolchain for Go capable of targeting

- `darwin/arm64` (dynamic)
- `darwin/amd64` (dynamic)
- `windows/amd64` (static / dynamic)
- `linux/amd64` (static / dynamic)
- `linux/arm64` (static / dynamic)

## Cross-compiling CGo applications

### `darwin/arm64`

```shell
CGO_ENABLED=1 CC=o64-clang CXX=o64-clang++ HOST=arm64-apple-darwin15 PREFIX=/usr/local GOOS=darwin GOARCH=arm64 go build ...
```

### `darwin/amd64`

```shell
CGO_ENABLED=1 CC=o64-clang CXX=o64-clang++ HOST=x86_64-apple-darwin15 PREFIX=/usr/local GOOS=darwin GOARCH=arm64 go build ...
```

### `linux/arm64` (static)

```shell
CGO_ENABLED=1 CC=/usr/bin/musl-aarch64/bin/musl-gcc GOOS=linux GOARCH=arm64 go build -ldflags="-linkmode external -extldflags='-static'" ...
```

### `linux/amd64` (static)

```shell
CGO_ENABLED=1 CC=/usr/bin/musl-x86_64/bin/musl-gcc GOOS=linux GOARCH=amd64 go build -ldflags="-linkmode external -extldflags='-static'" ...
```

### `windows/amd64` (static)

```shell
CGO_ENABLED=1 CC=x86_64-w64-mingw32-gcc-12 GOOS=windows GOARCH=amd64 go build -ldflags="-linkmode external -extldflags='-static'" ...
```

## Notes

The Docker image is ~4.7 GB and takes around 20 minutes to build. Therefore, it is recommended that
the image is pushed to a registry, and pulled from there.

## Maintenance

Upgrading Go versions should be easy. Just swap out the go version in the download step.
However, upgrading Ubuntu versions may not be that easy as it requires two things:

- Check what gcc version is shipped with `build-essential` for that version
- Check if mingw-gcc is available for that gcc version
- Change all the cross-compiler versions to use that gcc version
- Otherwise, just let the Ubuntu version be. DO NOT INSTALL MISMATCHING VERSIONS.

Another thing is upgrading macOS SDK versions. Please refer to xgo's toolchain `Dockerfile` for
version changes, and when you change a macOS SDK version, update the `patches.tar.xz` with the
one in xgo.
