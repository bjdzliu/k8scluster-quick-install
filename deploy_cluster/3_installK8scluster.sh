#!/bin/bash
#---------------------------
# scp bin file to worker bin
# author: bjdzliu@cn.ibm.com
# date: 07-06-2017
#---------------------------
#Set path of script
basepath=$(cd `dirname $0`; pwd)

HTTPS_PORT="8443"

mastercluster=false
workercluster=true
localmaster=true

#Set the num of cluster except for master
clusternum=3

VIRTUAL_HOST_DOMAIN="k8smaster0.baasclusteronz.local"

#set master for kubernetes component
MASTER1_HOST_NAME="k8smaster1"
MASTER1_HOST_DOMAIN="k8smaster1.baasclusteronz.local"

MASTER2_HOST_NAME="k8smaster2"
MASTER2_HOST_DOMAIN="k8smaster2.baasclusteronz.local"

MASTER3_HOST_NAME="k8smaster3"
MASTER3_HOST_DOMAIN="k8smaster3.baasclusteronz.local"

#MASTER3_HOST_NAME="k8smaster4"
#MASTER3_HOST_DOMAIN="k8smaster4.baasclusteronz.local"

#set etcd cluster name 
etcd_cluster_domain1="k8smaster1.baasclusteronz.local"
etcd_cluster_domain2="k8smaster2.baasclusteronz.local"
etcd_cluster_domain3="k8smaster3.baasclusteronz.local"


mkdir -p  /data/kubeletdir
mkdir -p     $basepath/deployfactory/k8sconf-common
mkdir -p  $basepath/deployfactory/k8sconf/masternode1
mkdir -p  $basepath/deployfactory/k8sconf/masternode2
mkdir -p  $basepath/deployfactory/k8sconf/masternode3
mkdir     $basepath/deployfactory/systemdconf
mkdir -p $basepath/deployfactory/files/

#Generate admin kube config 
cat <<EOF > $basepath/deployfactory/files/config
apiVersion: v1
clusters:
- cluster:
    certificate-authority: /srv/kubernetes/ca.crt
    server:  https://${VIRTUAL_HOST_DOMAIN}:${HTTPS_PORT}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: kubernetes-admin
  name: kubernetes-admin@kubernetes
current-context: kubernetes-admin@kubernetes
kind: Config
preferences: {}
users:
- name: kubernetes-admin
  user:
    client-certificate: /srv/kubernetes/client.crt
    client-key: /srv/kubernetes/client.key

EOF



#
if [ ! -d /root/.kube ]
then
    mkdir -p /root/.kube
	cp $SCRIPT_DIR/deployfactory/files/config /root/.kube/config
fi




#systemd dir
workersystemdpath=/lib/systemd/system/


#Create systemd conf 

cat <<EOF > $basepath/deployfactory/systemdconf/kube-apiserver.service
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/kubernetes/kubernetes
After=network.target etcd.service

[Service]
Type=notify
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/apiserver
User=root
ExecStart=/bin/kube-apiserver \\
            \$KUBE_LOGTOSTDERR \\
            \$KUBE_LOG_LEVEL \\
            \$KUBE_ETCD_SERVERS \\
            \$KUBE_ETCD_CERTS \\
            \$KUBE_API_ADDRESS \\
			\$KUBE_SECURE_PORT \\
            \$KUBE_API_PORT \\
			\$KUBE_AUTHORIZA_MODE \\
            \$KUBE_ALLOW_PRIV \\
            \$KUBE_SERVICE_ADDRESSES \\
            \$KUBE_ADMISSION_CONTROL \\
            \$KUBE_ENABLE_SWAGGER_UI \\
            \$KUBE_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF


cat <<EOF > $basepath/deployfactory/systemdconf/kube-scheduler.service
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/scheduler
User=root
ExecStart=/bin/kube-scheduler \\
            \$KUBE_LOGTOSTDERR \\
            \$KUBE_LOG_LEVEL \\
            \$KUBE_MASTER \\
            \$KUBE_SCHEDULER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF

cat <<EOF > $basepath/deployfactory/systemdconf/kube-controller-manager.service
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/kubernetes/kubernetes

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/controller-manager
User=root
ExecStart=/bin/kube-controller-manager \\
            \$KUBE_LOGTOSTDERR \\
            \$KUBE_LOG_LEVEL \\
            \$KUBE_MASTER \\
            \$KUBE_CONTROLLER_MANAGER_ARGS
Restart=on-failure
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target

EOF

cat <<EOF > $basepath/deployfactory/systemdconf/kube-proxy.service
[Unit]
Description=Kubernetes Proxy
After=network.target

[Service]
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/proxy
ExecStart=/bin/kube-proxy  \\
            \$KUBE_LOGTOSTDERR \\
            \$KUBE_LOG_LEVEL \\
            \$KUBE_MASTER \\
            \$KUBE_PROXY_ARGS
Restart=on-failure
LimitNOFILE=65536
[Install]
WantedBy=multi-user.target

EOF


cat <<EOF > $basepath/deployfactory/systemdconf/kubelet.service
[Unit]
Description=Kubernetes Kubelet
#After=docker.service
#Requires=docker.service

