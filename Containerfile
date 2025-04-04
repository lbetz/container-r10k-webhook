ARG R10K_VERSION=5.0.0

FROM docker.io/library/golang:alpine AS builder
ARG WEBHOOK_GO_VERSION=2.9.0

RUN apk add --no-cache ca-certificates

WORKDIR /build

RUN wget -qO - https://github.com/voxpupuli/webhook-go/archive/refs/tags/v$WEBHOOK_GO_VERSION.tar.gz | tar xfz - -C ./ --strip-components 1
RUN go mod download
RUN CGO_ENABLED=0 go build -ldflags="-s -w" -o ./webhook-go

FROM ghcr.io/voxpupuli/r10k:$R10K_VERSION-latest

LABEL org.label-schema.maintainer="Vox Pupuli Team <voxpupuli@groups.io>" \
      org.label-schema.vendor="Vox Pupuli" \
      org.label-schema.url="https://github.com/voxpupuli/container-r10k-webhook" \
      org.label-schema.vcs-url="https://github.com/voxpupuli/container-r10k-webhook" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.dockerfile="/Containerfile" \
      org.label-schema.name="Vox Pupuli R10k Webhook ($build_type)" \
      org.label-schema.version="$WEBHOOK_GO_VERSION-$vcs_ref" \
      org.label-schema.vcs-ref="$vcs_ref" \
      org.label-schema.build-date="$build_date"

ENV USER="puppet"
ENV PORT=4000
ENV TLS=false
ENV DEFAULT_BRANCH="production"
ENV GENERATE_TYPES=true
ENV VERBOSE=false
ENV CHAT=false
ENV CHAT_USER="r10kbot"

USER root

COPY --from=builder --chmod=755 /build/webhook-go /usr/sbin/webhook-go
COPY --chmod=755 webhook/docker-entrypoint.sh /docker-entrypoint.sh
COPY webhook/docker-entrypoint.d /docker-entrypoint.d
COPY Containerfile /

EXPOSE 4000
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD [ "server", "--config", "/etc/webhook.yml" ]
