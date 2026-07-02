#!/bin/bash
set -euo pipefail

cd /build

echo "=== Installing frontend dependencies ==="
pnpm install --frozen-lockfile

echo "=== Building Tauri app ==="
cd src-tauri
cargo build --release --locked

BINARY="target/release/md-reader"
if [ ! -f "$BINARY" ]; then
    echo "ERROR: Binary not found at $BINARY"
    exit 1
fi
echo "Binary built: $(ls -lh "$BINARY")"

echo "=== Creating AppImage ==="
APPDIR="/tmp/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/lib"
mkdir -p "$APPDIR/usr/share/icons/hicolor/256x256/apps"

# Copy binary
cp "$BINARY" "$APPDIR/usr/bin/md-reader"

# Copy icon (use the largest available)
if [ -f "../src-tauri/icons/icon.png" ]; then
    cp "../src-tauri/icons/icon.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/md-reader.png"
elif [ -f "../src-tauri/icons/128x128@2x.png" ]; then
    cp "../src-tauri/icons/128x128@2x.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/md-reader.png"
fi

# Create .desktop file
cat > "$APPDIR/md-reader.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=MD Reader
Comment=Markdown Reader
Exec=md-reader %F
Icon=md-reader
Categories=Office;Viewer;
MimeType=text/markdown;text/x-markdown;
EOF

# Collect WebKitGTK and related libraries to bundle
echo "Collecting shared libraries..."
LIBS=()
for lib_pattern in \
    "libwebkit2gtk-4.1*" \
    "libjavascriptcoregtk-4.1*" \
    "libwebkit2gtk-4.0*" \
    "libWPEWebKit*" \
    "libwpebackend-fdo*" \
    "libWPEPlatform*" \
    "libenchant-2*" \
    "libsoup-3*" \
    "libWTF*" \
    "libWPE*" \
    ; do
    for f in /usr/lib64/${lib_pattern}.so*; do
        [ -f "$f" ] && LIBS+=("--library=$f")
    done
done

# Also bundle GStreamer GL libraries if present
for f in /usr/lib64/gstreamer-1.0/libgstgl*.so; do
    [ -f "$f" ] && LIBS+=("--library=$f")
done

echo "Libraries to bundle: ${#LIBS[@]}"

# Build AppImage with linuxdeploy
# Exclude core system libs that must come from the host
# APPIMAGE_EXTRACT_AND_RUN=1 is needed inside Docker (no FUSE support)
cd "$APPDIR"
export APPIMAGE_EXTRACT_AND_RUN=1
OUTPUT=appimage linuxdeploy-x86_64.AppImage \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/md-reader.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/256x256/apps/md-reader.png" \
    ${LIBS[@]+"${LIBS[@]}"} \
    --exclude-library='libc.so*' \
    --exclude-library='libm.so*' \
    --exclude-library='libpthread*' \
    --exclude-library='libdl.so*' \
    --exclude-library='librt.so*' \
    --exclude-library='ld-linux*' \
    --exclude-library='libgcc_s.so*' \
    --exclude-library='libstdc++.so*' \
    --exclude-library='libglib-2.0.so*' \
    --exclude-library='libgobject-2.0.so*' \
    --exclude-library='libgio-2.0.so*' \
    --exclude-library='libgmodule-2.0.so*' \
    --exclude-library='libgthread-2.0.so*' \
    --exclude-library='libgtk-3.so*' \
    --exclude-library='libgdk-3.so*' \
    --exclude-library='libgtk-4.so*' \
    --exclude-library='libgdk-4.so*' \
    --exclude-library='libcairo*' \
    --exclude-library='libpango*' \
    --exclude-library='libatk*' \
    --exclude-library='libgstreamer*' \
    --exclude-library='libgst*' \
    --exclude-library='liborc*' \
    --output appimage

# Move AppImage to standard Tauri bundle output location
mkdir -p /build/src-tauri/target/release/bundle/appimage
mv *.AppImage /build/src-tauri/target/release/bundle/appimage/ || true

echo "=== Build complete ==="
ls -lh /build/src-tauri/target/release/bundle/appimage/
