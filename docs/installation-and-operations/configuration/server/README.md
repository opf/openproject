---
sidebar_navigation:
  title: Configuring a custom web server
  priority: 5
---

# Configuring a custom web server

Both the packaged and docker-based installations ship with Apache as the default web server, because the Git and SVN repository integrations (when OpenProject manages the repositories) only work with that web server.

For a packaged-based installation, if for instance you wish to use NginX, you will need to skip the web server installation when asked in the initial configuration, and then configure NginX yourself so that it forwards traffic to the OpenProject web process (listening by default on 127.0.0.1:6000).If using SSL/TLS, please ensure you set the header value `X-Forwarded-Proto https` so OpenProject can correctly produce responses.

For a docker-based installation, you will need to use the (recommended) Compose stack, which will allow you to swap the `proxy` container with whatever server you want to use.

For instance you could define a new proxy server like this:

```yaml
services:
  ...
  proxy:
    image: nginx
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "8080:80"
  ...
```

And the corresponding NginX configuration file would look like:

```
# default.conf
upstream web {
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
            proxy_pass         http://web/;
        }
}
```
