#!/bin/bash

export KUBECONFIG=/var/lib/nagios/.kube/config

# Auto generate the kubeconfig since it won't always exist
kubectl --kubeconfig=$KUBECONFIG config set-cluster development --server=https://kubernetes.default.svc.cluster.local --certificate-authority=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt >/dev/null
kubectl --kubeconfig=$KUBECONFIG config set-credentials developer --token=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token) >/dev/null
kubectl --kubeconfig=$KUBECONFIG config set-context development --cluster=development --user=developer >/dev/null
kubectl --kubeconfig=$KUBECONFIG config use-context development >/dev/null

# check_kube.sh - Monitors various aspects of Kubernetes
# Charles Bender
# csb1582@gmail.com
#
# This plugin attempts to provide general monitoring for Kubernetes
# deployments, daemonsets, replicationcontrollers, nodes, as well as
# Kubernetes components such as etcd, scheduler, and controller
#
# Some examples:
# Kubelet check on node1 - ./check_kube.sh -t node -c Ready -n default -o node1
# Deployment check for deployment1 - ./check_kube.sh -t deployment -c Available -n default -o deployment1
# Daemonset check for flannel - ./check_kube.sh -t daemonset -n kube-system -c status -o kube-flannel-ds-amd64
# Component check for etcd-0 - ./check_kube.sh -t componentstatuses -n default -c status -o etcd-0
#
# kubectl and jq are required for this plugin to work
#
# IMPORTANT - the variable KUBECONFIG must be set correctly. For some reason kubectl doesn't find the .kube/config
# file when executed under Nagios
#
# While this plugin will work with the admin config, it is highly recommended to create a read only user for Nagios
#
# A read only user can be created using the following commands:
#
# 1 - Create certificate for Nagios user
#     openssl req -new -newkey rsa:2048 -keyout nagios.key -nodes -out nagios.req -subj "/CN=nagios/O=developers"
#     openssl x509 -req -in nagios.req  -CA /etc/kubernetes/pki/ca.crt -CAkey /etc/kubernetes/pki/ca.key -CAcreateserial -out nagios.crt -days 3650
#
# 2 - Create service account
#     kubectl create sa nagios
#
# 3 - Apply the following YAML. This will create the ClusterRole and ClusterRoleBinding for Nagios. Note that this config allows
#     clusterwide read only access, including system namespaces. Adjust as needed!
#     cat <<EOF | kubectl apply -f -
#     kind: ClusterRole
#     apiVersion: rbac.authorization.k8s.io/v1
#     metadata:
#       name: nagios
#     rules:
#       - apiGroups: ['*']
#       resources: ['*']
#       verbs: ["get", "list", "watch"]
#     ---
#     kind: ClusterRoleBinding
#     apiVersion: rbac.authorization.k8s.io/v1
#     metadata:
#       name: nagios
#     subjects:
#       - kind: User
#       name: nagios
#       apiGroup: "rbac.authorization.k8s.io"
#     roleRef:
#       kind: ClusterRole
#       name: nagios
#       apiGroup: "rbac.authorization.k8s.io"
#     EOF
#
# 4 - Create the kubectl config file as follows in /home/nagios/.kube.config You can get certificate authority
#     and server from /etc/kubenetes/admin.conf on master Kubernetes server
#     apiVersion: v1
#     clusters:
#     - cluster:
#         certificate-authority-data: <sensitive data>
#         server: <server>
#       name: kubernetes
#       contexts:
#       - context:
#           cluster: kubernetes
#           user: nagios
#         name: nagios@kubernetes
#       current-context: nagios@kubernetes
#       kind: Config
#       preferences: {}
#       users:
#       - name: nagios
#         user:
#           client-certificate: nagios.crt
#           client-key: nagios.key

# do not modify below this line

usage="./check_kube.sh -t [node|deployment|daemonset|replicationcontroller|componentstatuses] -c [MemoryPressure,DiskPressure,PIDPressure,Ready|Available,Progressing|status|status|status] -n [namespace] -o [object]"
ok=0
warning=1
critical=2
unknown=3

# check prereqs
test_kubectl=`which kubectl`
test_jq=`which jq`
if [ -z "$test_kubectl" ] || [ -z "$test_jq" ]; then
  echo "kubectl or jq not found. Cannot continue"
  exit $unknown
fi

