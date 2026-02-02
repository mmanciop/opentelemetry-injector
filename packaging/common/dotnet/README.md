# OpenTelemetry .NET Auto-Instrumentation

This package provides the OpenTelemetry .NET Auto-Instrumentation for automatic instrumentation of .NET applications.

## Overview

The .NET instrumentation automatically instruments .NET applications to collect distributed traces, metrics, and logs without requiring code changes.

## Installation

The instrumentation is installed at `/usr/lib/opentelemetry/dotnet/` with two variants:

- `glibc/` - For standard Linux distributions (Debian, Ubuntu, Fedora, RHEL, etc.)
- `musl/` - For Alpine Linux and other musl-based distributions

When combined with the `opentelemetry-injector` package, .NET applications are automatically instrumented. The injector selects the correct variant based on the system's C library.

## Configuration

### Environment Variables

- `OTEL_SERVICE_NAME`: Service name for telemetry (required)
- `OTEL_EXPORTER_OTLP_ENDPOINT`: OTLP endpoint (default: http://localhost:4317)
- `OTEL_TRACES_EXPORTER`: Traces exporter (otlp, console, none)
- `OTEL_METRICS_EXPORTER`: Metrics exporter (otlp, console, none)
- `OTEL_LOGS_EXPORTER`: Logs exporter (otlp, console, none)
- `OTEL_DOTNET_AUTO_INSTRUMENTATION_ENABLED`: Set to "false" to disable

### Declarative Configuration

A configuration file is available at `/etc/opentelemetry/dotnet/otel-config.yaml`. To use it, set:

```bash
export OTEL_EXPERIMENTAL_CONFIG_FILE=/etc/opentelemetry/dotnet/otel-config.yaml
```

## Supported Libraries

The instrumentation supports automatic instrumentation for:

- ASP.NET Core
- HttpClient
- gRPC
- Entity Framework Core
- SQL Client
- StackExchange.Redis
- MongoDB
- Elasticsearch
- And many more...

## See Also

- `opentelemetry-dotnet(1)` - Man page
- https://opentelemetry.io/docs/zero-code/net/
