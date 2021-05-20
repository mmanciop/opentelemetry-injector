# OpenTelemetry Injector

This project contains an experimental [`LD_PRELOAD` object](https://man7.org/linux/man-pages/man8/ld.so.8.html) to automatically inject [OpenTelemetry](https://opentelemetry.io/) instrumentation into your unmodified applications.

## Supported Runtimes

Currently:

* [Java Virtual Machines](#java-virtual-machine) by means of the [OpenTelemetry Java Instrumentation](https://github.com/open-telemetry/opentelemetry-java-instrumentation)

Eventually (hopefully), all runtimes supported via OpenTelemetry in which the instrumentation can be injected at startup time (which oughta be more or less all those runtimes that are not compiled to binary):

* Erlang (???) (Not sure about the feasibility of this one really)
* .NET Core
* Node.js
* PHP
* Python
* Ruby

## See it in action!

```sh
./demo/run
```

Then open `http://localhost:16686` (if you use `docker-machine` or similar, you'll have to adjust the hostname) in your browser to access the Jaeger deployed in Docker Compose and see the traces flow!

Dependencies:

* Rust build toolchain
* Docker & Docker Compose
* `dpkg-deb`
* `bash`, `curl`, `libc`

## Usage

### How it works

This project works based on a simple principle, namely that OpenTelemetry is going to monitor your application if

1. The necessary instrumentation is available on the filesystem running under your application
2. You can activate the instrumentation _somehow_

Now, (2) is actually possible in many runtimes via `environment variables`, e.g., `JAVA_TOOL_OPTIONS` or `NODE_OPTIONS` (in Node.js 8+).
However, asking DevOps people to setup environment variables for their apps is a chore, so this project steps in by providing a consistent interface to ensure that the right variables are set for all supported runtimes providing one consistent API using `LD_PRELOAD`.

In short, `LD_PRELOAD` is a way to _hijack_ the way most application runtimes (think of the Java Virtual Machine, the Node.js V8, etc.) _look up_ environment variables, which is mostly via the `getenv` API of LibC.
The `LD_PRELOAD` object provided by building this repository does just that: it intercepts calls to `getenv` by runtimes, modifying the results for some runtime-specific environment variables to add what is needed to activate the OpenTelemetry instrumentation.

Sounds like dark magic, but actually this technique has been used in the commercial APM space for the best part of a decade :-)

### Setup the LD_PRELOAD object

There are two ways to install this `LD_PRELOAD` object so that your applications get automatically monitored with OpenTelemetry:

* Set the `LD_PRELOAD` environment variable pointing to the file location of the `.so` object
* Copy the path to this `.so` object into the `/etc/ld.so.preload` file

Both installation methods can be conveniently done in Kubernets via [environment variables](https://kubernetes.io/docs/tasks/inject-data-application/define-environment-variable-container/) and [volume mounts](https://kubernetes.io/docs/tasks/configure-pod-container/configure-volume-storage/) to your application pods.

### Configuration

#### Configuration file

The OpenTelemetry injector needs a [TOML](https://github.com/toml-lang/toml) configuration file situated at `/etc/opentelemetry/injector/configuration.toml`, but the configuration file location is customizable via the `OPENTELEMETRY_INJECTOR_CONFIGURATION` environment variable.

#### Java Virtual Machine

The `LD_PRELOAD` object needs to know where to find the [OpenTelemetry Java Instrumentation](https://github.com/open-telemetry/opentelemetry-java-instrumentation), so that is can pass it via the `-javaagent:<agent_path>` startup argument via the `JAVA_TOOL_OPTIONS` environment variable.

Add the following to the [configuration file](#configuration-file), adjusting the value of `jvm.agent_path` to your own setup:

```toml
[jvm]
agent_path = '/opt/opentelemetry/opentelemetry-javaagent-all.jar'
```

If the file listed as `jvm.agent_path` does not exist, the `LD_PRELOAD` object will not modify the `JAVA_TOOL_OPTIONS` environment variable, but no further verification of the _content_ of the file will be performed.

## Development

### Build

Assuming you have a working Rust setup, it is as simple as running the following from the root of the repository:

```sh
cargo build
```

The `LD_PRELOAD` object is going to be available at `<repository_root>/target/debug/libopentelemetry_injector.so`.

### Why Rust

Why using [Rust](https://www.rust-lang.org/) for an `LD_PRELOAD` object, rather than something more traditional like C?
Well, Rust has very nice memory management and the [redhook](https://crates.io/crates/redhook) crate to create `LD_PRELOAD` objects that makes me fret far less over catastrophic bugs this project might introduce.

## Limitations

The runtime used by your applications needs to be dynamically linked to LibC for the `LD_PRELOAD` mechanic used in this project to work.

## Support

This is super-experimental and currently no support can be ensured.
But please do let me know of issues by [opening one](../../issues) on GitHub.
