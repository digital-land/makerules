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

fetch-organisation::
	@mkdir -p $(CACHE_DIR)
	curl -qfs "https://raw.githubusercontent.com/digital-land/organisation-dataset/main/collection/organisation.csv" > $(CACHE_DIR)organisation.csv

EXTRA_DOCKER_ARGS :=
EXTRA_DL_ARGS :=
ifeq ($(DEVELOPMENT),1)
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/collection/log:/pipeline/collection/log
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/collection/resource:/pipeline/collection/resource
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/transformed:/pipeline/transformed
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/issue:/pipeline/issue
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/dataset:/pipeline/dataset
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/fixed:/pipeline/fixed
EXTRA_DOCKER_ARGS += -v $(PWD)/local_collection/harmonised:/pipeline/harmonised

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

mk-local-collection::
	mkdir -p local_collection/collection/log
	mkdir -p local_collection/collection/resource
	mkdir -p local_collection/transformed
	mkdir -p local_collection/issue
	mkdir -p local_collection/dataset
	mkdir -p local_collection/fixed
	mkdir -p local_collection/harmonised

init:: mk-local-collection specification fetch-organisation
else
mk-collection::
	mkdir -p collection/resource
	mkdir -p collection/transformed
	mkdir -p issue
	mkdir -p dataset
	mkdir -p fixed
	mkdir -p harmonised

init:: mk-collection specification fetch-organisation
endif

# DOCKER_TAG=latest
ECR_URL=public.ecr.aws/l6z6v3j6/
DOCKER_TAG=$(shell basename $(PWD))
DOCKER_PATH=$(ECR_URL)digital-land-python:$(DOCKER_TAG)

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
	-v dl-pipeline-var-cache:/var/cache \
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

