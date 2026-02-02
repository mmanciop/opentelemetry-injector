ARCH?=amd64
VERSION?=0.0.0-dev
INSTALL_DIR:=/usr/lib/opentelemetry/otelinject
DIST_DIR_BINARY:=dist
BINARY_NAME_PREFIX:=libotelinject
BINARY_NAME_NO_ARCH:=$(BINARY_NAME_PREFIX).so
BINARY_NAME:=$(BINARY_NAME_PREFIX)_$(ARCH).so
DIST_DIR_PACKAGE:=build/packages
PACKAGE_NAME:=opentelemetry-injector

# Docker repository used.
DOCKER_REPO?=docker.io

DIST_SRCS:=\
	$(wildcard src/*.*) \
	build.zig \
	build.zig.zon \
	Dockerfile \
	zig-version

DIST_TARGET:=$(DIST_DIR_BINARY)/$(BINARY_NAME)

ifeq ($(ARCH),arm64)
  RPM_PACKAGE_ARCH:=aarch64
else
  RPM_PACKAGE_ARCH:=x86_64
endif
RPM_VERSION=$(subst -,_,$(VERSION))

.PHONY: all
all: so/$(BINARY_NAME_NO_ARCH)

so:
	@mkdir -p so

obj:
	@mkdir -p obj

.PHONY: clean
clean:
	rm -rf so $(DIST_DIR_BINARY) $(DIST_DIR_PACKAGE) zig-out .zig-cache build

so/$(BINARY_NAME_NO_ARCH): so
	zig build -Dcpu-arch=${ARCH} --prominent-compile-errors --summary none

$(DIST_TARGET): $(DIST_SRCS)
	@echo building the injector binary for architecture $(ARCH)
	@set -e
	@mkdir -p $(DIST_DIR_BINARY)
	if [[ "$(ARCH)" = arm64 ]]; then \
	  ZIG_ARCHITECTURE=aarch64; \
	elif [[ "$(ARCH)" = amd64 ]]; then \
	  ZIG_ARCHITECTURE=x86_64; \
	fi; \
	docker buildx build --platform linux/$(ARCH) --build-arg DOCKER_REPO=$(DOCKER_REPO) --build-arg ZIG_ARCHITECTURE=$$ZIG_ARCHITECTURE -o type=image,name=libotelinject-builder:$(ARCH),push=false .
	docker rm -f libotelinject-builder 2>/dev/null || true
	docker run -d --platform linux/$(ARCH) --name libotelinject-builder libotelinject-builder:$(ARCH) sleep inf
	docker exec libotelinject-builder make ARCH=$(ARCH) SHELL=/bin/sh all
	docker cp libotelinject-builder:/libotelinject/so/$(BINARY_NAME_NO_ARCH) $(DIST_DIR_BINARY)/$(BINARY_NAME)
	docker rm -f libotelinject-builder

.PHONY: dist
dist: $(DIST_TARGET)

.PHONY: deb-package
deb-package: deb-packages

.PHONY: rpm-package
rpm-package: rpm-packages

# Run this to install and enable the auto-instrumentation files. Mostly intended for development.
.PHONY: install
install: all uninstall
	mkdir -p $(INSTALL_DIR)
	cp javaagent.jar $(INSTALL_DIR)
	cp so/$(BINARY_NAME_NO_ARCH) $(INSTALL_DIR)
	echo $(INSTALL_DIR)/$(BINARY_NAME_NO_ARCH) > /etc/ld.so.preload

.PHONY: uninstall
uninstall:
	rm -f /etc/ld.so.preload
	rm -f $(INSTALL_DIR)/javaagent.jar
	rm -f $(INSTALL_DIR)/$(BINARY_NAME_NO_ARCH)

# Run this from with this directory to build and run the development container.
# Once you have a command line inside the container, you can run make zig-build, make zig-unit-tests,
# make watch-zig-build, make watch-zig-unit-tests etc.
# Alternatively, you can also use the same commands directly on your development machine, without using the development
# container.
# By explicitly setting ARCH=arm64 or ARCH=amd64 you can run and test on different CPU platforms.
# Mostly intended for development.
.PHONY: docker-dev-run
docker-dev-run:
	ARCH=$(ARCH) ./start-injector-dev-container.sh

.PHONY: check-zig-installed
check-zig-installed:
	@set +x
	@if ! zig version > /dev/null; then \
	  echo "error: zig is not installed. Run 'brew install zig' or similar."; \
	  exit 1; \
	fi

.PHONY: zig-build
zig-build: check-zig-installed
	@mkdir -p so
	@(zig build -Dcpu-arch=${ARCH} --prominent-compile-errors --summary none && echo $(shell date) build successful) || (echo $(shell date) build failed && exit 1)

.PHONY: watch-zig-build
watch-zig-build: check-zig-installed
	@fd -e zig | entr make zig-build

.PHONY: zig-unit-tests
zig-unit-tests: check-zig-installed
	@(zig build test -Dcpu-arch=${ARCH} --prominent-compile-errors --summary none && echo $(shell date) tests successful) || (echo $(shell date) tests failed && exit 1)

.PHONY: watch-zig-unit-tests
watch-zig-unit-tests: check-zig-installed
	@fd -e zig | entr make zig-unit-tests

.PHONY: tests
tests: zig-unit-tests injector-integration-tests-for-one-architecture

.PHONY: injector-integration-tests-for-one-architecture
injector-integration-tests-for-one-architecture:
	ARCHITECTURES=$(ARCH) injector-integration-tests/scripts/test-all.sh

.PHONY: injector-integration-tests-for-all-architectures
injector-integration-tests-for-all-architectures:
	injector-integration-tests/scripts/test-all.sh

.PHONY: lint
lint: zig-fmt-check zig-validate-test-imports shellcheck-lint

.PHONY: zig-fmt-check
zig-fmt-check: check-zig-installed
	@zig fmt --check src

# Run this to auto-format Zig code.
.PHONY: zig-fmt
zig-fmt: check-zig-installed
	zig fmt src

.PHONY: zig-validate-test-imports
zig-validate-test-imports:
	@set -e; \
	files=$$(cd src && grep -l 'test "' ./*.zig 2>/dev/null || true); \
	[ -n "$$files" ] || { echo "None of the .zig files contain any tests, this is likely an error in the zig-validate-test-imports make recipe."; exit 1; }; \
	echo $$names; \
	names=$$(printf '%s\n' $$files | sed -e 's|.*/||'); \
	missing=0; \
	for n in $$names; do \
	  if ! grep -q "@import(\"$$n\")" src/test.zig; then \
	    echo "- The file \"src/test.zig\" is missing an import for \"$$n\", tests in \"$$n\" will ignored."; \
	    missing=1; \
	  fi; \
	done; \
	if [ $$missing -gt 0 ]; then \
	  echo ;\
	  echo "The file \"src/test.zig\" is missing imports to files with Zig unit tests, see above. Please add all files with test cases to \"src/test.zig\"."; \
	  exit 1; \
	fi

.PHONY: check-shellcheck-installed
check-shellcheck-installed:
	@set +x
	@if ! shellcheck --version > /dev/null; then \
	echo "error: shellcheck is not installed. See https://github.com/koalaman/shellcheck?tab=readme-ov-file#installing for installation instructions."; \
	exit 1; \
	fi

.PHONY: shellcheck-lint
shellcheck-lint: check-shellcheck-installed
	@echo "linting shell scripts with shellcheck"
	find . -name \*.sh | xargs shellcheck -x

SHELL = /bin/bash
.SHELLFLAGS = -o pipefail -c

# SRC_ROOT is the top of the source tree.
SRC_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
TOOLS_BIN_DIR    := $(SRC_ROOT)/.tools
CHLOGGEN_CONFIG  := .chloggen/config.yaml
CHLOGGEN         := $(TOOLS_BIN_DIR)/chloggen

$(TOOLS_BIN_DIR):
	mkdir -p $@

$(CHLOGGEN): $(TOOLS_BIN_DIR)
	GOBIN=$(TOOLS_BIN_DIR) go install go.opentelemetry.io/build-tools/chloggen@v0.23.1

FILENAME?=$(shell git branch --show-current)
.PHONY: chlog-new
chlog-new: $(CHLOGGEN)
	$(CHLOGGEN) new --config $(CHLOGGEN_CONFIG) --filename $(FILENAME)

.PHONY: chlog-validate
chlog-validate: $(CHLOGGEN)
	$(CHLOGGEN) validate --config $(CHLOGGEN_CONFIG)

.PHONY: chlog-preview
chlog-preview: $(CHLOGGEN)
	$(CHLOGGEN) update --config $(CHLOGGEN_CONFIG) --dry

.PHONY: chlog-update
chlog-update: $(CHLOGGEN)
	$(CHLOGGEN) update --config $(CHLOGGEN_CONFIG) --version $(VERSION)

list:
	@grep '^[^#[:space:]].*:' Makefile

.PHONY: packaging-integration-test-deb
packaging-integration-test-deb-%: deb-package
	(cd packaging/tests/deb/$* && ARCH=$(ARCH) ./run.sh)

.PHONY: packaging-integration-test-rpm
packaging-integration-test-rpm-%: rpm-package
	(cd packaging/tests/rpm/$* && ARCH=$(ARCH) ./run.sh)

# ============================================================================
# Modular Package Targets (OTEP #4793 compliant)
# ============================================================================
# These targets build individual packages following the OTEP #4793 specification.
# Package names:
#   - opentelemetry-injector: LD_PRELOAD injector
#   - opentelemetry-java-autoinstrumentation: Java agent
#   - opentelemetry-nodejs-autoinstrumentation: Node.js agent
#   - opentelemetry-dotnet-autoinstrumentation: .NET agent
#   - opentelemetry: Meta-package (depends on all above)

# Common source files for packages
PACKAGE_SRCS:=\
	$(DIST_SRCS) \
	$(wildcard packaging/*-release.txt) \
	$(wildcard packaging/common/**/*) \
	$(wildcard packaging/deb/**/*) \
	$(wildcard packaging/rpm/**/*) \
	$(wildcard packaging/common/fpm/*)

# Build the FPM Docker image
.PHONY: fpm-docker-image
fpm-docker-image:
	docker build -t instrumentation-fpm packaging/common/fpm

# Generic function to build a modular package
# Output directory: build/packages (same as legacy for compatibility)
define build_modular_package
$(eval $@_PKG_TYPE = $(1))
$(eval $@_PKG_NAME = $(2))
$(eval $@_VERSION = $(3))
@echo "Building modular $($@_PKG_TYPE) package: $($@_PKG_NAME) version $($@_VERSION) for $(ARCH)"
@mkdir -p $(DIST_DIR_PACKAGE)
docker rm -f libotelinject-packager 2>/dev/null || true
docker run -d --name libotelinject-packager --rm -v $(CURDIR):/repo -e VERSION=$($@_VERSION) -e ARCH=$(ARCH) instrumentation-fpm sleep inf
docker exec libotelinject-packager ./packaging/$($@_PKG_TYPE)/$($@_PKG_NAME)/build.sh "$($@_VERSION)" "$(ARCH)" "/repo/$(DIST_DIR_PACKAGE)"
docker rm -f libotelinject-packager 2>/dev/null
endef

# ============================================================================
# DEB Package Targets
# ============================================================================

# Individual DEB packages
.PHONY: deb-package-injector
deb-package-injector: dist fpm-docker-image
	@$(call build_modular_package,deb,injector,$(VERSION))

.PHONY: deb-package-java
deb-package-java: fpm-docker-image
	@$(call build_modular_package,deb,java,$(VERSION))

.PHONY: deb-package-nodejs
deb-package-nodejs: fpm-docker-image
	@$(call build_modular_package,deb,nodejs,$(VERSION))

.PHONY: deb-package-dotnet
deb-package-dotnet: fpm-docker-image
	@$(call build_modular_package,deb,dotnet,$(VERSION))

.PHONY: deb-package-meta
deb-package-meta: fpm-docker-image
	@$(call build_modular_package,deb,meta,$(VERSION))

.PHONY: deb-packages
deb-packages: deb-package-injector deb-package-java deb-package-nodejs deb-package-dotnet deb-package-meta
	@echo "All modular DEB packages built successfully"

# ============================================================================
# RPM Package Targets
# ============================================================================

# Individual RPM packages
.PHONY: rpm-package-injector
rpm-package-injector: dist fpm-docker-image
	@$(call build_modular_package,rpm,injector,$(RPM_VERSION))

.PHONY: rpm-package-java
rpm-package-java: fpm-docker-image
	@$(call build_modular_package,rpm,java,$(RPM_VERSION))

.PHONY: rpm-package-nodejs
rpm-package-nodejs: fpm-docker-image
	@$(call build_modular_package,rpm,nodejs,$(RPM_VERSION))

.PHONY: rpm-package-dotnet
rpm-package-dotnet: fpm-docker-image
	@$(call build_modular_package,rpm,dotnet,$(RPM_VERSION))

.PHONY: rpm-package-meta
rpm-package-meta: fpm-docker-image
	@$(call build_modular_package,rpm,meta,$(RPM_VERSION))

.PHONY: rpm-packages
rpm-packages: rpm-package-injector rpm-package-java rpm-package-nodejs rpm-package-dotnet rpm-package-meta
	@echo "All modular RPM packages built successfully"

.PHONY: packages
packages: deb-packages rpm-packages
	@echo "All packages built successfully"

# ============================================================================
# Local Package Repositories for Testing
# ============================================================================
# These targets create local APT and RPM repositories that can be mounted
# into containers for testing package installation.

LOCAL_REPO_DIR := $(CURDIR)/build/local-repo

.PHONY: local-apt-repo
local-apt-repo: deb-packages
	@echo "Creating local APT repository in $(LOCAL_REPO_DIR)/apt"
	@mkdir -p $(LOCAL_REPO_DIR)/apt/pool
	@cp $(DIST_DIR_PACKAGE)/*.deb $(LOCAL_REPO_DIR)/apt/pool/
	@docker run --rm --platform linux/amd64 -v $(LOCAL_REPO_DIR)/apt:/repo -w /repo debian:12 bash -c '\
		apt-get update -qq && apt-get install -y -qq dpkg-dev && \
		mkdir -p dists/stable/main/binary-amd64 && \
		dpkg-scanpackages pool > dists/stable/main/binary-amd64/Packages && \
		gzip -kf dists/stable/main/binary-amd64/Packages && \
		printf "Origin: OpenTelemetry Local\nLabel: OpenTelemetry Local Repository\nSuite: stable\nCodename: stable\nArchitectures: amd64 all\nComponents: main\n" > dists/stable/Release \
	'
	@echo ""
	@echo "APT repository created at $(LOCAL_REPO_DIR)/apt"
	@echo ""
	@echo "To test in a container:"
	@echo "  docker run --platform linux/amd64 -v $(LOCAL_REPO_DIR)/apt:/local-repo -it debian:12 bash"
	@echo ""
	@echo "Then inside the container:"
	@echo "  echo 'deb [trusted=yes] file:///local-repo stable main' > /etc/apt/sources.list.d/local.list"
	@echo "  apt-get update"
	@echo "  apt-get install opentelemetry-injector opentelemetry-java-autoinstrumentation"

.PHONY: local-rpm-repo
local-rpm-repo: rpm-packages
	@echo "Creating local RPM repository in $(LOCAL_REPO_DIR)/rpm"
	@mkdir -p $(LOCAL_REPO_DIR)/rpm/packages
	@cp $(DIST_DIR_PACKAGE)/*.rpm $(LOCAL_REPO_DIR)/rpm/packages/
	@docker run --rm --platform linux/amd64 -v $(LOCAL_REPO_DIR)/rpm:/repo -w /repo fedora:41 bash -c '\
		dnf install -y -q createrepo_c && \
		createrepo_c /repo/packages \
	'
	@echo ""
	@echo "RPM repository created at $(LOCAL_REPO_DIR)/rpm"
	@echo ""
	@echo "To test in a container:"
	@echo "  docker run --platform linux/amd64 -v $(LOCAL_REPO_DIR)/rpm:/local-repo -it fedora:41 bash"
	@echo ""
	@echo "Then inside the container:"
	@echo "  echo -e '[local]\nname=Local\nbaseurl=file:///local-repo/packages\nenabled=1\ngpgcheck=0' > /etc/yum.repos.d/local.repo"
	@echo "  dnf install opentelemetry-injector opentelemetry-java-autoinstrumentation"

.PHONY: local-repos
local-repos: local-apt-repo local-rpm-repo
	@echo "All local repositories created in $(LOCAL_REPO_DIR)"

.PHONY: clean-local-repos
clean-local-repos:
	rm -rf $(LOCAL_REPO_DIR)

