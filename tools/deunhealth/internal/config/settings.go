package config

import (
	"fmt"

	"github.com/qdm12/gosettings/reader"
)

type Settings struct {
	Docker Docker
	Health Health
	Log    Log
}

func (s *Settings) SetDefaults() {
	s.Docker.setDefaults()
	s.Health.SetDefaults()
	s.Log.setDefaults()
}

func (s *Settings) Validate() (err error) {
	err = s.Docker.validate()
	if err != nil {
		return fmt.Errorf("validating Docker settings: %w", err)
	}

	err = s.Health.Validate()
	if err != nil {
		return fmt.Errorf("validating health settings: %w", err)
	}

	err = s.Log.validate()
	if err != nil {
		return fmt.Errorf("validating log settings: %w", err)
	}

	return nil
}

func (s *Settings) Read(r *reader.Reader) {
	s.Docker.read(r)
	s.Health.Read(r)
	s.Log.read(r)
}
