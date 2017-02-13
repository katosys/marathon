#------------------------------------------------------------------------------
# Set the base image for subsequent instructions:
#------------------------------------------------------------------------------

FROM alpine:3.5
MAINTAINER Marc Villacorta Morera <marc.villacorta@gmail.com>

#------------------------------------------------------------------------------
# Install glibc:
#------------------------------------------------------------------------------

ENV GLIBC_VERSION="2.25-r0" \
    RSA_URL="https://raw.githubusercontent.com/sgerrand/alpine-pkg-glibc/master" \
    APK_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"

RUN apk add -U --no-cache -t dev ca-certificates libressl \
    && wget -q ${APK_URL}/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk \
    && wget -q ${APK_URL}/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk \
    && wget -q ${APK_URL}/${GLIBC_VERSION}/glibc-i18n-${GLIBC_VERSION}.apk \
    && wget -qO /etc/apk/keys/sgerrand.rsa.pub ${RSA_URL}/sgerrand.rsa.pub \
    && apk add --no-cache *.apk && rm /etc/apk/keys/sgerrand.rsa.pub *.apk

RUN ln -s /usr/glibc-compat/etc/ld.so.conf /etc/ \
    && echo '/opt/lib' >> /etc/ld.so.conf \
    && echo 'export LANG=en_US.UTF-8' > /etc/profile.d/locale.sh \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && sed -i '/^RTLDLIST=/c\RTLDLIST=/usr/glibc-compat/lib/ld-linux-x86-64.so.2' \
    /usr/glibc-compat/bin/ldd && apk del glibc-i18n

#------------------------------------------------------------------------------
# Install marathon:
#------------------------------------------------------------------------------

ENV TAG="1.4.0-RC8" \
    SBT_URL="http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch" \

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
