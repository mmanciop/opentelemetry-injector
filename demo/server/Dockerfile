FROM ubuntu:21.04

RUN apt-get update && apt-get upgrade && apt-get install -y default-jre-headless && apt-get clean

ADD target/server-app.jar /app/server-app.jar

ADD ./opentelemetry-injector.deb /tmp/opentelemetry-injector.deb
RUN dpkg -i /tmp/opentelemetry-injector.deb

ENTRYPOINT [ "java", "-jar", "/app/server-app.jar" ]