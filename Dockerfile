#
# FogLAMP for AWS ECS
#
FROM ubuntu:18.04

# Set the timezone for Ubuntu
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install FogLAMP prerequisites
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    apt-utils \
    autoconf \ 
    automake \
    avahi-daemon \
    build-essential \
    cmake \
    curl \
    g++ \
    git \
    libboost-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libpq-dev \
    libsqlite3-dev \
    libssl-dev \
    libtool \
    libz-dev \
    make \
    postgresql \
    python3-dev \
    python3-pip \
    python3-dbus \
    python3-setuptools \
    rsyslog \
    sqlite3 \
    uuid-dev \
&& apt-get clean \
&& rm -rf /var/lib/apt/lists/* \
&& pip3 install kafka-python asyncio

# Clone FogLAMP from github repository, checkout v1.5.1, make and install FogLAMP
RUN mkdir /foglamp 
WORKDIR /foglamp
RUN git clone https://github.com/foglamp/FogLAMP.git /foglamp \ 
&& git checkout v1.5.1 \ 
&& make \
&& make install

ENV FOGLAMP_ROOT=/foglamp

# Make the Kafka library files
RUN  mkdir -p /librdkafka
WORKDIR /librdkafka
RUN git clone https://github.com/edenhill/librdkafka.git /librdkafka \
&& ./configure \ 
&& make \
&& make install

# Make the Kafka North Plugin and install in FogLAMP
RUN git clone https://github.com/foglamp/foglamp-north-kafka.git /kafka_north
WORKDIR /kafka_north
RUN mkdir build \
&& cd build \
&& cmake .. \
&& make \
&& mkdir -p /usr/local/foglamp/plugins/north/kafka \
&& cp libKafka.so /usr/local/foglamp/plugins/north/kafka \
&& cd /usr/local/foglamp/plugins/north/kafka \
&& chmod 644 libKafka.so \
&& ln -s libKafka.so libKafka.so.1 \
&& ls -al /usr/local/foglamp/plugins/north/kafka
 

# Install plugins
RUN mkdir -p /usr/local/foglamp/python/foglamp/plugins/south/http_south
COPY plugins/south/http /usr/local/foglamp/python/foglamp/plugins/south/http_south

RUN mkdir -p /usr/local/foglamp/python/foglamp/plugins/north/kafka_north
COPY plugins/north/kafka_north /usr/local/foglamp/python/foglamp/plugins/north/kafka_north

# Script used to start foglamp
WORKDIR /usr/local/foglamp
COPY foglamp.sh .

ENV FOGLAMP_ROOT=/usr/local/foglamp

# Data directory must be saved to preserve configuration between container starts
VOLUME /usr/local/foglamp/data

# 8081 FogLAMP API port
# 1995 FogLAMP API port using TLS
# 6683 HTTP South Plugin
# 6684 HTTP South Plugin using TLS
EXPOSE 8081 1995 6683 6684

# start rsyslog, FogLAMP, and tail syslog
CMD ["bash", "/usr/local/foglamp/foglamp.sh"]

LABEL maintainer="rob@raesemann.com" \
author="Raesemann" \
target="AWS" \
version="1.5.1" \