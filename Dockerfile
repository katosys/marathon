#------------------------------------------------------------------------------
# Set the base image for subsequent instructions:
#------------------------------------------------------------------------------

FROM quay.io/kato/mesos:v1.0.1-1.10.3-1
MAINTAINER Marc Villacorta Morera <marc.villacorta@gmail.com>

#------------------------------------------------------------------------------
# Environment variables:
#------------------------------------------------------------------------------

ENV TAG="1.3.3" \
    SBT_URL="http://repo.typesafe.com/typesafe/ivy-releases/org.scala-sbt/sbt-launch"

#------------------------------------------------------------------------------
# Install marathon:
#------------------------------------------------------------------------------

RUN apk add -U --no-cache -t dev git openjdk8 \
    && apk add -U --no-cache bash openjdk8-jre \
    && git clone https://github.com/mesosphere/marathon.git && cd marathon \
    && { [ "${TAG}" != "master" ] && git checkout tags/v${TAG} -b v${TAG}; }; \
    eval $(sed s/sbt.version/SBT_VERSION/ < project/build.properties) \
    && wget -P /usr/local/bin ${SBT_URL}/${SBT_VERSION}/sbt-launch.jar \
    && cp project/sbt /usr/local/bin && chmod +x /usr/local/bin/sbt \
    && sbt -Dsbt.log.format=false assembly \
    && mv $(find target -name 'marathon-assembly-*.jar' | sort | tail -1) . \
    && rm -rf target/* ~/.sbt ~/.ivy2 && mv marathon-assembly-*.jar target \
    && apk del --purge dev && rm -rf /var/cache/apk/* /tmp/* /marathon/.git

#------------------------------------------------------------------------------
# Expose ports and entrypoint:
#------------------------------------------------------------------------------

WORKDIR /marathon
ENTRYPOINT ["./bin/start"]
