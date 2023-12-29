FROM ubuntu:latest as cloner
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get -qy update && apt-get install -yq git
WORKDIR /src
RUN git clone https://github.com/FFmpeg/nv-codec-headers -b n12.1.14.0
RUN git clone https://github.com/FFmpeg/FFmpeg -b n6.1

FROM nvidia/cuda:12.2.0-devel-ubuntu22.04 as builder
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get -yq update && apt-get install -yq build-essential yasm cmake libtool libc6 libc6-dev unzip wget libnuma1 libnuma-dev pkg-config
COPY --from=cloner /src /src
WORKDIR /src/nv-codec-headers 
RUN make install
WORKDIR /src/FFmpeg
RUN ./configure --enable-nonfree --enable-cuda-nvcc --enable-libnpp --extra-cflags=-I/usr/local/cuda/include --extra-ldflags=-L/usr/local/cuda/lib64 --disable-static --enable-shared
RUN make -j $(nproc) && make install

FROM nvidia/cuda:12.2.0-runtime-ubuntu22.04
COPY --from=builder /usr/local /usr/local
RUN ldconfig -v
RUN ffmpeg --help
