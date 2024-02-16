SET search_path="public";
SET client_min_messages TO WARNING;

BEGIN;

CREATE SCHEMA helpers;

CREATE OR REPLACE FUNCTION helpers.missing_project_id()
RETURNS integer
AS
$$
SELECT 773 -- DEFINE MISSING PROJECT ID HERE
$$
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION helpers.camel_to_down_case(identifier TEXT)
RETURNS text
AS
$$
SELECT regexp_replace(lower(regexp_replace(identifier, E'([A-Z])', E'\_\\1','g')), E'^_', '', 'g');
$$
LANGUAGE SQL IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION helpers.pluralize(table_name TEXT)
RETURNS text
AS
$$
SELECT regexp_replace(lower(regexp_replace(table_name, E'y$', E'ie','g')), E'([^s])$', E'\\1s', 'g');
$$
LANGUAGE SQL IMMUTABLE STRICT;

-- remove all the missing_* tables we created during the last try if there are any
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

-- restore missing rows in all tables where deleted project was referenced (via project_id)
DO
$$
DECLARE source_table TEXT;
DECLARE source_column TEXT;
BEGIN

EXECUTE 'CREATE TABLE missing_projects AS (select * from projects where id = ' || helpers.missing_project_id() || ');';

FOR source_table, source_column IN (
  select table_name, column_name
  from information_schema.columns
  where table_schema = 'public' and column_name = 'project_id'
    and table_name not like '%_journals'
)
LOOP
  EXECUTE 'CREATE TABLE missing_' || source_table || ' AS (' ||
    'SELECT * from ' || source_table || ' where project_id = ' || helpers.missing_project_id() || ')';
END LOOP;

END;
$$;

-- BEGIN: restore rows related to restrored rows above
--
-- todo: This could probably be scripted to cover all relevant tables as well.
--       But for now it's easier to just list them by hand. This is the only
--       part of this script which may have to be adapted in the future to
--       account for new tables or relations.

CREATE TABLE missing_attachments AS (
  select * from attachments where container_type = 'WorkPackage' and container_id in (
    select id from missing_work_packages
  )
);

CREATE TABLE missing_meeting_contents AS (
  select * from meeting_contents where meeting_id in (select id from missing_meetings)
);

CREATE TABLE missing_messages AS (
  select * from messages where forum_id in (select id from missing_forums)
);

CREATE TABLE missing_wiki_pages AS (
  select * from wiki_pages where wiki_id in (select id from missing_wikis)
);

CREATE TABLE missing_changesets AS (
  select * from changesets where repository_id in (select id from missing_repositories)
);

CREATE TABLE missing_member_roles AS (
  select * from member_roles where member_id in (select id from missing_members)
);

-- END: restore rows related to restrored rows above

-- create missing journals and journal data
DO
$$
DECLARE journable_type_name TEXT;
DECLARE clauses TEXT;
DECLARE clause TEXT;
BEGIN

clauses := '(journable_id = ' || helpers.missing_project_id() || ' and journable_type = ''Project'')';

FOR journable_type_name IN (
  select distinct(journable_type) from journals where journable_type != 'Project'
)
LOOP
  clause := '(journable_id in (select id from missing_' ||
    helpers.pluralize(helpers.camel_to_down_case(journable_type_name)) ||
    ') and journable_type = ''' || journable_type_name ||
    ''')';
  clauses := FORMAT('%s or %s', clauses, clause);
END LOOP;

EXECUTE 'CREATE TABLE missing_journals AS (select * from journals where ' || clauses || ')';

FOR journable_type_name IN (
  select distinct(journable_type) from journals where journable_type != 'Project'
)
LOOP
  EXECUTE 'CREATE TABLE missing_' || helpers.camel_to_down_case(journable_type_name) || '_journals AS (' ||
    'select * from ' || helpers.camel_to_down_case(journable_type_name) || '_journals where id in (' ||
      'select data_id from missing_journals where journable_type = ''' || journable_type_name || '''))';
END LOOP;

END;
$$;

-- create missing custom values
DO
$$
DECLARE customized_type_name TEXT;
DECLARE query TEXT;
DECLARE clause TEXT;
BEGIN

query := 'SELECT * from custom_values where (customized_type = ''Project'' and customized_id = ' || helpers.missing_project_id() || ')';

FOR customized_type_name IN (select distinct(customized_type) from custom_values where customized_type != 'Project')
LOOP
  clause := '(customized_type = ''' || customized_type_name ||
    ''' and customized_id in (select id from missing_' ||
    helpers.pluralize(helpers.camel_to_down_case(customized_type_name)) || '))';
  query := FORMAT('%s or %s', query, clause);
END LOOP;

EXECUTE 'CREATE TABLE missing_custom_values AS (' || query || ')';

END;
$$;

DROP SCHEMA helpers CASCADE;

COMMIT;
