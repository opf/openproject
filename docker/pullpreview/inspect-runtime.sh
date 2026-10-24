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

empty_state=$(docker exec -i app-db-1 psql -U app -d app -qtAX <<'SQL' 2>/dev/null
CREATE OR REPLACE FUNCTION pg_temp.application_tables_empty() RETURNS boolean LANGUAGE plpgsql AS $$
DECLARE item record; populated boolean;
BEGIN
  FOR item IN SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT IN ('schema_migrations', 'ar_internal_metadata') LOOP
    EXECUTE format('SELECT EXISTS (SELECT 1 FROM public.%I LIMIT 1)', item.tablename) INTO populated;
    IF populated THEN RETURN false; END IF;
  END LOOP;
  RETURN true;
END;
$$;
SELECT pg_temp.application_tables_empty();
SQL
) || empty_state=unknown
case "${empty_state}" in
  *t) echo 'application_tables_empty=yes' ;;
  *f) echo 'application_tables_empty=no' ;;
  *) echo 'application_tables_empty=unknown' ;;
esac

diagnosis_db="pp24891_check_$(date +%s)"
if docker exec app-db-1 createdb -U app "${diagnosis_db}" 2>/dev/null; then
  trap 'docker exec app-db-1 dropdb -U app "${diagnosis_db}" >/dev/null 2>&1' EXIT
  if schema_result=$(docker run --rm --entrypoint cat app-web /app/db/structure.sql |
      docker exec -i app-db-1 psql -U app -d "${diagnosis_db}" --single-transaction --set ON_ERROR_STOP=1 --set VERBOSITY=sqlstate 2>&1); then
    echo 'isolated_schema_load=success'
  else
    echo 'isolated_schema_load=failure'
    printf '%s\n' "${schema_result}" | grep -oE 'ERROR:  [A-Z0-9]{5}|ERROR: [A-Z0-9]{5}' | sort -u || true
  fi
fi
