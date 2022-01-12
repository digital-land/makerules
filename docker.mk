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
$(info    DOCKERISED is $(DOCKERISED))
$(info    DEVELOPMENT is $(DEVELOPMENT))

EXTRA_DOCKER_ARGS :=
EXTRA_DL_ARGS :=
ifeq ($(DEVELOPMENT),1)
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

ifeq ($(word 2, $(MAKECMDGOALS)),shell_cmd)
EXTRA_DOCKER_ARGS += --entrypoint bash
endif

endif
$(info    EXTRA_DOCKER_ARGS is $(EXTRA_DOCKER_ARGS))

# DOCKER_TAG=latest
ECR_URL=public.ecr.aws/l6z6v3j6/
DOCKER_TAG=$(shell basename $(PWD))
DOCKER_PATH=$(ECR_URL)digital-land-python:$(DOCKER_TAG)

docker-prefix = docker run -t \
	-e LOCAL_USER_ID=$(shell id -u) \
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

digital-land-cli = $(dockerised) \
	digital-land \
	$(EXTRA_DL_ARGS)

dockerised::
	$(info MAKECMDGOALS is $(MAKECMDGOALS))
	$(dockerised) $(word 2, $(MAKECMDGOALS))

ifeq ($(DOCKERISED),1)
init:: docker-pull
endif

docker-build::
	docker build . -f makerules/Dockerfile -t $(DOCKER_PATH)

docker-pull::
ifndef ($(DISABLE_DOCKER_PULL),)
	docker pull $(ECR_URL)digital-land-python:$(DOCKER_TAG)
endif

debug_shell:
	$(shell_cmd)

digital-land-cli:
	$(digital-land-cli)
