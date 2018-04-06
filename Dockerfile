FROM resin/rpi-raspbian:stretch

RUN apt-get -q update && apt-get -y install \
    # Raspivid and ffmpeg
    libraspberrypi-bin ffmpeg \
    # Helpers to build nginx
    build-essential wget git \
    libpcre3-dev zlib1g-dev libssl-dev \
    --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# Some magic for raspvid
RUN usermod -a -G video root
CMD modprobe bcm2835-v4l2

ENV PATH $PATH:/usr/local/nginx/sbin

# create directories
RUN mkdir /src && mkdir /config && mkdir /logs && mkdir /data && mkdir /static

# get nginx source
RUN cd /src && wget http://nginx.org/download/nginx-1.12.0.tar.gz && tar zxf nginx-1.12.0.tar.gz && rm nginx-1.12.0.tar.gz

# get nginx-rtmp module
RUN cd /src && git clone git://github.com/arut/nginx-rtmp-module.git nginx-rtmp-module

# compile nginx
RUN cd /src/nginx-1.12.0 && ./configure --add-module=/src/nginx-rtmp-module --conf-path=/config/nginx.conf --error-log-path=/logs/error.log --http-log-path=/logs/access.log
RUN cd /src/nginx-1.12.0 && make && make install
RUN rm -rf src

# Install node.js
RUN groupadd --gid 1000 node \
  && useradd --uid 1000 --gid node --shell /bin/bash --create-home node

# gpg keys listed at https://github.com/nodejs/node#release-team
RUN set -ex \
  && for key in \
    94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
    FD3A5288F042B6850C66B31F09FE44734EB7990E \
    71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
    DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
    C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
    B9AE9905FFD7803F25714661B63B535A4C206CA9 \
    56730D5401028683275BD23C23EFEFE93C4CFFFE \
    77984A986EBC2AA786BC0F66B01FBB92821C587A \
  ; do \
    gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys "$key" || \
    gpg --keyserver hkp://ipv4.pool.sks-keyservers.net --recv-keys "$key" || \
    gpg --keyserver hkp://pgp.mit.edu:80 --recv-keys "$key" ; \
  done

ENV NODE_VERSION 8.11.1

RUN ARCH= && dpkgArch="$(dpkg --print-architecture)" \
  && case "${dpkgArch##*-}" in \
    amd64) ARCH='x64';; \
    ppc64el) ARCH='ppc64le';; \
    s390x) ARCH='s390x';; \
    arm64) ARCH='arm64';; \
    armhf) ARCH='armv7l';; \
    i386) ARCH='x86';; \
    *) echo "unsupported architecture"; exit 1 ;; \
  esac \
  && curl -SLO "https://nodejs.org/dist/v$NODE_VERSION/node-v$NODE_VERSION-linux-$ARCH.tar.xz" \
  && curl -SLO --compressed "https://nodejs.org/dist/v$NODE_VERSION/SHASUMS256.txt.asc" \
  && gpg --batch --decrypt --output SHASUMS256.txt SHASUMS256.txt.asc \
  && grep " node-v$NODE_VERSION-linux-$ARCH.tar.xz\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "node-v$NODE_VERSION-linux-$ARCH.tar.xz" -C /usr/local --strip-components=1 --no-same-owner \
  && rm "node-v$NODE_VERSION-linux-$ARCH.tar.xz" SHASUMS256.txt.asc SHASUMS256.txt \
  && ln -s /usr/local/bin/node /usr/local/bin/nodejs

EXPOSE 1935
EXPOSE 80

# Nginx config
ADD nginx.conf /config/nginx.conf

# Node server
RUN mkdir /js
ADD js /js
WORKDIR /js
RUN npm install

# Startup script
ADD startup.sh /js

CMD ["./startup.sh"]