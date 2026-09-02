#!/bin/bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/.build/ImageMagick"
OUT="$ROOT/ImageMagickApp/Vendor/ImageMagickBuild"

IM_VERSION="${IM_VERSION:-main}"
SDK_VERSION="${SDK_VERSION:-$(xcrun --sdk iphoneos --show-sdk-version)}"

rm -rf "$SRC" "$OUT"
mkdir -p "$SRC" "$OUT"

git clone --depth 1 --branch "$IM_VERSION" https://github.com/ImageMagick/ImageMagick.git "$SRC"

# ImageMagick's configure test detects getentropy() on the macOS build host and
# enables MAGICKCORE_HAVE_GETENTROPY. On iOS, getentropy() is declared by
# <unistd.h>, while <sys/random.h> is not provided by the iPhoneOS SDK.
# Remove the non-portable include before configuring/building for Apple SDKs.
if [[ "$OSTYPE" == darwin* ]]; then
  python3 - "$SRC/MagickCore/random.c" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
s = p.read_text()
s = s.replace(
    '#if defined(MAGICKCORE_HAVE_GETENTROPY)\n#include <sys/random.h>\n#endif',
    '#if defined(MAGICKCORE_HAVE_GETENTROPY) && !defined(__APPLE__)\n#include <sys/random.h>\n#endif'
)
p.write_text(s)
PY
fi

build_one() {
  local sdk="$1"
  local arch="$2"
  local platform="$3"
  local name="$4"

  local sdk_path
  sdk_path="$(xcrun --sdk "$sdk" --show-sdk-path)"
  local clang
  clang="$(xcrun --sdk "$sdk" -f clang)"
  local sysroot="$sdk_path"

  local prefix="$OUT/$name"
  rm -rf "$prefix"
  mkdir -p "$prefix"

  pushd "$SRC" >/dev/null
  make distclean >/dev/null 2>&1 || true
  git clean -fdx >/dev/null 2>&1 || true

  # git clean above restores the checked-out source, so reapply the iOS
  # compatibility patch after every clean/reconfigure cycle.
  if [[ "$OSTYPE" == darwin* ]]; then
    python3 - "MagickCore/random.c" <<'PY'
from pathlib import Path
p = Path(__import__('sys').argv[1])
s = p.read_text()
s = s.replace(
    '#if defined(MAGICKCORE_HAVE_GETENTROPY)\n#include <sys/random.h>\n#endif',
    '#if defined(MAGICKCORE_HAVE_GETENTROPY) && !defined(__APPLE__)\n#include <sys/random.h>\n#endif'
)
p.write_text(s)
PY
  fi

  ./configure \
    --host="$platform" \
    CC="$clang" \
    CFLAGS="-arch $arch -isysroot $sysroot -mios-version-min=17.0 -O2" \
    CPPFLAGS="-arch $arch -isysroot $sysroot -mios-version-min=17.0" \
    LDFLAGS="-arch $arch -isysroot $sysroot -mios-version-min=17.0" \
    --prefix="$prefix" \
    --with-quantum-depth=8 \
    --disable-hdri \
    --disable-shared \
    --enable-static \
    --without-modules \
    --without-perl \
    --without-magick-plus-plus \
    --without-x \
    --without-pango \
    --without-openexr \
    --without-lcms \
    --without-rsvg \
    --without-heic \
    --without-jxl \
    --without-webp \
    --without-tiff \
    --without-jpeg \
    --without-png \
    --without-bzlib \
    --without-zstd \
    --without-freetype \
    --without-raqm \
    --without-lqr \
    --without-djvu \
    --without-fftw \
    --without-fpx \
    --without-gslib \
    --without-gvc \
    --without-zip

  make -j"$(sysctl -n hw.ncpu)"
  make install
  popd >/dev/null
}

build_one iphoneos arm64 arm64-apple-darwin iphoneos
build_one iphonesimulator arm64 arm64-apple-darwin iphonesimulator

echo "ImageMagick iOS libraries built for SDK $SDK_VERSION"
