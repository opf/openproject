SET search_path="public";

BEGIN;

DO
$$
DECLARE table_to_copy TEXT;
DECLARE primary_keys TEXT;
DECLARE insert_sql TEXT;
BEGIN
FOR table_to_copy IN (
  select table_name
  from information_schema.tables
  where table_schema = 'public' and table_name like 'missing_%'
  order by table_name = 'missing_projects' desc
  -- order such that project is re-created first to satisfy foreign key constraints
)
LOOP
  raise notice 'Restoring % to %', table_to_copy, REPLACE(table_to_copy, 'missing_', '');

  -- get primary keys for table
  SELECT STRING_AGG(a.attname, ',') AS TEXT INTO primary_keys
  FROM   pg_index i
  JOIN   pg_attribute a 
  ON a.attrelid = i.indrelid AND a.attnum = ANY(i.indkey)
  WHERE  i.indrelid = REPLACE(table_to_copy, 'missing_', '')::regclass
  AND    i.indisprimary;


  insert_sql := 'INSERT INTO ' || REPLACE(table_to_copy, 'missing_', '') ||
    ' (SELECT * FROM ' || table_to_copy || ')';

  -- do nothing on conflict if a primary key exists
  IF primary_keys IS NOT NULL
  THEN
   insert_sql := (insert_sql || ' ON CONFLICT ('|| primary_keys ||') DO NOTHING');
  END IF;

  EXECUTE (insert_sql || ';');
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
