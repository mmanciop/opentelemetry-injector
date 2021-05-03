# OpenTelemetry Injector

This project contains an experimental [`LD_PRELOAD` object](https://man7.org/linux/man-pages/man8/ld.so.8.html) to automatically inject [OpenTelemetry](https://opentelemetry.io/) instrumentation into your unmodified applications.

## Supported Runtimes

* Java Virtual Machines by means of the [OpenTelemetry Java Instrumentation](https://github.com/open-telemetry/opentelemetry-java-instrumentation)

## Usage

### Setup the LD_PRELOAD object

There are two ways to install this `LD_PRELOAD` object so that your applications get automatically monitored with OpenTelemetry:

* Set the `LD_PRELOAD` environment variable pointing to the file location of the `.so` object
* Copy the `.so` object at `/etc/ld.so.preload`

Both installation methods can be conveniently done in Kubernets via [environment variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/) and [volume mounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/) to your application pods.

### Configuration

#### Configuration file

The OpenTelemetry injector needs a [TOML](https://github.com/toml-lang/toml) configuration file situated at `/etc/opentelemetry/injector/configuration.toml`, but the configuration file location is customizable via the `OPENTELEMETRY_INJECTOR_CONFIGURATION` environment variable.

#### Java Virtual Machine

The `LD_PRELOAD` object needs to know where to find the [OpenTelemetry Java Instrumentation](https://github.com/open-telemetry/opentelemetry-java-instrumentation).
Add the following to the [configuration file](#configuration-file), adjusting the value of `jvm.agent_path` to your own setup:

```toml
[jvm]
agent_path = '/opt/opentelemetry/opentelemetry-javaagent-all.jar'
```

## Development

Why using [rust](https://www.rust-lang.org/) for an `LD_PRELOAD` object, rather than something more traditional like C?
Well, rust has very nice memory management and the [redhook](https://crates.io/crates/redhook) crate to create `LD_PRELOAD` objects that makes me fret far less over catastrophic bugs this might introduce.
