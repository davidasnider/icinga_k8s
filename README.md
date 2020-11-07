This is Icinga designed for Kubernetes instead of Docker Compose.

# Deployment

![image](diagram.svg)

## Local

1. Select the proper k8s environment
1. `kubectl config us-context docker-for-desktop`
1. Run the below script

```
kubectl delete -k local-dev
kubectl apply -k local-dev
```

## Dev

1. Select the proper k8s environment
1. `kubectl config us-context k8s1`
1. Run the below script

```
kubectl delete -k secondary
kubectl apply -k secondary
```

## Prod

1. Select the proper k8s environment
1. `kubectl config us-context k8s2`
1. Run the below script

```
kubectl delete -k primary
kubectl apply -k primary
```
