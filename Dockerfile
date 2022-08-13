FROM rust:slim-buster AS builder

COPY src /code/src
COPY Cargo.* /code/
WORKDIR /code/

RUN find /code && cargo build && mkdir /build && cp target/debug/libopentelemetry_injector.so /build/

FROM scratch AS opentelemetry-injector

COPY --from=builder /build/libopentelemetry_injector.so /opt/opentelemetry/