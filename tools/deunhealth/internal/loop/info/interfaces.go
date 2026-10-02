package info

import (
	"context"

	"github.com/qdm12/deunhealth/internal/docker"
)

type Docker interface {
	GetLabeled(ctx context.Context, labels []string) (
		containers []docker.Container, err error)
	StreamLabeled(ctx context.Context, ready chan<- struct{},
		labels []string, containers chan<- docker.Container, crashed chan<- error)
}

type Logger interface {
	Infof(format string, args ...interface{})
}
