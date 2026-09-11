---- copyright
-- OpenProject is an open source project management software.
-- Copyright (C) the OpenProject GmbH
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License version 3.
--
-- OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
-- Copyright (C) 2006-2013 Jean-Philippe Lang
-- Copyright (C) 2010-2013 the ChiliProject Team
--
-- This program is free software; you can redistribute it and/or
-- modify it under the terms of the GNU General Public License
-- as published by the Free Software Foundation; either version 2
-- of the License, or (at your option) any later version.
--
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
--
-- You should have received a copy of the GNU General Public License
-- along with this program; if not, write to the Free Software
-- Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
--
-- See COPYRIGHT and LICENSE files for more details.
--++

DELETE FROM sessions;
DELETE FROM user_passwords;
DELETE FROM two_factor_authentication_devices;
DELETE FROM tokens;
DELETE FROM enterprise_tokens;
DELETE FROM recaptcha_entries;
DELETE FROM job_statuses;
DELETE FROM good_jobs;
DELETE FROM good_job_batches;
DELETE FROM good_job_executions;
DELETE FROM good_job_processes;
DELETE FROM good_job_settings;
DELETE FROM deploy_targets;
DELETE FROM deploy_status_checks;
DELETE FROM storages;
DELETE FROM storages_file_links_journals;
DELETE FROM project_storages;
DELETE FROM last_project_folders;
DELETE FROM remote_identities;
DELETE FROM file_links;
DELETE FROM oauth_access_tokens;
DELETE FROM oauth_access_grants;
DELETE FROM oauth_applications;
DELETE FROM oauth_client_tokens;
DELETE FROM oauth_clients;
DELETE FROM oidc_user_session_links;
DELETE FROM webhooks_events;
DELETE FROM webhooks_logs;
DELETE FROM webhooks_webhooks;
DELETE FROM paper_trail_audits;
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
  SELECT DISTINCT information_schema.columns.table_name, information_schema.columns.column_name
  FROM information_schema.columns
  WHERE information_schema.columns.table_schema = 'public'
    AND data_type IN ('character varying', 'text')
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
     'tokens',
     'job_statuses'
    )
  AND information_schema.columns.column_name NOT LIKE '%type%'
  AND NOT (information_schema.columns.table_name = 'grids' AND information_schema.columns.column_name = 'options')
  AND NOT (information_schema.columns.table_name = 'users' AND information_schema.columns.column_name = 'language')
  AND NOT (information_schema.columns.table_name = 'types' AND information_schema.columns.column_name = 'attribute_groups')
)
  LOOP
    RAISE INFO '%', CONCAT('UPDATE ', table_name, ' SET ', column_name, '=MD5(', column_name, ') WHERE NOT ', column_name, ' = '''';');
  EXECUTE CONCAT('UPDATE ', table_name, ' SET ', column_name, '=MD5(', column_name, ') WHERE NOT ', column_name, ' = '''';');

  END LOOP;
END $$;

UPDATE roles SET name = MD5(name)::varchar(30);
UPDATE enumerations SET name = MD5(name)::varchar(30);
UPDATE custom_fields SET name = MD5(name)::varchar(30);
UPDATE statuses SET name = MD5(name)::varchar(30);
UPDATE queries SET name = MD5(name)::varchar(30);
UPDATE custom_values SET value = MD5(value) WHERE custom_field_id in (SELECT id from custom_fields where field_format IN ('text', 'string'));
UPDATE customizable_journals SET value = MD5(value) WHERE custom_field_id in (SELECT id from custom_fields where field_format IN ('text', 'string'));
UPDATE grid_widgets SET options = '---\n:name: Custom title\n:text: Custom text\n' WHERE identifier = 'custom_text';
