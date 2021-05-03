#!/bin/env bash

set -euo pipefail

readonly script_dir=$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
readonly project_dir=$(dirname "${script_dir}")

function echo_header {
    local header="${1}"

    if [ -z "${header}" ]; then
        echo 'No header provided'
        exit 1
    fi

    local header_wrapped="#### ${header} ####"
    local header_length="${#header_wrapped}"

    echo
    head -c ${header_length} < /dev/zero | tr '\0' '#'
    echo
    echo "${header_wrapped}"
    head -c ${header_length} < /dev/zero | tr '\0' '#'
    echo
    echo
}

echo_header 'Building the LD_PRELOAD object'

(cd "${project_dir}"; cargo build)

echo_header 'Building the Java app'

(cd "${project_dir}/test/java/app"; ./mvnw package)

readonly opentelemetry_agent_path="${project_dir}/test/java/app/target/java-test-app.jar"

if [ ! -f "${project_dir}/test/java/app/target/java-test-app.jar" ]; then
    echo_header 'Downloading the OpenTelemetry Java agent'

    curl -L --silent --fail --show-error https://github.com/open-telemetry/opentelemetry-java-instrumentation/releases/download/v1.1.0/opentelemetry-javaagent-all.jar -o "${project_dir}/test/java/opentelemetry-javaagent-all.jar"
fi

echo_header 'Running the Java app locally'

LD_PRELOAD="${project_dir}/target/debug/libopentelemetry_injector.so" \
    OPENTELEMETRY_INJECTOR_DEBUG=true \
    OPENTELEMETRY_INJECTOR_CONFIGURATION="${project_dir}/test/config/otel_config_jvm_agent.toml" \
    java -jar "${project_dir}/test/java/app/target/java-test-app.jar"

# echo_header 'Building the Java Docker container'

# (cd "${project_dir}"; docker build . -t injector-test -f test/java/Dockerfile.x86.glibc.openjdk11.ok)

# echo_header 'Running the Java Docker container'

# docker run injector-test