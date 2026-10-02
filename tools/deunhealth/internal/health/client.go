package health

import (
	"context"
	"errors"
	"fmt"
	"io"
	"net"
	"net/http"
	"time"
)

func IsClientMode(args []string) bool {
	return len(args) > 1 && args[1] == "healthcheck"
}

type Client struct {
	*http.Client
}

func NewClient() *Client {
	const timeout = 5 * time.Second
	return &Client{
		Client: &http.Client{Timeout: timeout},
	}
}

var ErrUnhealthy = errors.New("unhealthy")

// Query sends an HTTP request to the other instance of
// the program, and to its internal healthcheck server.
func (c *Client) Query(ctx context.Context, address string) error {
	_, port, err := net.SplitHostPort(address)
	if err != nil {
		return fmt.Errorf("parsing health server address: %w", err)
	}

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, "http://127.0.0.1:"+port, nil)
	if err != nil {
		return fmt.Errorf("querying health server: %w", err)
	}
	resp, err := c.Do(req)
	if err != nil {
		return fmt.Errorf("querying health server: %w", err)
	} else if resp.StatusCode == http.StatusOK {
		return nil
	}

	b, err := io.ReadAll(resp.Body)
	defer resp.Body.Close()
	if err != nil {
		return fmt.Errorf("%w: %s: %w", ErrUnhealthy, resp.Status, err)
	}
	return fmt.Errorf("%w: %s", ErrUnhealthy, string(b))
}
