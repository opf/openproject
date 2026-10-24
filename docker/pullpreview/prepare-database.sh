#!/bin/bash
set -euo pipefail

if ! docker container inspect app-db-1 >/dev/null 2>&1; then
  exit 0
fi

schema_present=$(docker exec app-db-1 psql -U app -d app -qtAX -v ON_ERROR_STOP=1 \
  -c "SELECT to_regclass('public.schema_migrations') IS NOT NULL")
if [[ "${schema_present}" != t ]]; then
  exit 0
fi

migration_count() {
  docker exec app-db-1 psql -U app -d app -qtAX -v ON_ERROR_STOP=1 \
    -c 'SELECT count(*) FROM public.schema_migrations'
}

application_tables_empty() {
  local result
  result=$(docker exec -i app-db-1 psql -U app -d app -qtAX -v ON_ERROR_STOP=1 <<'SQL'
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
  )
  [[ "${result}" == t ]]
}

if [[ "$(migration_count)" != 0 ]]; then
  exit 0
fi
if ! application_tables_empty; then
  echo 'Refusing schema recovery: application data exists.' >&2
  exit 1
fi

stopped_containers=()
resume_on_failure() {
  local status=$?
  if [[ "${status}" != 0 && ${#stopped_containers[@]} -gt 0 ]]; then
    docker start "${stopped_containers[@]}" >/dev/null 2>&1 || true
  fi
}
trap resume_on_failure EXIT

for container in app-web-1 app-worker-1; do
  if docker container inspect "${container}" >/dev/null 2>&1; then
    docker stop "${container}" >/dev/null
    stopped_containers+=("${container}")
  fi
done

if [[ "$(migration_count)" != 0 ]]; then
  exit 0
fi
if ! application_tables_empty; then
  echo 'Refusing schema recovery: application data appeared during startup.' >&2
  exit 1
fi

umask 077
recovery_dir=$(mktemp -d /var/tmp/pullpreview-recovery-24891.XXXXXX)
docker exec app-db-1 pg_dump -U app -d app --format=custom > "${recovery_dir}/before.dump"
test -s "${recovery_dir}/before.dump"
docker run --rm --entrypoint cat app-web /app/db/structure.sql > "${recovery_dir}/schema.sql"
test -s "${recovery_dir}/schema.sql"

{
  printf 'DROP SCHEMA public CASCADE;\nCREATE SCHEMA public AUTHORIZATION app;\n'
  cat "${recovery_dir}/schema.sql"
} | docker exec -i app-db-1 psql -U app -d app -qX --single-transaction -v ON_ERROR_STOP=1 >/dev/null

if [[ "$(migration_count)" == 0 ]]; then
  echo 'Schema recovery did not restore migration history.' >&2
  exit 1
fi
echo 'Recovered the empty preview schema. A backup is retained on the preview instance.'
