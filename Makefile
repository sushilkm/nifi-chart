SHELL := /bin/bash

IDENTIFIER ?= $(shell date +%s)
RELEASE_NAME ?= $(shell whoami)-${IDENTIFIER}
NAMESPACE_NAME ?= $(shell whoami)-${IDENTIFIER}
NIFI_CHART_DIR ?= nifi


.phony: add-helm-incubator-repository
add-helm-incubator-repository:
	helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com

.phony: update-nifi-dependency
update-nifi-dependency: add-helm-incubator-repository
	cd nifi && helm dep up

.phony: deploy-nifi
deploy-nifi: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi
deploy-secured-nifi: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/secured-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-nifi-on-minikube
deploy-nifi-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/minikube-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-on-minikube
deploy-secured-nifi-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/minikube-values.yaml -f ${NIFI_CHART_DIR}/secured-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: delete-nifi-release
delete-nifi-release:
	helm delete ${RELEASE_NAME} -n ${NAMESPACE_NAME}
