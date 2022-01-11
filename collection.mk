.PHONY: \
	collect\
	collection\
	commit-collection\
	clobber-today

include makerules/docker.mk

ifeq ($(COLLECTION_DIR),)
COLLECTION_DIR=collection/
endif

ifeq ($(RESOURCE_DIR),)
RESOURCE_DIR=$(COLLECTION_DIR)resource/
endif

ifeq ($(DATASTORE_URL),)
DATASTORE_URL=https://collection-dataset.s3.eu-west-2.amazonaws.com/
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

# These will run as usual unless we're in a dockerised environment and DEVELOPMENT isn't explicitly set to 1 i.e if DEVELOPMENT != 1 or DOCKERISED != 1
ifeq ($(DEVELOPMENT),0)
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
