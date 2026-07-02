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

# Collect ALL shared library dependencies (except core system libs)
# This bundles WebKitGTK, GLib, libsoup3, GTK3, and all other deps
# so the AppImage works on systems without these libraries installed
echo "Collecting shared libraries..."
LIBS=()
CORE_LIBS="libc\.so|libm\.so|libpthread|libdl\.so|librt\.so|ld-linux|libresolv|libutil|libnsl|libcrypt\.so"

while IFS= read -r line; do
    lib_path=$(echo "$line" | grep -oP '=> \K\S+' 2>/dev/null || true)
    if [ -n "$lib_path" ] && [ -f "$lib_path" ]; then
        lib_name=$(basename "$lib_path")
        if ! echo "$lib_name" | grep -qE "^($CORE_LIBS)"; then
            LIBS+=("--library=$lib_path")
        fi
    fi
done < <(ldd "$BINARY" 2>/dev/null || true)

# Also explicitly collect WebKitGTK and custom-built libraries
for pattern in \
    "/usr/lib64/libwebkit2gtk-4.1*" \
    "/usr/lib64/libjavascriptcoregtk-4.1*" \
    "/usr/lib64/libsoup-3*" \
    "/usr/lib64/libwpe-1.0*" \
    "/usr/lib64/libWPEWebKit*" \
    "/usr/lib64/libwpebackend-fdo*" \
    "/usr/lib64/libenchant-2*" \
    ; do
    for f in ${pattern}.so*; do
        [ -f "$f" ] && LIBS+=("--library=$f")
    done
done

# Deduplicate
IFS=$'\n' LIBS=($(printf '%s\n' "${LIBS[@]}" | sort -u)); unset IFS

echo "Libraries to bundle: ${#LIBS[@]}"

# Build AppImage with linuxdeploy
# APPIMAGE_EXTRACT_AND_RUN=1 is needed inside Docker (no FUSE support)
cd "$APPDIR"
export APPIMAGE_EXTRACT_AND_RUN=1
OUTPUT=appimage linuxdeploy-x86_64.AppImage \
    --appdir "$APPDIR" \
    --desktop-file "$APPDIR/md-reader.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/256x256/apps/md-reader.png" \
    ${LIBS[@]+"${LIBS[@]}"} \
    --output appimage

# Move AppImage to standard Tauri bundle output location
mkdir -p /build/src-tauri/target/release/bundle/appimage
mv *.AppImage /build/src-tauri/target/release/bundle/appimage/ || true

echo "=== Build complete ==="
ls -lh /build/src-tauri/target/release/bundle/appimage/
