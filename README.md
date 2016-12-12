# marathon

[![Build Status](https://travis-ci.org/katosys/marathon.svg?branch=master)](https://travis-ci.org/katosys/marathon)

This container is used to build, ship and run Marathon. The run-time dependency `libmesos.so` is not included but it is expected to be bind mounted in `/opt/lib`. You can run this container in combination with https://github.com/katosys/mesos.

**Marathon systemd unit**:
```
[Unit]
Description=Marathon
After=mesos-master.service

[Service]
Slice=kato.slice
Restart=always
RestartSec=10
TimeoutStartSec=0
KillMode=mixed
LimitNOFILE=8192
EnvironmentFile=/etc/kato.env
Environment=IMG=quay.io/kato/marathon:latest
ExecStartPre=/opt/bin/zk-alive ${KATO_QUORUM_COUNT}
ExecStartPre=/usr/bin/rkt fetch ${IMG}
ExecStart=/usr/bin/rkt run \
 --net=host \
 --dns=host \
 --hosts-entry=host \
 --hostname master-${KATO_HOST_ID}.${KATO_DOMAIN} \
 --set-env=LIBPROCESS_IP=${KATO_HOST_IP} \
 --set-env=LIBPROCESS_PORT=9292 \
 --set-env=MESOS_NATIVE_JAVA_LIBRARY=/opt/lib/libmesos.so \
 --volume lib,kind=host,source=/opt/lib \
 --mount volume=lib,target=/opt/lib \
 ${IMG} -- \
 --no-logger \
 --http_address ${KATO_HOST_IP} \
 --master zk://${KATO_ZK}/mesos \
 --zk zk://${KATO_ZK}/marathon \
 --task_launch_timeout 240000 \
 --hostname master-${KATO_HOST_ID}.${KATO_DOMAIN} \
 --checkpoint

[Install]
WantedBy=kato.target
```

**Run from the shell**:

Source the environment:
```
source /etc/kato.env
IMG=quay.io/kato/marathon:latest
```

Run the container:
```
sudo sh -c "ulimit -n 8192; rkt run --interactive --set-env-file=/etc/kato.env --net=host --dns=host --hosts-entry=host --hostname master-${KATO_HOST_ID}.${KATO_DOMAIN} --set-env=LIBPROCESS_IP=${KATO_HOST_IP} --set-env=LIBPROCESS_PORT=9292 --set-env=MESOS_NATIVE_JAVA_LIBRARY=/opt/lib/libmesos.so --volume lib,kind=host,source=/opt/lib --mount volume=lib,target=/opt/lib ${IMG} --exec /bin/sh"
```

Run marathon:
```
/usr/glibc-compat/sbin/ldconfig
marathon --no-logger --checkpoint --http_address ${KATO_HOST_IP} --master zk://${KATO_ZK}/mesos --zk zk://${KATO_ZK}/marathon --task_l
aunch_timeout 240000 --hostname master-${KATO_HOST_ID}.${KATO_DOMAIN} --enable_features external_volumes
```
