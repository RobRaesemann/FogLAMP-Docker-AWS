#
# FogLAMP Aggregator Node
# 
FROM ubuntu:18.04

# Must setup timezone or apt-get hangs with prompt
ENV TZ=America/New_York
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install packages required for FogLAMP
RUN apt update && \
    apt -y install wget rsyslog python3-dbus iputils-ping && \
    wget --quiet https://s3.amazonaws.com/foglamp/debian/x86_64/foglamp-1.6.0-x86_64_ubuntu_18_04.tgz && \
    tar -xzvf ./foglamp-1.6.0-x86_64_ubuntu_18_04.tgz && \
    apt -y install `dpkg -I ./foglamp-1.6.0-x86_64_ubuntu_18_04/foglamp-1.6.0-x86_64.deb | awk '/Depends:/{print$2}' | sed 's/,/ /g'` && \
    dpkg-deb -R ./foglamp-1.6.0-x86_64_ubuntu_18_04/foglamp-1.6.0-x86_64.deb foglamp-1.6.0-x86_64 && \
    dpkg-deb -R ./foglamp-1.6.0-x86_64_ubuntu_18_04/foglamp-south-sinusoid-1.6.0.deb foglamp-south-sinusoid-1.6.0 && \
    dpkg-deb -R ./foglamp-1.6.0-x86_64_ubuntu_18_04/foglamp-notify-python35-1.6.0-x86_64.deb foglamp-notify-python35-1.6.0 && \
    dpkg-deb -R ./foglamp-1.6.0-x86_64_ubuntu_18_04/foglamp-notify-email-1.6.0-x86_64.deb foglamp-notify-email-1.6.0 && \
    dpkg-deb -R ./foglamp-1.6.0-x86_64_ubuntu_18_04/foglamp-rule-outofbound-1.6.0-x86_64.deb foglamp-rule-outofbound-1.6.0 && \
    cp -r ./foglamp-1.6.0-x86_64/usr /. && \
    cp -r ./foglamp-south-sinusoid-1.6.0/usr /. && \
    cp -r ./foglamp-notify-python35-1.6.0/usr /. && \
    cp -r ./foglamp-notify-email-1.6.0/usr /. && \
    cp -r ./foglamp-rule-outofbound-1.6.0/usr /. && \
    mv /usr/local/foglamp/data.new /usr/local/foglamp/data && \
    cd /usr/local/foglamp && \
    ./scripts/certificates foglamp 365 && \
    chown -R root:root /usr/local/foglamp && \
    chown -R ${SUDO_USER}:${SUDO_USER} /usr/local/foglamp/data && \
    pip3 install -r /usr/local/foglamp/python/requirements.txt && \
    apt clean && \
    rm -rf /var/lib/apt/lists/* /foglamp* /usr/include/boost

ENV FOGLAMP_ROOT=/usr/local/foglamp 

WORKDIR /usr/local/foglamp
COPY foglamp.sh foglamp.sh
RUN chown root:root /usr/local/foglamp/foglamp.sh \
    && chmod 777 /usr/local/foglamp/foglamp.sh

RUN pip3 install kafka-python asyncio

RUN mkdir -p /usr/local/foglamp/python/foglamp/plugins/north/kafka_north
COPY plugins/north/kafka_north /usr/local/foglamp/python/foglamp/plugins/north/kafka_north

RUN mkdir -p /usr/local/foglamp/python/foglamp/plugins/south/http_south
COPY plugins/south/http_south /usr/local/foglamp/python/foglamp/plugins/south/http_south


VOLUME /usr/local/foglamp/data

# 8081 FogLAMP API port
# 1995 FogLAMP API port using TLS
# 6683 HTTP South Plugin
# 6684 HTTP South Plugin using TLS
EXPOSE 8081 1995 6683 6684


# start rsyslog, FogLAMP, and tail syslog
CMD ["bash","/usr/local/foglamp/foglamp.sh"]

LABEL maintainer="rob@raesemann.com" \
      author="Rob Raesemann" \
      target="Docker" \
      version="1.6"
