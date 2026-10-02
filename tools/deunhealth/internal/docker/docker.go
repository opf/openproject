package docker

import (
	"github.com/moby/moby/client"
)

type Docker struct {
	client client.APIClient
}

func New(dockerHost string) (d *Docker, err error) {
	client, err := client.NewClientWithOpts(client.WithHost(dockerHost), client.WithAPIVersionNegotiation())
	if err != nil {
		return nil, err
	}

	return &Docker{
		client: client,
	}, nil
}
