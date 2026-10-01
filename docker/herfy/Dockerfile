# Herfy OpenProject = the stock all-in-one image + the Control Center login.
# Build from the repo root:  docker build -f docker/herfy/Dockerfile -t herfy-openproject .
# Pin the base to the exact stock tag the database was created with.
ARG OPENPROJECT_TAG=17
FROM openproject/openproject:${OPENPROJECT_TAG}

COPY --chown=app:app lib/herfy /app/lib/herfy
COPY --chown=app:app lib/tasks/herfy_control_center.rake /app/lib/tasks/herfy_control_center.rake
COPY --chown=app:app config/initializers/zz_herfy_control_center.rb /app/config/initializers/zz_herfy_control_center.rb
COPY --chown=app:app modules/openid_connect/lib/open_project/openid_connect/engine.rb /app/modules/openid_connect/lib/open_project/openid_connect/engine.rb

# OIDC/SSO login is an OpenProject Enterprise feature. The fork's zz_enterprise_unlocked.rb
# (PR #2) removes the license gate. It is shipped by default so the Control Center login works;
# build with --build-arg ENTERPRISE_UNLOCK=false if you hold an Enterprise token instead.
ARG ENTERPRISE_UNLOCK=true
COPY config/initializers/zz_enterprise_unlocked.rb /tmp/zz_enterprise_unlocked.rb
RUN if [ "$ENTERPRISE_UNLOCK" = "true" ]; then \
      install -o app -g app /tmp/zz_enterprise_unlocked.rb /app/config/initializers/zz_enterprise_unlocked.rb; \
    fi; rm -f /tmp/zz_enterprise_unlocked.rb

# Fail the build (not the first request) if any Herfy file has a syntax error.
RUN for f in $(find /app/lib/herfy -name '*.rb') /app/config/initializers/zz_herfy_control_center.rb \
      /app/modules/openid_connect/lib/open_project/openid_connect/engine.rb; do ruby -c "$f" >/dev/null || exit 1; done
