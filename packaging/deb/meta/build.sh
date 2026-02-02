#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Build script for opentelemetry metapackage (DEB)

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# shellcheck disable=SC1091
. "$SCRIPT_DIR/../common.sh"

PKG_NAME="opentelemetry"
PKG_DESCRIPTION="OpenTelemetry Auto-Instrumentation Suite (metapackage)"

VERSION="${1:-}"
ARCH="${2:-amd64}"
OUTPUT_DIR="${3:-$REPO_DIR/build/packages}"

if [[ -z "$VERSION" ]]; then
    VERSION="$( get_version )"
fi
VERSION="${VERSION#v}"

echo "Building DEB metapackage: $PKG_NAME version $VERSION"

# Metapackage has no files, just dependencies
buildroot="$(mktemp -d)"
trap 'rm -rf "$buildroot"' EXIT

mkdir -p "$OUTPUT_DIR"

# Create an empty directory structure for the metapackage
mkdir -p "${buildroot}/usr/share/doc/${PKG_NAME}"
echo "OpenTelemetry Auto-Instrumentation Suite" > "${buildroot}/usr/share/doc/${PKG_NAME}/README"
chown -R root:root "$buildroot"

fpm -s dir -t deb -n "$PKG_NAME" -v "$VERSION" -f -p "$OUTPUT_DIR" \
    --vendor "$PKG_VENDOR" \
    --maintainer "$PKG_MAINTAINER" \
    --description "$PKG_DESCRIPTION" \
    --license "$PKG_LICENSE" \
    --url "$PKG_URL" \
    --architecture "all" \
    --deb-dist "stable" \
    --depends "opentelemetry-injector (= ${VERSION})" \
    --depends "opentelemetry-java-autoinstrumentation (= ${VERSION})" \
    --depends "opentelemetry-nodejs-autoinstrumentation (= ${VERSION})" \
    --depends "opentelemetry-dotnet-autoinstrumentation (= ${VERSION})" \
    "$buildroot/"=/

echo "Built: ${OUTPUT_DIR}/${PKG_NAME}_${VERSION}_all.deb"

if [[ "${LIST_PACKAGE_CONTENTS_AFTER_BUILD:-}" == "true" ]]; then
    dpkg -c "${OUTPUT_DIR}/${PKG_NAME}_${VERSION}_all.deb"
fi
