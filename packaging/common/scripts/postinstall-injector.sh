#!/bin/sh

# Copyright The OpenTelemetry Authors
# SPDX-License-Identifier: Apache-2.0

# Post-installation script for opentelemetry-injector package.
# This script adds the injector library to /etc/ld.so.preload.

PRELOAD_PATH="/etc/ld.so.preload"
LIBOTELINJECT_PATH="/usr/lib/opentelemetry/injector/libotelinject.so"

# Check if the library is already in the preload file
if [ -f "$PRELOAD_PATH" ] && grep -q "$LIBOTELINJECT_PATH" "$PRELOAD_PATH"; then
    echo "OpenTelemetry Injector is already configured in $PRELOAD_PATH"
    exit 0
fi

# Add the library to the preload file
echo "Adding $LIBOTELINJECT_PATH to $PRELOAD_PATH"
echo "$LIBOTELINJECT_PATH" >> "$PRELOAD_PATH"

echo "OpenTelemetry Injector installed successfully."
echo "All new processes will now be instrumented automatically."