[Service]
WorkingDirectory=/data/kubeletdir
EnvironmentFile=-/etc/kubernetes/config
EnvironmentFile=-/etc/kubernetes/kubelet
ExecStart=/bin/kubelet \\
            \$KUBE_LOGTOSTDERR \\
            \$KUBE_LOG_LEVEL \\
            \$KUBELET_API_SERVER \\
            \$KUBELET_ADDRESS \\
            \$KUBELET_PORT \\
            \$KUBELET_HOSTNAME \\
            \$KUBE_ALLOW_PRIV \\
            \$KUBELET_POD_INFRA_CONTAINER \\
            \$KUBELET_ARGS

Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
EOF


#KUBE_LOG_LEVEL="--v=2" could be set1 to reduce the /var/log/messages size

cat <<EOF > $basepath/deployfactory/k8sconf-common/config
KUBE_LOGTOSTDERR="--logtostderr=true"
KUBE_LOG_LEVEL="--v=2"
KUBE_ALLOW_PRIV="--allow-privileged=true"
KUBE_MASTER="--master=https://READY_EPLACE_MASTER_NAME:READY_EPLACE_MASTER_PORT"
EOF



cat << EOF >$basepath/deployfactory/k8sconf-common/kubelet
###
# kubernetes kubelet (minion) config

# The address for the info server to serve on (set to 0.0.0.0 or "" for all interfaces)
KUBELET_ADDRESS="--address=0.0.0.0"

#KUBELET_CLUSTER_DOMAIN="--cluster-domain=cluster.local"

#KUBE_CLUSTER_DNS="--cluster-dns=10.96.0.10"

#KUBE_CLIENT_CA_FILE="--client-ca-file=/srv/kubernetes/ca.crt"

#KUBE_TLS_CERT_FILE="--tls-cert-file=/srv/kubernetes/server.crt"

#KUBE_TLS_PRIVATE_KEY_FILE="--tls-private-key-file=/srv/kubernetes/server.key"

#KUBE_CONFIG="--kubeconfig=/root/.kube/config"
# The port for the info server to serve on
# KUBELET_PORT="--port=10250"

# You may leave this blank to use the actual hostname
KUBELET_HOSTNAME="--hostname-override=READY_EPLACE_WORKERNAME"

# location of the api-server
KUBELET_API_SERVER="--api-servers=https://READY_EPLACE_MASTER_NAME:READY_EPLACE_MASTER_PORT"

# Add your own!
KUBELET_ARGS="--max-pods=1000 --hairpin-mode=hairpin-veth  --cluster-domain=cibfintech.com  --cluster-dns=10.96.0.10 --client-ca-file=/srv/kubernetes/ca.crt --tls-cert-file=/srv/kubernetes/server.crt --tls-private-key-file=/srv/kubernetes/server.key --kubeconfig=/root/.kube/config"
EOF



cat << EOF >$basepath/deployfactory/k8sconf-common/scheduler
KUBE_SCHEDULER_ARGS="--kubeconfig=/root/.kube/config  --leader-elect=true"
EOF

cat << EOF >$basepath/deployfactory/k8sconf-common/controller-manager
#CONTROLLER ENABLE HTTPS
KUBE_CONTROLLER_MANAGER_ARGS="--insecure-experimental-approve-all-kubelet-csrs-for-group=system:bootstrappers --leader-elect=true  --kubeconfig=/root/.kube/config --cluster-signing-cert-file=/srv/kubernetes/ca.crt --cluster-signing-key-file=/srv/kubernetes/ca.key --service-account-private-key-file=/srv/kubernetes/server.key --root-ca-file=/srv/kubernetes/ca.crt"

EOF

cat << EOF >$basepath/deployfactory/k8sconf-common/apiserver
#KUBE_API_INSECURE_ADDRESS="--insecure-bind-address=0.0.0.0"

KUBE_API_ADDRESS="--bind-address=0.0.0.0"

KUBE_API_PORT="--insecure-port=0"

KUBE_ETCD_SERVERS="--etcd-servers=https://READY_ETCD_CLUSTER_NAME1:2379,https://READY_ETCD_CLUSTER_NAME2:2379,https://READY_ETCD_CLUSTER_NAME3:2379"

KUBE_ETCD_CERTS="--etcd-cafile=/srv/kubernetes/ca.crt --etcd-certfile=/srv/kubernetes/client.crt --etcd-keyfile=/srv/kubernetes/client.key"

KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.96.0.0/12"

KUBE_ADMISSION_CONTROL="--admission-control=ServiceAccount,NamespaceLifecycle,NamespaceExists,LimitRanger,SecurityContextDeny,PersistentVolumeLabel,DefaultStorageClass,ResourceQuota,DefaultTolerationSeconds"

KUBE_ENABLE_SWAGGER_UI="--enable-swagger-ui=true"

KUBE_AUTHORIZA_MODE="--authorization-mode=AlwaysAllow"

KUBE_SECURE_PORT="--secure-port=443"

#KUBE_CLIENT_CA_FILE="--client-ca-file=/srv/kubernetes/ca.crt"

