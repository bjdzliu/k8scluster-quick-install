
[TOC]
# IP arrangement
There are four machines, three of them are master node, the last one  is worker node.
Must prepare a virtual IP in your environment.
your ip arrangement might like below:
VIP                 172.16.30.178
master1      172.16.30.176
master2      172.16.30.179
master3      172.16.30.174
worker        172.16.30.173

Operate bash command  on every master node:

cat <<EOF >> /etc/hosts
172.16.30.176 master1
172.16.30.179 master2
172.16.30.174 master3

172.16.30.176 k8smaster1
172.16.30.179 k8smaster2
172.16.30.174 k8smaster3

172.16.30.176 k8smaster1.baasclusteronz.local
172.16.30.179 k8smaster2.baasclusteronz.local
172.16.30.174 k8smaster3.baasclusteronz.local
172.16.30.178     k8smaster0.baasclusteronz.local
EOF


# Prepare installation package on every master node
operate on master1 , master2  and master3:
1. Download  deploy_cluster

2. Install packages to be required
if you have internet access, directly install.
```
apt-get update
apt-get install pacemaker  docker.io haproxy nfs-server expect
```

if you in a private environment, no internet access,
```
cd  /root/deploy_cluster/Ubuntu_Install_Package/
tar xf  archives_docker_pacemaker_haproxy_expect.tar
cd archives
dpkg -i *
```

# Configure  ssh login without password
write  your own IP in this script.
```
vi ~/deploy_cluster/0_sshlogin.sh
NODE1="{your master1 ip}"
NODE2="{your master2 ip}"
NODE3="{your master3 ip}"
```

example:  
    NODE1="172.16.30.176"  
    NODE2="172.16.30.179"  
    NODE3="172.16.30.174"  

```
./0_sshlogin.sh
```

# Create some dirs
```
 mkdir /etcd_data
 mkdir /etc/etcd
 mkdir /var/lib/etcd/
 mkdir /etc/kubernetes
 mkdir /root/.kube/    
 mkdir /data/kubeletdir
 mkdir /srv/kubernetes
```
only operate on master1
```
rm -fr /root/.kube/
```

# Create certs on master1:
```
#cd /root/deploy_cluster/openssldir
# ls
openssl-ca.cnf  openssl-client.cnf  openssl-server.cnf
#cp * /srv/kubernetes
#cd /srv/kubernetes
#openssl genrsa -out ca.key 2048
#openssl req -x509 -new -nodes -key ca.key -days 10000 -out ca.crt -config openssl-ca.cnf

Country Name (2 letter code) [AU]:CN
State or Province Name (full name) [Some-State]:BeiJing
Locality Name (eg, city) []:BJ
Organization Name (eg, company) [Internet Widgits Pty Ltd]:xingye
Organizational Unit Name (eg, section) [Default Company Ltd]:cibft
Common Name (e.g. server FQDN or YOUR name) []:k8scaserver

#openssl genrsa -out server.key 2048

#openssl req -new -key server.key -out server.csr -config openssl-server.cnf
Country Name (2 letter code) [AU]:CN
State or Province Name (full name) [Some-State]:BeiJing
Locality Name (eg, city) []:BJ
Organization Name (eg, company) [Internet Widgits Pty Ltd]:xingye
Organizational Unit Name (eg, section) [Default Company Ltd]:cibft
Common Name (e.g. server FQDN or YOUR name) []:kubernetes
```

Create a extfile.cnf and write down a "subjectAltName " line:
write your own IP in this file.
```
#vi extfile.cnf
subjectAltName = IP.1:10.0.0.1,IP.2:{Your VIP},IP.3:127.0.0.1 ,IP.4:10.96.0.1,IP.5:{master1'IP} ,IP.6:{master2'IP},IP.7:{master3'IP} ,DNS.3:kubernetes.default,DNS.4:*.baasclusteronz.local,DNS.5:kubernetes.default.svc.cibfintech.com,DNS.6:kubernetes.default.svc,DNS.7:kubernetes,DNS.8:*.cibfintech.com
```

This is my example:
subjectAltName = IP.1:10.0.0.1,IP.2:172.16.30.178,IP.3:127.0.0.1,IP.4:10.96.0.1 ,IP.5:172.16.30.176,IP.6:172.16.30.174,IP.7:172.16.30.179,DNS.3:kubernetes.default,DNS.4:*.baasclusteronz.local,DNS.5:kubernetes.default.svc.cibfintech.com,DNS.6:kubernetes.default.svc,DNS.7:kubernetes,DNS.8:*.cibfintech.com

```
# openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 10000 -extfile extfile.cnf

#openssl verify -CAfile ca.crt server.crt

#openssl genrsa -out client.key 2048
#openssl req -new -key client.key -out client.csr -config openssl-client.cnf

Input value:
Organization Name (eg, company) [Internet Widgits Pty Ltd]:system:masters
Organizational Unit Name (eg, section) [Default Company Ltd]:cibfintech
CN=kubernetes-admin

# mkdir newcerts
# touch index.txt
# echo "02" > serial

# openssl ca -config ./openssl-client.cnf -out client.crt  -infiles client.csr

# scp /srv/kubernetes/* k8smaster2:/srv/kubernetes
# scp /srv/kubernetes/* k8smaster3:/srv/kubernetes
```

