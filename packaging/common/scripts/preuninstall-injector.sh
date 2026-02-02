#!/bin/sh

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Pre-uninstall script for opentelemetry-injector package.
# This script removes the injector library from /etc/ld.so.preload.

PRELOAD_PATH="/etc/ld.so.preload"
LIBOTELINJECT_PATH="/usr/lib/opentelemetry/injector/libotelinject.so"

if [ -f "$PRELOAD_PATH" ] && grep -q "$LIBOTELINJECT_PATH" "$PRELOAD_PATH"; then
    echo "Removing $LIBOTELINJECT_PATH from $PRELOAD_PATH"
    sed -i -e "s|$LIBOTELINJECT_PATH||" "$PRELOAD_PATH"

    # Remove the file if it's empty or contains only whitespace
    if [ ! -s "$PRELOAD_PATH" ] || ! grep -q '[^[:space:]]' "$PRELOAD_PATH"; then
        echo "Removing empty $PRELOAD_PATH"
        rm -f "$PRELOAD_PATH"
    fi
fi

echo "OpenTelemetry Injector removed from ld.so.preload."
