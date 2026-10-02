package docker

import (
	"context"

	"github.com/docker/docker/api/types/container"
)

func (d *Docker) RestartContainer(ctx context.Context, name string) (err error) {
	return d.client.ContainerRestart(ctx, name, container.StopOptions{})
}
