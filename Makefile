# Petalinux Configuration
PETA_VERSION = 2020.2
PETA_RUN = petalinux-v$(PETA_VERSION)-final-installer.run
PETA_BSP = xilinx-zcu102-v$(PETA_VERSION)-final.bsp
# Destination to copy the built barrelfish kernel to
CP_DIR = .
# File temporarily holding the Docker container ID (CID)
CID_FILE := $(shell mktemp)
TODAY = `date -I`

default: run


build: Dockerfile $(PETA_RUN) $(PETA_BSP)
	docker build --build-arg PETA_VERSION=$(PETA_VERSION) --build-arg PETA_RUN_FILE=$(PETA_RUN) --build-arg PETA_BSP=$(PETA_BSP) -t petalinux:$(PETA_VERSION) .

run: build
	docker run -it -v petalinux-projects:/home/vivado/project petalinux:$(PETA_VERSION)

cp:
	@echo "Clean up previous build"
	docker run -d -v petalinux-projects:/home/vivado/project petalinux:$(PETA_VERSION) > $(CID_FILE)
	docker cp `cat $(CID_FILE)`:/home/builder/barrelfish/build $(CP_DIR)
	docker cp `cat $(CID_FILE)`:/home/vivado/project/lnx_zynq/images/linux $(CP_DIR)/$(TODAY)-lnx_zynq
	docker rm `cat $(CID_FILE)`

.PHONY: build run cp
