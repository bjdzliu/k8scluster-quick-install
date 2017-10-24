## k8scluster-quick-install

## 目标
k8s有3个master，有HA。  
配置一个虚拟IP。  
一套证书，master和node共用。  
自定义的domain name in k8s cluster。  
自定义k8s node name。

## 环境
内部网络，无互联网。  
3台master。

## 不足
加入node时，需要手工在/etc/hosts内添加node name。
