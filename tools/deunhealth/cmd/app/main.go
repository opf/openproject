package main

import (
	"context"
	"fmt"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"
	_ "time/tzdata"

	"github.com/qdm12/deunhealth/internal/config"
	"github.com/qdm12/deunhealth/internal/docker"
	"github.com/qdm12/deunhealth/internal/health"
	"github.com/qdm12/deunhealth/internal/loop"
	"github.com/qdm12/deunhealth/internal/loop/info"
	"github.com/qdm12/deunhealth/internal/models"
	"github.com/qdm12/goservices"
	"github.com/qdm12/gosettings/reader"
	"github.com/qdm12/gosplash"
	"github.com/qdm12/log"
)

var (
	// Values set by the build system.
	version   = "unknown"
	commit    = "unknown"         //nolint:gochecknoglobals
	buildDate = "an unknown date" //nolint:gochecknoglobals
)

func main() {
	signalCh := make(chan os.Signal, 1)
	signal.Notify(signalCh, syscall.SIGINT, syscall.SIGTERM, os.Interrupt)

	buildInfo := models.BuildInformation{
		Version:   version,
		Commit:    commit,
		BuildDate: buildDate,
	}

	args := os.Args

	logger := log.New()

	reader := reader.New(reader.Settings{})

	ctx, cancel := context.WithCancel(context.Background())
	errorCh := make(chan error)
	go func() {
		errorCh <- _main(ctx, buildInfo, args, logger, reader)
	}()

	select {
	case signal := <-signalCh:
		fmt.Println("") // Skip a line for ^C character
		logger.Warnf("Caught OS signal %s (%d), shutting down", signal, signal)
		cancel()
	case err := <-errorCh:
		close(errorCh)
		if err == nil { // expected exit such as healthcheck query
			os.Exit(0)
		}
		logger.Error("Fatal error: " + err.Error())
		os.Exit(1)
	}

	select {
	case <-signalCh: // hard exit on second signal
	case err := <-errorCh:
		if err != nil {
			logger.Error("shutdown error: " + err.Error())
		}
	}
	os.Exit(1)
}

func _main(ctx context.Context, buildInfo models.BuildInformation,
	args []string, logger log.LoggerInterface, reader *reader.Reader,
) (err error) {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	if health.IsClientMode(args) {
		// Running the program in a separate instance through the Docker
		// built-in healthcheck, in an ephemeral fashion to query the
		// long running instance of the program about its status
		return runHealthClient(ctx, reader)
	}

	splashLines(buildInfo)

	var settings config.Settings
	settings.Read(reader)
	settings.SetDefaults()
	err = settings.Validate()
	if err != nil {
		return fmt.Errorf("validating settings: %w", err)
	}

	logLevel, _ := log.ParseLevel(settings.Log.Level)
	logger.Patch(log.SetLevel(logLevel))

	docker, err := docker.New(settings.Docker.Host)
	if err != nil {
		return err
	}

	docker.NegotiateVersion(ctx)

	var services []goservices.Service

	unhealthyLoop := loop.NewUnhealthyLoop(docker, logger)
	services = append(services, unhealthyLoop)

	unhealthyInfoLoop := info.NewUnhealthyLoop(docker, logger)
	services = append(services, unhealthyInfoLoop)

	healthcheck := func() error { return nil }
	heathcheckLogger := logger.New(log.SetComponent("healthcheck"))
	healthServer, err := health.NewServer(settings.Health.Address, heathcheckLogger, healthcheck)
	if err != nil {
		return fmt.Errorf("creating health server: %w", err)
	}
	services = append(services, healthServer)

	return setupAndRunServices(ctx, services)
}

func runHealthClient(ctx context.Context,
	configReader *reader.Reader,
) (err error) {
	client := health.NewClient()

	var settings config.Health
	settings.Read(configReader)
	settings.SetDefaults()
	err = settings.Validate()
	if err != nil {
		return fmt.Errorf("validating health settings: %w", err)
	}

	return client.Query(ctx, settings.Address)
}

func splashLines(buildInfo models.BuildInformation) {
	announcementExpiration, err := time.Parse("2006-01-02", "2021-07-14")
	if err != nil {
		panic(err)
	}
	splashLines := gosplash.MakeLines(gosplash.Settings{
		User:          "qdm12",
		Repository:    "deunhealth",
		Authors:       []string{"github.com/qdm12"},
		Emails:        []string{"quentin.mcgaw@gmail.com"},
		Version:       buildInfo.Version,
		Commit:        buildInfo.Commit,
		BuildDate:     buildInfo.BuildDate,
		Announcement:  "",
		AnnounceExp:   announcementExpiration,
		PaypalUser:    "qmcgaw",
		GithubSponsor: "qdm12",
	})
	fmt.Println(strings.Join(splashLines, "\n"))
}

func setupAndRunServices(ctx context.Context,
	services []goservices.Service,
) (err error) {
	group, err := goservices.NewGroup(goservices.GroupSettings{
		Services: services,
	})
	if err != nil {
		return fmt.Errorf("creating services group: %w", err)
	}
	runError, err := group.Start(ctx)
	if err != nil {
		return fmt.Errorf("starting services group: %w", err)
	}

	select {
	case <-ctx.Done():
		err = group.Stop()
		if err != nil {
			return fmt.Errorf("stopping services group: %w", err)
		}
		return nil
	case err = <-runError:
		return fmt.Errorf("services group encountered an error: %w", err)
	}
}
