FROM rockylinux:8

# Enable EPEL and CRB (CodeReady Builder) for additional dev packages
RUN dnf -y install 'dnf-command(config-manager)' && \
    dnf -y install epel-release && \
    dnf config-manager --set-enabled crb || \
    dnf config-manager --set-enabled powertools && \
    dnf -y update && \
    dnf clean all

# Build tools
RUN dnf -y install \
    git \
    gcc-toolset-12-gcc \
    gcc-toolset-12-gcc-c++ \
    gcc-toolset-12-binutils \
    cmake \
    ninja-build \
    perl \
    python3 \
    ruby \
    rubygems \
    pkgconfig \
    unzip \
    curl \
    wget \
    bzip2 \
    xz \
    which \
    findutils \
    file \
    fuse-libs \
    patchelf \
    appstream \
    && dnf clean all

# Enable GCC 12 by default (better C++20 support for WebKitGTK)
ENV PATH=/opt/rh/gcc-toolset-12/root/usr/bin:$PATH \
    LD_LIBRARY_PATH=/opt/rh/gcc-toolset-12/root/usr/lib64:$LD_LIBRARY_PATH \
    MANPATH=/opt/rh/gcc-toolset-12/root/usr/share/man: \
    CC=/opt/rh/gcc-toolset-12/root/usr/bin/gcc \
    CXX=/opt/rh/gcc-toolset-12/root/usr/bin/g++

# WebKitGTK build dependencies
RUN dnf -y install \
    gtk3-devel \
    gtk4-devel \
    libnotify-devel \
    libsecret-devel \
    libsoup3-devel \
    enchant2-devel \
    libtasn1-devel \
    libgcrypt-devel \
    gperf \
    gobject-introspection-devel \
    harfbuzz-devel \
    icu-devel \
    libjpeg-turbo-devel \
    libpng-devel \
    webp-devel \
    openjpeg2-devel \
    libtiff-devel \
    libavif-devel \
    gst-plugins-base-devel \
    gstreamer1-plugins-good \
    gstreamer1-plugins-good-devel \
    gstreamer1-plugins-bad-free-devel \
    libwpe-devel \
    wpebackend-fdo-devel \
    libXt-devel \
    wayland-devel \
    wayland-protocols-devel \
    mesa-libEGL-devel \
    mesa-libGL-devel \
    mesa-libGLES-devel \
    libxslt-devel \
    sqlite-devel \
    libxml2-devel \
    zlib-devel \
    libsodium-devel \
    && dnf clean all

# Build WebKitGTK 2.42 from source (provides webkit2gtk-4.1 API needed by Tauri 2)
ARG WEBKITGTK_VERSION=2.42.5
RUN cd /tmp && \
    curl -L -o webkitgtk.tar.xz \
      "https://webkitgtk.org/releases/webkitgtk-${WEBKITGTK_VERSION}.tar.xz" && \
    tar xf webkitgtk.tar.xz && \
    cd "webkitgtk-${WEBKITGTK_VERSION}" && \
    mkdir build && cd build && \
    cmake -G Ninja \
        -DPORT=GTK \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_INSTALL_LIBDIR=lib64 \
        -DENABLE_MINIBROWSER=OFF \
        -DENABLE_INTROSPECTION=OFF \
        -DENABLE_DOCS=OFF \
        -DENABLE_GTK4=ON \
        .. && \
    ninja && \
    ninja install && \
    cd / && \
    rm -rf /tmp/webkitgtk*

# Node.js 20
RUN curl -fsSL https://rpm.nodesource.com/setup_20.x | bash - && \
    dnf -y install nodejs && \
    dnf clean all

# pnpm
RUN npm install -g pnpm@10

# Rust
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
ENV PATH=/root/.cargo/bin:$PATH

# linuxdeploy for AppImage creation
RUN curl -L -o /usr/local/bin/linuxdeploy-x86_64.AppImage \
      https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage && \
    chmod +x /usr/local/bin/linuxdeploy-x86_64.AppImage

# appstream-glib for AppStream metadata validation
RUN dnf -y install libappstream-glib && dnf clean all

WORKDIR /build
