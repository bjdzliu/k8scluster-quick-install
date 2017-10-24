#!/bin/bash
echo "======BEGIN DEPLOY flannel ===================="
counter=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [ $counter -le 3 ];do
    echo "begin copy  flanneld to /bin/"
    scp ${SCRIPT_DIR}/deployfactory/flanneld  k8smaster${counter}:/bin/
let counter++
done


mkdir ${SCRIPT_DIR}/deployfactory/flanneldconf

cat <<EOF >   ${SCRIPT_DIR}/deployfactory/flanneldconf/flannelconf
FLANNEL_ETCD_KEY="-etcd-prefix=/coreos.com/network"
FLANNEL_ETCD="-etcd-endpoints=https://k8smaster1.baasclusteronz.local:2379,https://k8smaster2.baasclusteronz.local:2379,https://k8smaster3.baasclusteronz.local:2379"
FLANNEL_IFACE="-iface=172.16.32.131 --ip-masq"
FLANNEL_OPTIONS="-etcd-cafile=/srv/kubernetes/ca.crt  -etcd-certfile=/srv/kubernetes/server.crt -etcd-keyfile=/srv/kubernetes/server.key"
EOF


#etcdctl  --endpoints=https://127.0.0.1:2379 --ca-file="/srv/kubernetes/ca.crt" --cert-file="/srv/kubernetes/client.crt" --key-file="/srv/kubernetes/client.key" set /coreos.com/network/config  '{ "Network": "33.0.0.0/8","SubnetLen":24,"Backend": { "Type": "host-gw", "VNI": 1 } }'

etcdctl --endpoints=https://127.0.0.1:2379 --ca-file="/srv/kubernetes/ca.crt" --cert-file="/srv/kubernetes/client.crt" --key-file="/srv/kubernetes/client.key" set /coreos.com/network/config '{ "Network": "33.0.0.0/8","SubnetLen":16,"Backend": { "Type": "vxlan", "VNI": 1 } }'



cat <<EOF > ${SCRIPT_DIR}/deployfactory/flanneldconf/system_flannel
[Unit]
Description=Flanneld
Documentation=https://github.com/coreos/flannel
After=network.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
User=root
EnvironmentFile=/etc/sysconfig/flanneld
EnvironmentFile=-/etc/sysconfig/docker-network
ExecStart=/bin/flanneld \\
					 \$FLANNEL_ETCD \\
                       \$FLANNEL_ETCD_KEY \\
                       \$FLANNEL_IFACE \\
                        \$FLANNEL_OPTIONS
Restart=on-failure
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF


scp  ${SCRIPT_DIR}/deployfactory/flanneldconf/flannelconf /etc/sysconfig/flanneld
scp  /etc/sysconfig/flanneld  k8smaster2:/etc/sysconfig/
scp  /etc/sysconfig/flanneld  k8smaster3:/etc/sysconfig/



scp ${SCRIPT_DIR}/deployfactory/flanneldconf/system_flannel  /lib/systemd/system/flanneld.service
scp /lib/systemd/system/flanneld.service k8smaster2:/lib/systemd/system/flanneld.service
scp /lib/systemd/system/flanneld.service k8smaster3:/lib/systemd/system/flanneld.service

systemctl daemon-reload




