FROM ubuntu:21.04

RUN apt-get update && apt-get upgrade && apt-get install -y default-jre-headless && apt-get clean

ADD target/server-app.jar /app/server-app.jar

### THIS SHOULD BE REPLACED BY ONE PACKAGE
COPY --from=otel-injector:latest /opt/opentelemetry /opt/opentelemetry

RUN echo '[jvm]\n\
agent_path = "/opt/opentelemetry/java/opentelemetry-javaagent-all.jar"' > /app/otel_config.toml

ENV LD_PRELOAD="/opt/opentelemetry/libopentelemetry_injector.so"
ENV OPENTELEMETRY_INJECTOR_DEBUG="true"
ENV OPENTELEMETRY_INJECTOR_CONFIGURATION="/app/otel_config.toml"
### END

ENTRYPOINT [ "java", "-jar", "/app/server-app.jar" ]