package loop

import (
	"context"

	"github.com/qdm12/deunhealth/internal/docker"
)

type Docker interface {
	GetUnhealthy(ctx context.Context) (containers []docker.Container, err error)
	StreamUnhealthy(ctx context.Context, ready chan<- struct{},
		containers chan<- docker.Container, crashed chan<- error)
	RestartContainer(ctx context.Context, containerID string) (err error)
}
