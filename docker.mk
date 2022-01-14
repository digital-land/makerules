ifneq ($(DOCKERISED),1)
DOCKERISED = 0
DEVELOPMENT = 0
else
# Run in development mode by default for now
ifeq ($(DEVELOPMENT),0)
DEVELOPMENT = 0
else
DEVELOPMENT = 1
endif
endif

EXTRA_DOCKER_ARGS :=
EXTRA_DL_ARGS :=
ifeq ($(DEVELOPMENT),1)
init:: mk-local-collection specification
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/collection/log:/pipeline/collection/log
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/collection/resource:/pipeline/collection/resource
ifneq (,$(wildcard ./fixed))
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/fixed:/pipeline/fixed
endif
ifneq (,$(wildcard ./harmonised))
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/harmonised:/pipeline/harmonised
endif
ifneq (,$(wildcard ./harmonised))
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/transformed:/pipeline/transformed
endif

ifdef ($(LOCAL_SPECIFICATION_PATH),)
EXTRA_DOCKER_ARGS += -v $(LOCAL_SPECIFICATION_PATH)/specification:/collection/specification
else ifeq ($(LOCAL_SPECIFICATION),1)
EXTRA_DOCKER_ARGS += -v $(PWD)/../specification/specification:/collection/specification
endif

ifdef ($(LOCAL_DL_PYTHON_PATH),)
EXTRA_DOCKER_ARGS += -v $(LOCAL_DL_PYTHON_PATH):/Src
else ifeq ($(LOCAL_DL_PYTHON),1)
EXTRA_DOCKER_ARGS += -v $(PWD)/../digital-land-python:/src
endif


else
mk-collection-resource::
	mkdir -p collection/resource

init:: mk-collection-resource specification
endif

# DOCKER_TAG=latest
ECR_URL=public.ecr.aws/l6z6v3j6/
DOCKER_TAG=$(shell basename $(PWD))
DOCKER_PATH=$(ECR_URL)digital-land-python:$(DOCKER_TAG)

mk-local-collection::
	mkdir -p local_collection/collection/log
	mkdir -p local_collection/collection/resource

docker-prefix = docker run -t \
	-u $(shell id -u) \
	-e AWS_ACCESS_KEY_ID \
    -e AWS_DEFAULT_REGION \
    -e AWS_REGION \
    -e AWS_SECRET_ACCESS_KEY \
    -e AWS_SECURITY_TOKEN \
    -e AWS_SESSION_EXPIRATION \
    -e AWS_SESSION_TOKEN \
	-v $(PWD):/pipeline \
	$(EXTRA_DOCKER_ARGS)

dockerised = $(docker-prefix) \
	$(DOCKER_PATH)

shell_cmd::
	$(docker-prefix) \
		--entrypoint bash \
		$(DOCKER_PATH)

dockerised::
	$(info MAKECMDGOALS is $(MAKECMDGOALS))
	$(dockerised) \
		$(TARGET)

docker-build:: docker-check
	docker build . -f makerules/Dockerfile -t $(DOCKER_PATH)

ifneq ($(DISABLE_DOCKER_PULL),1)
docker-pull:: docker-ecr-login
	docker pull $(DOCKER_PATH)
else
docker-pull::
endif

digital-land-cli::
	$(docker-prefix) \
		--entrypoint digital-land \
		$(DOCKER_PATH) \
		$(TARGET)

docker-check:
ifeq (, $(shell which docker))
	$(error "No docker in $(PATH), consider doing apt-get install docker OR brew install --cask docker")
endif

docker-ecr-login: docker-check
	aws ecr-public get-login-password --region us-east-1 | docker login --username AWS --password-stdin public.ecr.aws

docker-push: docker-ecr-login
	docker push $(DOCKER_PATH)

