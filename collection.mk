.PHONY: \
	collect\
	collection\
	commit-collection\
	clobber-today

ifeq ($(COLLECTION_DIR),)
COLLECTION_DIR=collection/
endif

ifeq ($(RESOURCE_DIR),)
RESOURCE_DIR=$(COLLECTION_DIR)resource/
endif

ifeq ($(DATASTORE_URL),)
DATASTORE_URL=https://collection-dataset.s3.eu-west-2.amazonaws.com/
endif

ifeq ($(DOCKERISED),1)
EXTRA_MOUNTS :=
# Run in development mode by default for now
ifneq ($(DEVELOPMENT),0)
EXTRA_MOUNTS += -v $(PWD)/local_collection:/data --workdir /data

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
endif

DOCKER_TAG=latest
ECR_URL=public.ecr.aws/l6z6v3j6/

digital-land = docker run -t \
	-u $(shell id -u) \
	-v $(PWD):/pipeline \
	$(EXTRA_MOUNTS) \
	$(ECR_URL)digital-land-python:$(DOCKER_TAG) \
	digital-land \
	--specification-dir /collection/specification

docker-pull::
ifndef ($(DISABLE_DOCKER_PULL),)
	docker pull $(ECR_URL)digital-land-python:$(DOCKER_TAG)
endif

init:: docker-pull
else
digital-land = digital-land
endif


# data sources
SOURCE_CSV=$(COLLECTION_DIR)source.csv
ENDPOINT_CSV=$(COLLECTION_DIR)endpoint.csv

# collection log
LOG_DIR=$(COLLECTION_DIR)log/
LOG_FILES_TODAY:=$(LOG_DIR)$(shell date +%Y-%m-%d)/

# collection index
COLLECTION_INDEX=\
	$(COLLECTION_DIR)/log.csv\
	$(COLLECTION_DIR)/resource.csv

first-pass:: collect

second-pass:: collection

collect:: $(SOURCE_CSV) $(ENDPOINT_CSV)
	$(digital-land) collect $(ENDPOINT_CSV)

collection::
	$(digital-land) collection-save-csv

clobber-today::
	rm -rf $(LOG_FILES_TODAY) $(COLLECTION_INDEX)

makerules::
	curl -qfsL '$(SOURCE_URL)/makerules/main/collection.mk' > makerules/collection.mk

# These will run as usual unless we're in a dockerised environment and DEVELOPMENT isn't explicitly set to 1
ifneq ($(DOCKERISED),1)
ifneq ($(DEVELOPMENT),1)
commit-dataset::
	mkdir -p $(DATASET_DIRS)
	git add $(DATASET_DIRS)
	git diff --quiet && git diff --staged --quiet || (git commit -m "Data $(shell date +%F)"; git push origin $(BRANCH))

commit-collection::
	git add collection
	git diff --quiet && git diff --staged --quiet || (git commit -m "Collection $(shell date +%F)"; git push origin $(BRANCH))

save-resources::
	aws s3 sync s3://collection-dataset/$(REPOSITORY)/$(RESOURCE_DIR) $(RESOURCE_DIR)
endif

load-resources::
	aws s3 sync $(RESOURCE_DIR) s3://collection-dataset/$(REPOSITORY)/$(RESOURCE_DIR)

collection/resource/%:
	@mkdir -p collection/resource/
	curl -qfsL '$(DATASTORE_URL)$(REPOSITORY)/$(RESOURCE_DIR)$(notdir $@)' > $@
