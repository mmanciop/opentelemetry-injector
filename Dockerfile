FROM ubuntu:21.04 AS opentelemetry-javaagent-dependency

RUN apt-get update && apt-get upgrade && apt-get install -y curl jq && apt-get clean

ARG otel_repo="https://api.github.com/repos/open-telemetry/opentelemetry-java-instrumentation"

RUN mkdir -p /opt/opentelemetry/java \
    && OTEL_JAVA_AGENT_URL=$(curl --silent --fail --show-error "${otel_repo}/releases/latest" | jq -r '.assets[] | select(.name == "opentelemetry-javaagent-all.jar") | .browser_download_url') \
    && echo "Downloading the OpenTelemetry Java agent at: ${OTEL_JAVA_AGENT_URL}" \
    && curl -sL ${OTEL_JAVA_AGENT_URL} -o /opt/opentelemetry/java/opentelemetry-javaagent-all.jar \
    && ls -al /opt/opentelemetry/java/opentelemetry-javaagent-all.jar

FROM scratch

ADD target/debug/libopentelemetry_injector.so /opt/opentelemetry/libopentelemetry_injector.so
COPY --from=opentelemetry-javaagent-dependency /opt/opentelemetry/java/opentelemetry-javaagent-all.jar /opt/opentelemetry/java/opentelemetry-javaagent-all.jar