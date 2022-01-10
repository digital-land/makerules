.PHONY: \
	virtualenv\
	workon\
	dev

EXTRA_MOUNTS :=
ifdef ($(LOCAL_SPECIFICATION_PATH),)
	EXTRA_MOUNTS += -v $(LOCAL_SPECIFICATION_PATH)/specification:/collection/specification
else ifeq ($(LOCAL_SPECIFICATION),1)
	EXTRA_MOUNTS += -v $(PWD)/../specification/specificaiton:/collection/specification
endif

ifdef ($(LOCAL_DL_PYTHON_PATH),)
	EXTRA_MOUNTS += -v $(LOCAL_DL_PYTHON_PATH):/Src
else ifeq ($(LOCAL_DL_PYTHON),1)
	EXTRA_MOUNTS += -v $(PWD)/../digital-land-python:/src
endif

DOCKER_TAG=latest
ECR_URL=public.ecr.aws/l6z6v3j6/

# useful when developing
# export PIP_REQUIRE_VIRTUALENV=true

# create a virtual environment
virtualenv::
	python3 -m venv .venv/$$(basename $$PWD)

workon::
	bash --init-file .venv/$$(basename $$PWD)/bin/activate

# create a symbolic link from the virtual environment to a cloned repository
dev::
ifndef VIRTUAL_ENV
	$(error not in a virtual environment)
endif
	pip install -e ../digital-land-python/

prune::
	rm -rf ./.venv

makerules::
	curl -qfsL '$(SOURCE_URL)/makerules/main/development.mk' > makerules/development.mk

dockerised = docker run -t \
	-u $(shell id -u) \
	-v $(PWD):/pipeline \
	-v $(PWD)/local_collection:/data \
	$(EXTRA_MOUNTS) \
	--workdir /data \
	$(ECR_URL)digital-land-python:$(DOCKER_TAG) \
	digital-land \
	--specification-dir /collection/specification

docker-pull::
ifndef ($(DISABLE_DOCKER_PULL),)
	docker pull $(ECR_URL)digital-land-python:$(DOCKER_TAG)
endif

dockerised-fetch:: docker-pull
	mkdir -p local_collection
	$(dockerised) \
		fetch \
		'$(ENDPOINT_URL)'
