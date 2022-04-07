FROM python:slim-buster as builder
ENV DEBIAN_FRONTEND noninteractive

# install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y git build-essential cmake

# add 32-bit ARM (armhf)
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt install -y gcc-arm-linux-gnueabihf libc6:armhf libncurses5:armhf libstdc++6:armhf

# clone box86 git repo
RUN git clone https://github.com/ptitSeb/box86 && mkdir /box86/build

# clone box64 git repo
RUN git clone https://github.com/ptitSeb/box64.git && mkdir /box64/build

# compile box86
WORKDIR /box86/build
RUN cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
RUN make -j$(nproc)

# compile box64
WORKDIR /box64/build
RUN cmake .. -DRPI4ARM64=1 -DCMAKE_BUILD_TYPE=RelWithDebInfo
RUN make -j$(nproc)

# *********************************************************************
# container to install box86 and box64 in
FROM debian:buster-slim

# install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y make cmake

# add 32-bit ARM (armhf)
RUN dpkg --add-architecture armhf && \
    apt-get update && \
    apt install -y gcc-arm-linux-gnueabihf libc6:armhf libncurses5:armhf libstdc++6:armhf

# copy box86 build from above and install in container
COPY --from=builder /box86 /box86
WORKDIR /box86/build
RUN make install

# copy box64 build from above and install in container
COPY --from=builder /box64 /box64
WORKDIR /box64/build
RUN make install