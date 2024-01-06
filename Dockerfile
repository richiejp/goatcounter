FROM golang:1.21 AS build

WORKDIR /go/src/goatcounter

# we squat the "dynamically created user accounts" space, see:
# https://www.debian.org/doc/debian-policy/ch-opersys.html#uid-and-gid-classes
# this assumes 32bit support (!)
RUN groupadd -K GID_MIN=65536 -K GID_MAX=4294967293 builder && \
        useradd --no-log-init --create-home -K UID_MIN=65536 -K UID_MAX=4294967293 --gid builder builder && \
        chown builder:builder /go/src/goatcounter

COPY --chown=builder:builder . .

USER builder

# if build fails, try this for more verbosity:
# RUN go build -x -v -work ./cmd/goatcounter
RUN go build -ldflags="-X zgo.at/goatcounter/v2.Version=$(git log -n1 --format='%h_%cI')" ./cmd/goatcounter

FROM debian:bookworm-slim AS runtime

RUN groupadd -K GID_MIN=65536 -K GID_MAX=4294967293 user && \
        useradd --no-log-init --create-home -K UID_MIN=65536 -K UID_MAX=4294967293 --gid user user && \
        rm -fr -- /var/lib/apt/lists/* /var/cache/*

COPY --from=build /go/src/goatcounter/goatcounter /usr/local/bin

USER user
WORKDIR /home/user

RUN mkdir /home/user/db

VOLUME ["/home/user/db/"]
EXPOSE 8080

ENTRYPOINT ["/usr/local/bin/goatcounter"]
CMD ["serve", "-automigrate", "-store-every=1", "-listen=:8080", "-tls=http"]
