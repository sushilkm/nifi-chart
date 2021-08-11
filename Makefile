SHELL := /bin/bash

# helm variables
IDENTIFIER ?= $(shell date +%s)
RELEASE_NAME ?= $(shell whoami)-${IDENTIFIER}
NAMESPACE_NAME ?= $(shell whoami)-${IDENTIFIER}
NIFI_CHART_DIR ?= nifi
DEPLOYED_NS ?= ""
DEPLOYED_RELEASE ?= ${DEPLOYED_NS}

STRUCTURED_LOG ?= false
MEMORY_GB ?= 50

# set docker registry variables based on ACR name
ifdef ACR
IMAGE_REGISTRY := $(shell az acr show-endpoints -n ${ACR} -o tsv --query loginServer 2>/dev/null)
IMAGE_REGISTRY_USER := $(shell az acr credential show -n ${ACR} -o tsv --query username)
IMAGE_REGISTRY_PASS := $(shell az acr credential show -n ${ACR} -o tsv --query passwords[0].value)
endif

# if a docker registry is provided, ensure user and pass are also provided
ifdef IMAGE_REGISTRY
IMAGE_REPO ?= ${IMAGE_REGISTRY}/nifi
IMAGE_TAG ?= latest
ifndef IMAGE_REGISTRY_USER
$(error IMAGE_REGISTRY_USER is not set)
endif
ifndef IMAGE_REGISTRY_PASS
$(error IMAGE_REGISTRY_PASS is not set)
endif

# define docker registry options for helm
define HELM_OPTS_DOCKER_REPO
--set imageCredentials[0].name=privaterepo \
--set imageCredentials[0].registry=${IMAGE_REGISTRY} \
--set imageCredentials[0].username=${IMAGE_REGISTRY_USER} \
--set imageCredentials[0].password=${IMAGE_REGISTRY_PASS} \
--set image.repository=${IMAGE_REPO} \
--set image.tag=${IMAGE_TAG} \
--set image.imagePullSecret=privaterepo \
--set image.pullPolicy=Always
endef
endif

# define helm options
define HELM_OPTS
${NIFI_CHART_DIR} \
-n ${NAMESPACE_NAME} \
--set nifi.logging.structured=${STRUCTURED_LOG} \
--set resources.requests.memory=${MEMORY_GB}Gi \
${HELM_OPTS_DOCKER_REPO}
endef

# make targets
.phony: add-helm-incubator-repository
add-helm-incubator-repository:
ifneq (https://charts.helm.sh/incubator, $(shell helm repo list -o json | jq -e -r '.[] | select(.name=="incubator") | .url'))
	helm repo add --force-update incubator https://charts.helm.sh/incubator && helm repo update
endif

.phony: update-nifi-dependency
update-nifi-dependency: add-helm-incubator-repository
	cd nifi && helm dep up --skip-refresh

.phony: deploy-nifi
deploy-nifi: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		${HELM_OPTS}

# same as deploy-nifi but outputs template, to validate helm generated k8s resources
.phony: template-nifi
template-nifi: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm template ${RELEASE_NAME} \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-toolkit
deploy-secured-nifi-with-toolkit: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${HELM_OPTS}

.phony: delete-nifi-release
delete-nifi-release:
	helm delete ${RELEASE_NAME} -n ${NAMESPACE_NAME}

.phony: deploy-secured-nifi-with-openid-authentication-with-toolkit
deploy-secured-nifi-with-openid-authentication-with-toolkit: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-ldap-authentication-with-toolkit
deploy-secured-nifi-with-ldap-authentication-with-toolkit: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/ldap-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-user-certs
deploy-secured-nifi-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		${HELM_OPTS}

.phony: update-secret-with-more-certs
update-secret-with-more-certs:
	kubectl -n ${DEPLOYED_NS} get secret ${DEPLOYED_RELEASE}-nifi-certs -o yaml > deployed_secret.yaml
	helm template ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/add-more-certs-values.yaml \
		-s templates/certs-secret.yaml \
		${NIFI_CHART_DIR}  --dry-run

.phony: deploy-secured-nifi-with-openid-authentication-with-user-certs
deploy-secured-nifi-with-openid-authentication-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-ldap-authentication-with-user-certs
deploy-secured-nifi-with-ldap-authentication-with-user-certs: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/ldap-values.yaml \
		${HELM_OPTS}

# Minikube related targets
.phony: deploy-nifi-on-minikube
deploy-nifi-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-toolkit-on-minikube
deploy-secured-nifi-with-toolkit-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-openid-authentication-with-toolkit-on-minikube
deploy-secured-nifi-with-openid-authentication-with-toolkit-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-ldap-authentication-with-toolkit-on-minikube
deploy-secured-nifi-with-ldap-authentication-with-toolkit-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-nifi-toolkit.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-user-certs-on-minikube
deploy-secured-nifi-with-user-certs-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-openid-authentication-with-user-certs-on-minikube
deploy-secured-nifi-with-openid-authentication-with-user-certs-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/openid-values.yaml \
		${HELM_OPTS}

.phony: deploy-secured-nifi-with-ldap-authentication-with-user-certs-on-minikube
deploy-secured-nifi-with-ldap-authentication-with-user-certs-on-minikube: update-nifi-dependency
	kubectl get namespace ${NAMESPACE_NAME} > /dev/null 2>&1  || kubectl create namespace ${NAMESPACE_NAME}
	helm install ${RELEASE_NAME} \
		-f ${NIFI_CHART_DIR}/minikube-values.yaml \
		-f ${NIFI_CHART_DIR}/secured-values-with-user-provided-certs.yaml \
		-f ${NIFI_CHART_DIR}/ldap-values.yaml \
		${HELM_OPTS}