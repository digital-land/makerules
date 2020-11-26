GDAL := $(shell command -v ogr2ogr 2> /dev/null)
UNAME := $(shell uname)
init::
ifndef GDAL
ifeq ($(UNAME),Darwin)
$(error GDAL tools not found in PATH)
endif
	sudo apt-get install gdal-bin
endif