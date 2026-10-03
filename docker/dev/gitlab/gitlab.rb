# frozen_string_literal: true

# Configure GitLab hostname based on the same environment variable that we use to configure our front-proxy as well
dns_zone = ENV.fetch("OPENPROJECT_DOCKER_DEV_TLD")
external_url "https://gitlab.#{dns_zone}"

# Configure GitLab to run behind our own reverse proxy, which handles TLS-termination already
gitlab_rails["nginx"]["listen_port"] = 80
gitlab_rails["nginx"]["listen_https"] = false
letsencrypt["enable"] = false