# node checks
check_node () {
  node_status=`kubectl -n $namespace get nodes $object -o json | jq -r --arg check "$check" '.status | .conditions[] | select(.type==$check) | .status'`
  if [ "$check" == "Ready" ] && [ "$node_status" == "False" ]; then
    echo "CRITICAL - Kubelet reports Not Ready"
    return $critical
  elif [ "$check" == "Ready" ] && [ "$node_status" == "True" ]; then
    echo "OK - Kubelet reports Ready"
    return $ok
  elif ( [ "$check" == "MemoryPressure" ] || [ "$check" == "DiskPressure" ] || [ "$check" == "PIDPressure" ] ) && [ "$node_status" == "True" ]; then
    echo "CRITICAL - $check reports True"
    return $critical
  elif ( [ "$check" == "MemoryPressure" ] || [ "$check" == "DiskPressure" ] || [ "$check" == "PIDPressure" ] ) && [ "$node_status" == "False" ]; then
    echo "OK - $check reports False"
    return $ok
  else
    echo "UNKNOWN - output not understood"
    return $unknown
  fi
}

# deployment checks
check_deployment () {
  deployment_status=`kubectl -n $namespace get deployments. $object -o json | jq -r --arg check "$check" '.status | .conditions[] | select(.type==$check) | .status'`
  ready_replicas=`kubectl -n $namespace get deployments. $object -o json | jq -r '.status | .readyReplicas'`
  progess_message=`kubectl -n $namespace get deployments. $object -o json | jq -r '.status | .conditions[] | select(.type=="Progressing") | .message'`
  if ( [ "$check" == "Available" ] || [ "$check" == "Progressing" ] ) && [ "$deployment_status" == "False" ]; then
    echo "CRITICAL - Deployment check $check returned False. $ready_replicas replicas are running. Last progress message $progess_message"
    return $critical
  elif ( [ "$check" == "Available" ] || [ "$check" == "Progressing" ] ) && [ "$deployment_status" == "True" ]; then
    echo "OK - Deployment check $check returned True. $ready_replicas replicas are running. Last progress message $progess_message"
    return $ok
  else
    echo "UNKNOWN - output not understood"
    return $unknown
  fi
}

# daemonset checks
check_daemonset () {
  ds_ready=`kubectl -n $namespace get ds $object -o json | jq -r '.status | .numberReady'`
  ds_scheduled=`kubectl -n $namespace get ds $object -o json | jq -r '.status | .currentNumberScheduled'`
  if [ $ds_ready -lt $ds_scheduled ]; then
    echo "CRITICAL - $ds_ready replicas are running. $ds_scheduled are scheuled to run."
    return $critical
  elif [ $ds_ready -eq $ds_scheduled ]; then
    echo "OK - $ds_ready replicas are running. $ds_scheduled are scheduled to run."
    return $ok
  else
    echo "UNKNOWN - output not understood"
    return $unknown
  fi
}

# replicationcontroller checks
check_replicationcontroller () {
  rc_ready=`kubectl -n $namespace get rc $object -o json | jq -r '.status | .readyReplicas'`
  rc_scheduled=`kubectl -n $namespace get rc $object -o json | jq -r '.spec | .replicas'`
  if [ $rc_ready -lt $rc_scheduled ]; then
    echo "CRITICAL - $rc_ready replicas are running. $rc_scheduled are scheuled to run."
    return $critical
  elif [ $rc_ready -eq $rc_scheduled ]; then
    echo "OK - $rc_ready replicas are running. $rc_scheduled are scheduled to run."
    return $ok
  else
    echo "UNKNOWN - output not understood"
    return $unknown
  fi
}

# componentstatuses checks
check_componentstatuses () {
  cs_status=`kubectl -n $namespace get cs $object -o json | jq -r '.conditions[] | select(.type=="Healthy") | .status'`
  if [ "$cs_status" == "False" ]; then
    echo "CRITICAL - Component Status health check for $object returned False"
    return $critical
  elif [ "$cs_status" == "True" ]; then
    echo "OK - Component Status health check for $object returned True"
    return $ok
  else
    echo "UNKNOWN - output not understood"
    return $unknown
  fi
}

# get input parameters and validate
while getopts "t:c:n:o:" input; do
  case $input in
    o)
      object=$OPTARG
      ;;
    n)
      namespace=$OPTARG
      ;;
    c)
      check=$OPTARG
      ;;
    t)
      type=$OPTARG
      ;;
    *)
      echo $usage
      exit $unknown
      ;;
  esac
done
if [ -z "$object" ] || [ -z "$check" ] || [ -z "$type" ] || [ -z "$namespace" ]; then
  echo $usage
  exit $unknown
fi

# execute checks
check_$type
exit $?
