# Multi-arch docker container instance of the open-source home assistant project intended for Open Horizon Linux edge nodes

export DOCKER_IMAGE_BASE ?= ghcr.io/home-assistant/home-assistant
export DOCKER_IMAGE_NAME ?= homeassistant
export DOCKER_IMAGE_VERSION ?= latest
export DOCKER_VOLUME_NAME ?= homeassistant_config

# DockerHub ID of the third party providing the image (usually yours if building and pushing)
export DOCKERHUB_ID ?= homeassistant

# The Open Horizon organization ID namespace where you will be publishing the service definition file
export HZN_ORG_ID ?= examples

# Variables required by Home Assistant, can be overridden by your environment variables
export MY_TIME_ZONE ?= America/New_York

# Open Horizon settings for publishing metadata about the service
export DEPLOYMENT_POLICY_NAME ?= deployment-policy-homeassistant
export NODE_POLICY_NAME ?= node-policy-homeassistant
export SERVICE_NAME ?= service-homeassistant
export SERVICE_VERSION ?= 0.0.1

# Default ARCH to the architecture of this machine (assumes hzn CLI installed)
export ARCH ?= amd64

# Detect Operating System running Make
OS := $(shell uname -s)

default: init run browse

check:
	@echo "====================="
	@echo "ENVIRONMENT VARIABLES"
	@echo "====================="
	@echo "DOCKER_IMAGE_BASE      default: ghcr.io/home-assistant/home-assistant actual: ${DOCKER_IMAGE_BASE}"
	@echo "DOCKER_IMAGE_NAME      default: homeassistant                         actual: ${DOCKER_IMAGE_NAME}"
	@echo "DOCKER_IMAGE_VERSION   default: latest                                actual: ${DOCKER_IMAGE_VERSION}"
	@echo "DOCKER_VOLUME_NAME     default: homeassistant_config                  actual: ${DOCKER_VOLUME_NAME}"
	@echo "DOCKERHUB_ID           default: homeassistant                         actual: ${DOCKERHUB_ID}"
	@echo "HZN_ORG_ID             default: examples                              actual: ${HZN_ORG_ID}"
	@echo "MY_TIME_ZONE           default: America/New_York                      actual: ${MY_TIME_ZONE}"
	@echo "DEPLOYMENT_POLICY_NAME default: deployment-policy-homeassistant       actual: ${DEPLOYMENT_POLICY_NAME}"
	@echo "NODE_POLICY_NAME       default: node-policy-homeassistant             actual: ${NODE_POLICY_NAME}"
	@echo "SERVICE_NAME           default: service-homeassistant                 actual: ${SERVICE_NAME}"
	@echo "SERVICE_VERSION        default: 0.0.1                                 actual: ${SERVICE_VERSION}"
	@echo "ARCH                   default: amd64                                 actual: ${ARCH}"
	@echo ""
	@echo "=================="
	@echo "SERVICE DEFINITION"
	@echo "=================="
	@cat service.definition.json | envsubst
	@echo ""

stop:
	@docker rm -f $(DOCKER_IMAGE_NAME) >/dev/null 2>&1 || :

init:
	@docker volume create $(DOCKER_VOLUME_NAME)

run: stop
	@docker run -d \
		--name $(DOCKER_IMAGE_NAME) \
		--privileged \
		--restart=unless-stopped \
		-e TZ=$(MY_TIME_ZONE) \
		-v $(DOCKER_VOLUME_NAME):/config \
		-p 8123:8123 \
		$(DOCKER_IMAGE_BASE):$(DOCKER_IMAGE_VERSION)

dev: run attach

attach: 
	@docker exec -it \
		`docker ps -aqf "name=$(DOCKER_IMAGE_NAME)"` \
		/bin/bash		

test:
	@curl -sS http://127.0.0.1:8123

browse:
ifeq ($(OS),Darwin)
	@open http://127.0.0.1:8123
else
	@xdg-open http://127.0.0.1:8123
endif

clean: stop
	@docker rmi -f $(DOCKER_IMAGE_BASE):$(DOCKER_IMAGE_VERSION) >/dev/null 2>&1 || :
	@docker volume rm $(DOCKER_VOLUME_NAME)

distclean: clean
	@echo "TBD: unpublish files, unregister node"

build:
	@echo "There is no Docker image build process since this container is provided by a third-party from official sources."

push:
	@echo "There is no Docker image push process since this container is provided by a third-party from official sources."

publish: publish-service publish-service-policy publish-deployment-policy agent-run browse

# Pull, not push, Docker image since provided by third party
publish-service:
	@echo "=================="
	@echo "PUBLISHING SERVICE"
	@echo "=================="
	@hzn exchange service publish -O -P --json-file=service.definition.json
	@echo ""

publish-service-policy:
	@echo "========================="
	@echo "PUBLISHING SERVICE POLICY"
	@echo "========================="
	@hzn exchange service addpolicy -f service.policy.json $(HZN_ORG_ID)/$(SERVICE_NAME)_$(SERVICE_VERSION)_$(ARCH)
	@echo ""

publish-deployment-policy:
	@echo "============================"
	@echo "PUBLISHING DEPLOYMENT POLICY"
	@echo "============================"
	@hzn exchange deployment addpolicy -f deployment.policy.json $(HZN_ORG_ID)/policy-$(SERVICE_NAME)_$(SERVICE_VERSION)
	@echo ""

agent-run:
	@echo "================"
	@echo "REGISTERING NODE"
	@echo "================"
	@hzn register --policy=node.policy.json
	@watch hzn agreement list

agent-stop:
	@hzn unregister -f

deploy-check:
	@hzn deploycheck all -t device -B deployment.policy.json --service=service.definition.json --service-pol=service.policy.json --node-pol=node.policy.json

log:
	@echo "========="
	@echo "EVENT LOG"
	@echo "========="
	@hzn eventlog list
	@echo ""
	@echo "==========="
	@echo "SERVICE LOG"
	@echo "==========="
	@hzn service log -f $(SERVICE_NAME)

.PHONY: default stop init run dev test clean build push attach browse publish publish-service publish-service-policy publish-deployment-policy publish-pattern agent-run distclean deploy-check check log