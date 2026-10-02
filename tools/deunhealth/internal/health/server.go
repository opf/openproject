package health

import (
	"github.com/qdm12/goservices/httpserver"
)

func NewServer(address string, logger Logger, healthcheck func() error) (
	server *httpserver.Server, err error,
) {
	handler := newHandler(healthcheck)
	return httpserver.New(httpserver.Settings{
		Handler: handler,
		Name:    ptrTo("health"),
		Address: ptrTo(address),
		Logger:  logger,
	})
}

func ptrTo[T any](value T) *T { return &value }
