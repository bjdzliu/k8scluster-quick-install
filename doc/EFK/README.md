自托管的 bootstrap 过程记录在 [kubeadm 1.8 设计文档](https://github.com/kubernetes/kubeadm/blob/master/docs/design/design_v1.8.md#optional-self-hosting) 中。
简言概之，`kubeadm init --feature-gates=SelfHosting=true` 的工作原理如下：

<!--
  1. As usual, kubeadm creates static pod YAML files in `/etc/kubernetes/manifests/`.

  1. Kubelet loads these files and launches the initial static control plane.
    Kubeadm waits for this initial static control plane to be running and
    healthy. This is identical to the `kubeadm init` process without self-hosting.
-->

  1. 像往常一样，kubeadm 在 `/etc/kubernetes/manifests/` 中创建静态的 pod YAML 文件。

  1. Kubelet 加载这些文件并启动初始静态 control plane。Kubeadm 等待这个最初的 control plane 健康运行。这与没有自托管的 `kubeadm init` 进程相同。
<!--
  1. Kubeadm uses the static control plane pod manifests to construct a set of
    DaemonSet manifests that will run the self-hosted control plane.

  1. Kubeadm creates DaemonSets in the `kube-system` namespace and waits for the
    resulting pods to be running.
-->

  1. Kubeadm 使用静态 control plane pod manifests 来构建一组运行在自托管 control plane 的 DaemonSet manifests。

  1. Kubeadm 在 `kube-system` 命名空间中创建 DaemonSet，并等待生成的的 Pod 运行。
