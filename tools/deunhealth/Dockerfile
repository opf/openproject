# Sets linux/amd64 in case it's not injected by older Docker versions
ARG BUILDPLATFORM=linux/amd64

ARG ALPINE_VERSION=3.22
ARG GO_VERSION=1.25
ARG XCPUTRANSLATE_VERSION=v0.9.0
ARG GOLANGCI_LINT_VERSION=v2.4.0

FROM --platform=${BUILDPLATFORM} ghcr.io/qdm12/xcputranslate:${XCPUTRANSLATE_VERSION} AS xcputranslate
FROM --platform=${BUILDPLATFORM} ghcr.io/qdm12/binpot:golangci-lint-${GOLANGCI_LINT_VERSION} AS golangci-lint

FROM --platform=${BUILDPLATFORM} golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS base
ENV CGO_ENABLED=0
WORKDIR /tmp/gobuild
RUN apk --update add git g++
COPY --from=xcputranslate /xcputranslate /usr/local/bin/xcputranslate
COPY --from=golangci-lint /bin /go/bin/golangci-lint
COPY go.mod go.sum ./
RUN go mod download
COPY cmd/ ./cmd/
COPY internal/ ./internal/

FROM base AS test
# Note on the go race detector:
# - we set CGO_ENABLED=1 to have it enabled
# - we installed g++ in the base stage to support the race detector
ENV CGO_ENABLED=1
ENTRYPOINT go test -race -coverprofile=coverage.txt ./...

FROM base AS lint
COPY .golangci.yml ./
RUN golangci-lint run

FROM base AS build
ARG TARGETPLATFORM
ARG VERSION=unknown
ARG CREATED="an unknown date"
ARG COMMIT=unknown
RUN GOARCH="$(xcputranslate translate -targetplatform=${TARGETPLATFORM} -field arch)" \
    GOARM="$(xcputranslate translate -targetplatform=${TARGETPLATFORM} -field arm)" \
    go build -trimpath -ldflags="-s -w \
    -X 'main.version=$VERSION' \
    -X 'main.buildDate=$CREATED' \
    -X 'main.commit=$COMMIT' \
    " -o app cmd/app/main.go

FROM scratch
ENTRYPOINT ["/app"]
HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=2 CMD ["/app","healthcheck"]
ENV LOG_LEVEL=info \
    HEALTH_SERVER_ADDRESS=127.0.0.1:9999 \
    TZ=America/Montreal
ARG VERSION=unknown
ARG CREATED="an unknown date"
ARG COMMIT=unknown
LABEL \
    org.opencontainers.image.authors="quentin.mcgaw@gmail.com" \
    org.opencontainers.image.version=$VERSION \
    org.opencontainers.image.created=$CREATED \
    org.opencontainers.image.revision=$COMMIT \
    org.opencontainers.image.url="https://github.com/qdm12/deunhealth" \
    org.opencontainers.image.documentation="https://github.com/qdm12/deunhealth/blob/main/README.md" \
    org.opencontainers.image.source="https://github.com/qdm12/deunhealth" \
    org.opencontainers.image.title="deunhealth" \
    org.opencontainers.image.description="Restart your unhealthy containers in style"
COPY --from=build --chown=1000 /tmp/gobuild/app /app