# Trans k8s bin file to every node
```
#cd ~/deploy_cluster
#./1_transK8S.sh
```

#  Set up ETCD Cluster
```
#cd ~/deploy_cluster
#./2_installETCDcluster.sh
```
Start etcd service in every masters
```
# systemctl enable etcd
# systemctl start etcd
```

# Trans k8s conf file to every node
```
#cd ~/deploy_cluster
#./3_installK8scluster.sh
```

# Start Flannel Service
operate on every master
```
vi /etc/sysconfig/flanneld
On master1: -iface={Your master1 public IP}
On  master2:-iface={Your master2 public IP}
On  master3:-iface={Your master3 public IP}
```
example:  FLANNEL_IFACE="-iface=172.16.30.176 --ip-masq"

operate on master1 node:
```
#cd ~/deploy_cluster
#./4_installFLANNEL.sh
```

operate on every master node
```
systemctl daemon-reload
systemctl restart flanneld
systemctl status flanneld
```

# Start Docker Service
operate on master1 node
```
#cd  ~/deploy_cluster
#cp 5_dockersetting/docker.service  /lib/systemd/system/docker.service
#cp 5_dockersetting/docker    /etc/default/
# scp 5_dockersetting/docker.service master2:/lib/systemd/system/
# scp 5_dockersetting/docker.service master3:/lib/systemd/system/
# scp 5_dockersetting/docker    master2:/etc/default/
# scp 5_dockersetting/docker    master3:/etc/default/
```
operate on every masters node
```
#systemctl restart docker
#systemctl status docker
```

# Start k8s service
operate on every masters node
```
systemctl start kube-apiserver.service
systemctl start kube-controller-manager.service
systemctl start kube-scheduler.service
systemctl start kubelet.service
systemctl start kube-proxy

systemctl enable kube-apiserver.service
systemctl enable kube-controller-manager.service
systemctl enable kube-scheduler.service
systemctl enable kubelet.service
systemctl enable kube-proxy
systemctl enable flanneld
systemctl enable docker
```



# Start pacemaker service

 ## operate on every master node

 ```
cat <<EOF >>/etc/corosync/corosync.conf
service {
 #Load the Pacemaker Cluster Resource Manager
ver: 0
name: pacemaker
use_mgmtd: no
use_logd: no
}
EOF
```
write  your ip:
```
vi  /etc/corosync/corosync.conf
bindnetaddr: {your public ip}
```

## operate on master1
```
#cd /etc/corosync/
#corosync-keygen
#scp authkey  master2: /etc/corosync/
#scp authkey  master3: /etc/corosync/
```

## operate on every master node
```
systemctl enable corosync
systemctl enable pacemaker
systemctl restart corosync
systemctl restart pacemaker
```

Verify
```
crm status
```

## Set VIP
chose a nic name on which your public ip run, find  nic name using command:
```
#ip link show
2: enc1000: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 02:00:00:0e:59:7c brd ff:ff:ff:ff:ff:ff
    inet 172.16.30.176/24 brd 172.16.30.255 scope global enc1000

```

```
# ip addr add 172.16.30.178  dev enc1000
#crm configure rsc_defaults resource-stickiness=100
#crm configure property no-quorum-policy=ignore
#crm configure property stonith-enabled="false"
#crm configure rsc_defaults failure-timeout=0
#crm configure rsc_defaults migration-threshold=10
#crm configure primitive vip ocf:heartbeat:IPaddr2 params ip=172.16.30.178 cidr_netmask=24 nic=enc1000 op start interval=0s timeout=20s op stop interval=0s timeout=20s op monitor interval=30s meta priority=100
```

Verify
```
crm status
```

#  Start haproxy service
## Prepare haproxy conf
 Write your public ip in bottom of  haproxy.cfg
```
 cd ~/deploy_cluster/13_haproxy
 vi haproxy.cfg
         server          kube2 {master1 public ip }:443
         server          kube1  {master2 public ip }:443
         server          kube3  {master3 public ip }:443

 example:
         server          kube2 172.16.30.179:443
         server          kube1 172.16.30.176:443
         server          kube3 172.16.30.174:443

 # cp haproxy.conf  /etc/haproxy/
 # scp haproxy.conf master2:/etc/
 # scp haproxy.conf master3:/etc/
```



operate on every master node:
```
#systemctl restart haproxy
```

# Load docker image on every master node

