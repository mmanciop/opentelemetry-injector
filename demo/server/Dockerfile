FROM ubuntu:22.04 AS opentelemetry-javaagent-dependency

RUN apt-get update && apt-get upgrade -y && apt-get install -y curl jq && apt-get clean

ARG otel_repo="https://api.github.com/repos/open-telemetry/opentelemetry-java-instrumentation"

RUN mkdir -p /opt/opentelemetry/java \
    && OTEL_JAVA_AGENT_URL=$(curl --silent --fail --show-error "${otel_repo}/releases/latest" | jq -r '.assets[] | select(.name == "opentelemetry-javaagent.jar") | .browser_download_url') \
    && echo "Downloading the OpenTelemetry Java agent at: ${OTEL_JAVA_AGENT_URL}" \
    && curl -sL ${OTEL_JAVA_AGENT_URL} -o /opt/opentelemetry/java/opentelemetry-javaagent.jar \
    && ls -al /opt/opentelemetry/java/opentelemetry-javaagent.jar

FROM openjdk:17 AS app-builder

ADD src /code/src
ADD .mvn /code/.mvn
ADD mvnw pom.xml /code/

WORKDIR /code

RUN ./mvnw package

FROM ubuntu:22.04

RUN apt-get update && apt-get upgrade -y && apt-get install -y default-jre-headless && apt-get clean

COPY --from=opentelemetry-javaagent-dependency /opt/opentelemetry/java/opentelemetry-javaagent.jar /opt/opentelemetry/java/opentelemetry-javaagent.jar
COPY --from=opentelemetry-injector /opt/opentelemetry/libopentelemetry_injector.so /opt/opentelemetry/libopentelemetry_injector.so
ENV LD_PRELOAD=/opt/opentelemetry/libopentelemetry_injector.so

COPY --from=app-builder /code/target/server-app.jar /app/server-app.jar

ENTRYPOINT [ "java", "-jar", "/app/server-app.jar" ]