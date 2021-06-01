GDAL := $(shell command -v ogr2ogr 2> /dev/null)
UNAME := $(shell uname)

init::
ifndef GDAL
ifeq ($(UNAME),Darwin)
$(error GDAL tools not found in PATH)
endif
	sudo apt-get update
	sudo apt-get install gdal-bin
endif

makerules::
	curl -qfsL '$(SOURCE_URL)/makerules/main/geospatial.mk' > makerules/geospatial.mk
