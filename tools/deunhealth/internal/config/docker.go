package config

import (
	"github.com/moby/moby/client"
	"github.com/qdm12/gosettings"
	"github.com/qdm12/gosettings/reader"
)

type Docker struct {
	Host string
}

func (d *Docker) setDefaults() {
	d.Host = gosettings.DefaultComparable(d.Host, client.DefaultDockerHost)
}

func (d *Docker) validate() error {
	return nil
}

func (d *Docker) read(r *reader.Reader) {
	d.Host = r.String("DOCKER_HOST")
}
