DELETE FROM sessions;
DELETE FROM user_passwords;
DELETE FROM two_factor_authentication_devices;
DELETE FROM tokens;
DELETE FROM enterprise_tokens;
DELETE FROM settings WHERE name = 'welcome_text';
DELETE FROM settings WHERE name = 'welcome_title';
DELETE FROM settings WHERE name = 'app_title';
DELETE FROM settings WHERE name = 'mail_from';
DELETE FROM settings WHERE name = 'consent_info';

UPDATE attachments SET file_tsv = NULL, fulltext = NULL, fulltext_tsv = NULL;

DO $$
DECLARE table_name TEXT;
DECLARE column_name TEXT;
BEGIN
SET client_min_messages TO INFO;
FOR table_name, column_name IN (
	SELECT DISTINCT information_schema.columns.table_name, information_schema.columns.column_name FROM information_schema.columns WHERE information_schema.columns.table_schema = 'public' AND data_type IN ('character varying', 'text')
    AND information_schema.columns.table_name NOT IN 
	  (
	   'ar_internal_metadata', 
	   'audits', 
	   'schema_migrations', 
	   'colors', 
	   'changes',
	   'delayed_jobs', 
	   'github_check_runs', 
	   'github_pull_requests', 
	   'grid_widgets', 
	   'paper_trail_audits',
	   'custom_values', 
	   'customizable_values',
	   'custom_fields',
	   'roles',
	   'enumerations',
	   'queries',
	   'statuses',
	   'settings',
	   'role_permissions',
	   'enabled_modules',
	   'two_factor_authentication_devices',
	   'tokens'
	  ) 
	AND information_schema.columns.column_name NOT LIKE '%type%'
	AND NOT (information_schema.columns.table_name = 'grids' AND information_schema.columns.column_name = 'options')
	AND NOT (information_schema.columns.table_name = 'users' AND information_schema.columns.column_name = 'language')
	AND NOT (information_schema.columns.table_name = 'types' AND information_schema.columns.column_name = 'attribute_groups')
)	
  LOOP 
    RAISE INFO '%', CONCAT('UPDATE ', table_name, ' SET ', column_name, '=MD5(', column_name, ');');
	EXECUTE CONCAT('UPDATE ', table_name, ' SET ', column_name, '=MD5(', column_name, ');');
  
  END LOOP;
END $$;

UPDATE roles SET name = MD5(name)::varchar(30);
UPDATE enumerations SET name = MD5(name)::varchar(30);
UPDATE custom_fields SET name = MD5(name)::varchar(30);
UPDATE statuses SET name = MD5(name)::varchar(30);
UPDATE queries SET name = MD5(name)::varchar(30);
UPDATE custom_values SET value = MD5(value) WHERE custom_field_id in (SELECT id from custom_fields where field_format IN ('text', 'string'));
UPDATE customizable_journals SET value = MD5(value) WHERE custom_field_id in (SELECT id from custom_fields where field_format IN ('text', 'string'));

-- TODO: this sets all notes that originally had '' to that value again
--       Such values should be excluded from being md5ed. 
UPDATE journals set notes = '' where notes = 'd41d8cd98f00b204e9800998ecf8427e';
