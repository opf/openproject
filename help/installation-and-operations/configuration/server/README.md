---
sidebar_navigation:
  title: Configuring a custom web server
  priority: 5
---

# Configuring a custom web server

Both the packaged and docker-based installations ship with Apache as the default web server, because the Git and SVN repository integrations (when OpenProject manages the repositories) only work with that web server.

For a packaged-based installation, if for instance you wish to use NginX, you will need to skip the web server installation when asked in the initial configuration, and then configure NginX yourself so that it forwards traffic to the OpenProject web process (listening by default on 127.0.0.1:6000).If using SSL/TLS, please ensure you set the header value `X-Forwarded-Proto https` so OpenProject can correctly produce responses.

For a docker-based installation, you will need to switch to the single-process launch mode, where you would launch one or more containers for the `web` process, one container for the `worker` process, and then setup a web server of your choice in another container that forwards traffic to the `web` container(s). A simplified Compose file would look like:

```yaml
version: '3'
services:
  database:
    image: postgres:10
    environment:
      - POSTGRES_PASSWORD=p4ssw0rd
      - POSTGRES_DB=openproject
  nginx:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "8080:80"

  web: &openproject
    environment:
      - DATABASE_URL=postgres://postgres:p4ssw0rd@database/openproject
    image: openproject/community:10
    command: ./docker/web
  worker:
    <<: *openproject
    command: ./docker/worker
```

And the corresponding NginX configuration file would look like:

```
# default.conf
upstream app {
    server web:8080;
}

server {
        listen 80;
	server_name _;

        location / {
            proxy_pass_header  Server;
            proxy_set_header   Host $http_host;
            proxy_redirect     off;
            proxy_set_header   X-Real-IP $remote_addr;
            proxy_set_header   X-Scheme $scheme;
            proxy_pass         http://app/;
        }
}
```
