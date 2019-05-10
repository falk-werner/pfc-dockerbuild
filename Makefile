OUT_DIR = .build
GEN_DIRS += $(OUT_DIR)

IMAGE_DIR = $(OUT_DIR)/images
GEN_DIRS += $(IMAGE_DIR)

USERID ?= $(shell id -u)
USERID := $(USERID)
DOCKER_BUILDARGS += 'USERID=$(USERID)'

SKIP_BUILD_IMAGE ?=
SKIP_BUILD_IMAGE := $(SKIP_BUILD_IMAGE)
DOCKER_BUILDARGS += 'SKIP_BUILD_IMAGE=$(SKIP_BUILD_IMAGE)'


DOCKER_BUILDFLAGS = $(addprefix --build-arg ,$(DOCKER_BUILDARGS))

.PHONY: all
all: images

$(GEN_DIRS):
	mkdir -p $@

.PHONY: builder
builder: $(OUT_DIR)/pfc-builder

$(OUT_DIR)/Dockerfile: Dockerfile | $(OUT_DIR)
	cp $< $@

$(OUT_DIR)/pfc-builder: $(OUT_DIR)/Dockerfile  Makefile | $(OUT_DIR)
	docker build --rm $(DOCKER_BUILDFLAGS) --iidfile $@ --file $< --tag pfc-builder .

.PHONY: run
run: builder | $(IMAGE_DIR)
	docker run --rm -it --user "$(USERID)" -v "`realpath $(IMAGE_DIR)`:/backup" pfc-builder bash

.PHONY: images
images: builder | $(IMAGE_DIR)
	docker run --rm --user "$(USERID)" -v "`realpath $(IMAGE_DIR)`:/backup" pfc-builder bash -c "cp /home/user/ptxproj/platform-wago-pfcXXX/images/* /backup"

.PHONY: clean
clean:
	rm -rf $(GEN_DIRS)

