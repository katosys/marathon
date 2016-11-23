#------------------------------------------------------------------------------
# Set the base image for subsequent instructions:
#------------------------------------------------------------------------------

FROM alpine:edge
MAINTAINER Marc Villacorta Morera <marc.villacorta@gmail.com>

#------------------------------------------------------------------------------
# Environment variables:
#------------------------------------------------------------------------------

ENV TAG="1.3.6" \
    SBT_URL="http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch" \
    GLIBC_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3"

#------------------------------------------------------------------------------
# Install marathon:
#------------------------------------------------------------------------------

RUN apk add -U --no-cache -t dev git openjdk8 openssl \
    && apk add -U --no-cache bash openjdk8-jre \
    && git clone https://github.com/mesosphere/marathon.git && cd marathon \
    && { [ "${TAG}" != "master" ] && git checkout tags/v${TAG} -b build; }; \
    eval $(sed s/sbt.version/SBT_VERSION/ < project/build.properties) \
    && wget -P /usr/local/bin ${SBT_URL}/${SBT_VERSION}/sbt-launch.jar \
    && cp project/sbt /usr/local/bin && chmod +x /usr/local/bin/sbt

RUN cd marathon && sbt -Dsbt.log.format=false assembly \
    && ./bin/build-distribution && mv target/marathon-runnable.jar \
    /usr/bin/marathon && chmod +x /usr/bin/marathon

COPY alpine/rootfs /

#------------------------------------------------------------------------------
# Install glibc:
#------------------------------------------------------------------------------

RUN wget ${GLIBC_URL}/glibc-2.23-r3.apk \
    && wget ${GLIBC_URL}/glibc-bin-2.23-r3.apk \
    && apk add --no-cache --allow-untrusted *.apk \
    && ln -s /usr/glibc-compat/etc/ld.so.conf /etc/ \
    && echo /opt/lib >> /etc/ld.so.conf \
    && sed -i '/^RTLDLIST=/c\RTLDLIST=/usr/glibc-compat/lib/ld-linux-x86-64.so.2' \
    /usr/glibc-compat/bin/ldd && rm -f *.apk

#------------------------------------------------------------------------------
# Pre-squash cleanup:
#------------------------------------------------------------------------------

RUN apk del --purge dev \
    && rm -rf /var/cache/apk/* /tmp/* /marathon ~/.sbt ~/.ivy2

#------------------------------------------------------------------------------
# Entrypoint:
#------------------------------------------------------------------------------

ENTRYPOINT ["/init"]
