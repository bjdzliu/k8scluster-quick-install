# 不通过kubectl proxy的方式，访问kibana
环境 k8s 1.6.7

1. 部署安装EFK
涉及到授权的部分，参考[链接](https://github.com/opsnull/follow-me-install-kubernetes-cluster/blob/master/11-%E9%83%A8%E7%BD%B2EFK%E6%8F%92%E4%BB%B6.md)

2. 创建授权用户
创建一个用户admin，并授予权限,参考[链接](https://kubernetes.io/docs/admin/authorization/rbac/)

```
kubectl create clusterrolebinding root-cluster-admin-binding --clusterrole=cluster-admin --user=admin
```

3. 配置apiserver  
启用静态密码文件验证,参考[链接](https://kubernetes.io/docs/admin/authentication/)  
准备文件basic_auth.csv
```
cat > /etc/kubernetes/pki/basic_auth.csv << EOF
admin,admin,admin
EOF
```
编辑文件/etc/kubernetes/manifests/kube-apiserver.yaml，添加

```
- --basic-auth-file=/etc/kubernetes/pki/basic_auth.csv
```  

重启kubelet
```
systemctl restart kubelet.service
```
api pod 自动重新启动。

4. 配置客户端浏览器
如果是http客户端，加header，firefox安装modifyheader插件  
header的名字：Authorization  值：  Basic BASE64ENCODED(USER:PASSWORD)

验证：https://{master ip}/api/v1/proxy/namespaces/kube-system/services/kibana-logging/app/kibana
