#!/bin/bash
set -eu

for container in app-web-1 app-worker-1 app-proxy-1; do
  if docker container inspect "${container}" >/dev/null 2>&1; then
    echo "::group::Runtime status: ${container}"
    docker inspect --format 'status={{.State.Status}} exit_code={{.State.ExitCode}} restarts={{.RestartCount}}' "${container}"
    docker logs --tail 200 "${container}" 2>&1 |
      grep -oE '[A-Z][A-Za-z0-9_]+::[A-Z][A-Za-z0-9_:]+|[A-Z][A-Za-z_:]*(Error|Exception)|/app/(app|config|lib|modules|docker)/[A-Za-z0-9_./-]+:[0-9]+' |
      sort -u || true
    for signature in 'psql:' 'FATAL:' 'ERROR:' 'Permission denied' 'No such file or directory' 'could not translate host name' 'Connection refused' 'password authentication failed' 'role "app" does not exist' 'database "app" does not exist'; do
      if docker logs --tail 200 "${container}" 2>&1 | grep -qiF "${signature}"; then
        echo "matched_signature=${signature}"
      fi
    done
    echo '::endgroup::'
  fi
done

if database_state=$(docker exec app-db-1 psql -U app -d app -qtAX -c "SELECT to_regclass('public.schema_migrations') IS NOT NULL" 2>/dev/null); then
  case "${database_state}" in
    t)
      echo 'database_schema_present=yes'
      echo '::group::Applied migration versions'
      docker exec app-db-1 psql -U app -d app -qtAX -c 'SELECT version FROM schema_migrations ORDER BY version' 2>/dev/null |
        grep -E '^[0-9]{1,14}$' || true
      echo '::endgroup::'
      ;;
    f) echo 'database_schema_present=no' ;;
    *) echo 'database_schema_present=unknown' ;;
  esac
else
  echo 'database_metadata_available=no'
fi
