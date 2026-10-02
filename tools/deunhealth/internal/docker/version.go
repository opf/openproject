package docker

import "context"

func (d *Docker) NegotiateVersion(ctx context.Context) {
	d.client.NegotiateAPIVersion(ctx)
}
