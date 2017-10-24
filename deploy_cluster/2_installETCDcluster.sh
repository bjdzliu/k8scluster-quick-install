#!/bin/bash
basepath=$(cd `dirname $0`; pwd)
mkdir ${basepath}/etcdconfdir

tar xf etcd-3.1.9.tar

scp etcd-3.1.9/etcd k8smaster1:/bin
scp etcd-3.1.9/etcd k8smaster2:/bin
scp etcd-3.1.9/etcd k8smaster3:/bin

scp etcd-3.1.9/etcdctl k8smaster1:/bin
scp etcd-3.1.9/etcdctl k8smaster2:/bin
scp etcd-3.1.9/etcdctl k8smaster3:/bin


#set master for kubernetes component
MASTER1_HOST_NAME="k8smaster1"
MASTER1_HOST_DOMAIN="k8smaster1.baasclusteronz.local"

MASTER2_HOST_NAME="k8smaster2"
MASTER2_HOST_DOMAIN="k8smaster2.baasclusteronz.local"

MASTER3_HOST_NAME="k8smaster3"
MASTER3_HOST_DOMAIN="k8smaster3.baasclusteronz.local"



cat <<EOF > /lib/systemd/system/etcd.service
[Unit]
Description=etcd - highly-available key value store
Documentation=https://github.com/coreos/etcd
Documentation=man:etcd
After=network.target
Wants=network-online.target


[Service]
Type=notify
#ETCDCTL_API=3
Environment=ETCD_UNSUPPORTED_ARCH=s390x
WorkingDirectory=/var/lib/etcd
EnvironmentFile=-/etc/etcd/etcd.conf
# set GOMAXPROCS to number of processors
ExecStart=/bin/etcd
Restart=on-abnormal
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF

cat <<EOF > ${basepath}/etcdconfdir/etcd-common.conf
# [member]
ETCD_NAME={etcdname}
ETCD_DATA_DIR="/etcd_data"
ETCD_UNSUPPORTED_ARCH=s390x
ETCD_ELECTION_TIMEOUT="1000"
#--listen-peer-urls
ETCD_LISTEN_PEER_URLS="https://{nodename}.baasclusteronz.local:2380"
#--listen-client-urls
ETCD_LISTEN_CLIENT_URLS="https://127.0.0.1:2379,https://{nodename}.baasclusteronz.local:2379"
#[cluster]
#--initial-advertise-peer-urls
ETCD_INITIAL_ADVERTISE_PEER_URLS="https://{nodename}.baasclusteronz.local:2380"
ETCD_INITIAL_CLUSTER="etcd1=https://k8smaster1.baasclusteronz.local:2380,etcd2=https://k8smaster2.baasclusteronz.local:2380,etcd3=https://k8smaster3.baasclusteronz.local:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster-1"
#--advertise-client-urls
ETCD_ADVERTISE_CLIENT_URLS="https://{nodename}.baasclusteronz.local:2379"
#[security]
ETCD_CERT_FILE="/srv/kubernetes/server.crt"
ETCD_KEY_FILE="/srv/kubernetes/server.key"
ETCD_CLIENT_CERT_AUTH="true"
ETCD_TRUSTED_CA_FILE="/srv/kubernetes/ca.crt"

ETCD_PEER_CERT_FILE="/srv/kubernetes/server.crt"
ETCD_PEER_KEY_FILE="/srv/kubernetes/server.key"
ETCD_PEER_CLIENT_CERT_AUTH="true"
ETCD_PEER_TRUSTED_CA_FILE="/srv/kubernetes/ca.crt"

#ETCD_PEER_AUTO_TLS=
#
#[logging]
#ETCD_DEBUG="false"
# examples for -log-package-levels etcdserver=WARNING,security=DEBUG
#ETCD_LOG_PACKAGE_LEVELS=""
#
#[profiling]
#ETCD_ENABLE_PPROF="false"

EOF


sed   "s/{nodename}/k8smaster1/g"  ${basepath}/etcdconfdir/etcd-common.conf >  ${basepath}/etcdconfdir/etcd1.conf
sed  -i "s/{etcdname}/etcd1/g"  ${basepath}/etcdconfdir/etcd1.conf 

sed   "s/{nodename}/k8smaster2/g"  ${basepath}/etcdconfdir/etcd-common.conf >  ${basepath}/etcdconfdir/etcd2.conf
sed   -i "s/{etcdname}/etcd2/g"  ${basepath}/etcdconfdir/etcd2.conf 

sed   "s/{nodename}/k8smaster3/g"  ${basepath}/etcdconfdir/etcd-common.conf >  ${basepath}/etcdconfdir/etcd3.conf
sed   -i  "s/{etcdname}/etcd3/g"  ${basepath}/etcdconfdir/etcd3.conf 


scp ${basepath}/etcdconfdir/etcd1.conf k8smaster1:/etc/etcd/etcd.conf

scp ${basepath}/etcdconfdir/etcd2.conf k8smaster2:/etc/etcd/etcd.conf

scp ${basepath}/etcdconfdir/etcd3.conf k8smaster3:/etc/etcd/etcd.conf


scp /lib/systemd/system/etcd.service k8smaster2:/lib/systemd/system/

scp /lib/systemd/system/etcd.service k8smaster3:/lib/systemd/system/
 
systemctl daemon-reload

#ETCDCTL_API=3 etcdctl  member list  --endpoints=https://127.0.0.1:2379 --cacert="/srv/kubernetes/ca.crt" --cert="/srv/kubernetes/client.crt" --key="/srv/kubernetes/client.key"
#
#

