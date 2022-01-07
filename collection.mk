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

EXTRA_MOUNTS :=
ifdef ($(LOCAL_SPECIFICATION_PATH),)
	EXTRA_MOUNTS += -v $(LOCAL_SPECIFICATION_PATH)/specification:/collection/specification
else ifeq ($(LOCAL_SPECIFICATION),1)
	EXTRA_MOUNTS += -v $(PWD)/../specification/specificaiton:/collection/specification
endif

ifdef ($(LOCAL_DL_PYTHON_PATH),)
	EXTRA_MOUNTS += -v $(LOCAL_DL_PYTHON_PATH):/Src
else ifeq ($(LOCAL_DL_PYTHON),1)
	EXTRA_MOUNTS += -v $(PWD)/../digital-land-python:/src"
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
	digital-land collect $(ENDPOINT_CSV)

collection::
	digital-land collection-save-csv

clobber-today::
	rm -rf $(LOG_FILES_TODAY) $(COLLECTION_INDEX)

makerules::
	curl -qfsL '$(SOURCE_URL)/makerules/main/collection.mk' > makerules/collection.mk

commit-collection::
	git add collection
	git diff --quiet && git diff --staged --quiet || (git commit -m "Collection $(shell date +%F)"; git push origin $(BRANCH))

save-resources::
	aws s3 sync s3://collection-dataset/$(REPOSITORY)/$(RESOURCE_DIR) $(RESOURCE_DIR)

load-resources::
	aws s3 sync $(RESOURCE_DIR) s3://collection-dataset/$(REPOSITORY)/$(RESOURCE_DIR)

collection/resource/%:
	@mkdir -p collection/resource/
	curl -qfsL '$(DATASTORE_URL)$(REPOSITORY)/$(RESOURCE_DIR)$(notdir $@)' > $@

# dev
dockerised-fetch::
	mkdir -p local_collection
	docker run -t \
		-u $(shell id -u) \
		-v $(PWD):/pipeline \
		-v $(PWD)/local_collection:/data \
		$(EXTRA_MOUNTS) \
		--workdir /data \
		$(ECR_URL)digital_land_python:$(DOCKER_TAG) \
		digital-land \
		--specification-dir /collection/specification \
		fetch \
		'$(ENDPOINT_URL)'