Operate on every master  node
```
docker load < ~/deploy_cluster/docker_images/dashboard.tar
docker load < ~/deploy_cluster/docker_images/pause-s390x.tar
docker load < ~/deploy_cluster/6_dns_image/k8s-dns-sidecar-s390x-1.14.4.tar
docker load < ~/deploy_cluster/6_dns_image/k8s-dns-dnsmasq-nanny-s390x-1.14.4.tar
docker load < ~/deploy_cluster/6_dns_image/ k8s-dns-kube-dns-s390x-1.14.1.tar
```
Operate on master1:
```
#cd /root/deploy_cluster/6_dns_image
#kubectl create -f dns-sa.yaml
#kubectl create -f dns.yaml
#kubectl create -f dns.svc.yaml
```

# Install  k8s dashboard

root@master01:~# kubectl label node  k8smaster1.baasclusteronz.local noderole=master
node "k8smaster1.baasclusteronz.local" labeled
root@master01:~# kubectl label node  k8smaster2.baasclusteronz.local noderole=master
node "k8smaster2.baasclusteronz.local" labeled
root@master01:~# kubectl label node  k8smaster3.baasclusteronz.local noderole=master
node "k8smaster3.baasclusteronz.local" labeled

```
#kubectl create -f 7_dashboard.yaml  
```

Verify:
```
#kubectl get services -n kube-system
access in your Browser http://172.16.30.176:30117
```

# Install prometheus-s390x monitor
## Operate on every master node
```
#cd ~/deploy_cluster/8_monitoring
#tar xf k8s-monitor.tar
#cd  k8s-monitor/prometheus-s390x
#./load.sh
```

## install monitor
operate on master1 node
```
#cd ~/deploy_cluster/8_monitoring/k8s-monitor/prometheus-operator/contrib/kube-prometheus
Run deploy command:
#hack/cluster-monitoring/deploy
```

verify:
access prometheus-s390x monitor : http://{your master IP}:30902/
example:   http://172.16.30.173:30902/


# Add a k8s worker node

worker node  ip：172.16.30.173
worker node name: k8sworker01.baasclusteronz.local

operate on worker node:
```
mkdir /etc/kubernetes
mkdir /root/.kube/
mkdir /data/kubeletdir
mkdir  /srv/kubernetes
echo "172.16.30.173  k8sworker01.baasclusteronz.local"  >> /etc/hosts
echo "172.16.30.178  k8sworker0.baasclusteronz.local"  >> /etc/hosts
```

operate on the master1 node:

 ```
 export workerip=172.16.30.173
 echo "172.16.30.173  k8sworker01.baasclusteronz.local" >> /etc/hosts
 scp deploy_cluster.tar  ${workerip}:/root
scp /srv/kubernetes/*          ${workerip}:/srv/kubernetes
scp /root/.kube/config          ${workerip}:/root/.kube/
scp /bin/kube*                        ${workerip}:/bin/

 scp /bin/flanneld   ${workerip}:/bin

 scp /etc/sysconfig/flanneld  ${workerip}:/etc/sysconfig/

 scp /etc/kubernetes/   ${workerip}:/etc/sysconfig/

 scp /etc/default/docker    ${workerip}:/etc/default/

 scp /lib/systemd/system/docker.service  ${workerip}:/lib/systemd/system/

scp /lib/systemd/system/flanneld.service  ${workerip}:/lib/systemd/system/

scp /lib/systemd/system/kube-proxy.service  ${workerip}:/lib/systemd/system/

scp /lib/systemd/system/kubelet.service   ${workerip}:/lib/systemd/system/
```

operate on worker node
```
cd /root
tar xf deploy_cluster.tar
cd deploy_cluster/Ubuntu_Install_Package
tar xf archives.docker.tar
cd archives
dpkg -i *

Write worker node public ip on line 3 of file flanneld
#vi  /etc/sysconfig/flanneld

example: FLANNEL_IFACE="-iface=172.16.30.173 --ip-masq"

Write worker node hostname on line "KUBELET_HOSTNAME"  of file kubelet
#vi /etc/kubernetes/kubelet

example : KUBELET_HOSTNAME="--hostname-override= k8sworker01.baasclusteronz.local"

start flannel , docker, k8s service on worker node
systemctl start flanneld
systemctl start docker
 systemctl start  kubelet
 systemctl start kube-proxy
 systemctl enable flanneld
 systemctl enable docker
 systemctl enable kubelet
 systemctl enable  kube-proxy

```
operate on master node:
After a while , verify node status on master1 node
```
kubectl get nodes
```

Import images on every  the worker node:
operate on worker node:
```
cd /root
tar xf deploy_cluster.tar
cd ~/deploy_cluster/8_monitoring
tar xf k8s-monitor.tar
cd  k8s-monitor/prometheus-s390x
./load.sh

docker load < ~/deploy_cluster/docker_images/dashboard.tar
docker load < ~/deploy_cluster/docker_images/pause-s390x.tar
docker load < ~/deploy_cluster/6_dns_image/k8s-dns-sidecar-s390x-1.14.4.tar
docker load < ~/deploy_cluster/6_dns_image/k8s-dns-dnsmasq-nanny-s390x-1.14.4.tar
docker load < ~/deploy_cluster/6_dns_image/ k8s-dns-kube-dns-s390x-1.14.1.tar
```
