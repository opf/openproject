-- Usage: psql -v secured_share=0.8 -f assign_levels.sql
-- Re-distributes security levels on an already seeded database.
UPDATE work_packages SET security_level_id = NULL WHERE security_level_id IS NOT NULL;

-- In projects that use a scheme, :secured_share of the work packages get one of the scheme's levels.
UPDATE work_packages wp
SET security_level_id = sl.id
FROM projects p
JOIN security_levels sl ON sl.security_level_scheme_id = p.security_level_scheme_id
WHERE p.id = wp.project_id
  AND p.security_level_scheme_id IS NOT NULL
  AND sl.name = 'Level ' || (1 + wp.id % 3)
  AND (hashint8(wp.id) & 1023) < (:secured_share * 1024);

VACUUM ANALYZE work_packages;
