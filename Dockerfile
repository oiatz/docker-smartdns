FROM lsiobase/alpine:3.8 as builder

# set version label
ARG BUILD_DATE
ARG VERSION 
LABEL build_version="simoon version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="simoon"

ENV SMARTDNS_VERSION=latest

RUN echo "**** install packages ****" \
    #&& sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache build-base linux-headers openssl-dev jq libc6-compat curl \
    && cd /tmp \
    && archive=$(curl -fSL https://api.github.com/repos/pymumu/smartdns/releases/${SMARTDNS_VERSION}|jq -r '.tag_name') \
    && curl -fSL https://github.com/pymumu/smartdns/archive/${archive}.tar.gz -o smartdns.tar.gz \
    && tar zvxf smartdns.tar.gz \
    && cd smartdns-${archive} \
    && echo ${TARGETPLATFORM} \
    && if [ "${TARGETPLATFORM}" = "linux\/amd64" ]; then arch="x86-64"; else arch="arm64"; fi \
    && echo ${arch} \
    && cd package && sh ./build-pkg.sh --platform linux --arch ${arch}\
    && mv ../src/smartdns /tmp \
    && mv ../etc/smartdns/smartdns.conf /tmp

FROM lsiobase/alpine:3.8

ENV TZ=Asia/Shanghai

RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update \
    && apk add --no-cache openssl libc6-compat \
    && rm -rf /var/cache/apk/* \
    && rm -rf /tmp/*

RUN mkdir /default/
COPY --from=builder /tmp/smartdns /usr/sbin/
COPY --from=builder /tmp/smartdns.conf /default

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 53:53/udp
VOLUME /config