#KUBE_TLS_CERT_FILE="--tls-cert-file=/srv/kubernetes/server.crt"

#KUBE_TLS_PRIVATE_KEY_FILE="--tls-private-key-file=/srv/kubernetes/server.key"

#KUBE_SERVICE_ACCOUNT_KEY_FILE="--service-account-key-file=/srv/kubernetes/server.key"

#KUBE_CERTIFICATE_AUTHORITY="--kubelet-certificate-authority=/srv/kubernetes/ca.crt"

#KUBE_CLIENT_CERTIFICATE="--kubelet-client-certificate=/srv/kubernetes/client.crt"

#KUBE_CLIENT_KEY="--kubelet-client-key=/srv/kubernetes/client.key"

KUBE_ARGS="--apiserver-count=3 --experimental-bootstrap-token-auth=true --storage-backend=etcd3  --client-ca-file=/srv/kubernetes/ca.crt --tls-cert-file=/srv/kubernetes/server.crt --tls-private-key-file=/srv/kubernetes/server.key --service-account-key-file=/srv/kubernetes/server.key --kubelet-certificate-authority=/srv/kubernetes/ca.crt --kubelet-client-certificate=/srv/kubernetes/client.crt --kubelet-client-key=/srv/kubernetes/client.key"

EOF



cat << EOF >$basepath/deployfactory/k8sconf-common/proxy
KUBE_PROXY_ARGS="--kubeconfig=/root/.kube/config"
EOF


#set k8s port(default 443)
#sed  -i 's/READY_EPLACE_MASTER_PORT/'$HTTPS_PORT'/g' $basepath/deployfactory/k8sconf-common/apiserver
sed  -i 's/READY_EPLACE_MASTER_PORT/'$HTTPS_PORT'/g' $basepath/deployfactory/k8sconf-common/kubelet
sed  -i 's/READY_EPLACE_MASTER_PORT/'$HTTPS_PORT'/g' $basepath/deployfactory/k8sconf-common/config


#set config for k8s components using VIRTUAL_HOST_DOMAIN 
sed  -i 's/READY_EPLACE_MASTER_NAME/'$VIRTUAL_HOST_DOMAIN'/g' $basepath/deployfactory/k8sconf-common/config


#set etcd for api-server 

sed -i 's/READY_ETCD_CLUSTER_NAME1/'$etcd_cluster_domain1'/g'  $basepath/deployfactory/k8sconf-common/apiserver
sed -i 's/READY_ETCD_CLUSTER_NAME2/'$etcd_cluster_domain2'/g'  $basepath/deployfactory/k8sconf-common/apiserver
sed -i 's/READY_ETCD_CLUSTER_NAME3/'$etcd_cluster_domain3'/g'  $basepath/deployfactory/k8sconf-common/apiserver



cp $basepath/deployfactory/k8sconf-common/*  $basepath/deployfactory/k8sconf/masternode1
cp $basepath/deployfactory/k8sconf-common/*  $basepath/deployfactory/k8sconf/masternode2
cp $basepath/deployfactory/k8sconf-common/*  $basepath/deployfactory/k8sconf/masternode3



#set kubelet
sed  -i 's/READY_EPLACE_WORKERNAME/'$MASTER1_HOST_DOMAIN'/g' $basepath/deployfactory/k8sconf/masternode1/kubelet

sed  -i 's/READY_EPLACE_MASTER_NAME/'$VIRTUAL_HOST_DOMAIN'/g'  $basepath/deployfactory/k8sconf/masternode1/kubelet

sed  -i 's/READY_EPLACE_WORKERNAME/'$MASTER2_HOST_DOMAIN'/g' $basepath/deployfactory/k8sconf/masternode2/kubelet

sed  -i 's/READY_EPLACE_MASTER_NAME/'$VIRTUAL_HOST_DOMAIN'/g'  $basepath/deployfactory/k8sconf/masternode2/kubelet

sed  -i 's/READY_EPLACE_WORKERNAME/'$MASTER3_HOST_DOMAIN'/g' $basepath/deployfactory/k8sconf/masternode3/kubelet

sed  -i 's/READY_EPLACE_MASTER_NAME/'$VIRTUAL_HOST_DOMAIN'/g'  $basepath/deployfactory/k8sconf/masternode3/kubelet


#copy admin-config to master2 and master3
scp $basepath/deployfactory/files/config k8smaster2:/root/.kube/config
scp $basepath/deployfactory/files/config k8smaster3:/root/.kube/config


#copy k8s systemd conf to master1 master2 and master3
scp $basepath/deployfactory/systemdconf/* k8smaster1:${workersystemdpath}/
scp $basepath/deployfactory/systemdconf/* k8smaster2:${workersystemdpath}/
scp $basepath/deployfactory/systemdconf/* k8smaster3:${workersystemdpath}/

#copy k8s  conf to master1 master2 and master3
scp $basepath/deployfactory/k8sconf/masternode1/* k8smaster1:/etc/kubernetes/
scp $basepath/deployfactory/k8sconf/masternode2/* k8smaster2:/etc/kubernetes/
scp $basepath/deployfactory/k8sconf/masternode3/* k8smaster3:/etc/kubernetes/


