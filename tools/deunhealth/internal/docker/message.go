package docker

import "github.com/docker/docker/api/types/events"

func isContainerMessage(message events.Message) (ok bool) {
	return message.Type == "container"
}
