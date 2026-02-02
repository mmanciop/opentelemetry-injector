# OpenTelemetry Injector

The OpenTelemetry Injector is an LD_PRELOAD-based automatic instrumentation injector that enables zero-code instrumentation for applications running on Linux systems.

## How It Works

The injector library (`libotelinject.so`) is loaded via `/etc/ld.so.preload` into every process. It detects the runtime (Java, Node.js, .NET) and injects the appropriate OpenTelemetry auto-instrumentation agent.

## Configuration

The injector is configured via `/etc/opentelemetry/injector/otelinject.conf`. This file specifies the paths to the auto-instrumentation agents for each supported runtime.

### Configuration Options

- `all_auto_instrumentation_agents_env_path`: Path to environment variables file applied to all instrumented processes
- `jvm_auto_instrumentation_agent_path`: Path to the Java agent JAR file
- `nodejs_auto_instrumentation_agent_path`: Path to the Node.js agent entry point
- `dotnet_auto_instrumentation_agent_path_prefix`: Path prefix for .NET agent binaries

### Default Environment Variables

The file at `/etc/opentelemetry/injector/default_env.conf` contains environment variables that are set for all instrumented applications. Use this to configure common settings like:

- `OTEL_SERVICE_NAME`: Service name for telemetry
- `OTEL_EXPORTER_OTLP_ENDPOINT`: Endpoint for the OTLP exporter

## Files

- `/usr/lib/opentelemetry/injector/libotelinject.so`: The injector shared library
- `/etc/opentelemetry/injector/otelinject.conf`: Main configuration file
- `/etc/opentelemetry/injector/default_env.conf`: Default environment variables

## See Also

- `opentelemetry-injector(8)` - Man page for the injector
- https://opentelemetry.io/docs/
