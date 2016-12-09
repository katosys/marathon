#------------------------------------------------------------------------------
# Set the base image for subsequent instructions:
#------------------------------------------------------------------------------

FROM anapsix/alpine-java:8_jdk
MAINTAINER Marc Villacorta Morera <marc.villacorta@gmail.com>

#------------------------------------------------------------------------------
# Environment variables:
#------------------------------------------------------------------------------

ENV TAG="1.4.0-RC1" \
    SBT_URL="http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch"

#------------------------------------------------------------------------------
# Install marathon:
#------------------------------------------------------------------------------

RUN apk add -U --no-cache -t dev git openssl perl && apk add -U --no-cache bash grep \
    && git clone https://github.com/mesosphere/marathon.git && cd marathon \
    && { [ "${TAG}" != "master" ] && git checkout tags/v${TAG} -b build; }; \
    eval $(sed s/sbt.version/SBT_VERSION/ < project/build.properties) \
    && wget -P /usr/local/bin ${SBT_URL}/${SBT_VERSION}/sbt-launch.jar \
    && cp project/sbt /usr/local/bin && chmod +x /usr/local/bin/sbt

RUN cd marathon \
    && sbt -Dsbt.log.format=false 'set test in assembly := {}' assembly \
    && ./bin/build-distribution && mv target/marathon-runnable.jar \
    /usr/bin/marathon && chmod +x /usr/bin/marathon

COPY rootfs /

#------------------------------------------------------------------------------
# Setup glibc:
#------------------------------------------------------------------------------

RUN ln -s /usr/glibc-compat/etc/ld.so.conf /etc/ \
    && echo /opt/lib >> /etc/ld.so.conf \
    && sed -i '/^RTLDLIST=/c\RTLDLIST=/usr/glibc-compat/lib/ld-linux-x86-64.so.2' \
    /usr/glibc-compat/bin/ldd

#------------------------------------------------------------------------------
# Pre-squash cleanup:
#------------------------------------------------------------------------------

RUN apk del --purge dev \
    && rm -rf /var/cache/apk/* /tmp/* /marathon ~/.sbt ~/.ivy2

#------------------------------------------------------------------------------
# Entrypoint:
#------------------------------------------------------------------------------

ENTRYPOINT ["/init"]
