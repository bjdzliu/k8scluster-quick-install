#!/bin/bash
echo "======BEGIN DEPLOY K8S ===================="
tar -zxvf kubernetes-server-linux-s390x.tar.gz

counter=1
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

while [ $counter -le 3 ];do
for file in `ls  ${SCRIPT_DIR}/kubernetes/server/bin`;do
  if [ -x ${SCRIPT_DIR}/kubernetes/server/bin/$file ];then
    echo "begin copy  $file to /bin/"
    scp ${SCRIPT_DIR}/kubernetes/server/bin/$file k8smaster${counter}:/bin/
  fi
done
let counter++
done

