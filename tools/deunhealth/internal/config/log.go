package config

import (
	"fmt"

	"github.com/qdm12/gosettings"
	"github.com/qdm12/gosettings/reader"
	"github.com/qdm12/log"
)

type Log struct {
	Level string
}

func (l *Log) setDefaults() {
	l.Level = gosettings.DefaultComparable(l.Level, log.LevelInfo.String())
}

func (l *Log) validate() (err error) {
	_, err = log.ParseLevel(l.Level)
	if err != nil {
		return fmt.Errorf("parsing log level: %w", err)
	}
	return nil
}

func (l *Log) read(r *reader.Reader) {
	l.Level = r.String("LOG_LEVEL")
}
