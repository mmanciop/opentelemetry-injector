#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Build script for opentelemetry-java-autoinstrumentation DEB package

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/../common.sh"

PKG_NAME="opentelemetry-java-autoinstrumentation"
PKG_DESCRIPTION="OpenTelemetry Java Auto-Instrumentation Agent"

VERSION="${1:-}"
ARCH="${2:-amd64}"
OUTPUT_DIR="${3:-$REPO_DIR/instrumentation/dist}"

if [[ -z "$VERSION" ]]; then
    VERSION="$( get_version )"
fi
VERSION="${VERSION#v}"

echo "Building DEB package: $PKG_NAME version $VERSION"

buildroot="$(mktemp -d)"
trap 'rm -rf "$buildroot"' EXIT

setup_java_buildroot "$ARCH" "$VERSION" "$buildroot"

mkdir -p "$OUTPUT_DIR"

# Java agent is architecture-independent (JAR file)
sudo fpm -s dir -t deb -n "$PKG_NAME" -v "$VERSION" -f -p "$OUTPUT_DIR" \
    --vendor "$PKG_VENDOR" \
    --maintainer "$PKG_MAINTAINER" \
    --description "$PKG_DESCRIPTION" \
    --license "$PKG_LICENSE" \
    --url "$PKG_URL" \
    --architecture "all" \
    --deb-dist "stable" \
    --deb-use-file-permissions \
    --deb-no-default-config-files \
    --depends "opentelemetry-injector (>= ${VERSION})" \
    --deb-recommends "default-jre" \
    --config-files "$JAVA_CONFIG_DIR" \
    "$buildroot/"=/

echo "Built: ${OUTPUT_DIR}/${PKG_NAME}_${VERSION}_all.deb"

if [[ "${LIST_PACKAGE_CONTENTS_AFTER_BUILD:-}" == "true" ]]; then
    dpkg -c "${OUTPUT_DIR}/${PKG_NAME}_${VERSION}_all.deb"
fi
