## k8scluster-quick-install
改进于[version1](https://github.com/bjdzliu/k8scluster-quick-install/tree/version1)
## 目标
k8s有3个master，有HA。  
配置一个虚拟IP。  
一套证书，master和node共用。  
自定义的domain name in k8s cluster。  
自定义k8s node name。
手工配置k8s。

## 环境
内部网络，无互联网。  
3台master。

## 思路

1. 准备k8s、etcd、flannel的二进制文件  
1. 搭建etcd集群，定义pod的子网
1. 搭建falnnel网络
1. 生成k8s配置文件并传输到各master
1. 使用pacemaker管理虚拟IP
1. 使用haproy进行负载均衡
1. 新增node
