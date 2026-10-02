package loop

import (
	"context"
	"fmt"

	"github.com/qdm12/deunhealth/internal/docker"
	"github.com/qdm12/log"
)

func NewUnhealthyLoop(docker Docker, logger log.LeveledLogger) *Unhealthy {
	return &Unhealthy{
		docker: docker,
		logger: logger,
	}
}

type Unhealthy struct {
	logger log.LeveledLogger
	docker Docker
	cancel context.CancelFunc
	done   <-chan struct{}
}

func (l *Unhealthy) String() string {
	return "unhealthy loop"
}

func (l *Unhealthy) Start(ctx context.Context) (runError <-chan error, err error) {
	ready := make(chan struct{})
	done := make(chan struct{})
	l.done = done
	runErrorCh := make(chan error)
	runCtx, cancel := context.WithCancel(context.Background())
	l.cancel = cancel
	go l.run(runCtx, ready, done, runErrorCh) //nolint:contextcheck
	select {
	case <-ctx.Done():
		l.cancel()
		<-done
		return nil, ctx.Err()
	case <-ready:
		return runErrorCh, nil
	}
}

func (l *Unhealthy) Stop() (err error) {
	l.cancel()
	<-l.done
	return nil
}

func (l *Unhealthy) run(ctx context.Context, ready chan<- struct{},
	done chan<- struct{}, runError chan<- error,
) {
	defer close(done)

	streamReady := make(chan struct{})
	unhealthies := make(chan docker.Container)
	unhealthyStreamCrashed := make(chan error)

	go l.docker.StreamUnhealthy(ctx, streamReady, unhealthies, unhealthyStreamCrashed)

	select {
	case <-streamReady:
	case err := <-unhealthyStreamCrashed:
		runError <- fmt.Errorf("stream crashed: %w", err)
		return
	case <-ctx.Done():
		<-unhealthyStreamCrashed
		return
	}

	existingUnhealthies, err := l.docker.GetUnhealthy(ctx)
	if err != nil {
		runError <- fmt.Errorf("getting unhealthy containers: %w", err)
		return
	}
	for _, unhealthy := range existingUnhealthies {
		l.restartUnhealthy(ctx, unhealthy)
	}

	close(ready)

	for {
		select {
		case <-ctx.Done(): // stop requested
			<-unhealthyStreamCrashed
			return

		case err := <-unhealthyStreamCrashed:
			runError <- fmt.Errorf("streaming unhealthy containers: %w", err)
			return

		case unhealthy := <-unhealthies:
			l.restartUnhealthy(ctx, unhealthy)
		}
	}
}

func (l *Unhealthy) restartUnhealthy(ctx context.Context, unhealthy docker.Container) {
	l.logger.Info("container " + unhealthy.Name +
		" (image " + unhealthy.Image + ") is unhealthy, restarting it...")
	err := l.docker.RestartContainer(ctx, unhealthy.ID)
	if err != nil {
		l.logger.Error("failed restarting container: " + err.Error())
	} else {
		l.logger.Info("container " + unhealthy.Name + " restarted successfully")
	}
}
