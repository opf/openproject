package docker

import (
	"strings"

	"github.com/docker/docker/api/types/container"
	"github.com/docker/docker/api/types/events"
)

func extractName(container container.Summary) (name string) {
	name = container.ID
	for _, containerName := range container.Names {
		if containerName != "" {
			name = strings.TrimPrefix(containerName, "/")
			break
		}
	}
	return name
}

func extractNameFromActor(actor events.Actor) (name string) {
	return actor.Attributes["name"]
}

func extractImageFromActor(actor events.Actor) (image string) {
	return actor.Attributes["image"]
}
