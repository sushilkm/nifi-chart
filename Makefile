SHELL := /bin/bash

IDENTIFIER ?= $(shell date +%s)
RELEASE_NAME ?= $(shell whoami)-${IDENTIFIER}
NAMESPACE_NAME ?= $(shell whoami)-${IDENTIFIER}
NIFI_CHART_DIR ?= nifi
DEPLOYED_NS ?= ""
DEPLOYED_RELEASE ?= ${DEPLOYED_NS}


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
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-nifi-on-minikube
deploy-nifi-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/minikube-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-on-minikube
deploy-secured-nifi-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/minikube-values.yaml -f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: delete-nifi-release
delete-nifi-release:
	helm delete ${RELEASE_NAME} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-with-openid-authentication-on-minikube
deploy-secured-nifi-with-openid-authentication-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/minikube-values.yaml -f ${NIFI_CHART_DIR}/openid-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-with-openid-authentication
deploy-secured-nifi-with-openid-authentication: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/openid-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-with-ldap-authentication-on-minikube
deploy-secured-nifi-with-ldap-authentication-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/minikube-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-with-ldap-authentication
deploy-secured-nifi-with-ldap-authentication: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/ldap-values.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-with-user-certs
deploy-secured-nifi-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-on-minikube-with-user-certs
deploy-secured-nifi-on-minikube-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/minikube-values.yaml -f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml ${NIFI_CHART_DIR} -n ${NAMESPACE_NAME}

.phony: update-secret-with-more-certs
update-secret-with-more-certs:
	kubectl -n ${DEPLOYED_NS} get secret ${DEPLOYED_RELEASE}-certs -o yaml > deployed_secret.yaml
	helm install ${RELEASE_NAME} -f ${NIFI_CHART_DIR}/add-more-certs-values.yaml ${NIFI_CHART_DIR}/charts/certs --dry-run