#!/bin/bash

kind create cluster || echo cluster already exists

# install maistra extension CRD
kubectl apply -f extensions.maistra.io_servicemeshextensions.yaml

istioctl manifest apply -y --set values.pilot.image=registry.gitlab.com/dgrimm/istio/pilot:wasm

# patch cluster role
kubectl apply -f patched-clusterrole.yaml

kubectl create -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/latest/kubernetes-examples/keycloak.yaml
kubectl rollout status deployment/keycloak
source setup-keycloak.sh

kubectl label namespace default istio-injection=enabled || true
kubectl apply -f wasm-server.yaml
kubectl rollout status deployment/nginx-deployment
POD=$(kubectl get pods -lapp=nginx -o jsonpath='{.items[0].metadata.name}')
kubectl cp ../oidc.wasm  ${POD}:/var/www/oidc.wasm --container nginx

kubectl apply -f httpbin.yaml
kubectl apply -f httpbin-gateway.yaml
kubectl rollout status deployment/httpbin

kubectl apply -f istio-auth.yaml
sed -e "s/INSERT_CLIENT_SECRET_HERE/${CLIENT_SECRET}/" extension.yaml | kubectl apply -f -
