set search_path="public";

BEGIN;

DO
$$
DECLARE table_to_copy TEXT;
BEGIN
FOR table_to_copy IN (
  select table_name
  from information_schema.tables
  where table_schema = 'public' and table_name like 'missing_%'
)
LOOP
  raise notice 'Restoring % to %', table_to_copy, REPLACE(table_to_copy, 'missing_', '');

  EXECUTE 'INSERT INTO ' || REPLACE(table_to_copy, 'missing_', '') ||
    ' (SELECT * FROM ' || table_to_copy || ');';
END LOOP;
END;
$$;

-- remove all the missing_* tables we created after we're done
DO
$$
DECLARE table_to_remove TEXT;
BEGIN
FOR table_to_remove IN (
  select table_name
  from information_schema.tables
  where table_schema = 'public' and table_name like 'missing_%'
)
LOOP
  EXECUTE 'DROP TABLE IF EXISTS ' || table_to_remove || ' CASCADE';
END LOOP;
END;
$$;

COMMIT;
