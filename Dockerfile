#------------------------------------------------------------------------------
# Set the base image for subsequent instructions:
#------------------------------------------------------------------------------

FROM alpine:3.6
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
# Install Oracle JDK 8:
#------------------------------------------------------------------------------

ENV JAVA_HOME="/opt/jdk" \
    PATH="${PATH}:/opt/jdk/bin" \
    JAVA_URL="http://download.oracle.com/otn-pub/java/jdk"

RUN apk add -U --no-cache -t dev curl && mkdir /opt \
    && curl -sLH 'Cookie: oraclelicense=accept-securebackup-cookie' \
    ${JAVA_URL}/8u131-b11/d54c1d3a095b4ff2b6607d096fa80163/jdk-8u131-linux-x64.tar.gz \
    | tar zx -C /opt && mv /opt/jdk1.8.0_131 ${JAVA_HOME} \
    && sed -i s/#networkaddress.cache.ttl=-1/networkaddress.cache.ttl=10/ \
    ${JAVA_HOME}/jre/lib/security/java.security && chown -R root:root ${JAVA_HOME}

#------------------------------------------------------------------------------
# Install marathon:
#------------------------------------------------------------------------------

ENV TAG="1.4.5" \
    SBT_URL="http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch"

RUN apk add -U --no-cache -t dev git perl && apk add -U --no-cache bash grep \
    && git clone https://github.com/mesosphere/marathon.git && cd marathon \
    && { [ "${TAG}" != "master" ] && git checkout tags/v${TAG} -b build; }; \
    eval $(sed s/sbt.version/SBT_VERSION/ < project/build.properties) \
    && curl -Lo /usr/local/bin/sbt-launch.jar ${SBT_URL}/${SBT_VERSION}/sbt-launch.jar \
    && cp project/sbt /usr/local/bin && chmod +x /usr/local/bin/sbt

RUN cd marathon \
    && sbt -Dsbt.log.format=false 'set test in assembly := {}' assembly \
    && ./bin/build-distribution && mv target/marathon-runnable.jar \
    /usr/bin/marathon && chmod +x /usr/bin/marathon && rm -rf /marathon

COPY rootfs /

#------------------------------------------------------------------------------
# Strip JDK into JRE:
#------------------------------------------------------------------------------

RUN find /opt/jdk -maxdepth 1 -mindepth 1 | grep -v jre | xargs rm -rf \
    && cd /opt/jdk && ln -s ./jre/bin ./bin && cd /opt/jdk/jre && rm -rf \
    plugin bin/javaws bin/jjs bin/orbd bin/pack200 bin/policytool bin/rmid \
    bin/rmiregistry bin/servertool bin/tnameserv bin/unpack200 lib/javaws.jar \
    lib/deploy* lib/desktop lib/*javafx* lib/*jfx* lib/amd64/libdecora_sse.so \
    lib/amd64/libprism_*.so lib/amd64/libfxplugins.so lib/amd64/libglass.so \
    lib/amd64/libgstreamer-lite.so lib/amd64/libjavafx*.so lib/amd64/libjfx*.so \
    lib/ext/jfxrt.jar lib/ext/nashorn.jar lib/oblique-fonts lib/plugin.jar

#------------------------------------------------------------------------------
# Pre-squash cleanup:
#------------------------------------------------------------------------------

RUN apk del --purge dev && rm -rf /var/cache/apk/* /tmp/* ~/.sbt ~/.ivy2

#------------------------------------------------------------------------------
# Entrypoint:
#------------------------------------------------------------------------------

ENTRYPOINT ["/init"]
