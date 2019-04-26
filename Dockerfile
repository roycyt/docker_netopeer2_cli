# Based on https://hub.docker.com/r/sysrepo/sysrepo-netopeer2/dockerfile

FROM ubuntu:18.04 as builder

RUN \
      apt-get update && apt-get install -y \
      # general tools
      git \
      cmake \
      build-essential \
      # libyang
      libpcre3-dev \
      pkg-config \
      # netopeer2
      libssh-dev \
      libssl-dev

# use /opt/dev as working directory
RUN mkdir /opt/dev
WORKDIR /opt/dev

# libyang
RUN \
      git clone --depth=1 -b devel https://github.com/CESNET/libyang.git && \
      cd libyang && mkdir build && cd build && \
      git checkout devel && \
      cmake -DCMAKE_INSTALL_PREFIX=/opt/netconf -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install

# libnetconf2
RUN \
      git clone --depth=1 -b devel https://github.com/CESNET/libnetconf2.git && \
      cd libnetconf2 && mkdir build && cd build && \
      git checkout devel && \
      cmake -DCMAKE_INSTALL_PREFIX=/opt/netconf -DCMAKE_BUILD_TYPE:String="Debug" -DENABLE_BUILD_TESTS=OFF .. && \
      make -j2 && \
      make install

# netopeer2
RUN \
      cd /opt/dev && \
      git clone --depth=1 https://github.com/CESNET/Netopeer2.git && \
      cd Netopeer2/cli && mkdir build && cd build && \
      cmake -DCMAKE_INSTALL_PREFIX=/opt/netconf -DCMAKE_BUILD_TYPE:String="Debug" .. && \
      make -j2 && \
      make install

RUN tar zcvf /opt/netconf.tar.gz /opt/netconf

FROM ubuntu:18.04

RUN \
      apt-get update && apt-get install -y \
      libssh-4

COPY --from=builder /opt/netconf.tar.gz /opt

RUN tar zxvf /opt/netconf.tar.gz && rm /opt/netconf.tar.gz
COPY netconf.conf /etc/ld.so.conf.d
RUN ldconfig

CMD ["/opt/netconf/bin/netopeer2-cli"]
