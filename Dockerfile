#------------------------------------------------------------------------------
# Set the base image for subsequent instructions:
#------------------------------------------------------------------------------

FROM alpine:3.5
MAINTAINER Marc Villacorta Morera <marc.villacorta@gmail.com>

#------------------------------------------------------------------------------
# Install glibc:
#------------------------------------------------------------------------------

ENV SBT_URL="http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch" \
    RSA_URL="https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master" \
    APK_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download/2.23-r3"

RUN apk add -U --no-cache -t dev ca-certificates libressl \
    && wget -q -O /etc/apk/keys/sgerrand.rsa.pub ${RSA_URL}/sgerrand.rsa.pub \
    && wget ${APK_URL}/glibc-2.23-r3.apk && wget ${APK_URL}/glibc-bin-2.23-r3.apk \
    && apk add --no-cache *.apk && rm /etc/apk/keys/sgerrand.rsa.pub *.apk

RUN ln -s /usr/glibc-compat/etc/ld.so.conf /etc/ && echo /opt/lib >> /etc/ld.so.conf \
    && sed -i '/^RTLDLIST=/c\RTLDLIST=/usr/glibc-compat/lib/ld-linux-x86-64.so.2' \
    /usr/glibc-compat/bin/ldd

#------------------------------------------------------------------------------
# Install marathon:
#------------------------------------------------------------------------------

ENV TAG="1.4.0-RC8"

RUN apk add -U --no-cache -t dev git perl openjdk8 \
    && apk add -U --no-cache bash grep openjdk8-jre \
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
# Pre-squash cleanup:
#------------------------------------------------------------------------------

RUN apk del --purge dev \
    && rm -rf /var/cache/apk/* /tmp/* /marathon ~/.sbt ~/.ivy2

#------------------------------------------------------------------------------
# Entrypoint:
#------------------------------------------------------------------------------

ENTRYPOINT ["/init"]
