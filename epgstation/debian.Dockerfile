FROM l3tnun/epgstation:master-debian

ENV DEV="make gcc git g++ automake curl wget autoconf build-essential libass-dev libfreetype6-dev libsdl1.2-dev libtheora-dev libtool libva-dev libvdpau-dev libvorbis-dev libxcb1-dev libxcb-shm0-dev libxcb-xfixes0-dev pkg-config texinfo zlib1g-dev cmake meson"

RUN apt-get update && \
    apt-get -y install $DEV && \
    apt-get -y install yasm libx264-dev libmp3lame-dev libopus-dev libvpx-dev libdrm-dev && \
    apt-get -y install libx265-dev libnuma-dev && \
    apt-get -y install libasound2 libass9 libvdpau1 libva-x11-2 libva-drm2 libxcb-shm0 libxcb-xfixes0 libxcb-shape0 libvorbisenc2 libtheora0 libaribb24-dev && \
\
    # Build MPP
    mkdir -p /tmp/dev && cd /tmp/dev && \
    git clone -b jellyfin-mpp --depth=1 https://github.com/nyanmisaka/mpp.git rkmpp && \
    cd rkmpp && \
    mkdir rkmpp_build && \
    cd rkmpp_build && \
    cmake \
        -DCMAKE_INSTALL_PREFIX=/usr \
        -DCMAKE_BUILD_TYPE=Release \
        -DBUILD_SHARED_LIBS=ON \
        -DBUILD_TEST=OFF \
        ..  && \
    make -j $(nproc) && \
    make install && \
\
# Build RGA
    cd /tmp/dev && \
    git clone -b jellyfin-rga --depth=1 https://github.com/nyanmisaka/rk-mirrors.git rkrga && \
    meson setup rkrga rkrga_build \
        --prefix=/usr \
        --libdir=lib \
        --buildtype=release \
        --default-library=shared \
        -Dcpp_args=-fpermissive \
        -Dlibdrm=false \
        -Dlibrga_demo=false && \
    meson configure rkrga_build && \
    ninja -C rkrga_build install && \
\
# build fdk
    cd /tmp/dev && \
    git -C fdk-aac pull 2> /dev/null || git clone --depth 1 https://github.com/mstorsjo/fdk-aac && \
    cd fdk-aac && \
    autoreconf -fiv && \
    ./configure --disable-shared && \
    make -j$(nproc) && \
    make install && \
\
#ffmpeg build
    git clone https://github.com/nyanmisaka/ffmpeg-rockchip.git /tmp/ffmpeg_sources && \
    cd /tmp/ffmpeg_sources && \
    ./configure \
      --prefix=/usr/local \
      --disable-shared \
      --pkg-config-flags=--static \
      --enable-gpl \
      --enable-libdrm --enable-rkmpp --enable-rkrga \
      --enable-libfdk-aac \
      --enable-libass \
      --enable-libfreetype \
      --enable-libmp3lame \
      --enable-libopus \
      --enable-libtheora \
      --enable-libvorbis \
      --enable-libvpx \
      --enable-libx264 \
      --enable-libx265 \
      --enable-version3 \
      --enable-libaribb24 \
      --enable-nonfree \
      --disable-debug \
      --disable-doc \
    && \
    make -j$(nproc) && \
    make install && \
\
# 不要なパッケージを削除
    apt-get -y remove $DEV && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /tmp/*
