set search_path="public";

BEGIN;

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

CREATE TABLE missing_projects AS (
  select * from projects where id = 773
);

UPDATE missing_projects SET lft = null, rgt = null;

CREATE TABLE missing_work_packages AS (
  select * from work_packages where project_id = 773
);
CREATE TABLE missing_attachments AS (
  select * from attachments where container_type = 'WorkPackage' and container_id in (
    select id from missing_work_packages
  )
);
CREATE TABLE missing_meetings AS (
  select * from meetings where project_id = 773
);
CREATE TABLE missing_meeting_contents AS (
  select * from meeting_contents where meeting_id in (select id from missing_meetings)
);
CREATE TABLE missing_documents AS (
  select * from documents where project_id = 773
);
CREATE TABLE missing_forums AS (
  select * from forums where project_id = 773
);
CREATE TABLE missing_messages AS (
  select * from messages where forum_id in (select id from missing_forums)
);
CREATE TABLE missing_wikis AS (
  select * from wikis where project_id = 773
);
CREATE TABLE missing_wiki_pages AS (
  select * from wiki_pages where wiki_id in (select id from missing_wikis)
);
CREATE TABLE missing_budgets AS (
  select * from budgets where project_id = 773
);
CREATE TABLE missing_repositories AS (
  select * from repositories where project_id = 773
);
CREATE TABLE missing_changesets AS (
  select * from changesets where repository_id in (select id from missing_repositories)
);
CREATE TABLE missing_news AS (
  select * from news where project_id = 773
);
CREATE TABLE missing_time_entries AS (
  select * from time_entries where project_id = 773
);
-- along projects, work packages and attachments, plus the respective journals,
-- we would technically also have to restore the following:
--   budgets, changesets, news, time entries
CREATE TABLE missing_journals AS (
  select * from journals where
    (journable_id = 773 and journable_type = 'Project') or
    (journable_id in (select id from missing_work_packages) and journable_type = 'WorkPackage') or
    (journable_id in (select id from missing_attachments) and journable_type = 'Attachment') or
    (journable_id in (select id from missing_meetings) and journable_type = 'Meeting') or
    (journable_id in (select id from missing_meeting_contents) and journable_type = 'MeetingContent') or
    (journable_id in (select id from missing_documents) and journable_type = 'Document') or
    (journable_id in (select id from missing_messages) and journable_type = 'Message') or
    (journable_id in (select id from missing_wiki_pages) and journable_type = 'WikiPage') or
    (journable_id in (select id from missing_budgets) and journable_type = 'Budget') or
    (journable_id in (select id from missing_changesets) and journable_type = 'Changeset') or
    (journable_id in (select id from missing_news) and journable_type = 'News') or
    (journable_id in (select id from missing_time_entries) and journable_type = 'TimeEntry')
);
CREATE TABLE missing_project_journals AS (
  select * from project_journals where id in (
    select data_id from missing_journals where journable_type = 'Project'
  )
);
CREATE TABLE missing_work_package_journals AS (
  select * from work_package_journals where id in (
    select data_id from missing_journals where journable_type = 'WorkPackage'
  )
);
CREATE TABLE missing_attachment_journals AS (
  select * from attachment_journals where id in (
    select data_id from missing_journals where journable_type = 'Attachment'
  )
);
CREATE TABLE missing_meeting_journals AS (
  select * from meeting_journals where id in (
    select data_id from missing_journals where journable_type = 'Meeting'
  )
);
CREATE TABLE missing_meeting_content_journals AS (
  select * from meeting_content_journals where id in (
    select data_id from missing_journals where journable_type = 'MeetingContent'
  )
);
CREATE TABLE missing_document_journals AS (
  select * from document_journals where id in (
    select data_id from missing_journals where journable_type = 'Document'
  )
);
CREATE TABLE missing_message_journals AS (
  select * from message_journals where id in (
    select data_id from missing_journals where journable_type = 'Message'
  )
);
CREATE TABLE missing_wiki_page_journals AS (
  select * from wiki_page_journals where id in (
    select data_id from missing_journals where journable_type = 'WikiPage'
  )
);
CREATE TABLE missing_budget_journals AS (
  select * from budget_journals where id in (
    select data_id from missing_journals where journable_type = 'Budget'
  )
);
CREATE TABLE missing_changeset_journals AS (
  select * from changeset_journals where id in (
    select data_id from missing_journals where journable_type = 'Changeset'
  )
);
CREATE TABLE missing_news_journals AS (
  select * from news_journals where id in (
    select data_id from missing_journals where journable_type = 'News'
  )
);
CREATE TABLE missing_time_entry_journals AS (
  select * from time_entry_journals where id in (
    select data_id from missing_journals where journable_type = 'TimeEntry'
  )
);

CREATE TABLE missing_custom_values AS (
  select * from custom_values where
    (customized_type = 'Project' and customized_id = 773) or
    (customized_type = 'WorkPackage' and customized_id in (select id from missing_work_packages))
    -- only these are present in the dump, but could also include versions, groups, users, spent time, ...
    -- in the final version we should just loop over `distinct(customized_type)`
);

CREATE TABLE missing_enabled_modules AS (
  select * from enabled_modules where project_id = 773
);

CREATE TABLE missing_versions AS (
  select * from versions where project_id = 773
);

CREATE TABLE missing_categories AS (
  select * from categories where project_id = 773
);

CREATE TABLE missing_cost_entries AS (
  select * from cost_entries where project_id = 773
);

CREATE TABLE missing_cost_queries AS (
  select * from cost_queries where project_id = 773
);

CREATE TABLE missing_custom_actions_projects AS (
  select * from custom_actions_projects where project_id = 773
);

CREATE TABLE missing_custom_fields_projects AS (
  select * from custom_fields_projects where project_id = 773
);

CREATE TABLE missing_done_statuses_for_project AS (
  select * from done_statuses_for_project where project_id = 773
);

CREATE TABLE missing_grids AS (
  select * from grids where project_id = 773
);

CREATE TABLE missing_members AS (
  select * from members where project_id = 773
);

CREATE TABLE missing_notification_settings as (
  select * from notification_settings where project_id = 773
);

CREATE TABLE missing_rates as (
  select * from rates where project_id = 773
);

CREATE TABLE missing_projects_types as (
  select * from projects_types where project_id = 773
);

CREATE TABLE missing_queries AS (
  select * from queries where project_id = 773
);

CREATE TABLE missing_time_entry_activities_projects AS (
  select * from time_entry_activities_projects where project_id = 773
);

CREATE TABLE missing_webhooks_projects AS (
  select * from webhooks_projects where project_id = 773
);

CREATE TABLE missing_project_storages AS (
  select * from project_storages where project_id = 773
);

CREATE TABLE missing_notifications AS (
  select * from notifications where project_id = 773
);

CREATE TABLE missing_version_settings AS (
  select * from version_settings where project_id = 773
);

CREATE TABLE missing_enumerations AS (
  select * from enumerations where project_id = 773
);

CREATE TABLE missing_ifc_models AS (
  select * from ifc_models where project_id = 773
);

COMMIT;
