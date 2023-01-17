#!/bin/sh

/etc/eks/bootstrap.sh ${cluster_name} --kubelet-extra-args '${kubelet_extra_args}'

%{ for val in images ~}
sleep 1
${val}
%{ endfor ~}

exit 0