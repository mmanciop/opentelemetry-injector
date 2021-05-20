# OpenTelemetry Injector Demo

This directory contains a small Java-nased demo, in which two Spring Boot applications, `client` and `server`, interact over HTTP.
The interactions are traced by the [OpenTelemetry Java Agent](https://github.com/open-telemetry/opentelemetry-java-instrumentation), which is automatically injected into the Java Virtual Machines running `client` and `server` at startup using the OpenTelemetry Injector.
The OpenTelemetry Java Agents are configured to report tracing data to a Jaeger backend, also included in the demo setup

## The Diagram

```
 ┌──────────┐                                              ┌──────────┐
 │          │            HTTP GET /api/greeting            │          │
 │  Client  ├─────────────────────────────────────────────►│  Server  │
 │          │                                              │          │
 └───┬──────┤                                              └───┬──────┤
     │      │              Automatically injected              │      │
     │ OTEL │ ◄────────────  on JVM startup with  ───────────► │ OTEL │
     │      │                an LD_PRELOAD hook                │      │
     └───┬──┘                                                  └──┬───┘
         │                                                        │
         │                   ┌─────────────┐                      │
         │                   │             │                      │
         └───────────────────►   Jaeger    ◄──────────────────────┘
               Tracing data  │   Backend   │  Tracing data
                             │             │
                             └─────────────┘
```

(Note: The title of this section may or may not be inspired by Brandon Sanderon's "The Stormlight Archive" series.)

## Requirements

* `docker` and `docker-compose`
* Rust build toolchain to build the injector

## Let it rip!

```sh
./run
```

Don't forget to make a `docker-compose down` afterwards, so that the various components of the demo are cleaned up.
