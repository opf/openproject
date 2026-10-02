package config

import (
	"fmt"
	"os"

	"github.com/qdm12/gosettings"
	"github.com/qdm12/gosettings/reader"
	"github.com/qdm12/gosettings/validate"
)

type Health struct {
	Address string
}

func (h *Health) SetDefaults() {
	h.Address = gosettings.DefaultComparable(h.Address, "127.0.0.1:9999")
}

func (h *Health) Validate() (err error) {
	err = validate.ListeningAddress(h.Address, os.Getuid())
	if err != nil {
		return fmt.Errorf("validating listening address: %w", err)
	}
	return nil
}

func (h *Health) Read(r *reader.Reader) {
	h.Address = r.String("HEALTH_SERVER_ADDRESS")
}
