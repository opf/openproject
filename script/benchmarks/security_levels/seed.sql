-- Usage: psql -v wp_count=5000000 -v secured_share=0.2 -f seed.sql (after schema.sql)
SELECT setseed(0.42);

INSERT INTO security_level_schemes (name) SELECT 'Scheme ' || g FROM generate_series(1, 20) g;
INSERT INTO security_levels (security_level_scheme_id, name)
  SELECT s, 'Level ' || l FROM generate_series(1, 20) s, generate_series(1, 3) l ORDER BY s, l;

-- 2000 projects, every 4th project uses a security level scheme (Jira-like: a minority of projects).
INSERT INTO projects (name, security_level_scheme_id)
  SELECT 'Project ' || g, CASE WHEN g % 4 = 0 THEN 1 + (g / 4) % 20 END FROM generate_series(1, 2000) g;

-- Work packages are skewed towards low project ids so there are a few very large projects.
INSERT INTO work_packages (type_id, project_id, subject, description, due_date, status_id, assigned_to_id,
                           priority_id, version_id, author_id, done_ratio, estimated_hours,
                           created_at, updated_at, start_date, responsible_id, parent_id)
SELECT 1 + (random() * 7)::int,
       1 + floor(1999 * random() ^ 3)::int,
       md5(g::text),
       repeat(md5(g::text), 8),
       date '2024-01-01' + (random() * 900)::int,
       1 + (random() * 9)::int,
       CASE WHEN random() < 0.8 THEN 1 + (random() * 4999)::int END,
       1 + (random() * 3)::int,
       CASE WHEN random() < 0.5 THEN 1 + (random() * 999)::int END,
       1 + (random() * 4999)::int,
       (random() * 100)::int,
       random() * 40,
       ts, ts + random() * interval '200 days',
       date '2024-01-01' + (random() * 800)::int,
       CASE WHEN random() < 0.3 THEN 1 + (random() * 4999)::int END,
       NULL
FROM generate_series(1, :wp_count) g,
     LATERAL (SELECT timestamp '2023-01-01' + random() * interval '1000 days' AS ts) t;

\ir assign_levels.sql

-- Indexes that exist in OpenProject today.
CREATE INDEX ON work_packages (type_id);
CREATE INDEX ON work_packages (project_id);
CREATE INDEX ON work_packages (due_date);
CREATE INDEX ON work_packages (category_id);
CREATE INDEX ON work_packages (status_id);
CREATE INDEX ON work_packages (assigned_to_id);
CREATE INDEX ON work_packages (version_id);
CREATE INDEX ON work_packages (author_id);
CREATE INDEX ON work_packages (created_at);
CREATE INDEX ON work_packages (updated_at);
CREATE INDEX ON work_packages (start_date);
CREATE INDEX ON work_packages (responsible_id);
CREATE INDEX ON work_packages (parent_id);
CREATE INDEX ON work_packages (project_id, updated_at);

VACUUM ANALYZE;
