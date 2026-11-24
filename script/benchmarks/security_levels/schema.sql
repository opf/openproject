-- Mirrors the columns and indexes of OpenProject's work_packages table that matter
-- for query planning (see db/migrate/tables/work_packages.rb), plus the
-- security level column introduced in db/migrate/20261124100000_create_security_levels.rb.
DROP TABLE IF EXISTS work_packages, projects, security_levels, security_level_schemes CASCADE;

CREATE TABLE security_level_schemes (id bigserial PRIMARY KEY, name text NOT NULL);
CREATE TABLE security_levels (
  id bigserial PRIMARY KEY,
  security_level_scheme_id bigint NOT NULL REFERENCES security_level_schemes,
  name text NOT NULL
);
CREATE TABLE projects (
  id bigserial PRIMARY KEY,
  name text NOT NULL,
  security_level_scheme_id bigint REFERENCES security_level_schemes
);
CREATE TABLE work_packages (
  id bigserial PRIMARY KEY,
  type_id bigint NOT NULL,
  project_id bigint NOT NULL REFERENCES projects,
  subject varchar NOT NULL DEFAULT '',
  description text,
  due_date date,
  category_id bigint,
  status_id bigint NOT NULL,
  assigned_to_id bigint,
  priority_id bigint,
  version_id bigint,
  author_id bigint NOT NULL,
  lock_version int NOT NULL DEFAULT 0,
  done_ratio int,
  estimated_hours float,
  created_at timestamp,
  updated_at timestamp,
  start_date date,
  responsible_id bigint,
  parent_id bigint,
  security_level_id bigint
);
