#!/bin/bash

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Generate RPM repository metadata from .rpm packages
# This script is meant to run inside a Fedora/RHEL-based container.
#
# Usage: generate-rpm-repo.sh <repo_dir>
#
# Expected structure:
#   <repo_dir>/packages/*.rpm
#
# Generated structure:
#   <repo_dir>/repodata/repomd.xml
#   <repo_dir>/repodata/primary.xml.gz
#   <repo_dir>/repodata/filelists.xml.gz
#   <repo_dir>/repodata/other.xml.gz

set -euo pipefail

REPO_DIR="${1:-.}"

# Install dependencies if not present
if ! command -v createrepo_c &>/dev/null; then
    dnf install -y -q createrepo_c
fi

# Generate repository metadata
createrepo_c "$REPO_DIR/packages"

# Move repodata to repo root (packages/ subdirectory is where the RPMs live)
if [ -d "$REPO_DIR/packages/repodata" ]; then
    mv "$REPO_DIR/packages/repodata" "$REPO_DIR/"
fi

echo "=== RPM Repository Generated ==="
ls -la "$REPO_DIR/repodata/"
