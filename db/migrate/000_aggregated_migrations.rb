#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See doc/COPYRIGHT.rdoc for more details.
#++

# This migration aggregates the migrations detailed in the @@migrations
# heredoc
class AggregatedMigrations < ActiveRecord::Migration[4.2]
  class IncompleteMigrationsError < ::StandardError
  end

  @@migrations = <<-MIGRATIONS
    001_setup.rb
    002_issue_move.rb
    003_issue_add_note.rb
    004_export_pdf.rb
    005_issue_start_date.rb
    006_calendar_and_activity.rb
    007_create_journals.rb
    008_create_user_preferences.rb
    009_add_hide_mail_pref.rb
    010_create_comments.rb
    011_add_news_comments_count.rb
    012_add_comments_permissions.rb
    013_create_queries.rb
    014_add_queries_permissions.rb
    015_create_repositories.rb
    016_add_repositories_permissions.rb
    017_create_settings.rb
    018_set_doc_and_files_notifications.rb
    019_add_issue_status_position.rb
    020_add_role_position.rb
    021_add_tracker_position.rb
    022_serialize_possibles_values.rb
    023_add_tracker_is_in_roadmap.rb
    024_add_roadmap_permission.rb
    025_add_search_permission.rb
    026_add_repository_login_and_password.rb
    027_create_wikis.rb
    028_create_wiki_pages.rb
    029_create_wiki_contents.rb
    030_add_projects_feeds_permissions.rb
    031_add_repository_root_url.rb
    032_create_time_entries.rb
    033_add_timelog_permissions.rb
    034_create_changesets.rb
    035_create_changes.rb
    036_add_changeset_commit_date.rb
    037_add_project_identifier.rb
    038_add_custom_field_is_filter.rb
    039_create_watchers.rb
    040_create_changesets_issues.rb
    041_rename_comment_to_comments.rb
    042_create_issue_relations.rb
    043_add_relations_permissions.rb
    044_set_language_length_to_five.rb
    045_create_boards.rb
    046_create_messages.rb
    047_add_boards_permissions.rb
    048_allow_null_version_effective_date.rb
    049_add_wiki_destroy_page_permission.rb
    050_add_wiki_attachments_permissions.rb
    051_add_project_status.rb
    052_add_changes_revision.rb
    053_add_changes_branch.rb
    054_add_changesets_scmid.rb
    055_add_repositories_type.rb
    056_add_repositories_changes_permission.rb
    057_add_versions_wiki_page_title.rb
    058_add_issue_categories_assigned_to_id.rb
    059_add_roles_assignable.rb
    060_change_changesets_committer_limit.rb
    061_add_roles_builtin.rb
    062_insert_builtin_roles.rb
    063_add_roles_permissions.rb
    064_drop_permissions.rb
    065_add_settings_updated_on.rb
    066_add_custom_value_customized_index.rb
    067_create_wiki_redirects.rb
    068_create_enabled_modules.rb
    069_add_issues_estimated_hours.rb
    070_change_attachments_content_type_limit.rb
    071_add_queries_column_names.rb
    072_add_enumerations_position.rb
    073_add_enumerations_is_default.rb
    074_add_auth_sources_tls.rb
    075_add_members_mail_notification.rb
    076_allow_null_position.rb
    077_remove_issue_statuses_html_color.rb
    078_add_custom_fields_position.rb
    079_add_user_preferences_time_zone.rb
    080_add_users_type.rb
    081_create_projects_trackers.rb
    082_add_messages_locked.rb
    083_add_messages_sticky.rb
    084_change_auth_sources_account_limit.rb
    085_add_role_tracker_old_status_index_to_workflows.rb
    086_add_custom_fields_searchable.rb
    087_change_projects_description_to_text.rb
    088_add_custom_fields_default_value.rb
    089_add_attachments_description.rb
    090_change_versions_name_limit.rb
    091_change_changesets_revision_to_string.rb
    092_change_changes_from_revision_to_string.rb
    093_add_wiki_pages_protected.rb
    094_change_projects_homepage_limit.rb
    095_add_wiki_pages_parent_id.rb
    096_add_commit_access_permission.rb
    097_add_view_wiki_edits_permission.rb
    098_set_topic_authors_as_watchers.rb
    099_add_delete_wiki_pages_attachments_permission.rb
    100_add_changesets_user_id.rb
    101_populate_changesets_user_id.rb
    102_add_custom_fields_editable.rb
    103_set_custom_fields_editable.rb
    104_add_projects_lft_and_rgt.rb
    105_build_projects_tree.rb
    106_remove_projects_projects_count.rb
    107_add_open_id_authentication_tables.rb
    108_add_identity_url_to_users.rb
    20090214190337_add_watchers_user_id_type_index.rb
    20090312172426_add_queries_sort_criteria.rb
    20090312194159_add_projects_trackers_unique_index.rb
    20090318181151_extend_settings_name.rb
    20090323224724_add_type_to_enumerations.rb
    20090401221305_update_enumerations_to_sti.rb
    20090401231134_add_active_field_to_enumerations.rb
    20090403001910_add_project_to_enumerations.rb
    20090406161854_add_parent_id_to_enumerations.rb
    20090425161243_add_queries_group_by.rb
    20090503121501_create_member_roles.rb
    20090503121505_populate_member_roles.rb
    20090503121510_drop_members_role_id.rb
    20090614091200_fix_messages_sticky_null.rb
    20090704172350_populate_users_type.rb
    20090704172355_create_groups_users.rb
    20090704172358_add_member_roles_inherited_from.rb
    20091010093521_fix_users_custom_values.rb
    20091017212227_add_missing_indexes_to_workflows.rb
    20091017212457_add_missing_indexes_to_custom_fields_projects.rb
    20091017212644_add_missing_indexes_to_messages.rb
    20091017212938_add_missing_indexes_to_repositories.rb
    20091017213027_add_missing_indexes_to_comments.rb
    20091017213113_add_missing_indexes_to_enumerations.rb
    20091017213151_add_missing_indexes_to_wiki_pages.rb
    20091017213228_add_missing_indexes_to_watchers.rb
    20091017213257_add_missing_indexes_to_auth_sources.rb
    20091017213332_add_missing_indexes_to_documents.rb
    20091017213444_add_missing_indexes_to_tokens.rb
    20091017213536_add_missing_indexes_to_changesets.rb
    20091017213642_add_missing_indexes_to_issue_categories.rb
    20091017213716_add_missing_indexes_to_member_roles.rb
    20091017213757_add_missing_indexes_to_boards.rb
    20091017213835_add_missing_indexes_to_user_preferences.rb
    20091017213910_add_missing_indexes_to_issues.rb
    20091017214015_add_missing_indexes_to_members.rb
    20091017214107_add_missing_indexes_to_custom_fields.rb
    20091017214136_add_missing_indexes_to_queries.rb
    20091017214236_add_missing_indexes_to_time_entries.rb
    20091017214308_add_missing_indexes_to_news.rb
    20091017214336_add_missing_indexes_to_users.rb
    20091017214406_add_missing_indexes_to_attachments.rb
    20091017214440_add_missing_indexes_to_wiki_contents.rb
    20091017214519_add_missing_indexes_to_custom_values.rb
    20091017214611_add_missing_indexes_to_journals.rb
    20091017214644_add_missing_indexes_to_issue_relations.rb
    20091017214720_add_missing_indexes_to_wiki_redirects.rb
    20091017214750_add_missing_indexes_to_custom_fields_trackers.rb
    20091025163651_add_activity_indexes.rb
    20091108092559_add_versions_status.rb
    20091114105931_add_view_issues_permission.rb
    20091123212029_add_default_done_ratio_to_issue_status.rb
    20091205124427_add_versions_sharing.rb
    20091220183509_add_lft_and_rgt_indexes_to_projects.rb
    20091220183727_add_index_to_settings_name.rb
    20091220184736_add_indexes_to_issue_status.rb
    20091225164732_remove_enumerations_opt.rb
    20091227112908_change_wiki_contents_text_limit.rb
    20100129193402_change_users_mail_notification_to_string.rb
    20100129193813_update_mail_notification_values.rb
    20100221100219_add_index_on_changesets_scmid.rb
    20100313132032_add_issues_nested_sets_columns.rb
    20100313171051_add_index_on_issues_nested_set.rb
    20100705164950_change_changes_path_length_limit.rb
    20100714111651_prepare_journals_for_acts_as_journalized.rb
    20100714111652_update_journals_for_acts_as_journalized.rb
    20100714111653_build_initial_journals_for_acts_as_journalized.rb
    20100714111654_add_changes_from_journal_details_for_acts_as_journalized.rb
    20100804112053_merge_wiki_versions_with_journals.rb
    20100819172912_enable_calendar_and_gantt_modules_where_appropriate.rb
    20101104182107_add_unique_index_on_members.rb
    20101107130441_add_custom_fields_visible.rb
    20101114115114_change_projects_name_limit.rb
    20101114115359_change_projects_identifier_limit.rb
    20110220160626_add_workflows_assignee_and_author.rb
    20110223180944_add_users_salt.rb
    20110223180953_salt_user_passwords.rb
    20110224000000_add_repositories_path_encoding.rb
    20110226120112_change_repositories_password_limit.rb
    20110226120132_change_auth_sources_account_password_limit.rb
    20110227125750_change_journal_details_values_to_text.rb
    20110228000000_add_repositories_log_encoding.rb
    20110228000100_copy_repositories_log_encoding.rb
    20110314014400_add_start_date_to_versions.rb
    20110401192910_add_index_to_users_type.rb
    20110519194936_remove_comments_from_wiki_content.rb
    20110729125454_remove_double_initial_wiki_content_journals.rb
  MIGRATIONS

  def up
    intersection = aggregated_versions & all_versions

    if intersection == []

      # No migrations that this migration aggregates have already been
      # applied. In this case, run the aggregated migration.
      run_aggregated_migrations

    elsif intersection == aggregated_versions

      # All migrations that this migration aggregates have already
      # been applied. In this case, remove the information about those
      # migrations from the schema_migrations table and we're done.
      execute <<-SQL + (intersection.map { |version| <<-CONDITIONS }).join(' OR ')
        DELETE FROM
          #{quoted_schema_migrations_table_name}
        WHERE
      SQL
        #{version_column_for_comparison} = #{quote_value(version.to_s)}
      CONDITIONS

    else

      missing = aggregated_versions - intersection

      # Only a part of the migrations that this migration aggregates
      # have already been applied. In this case, fail miserably.
      raise IncompleteMigrationsError, <<-MESSAGE.split("\n").map(&:strip!).join(' ') + "\n"
        It appears you are migrating from an incompatible version of
        ChiliProject. Your database has only some migrations from ChiliProject <
        v2.4.0. Please update your database to the schema of ChiliProject
        v2.4.0 and run the OpenProject migrations again. The following
        migrations are missing: #{missing}
      MESSAGE

    end
  end

  def down
    # TODO.
    raise ActiveRecord::IrreversibleMigration, 'Kind of still a TODO.'
  end

  private

  def run_aggregated_migrations
    create_table 'attachments', force: true do |t|
      t.integer 'container_id',                 default: 0,  null: false
      t.string 'container_type', limit: 30, default: '', null: false
      t.string 'filename',                     default: '', null: false
      t.string 'disk_filename',                default: '', null: false
      t.integer 'filesize',                     default: 0,  null: false
      t.string 'content_type',                 default: ''
      t.string 'digest',         limit: 40, default: '', null: false
      t.integer 'downloads',                    default: 0,  null: false
      t.integer 'author_id',                    default: 0,  null: false
      t.datetime 'created_on'
      t.string 'description'
    end

    add_index 'attachments', ['author_id'], name: 'index_attachments_on_author_id'
    add_index 'attachments', ['container_id', 'container_type'], name: 'index_attachments_on_container_id_and_container_type'
    add_index 'attachments', ['created_on'], name: 'index_attachments_on_created_on'

    create_table 'auth_sources', force: true do |t|
      t.string 'type',              limit: 30, default: '',    null: false
      t.string 'name',              limit: 60, default: '',    null: false
      t.string 'host',              limit: 60
      t.integer 'port'
      t.string 'account'
      t.string 'account_password',                default: ''
      t.string 'base_dn'
      t.string 'attr_login',        limit: 30
      t.string 'attr_firstname',    limit: 30
      t.string 'attr_lastname',     limit: 30
      t.string 'attr_mail',         limit: 30
      t.boolean 'onthefly_register',               default: false, null: false
      t.boolean 'tls',                             default: false, null: false
    end

    add_index 'auth_sources', ['id', 'type'], name: 'index_auth_sources_on_id_and_type'

    create_table 'boards', force: true do |t|
      t.integer 'project_id',                      null: false
      t.string 'name',            default: '', null: false
      t.string 'description'
      t.integer 'position',        default: 1
      t.integer 'topics_count',    default: 0,  null: false
      t.integer 'messages_count',  default: 0,  null: false
      t.integer 'last_message_id'
    end

    add_index 'boards', ['last_message_id'], name: 'index_boards_on_last_message_id'
    add_index 'boards', ['project_id'], name: 'boards_project_id'

    create_table 'changes', force: true do |t|
      t.integer 'changeset_id',                               null: false
      t.string 'action',        limit: 1, default: '', null: false
      t.text 'path',                                       null: false
      t.text 'from_path'
      t.string 'from_revision'
      t.string 'revision'
      t.string 'branch'
    end

    add_index 'changes', ['changeset_id'], name: 'changesets_changeset_id'

    create_table 'changesets', force: true do |t|
      t.integer 'repository_id', null: false
      t.string 'revision',      null: false
      t.string 'committer'
      t.datetime 'committed_on',  null: false
      t.text 'comments'
      t.date 'commit_date'
      t.string 'scmid'
      t.integer 'user_id'
    end

    add_index 'changesets', ['committed_on'], name: 'index_changesets_on_committed_on'
    add_index 'changesets', ['repository_id', 'revision'], name: 'changesets_repos_rev', unique: true
    add_index 'changesets', ['repository_id', 'scmid'], name: 'changesets_repos_scmid'
    add_index 'changesets', ['repository_id'], name: 'index_changesets_on_repository_id'
    add_index 'changesets', ['user_id'], name: 'index_changesets_on_user_id'

    create_table 'changesets_issues', id: false, force: true do |t|
      t.integer 'changeset_id', null: false
      t.integer 'issue_id',     null: false
    end

    add_index 'changesets_issues', ['changeset_id', 'issue_id'], name: 'changesets_issues_ids', unique: true

    create_table 'comments', force: true do |t|
      t.string 'commented_type', limit: 30, default: '', null: false
      t.integer 'commented_id',                 default: 0,  null: false
      t.integer 'author_id',                    default: 0,  null: false
      t.text 'comments'
      t.datetime 'created_on',                                   null: false
      t.datetime 'updated_on',                                   null: false
    end

    add_index 'comments', ['author_id'], name: 'index_comments_on_author_id'
    add_index 'comments', ['commented_id', 'commented_type'], name: 'index_comments_on_commented_id_and_commented_type'

    create_table 'custom_fields', force: true do |t|
      t.string 'type',            limit: 30, default: '',    null: false
      t.string 'name',            limit: 30, default: '',    null: false
      t.string 'field_format',    limit: 30, default: '',    null: false
      t.text 'possible_values'
      t.string 'regexp',                        default: ''
      t.integer 'min_length',                    default: 0,     null: false
      t.integer 'max_length',                    default: 0,     null: false
      t.boolean 'is_required',                   default: false, null: false
      t.boolean 'is_for_all',                    default: false, null: false
      t.boolean 'is_filter',                     default: false, null: false
      t.integer 'position',                      default: 1
      t.boolean 'searchable',                    default: false
      t.text 'default_value'
      t.boolean 'editable',                      default: true
      t.boolean 'visible',                       default: true,  null: false
    end

    add_index 'custom_fields', ['id', 'type'], name: 'index_custom_fields_on_id_and_type'

    create_table 'custom_fields_projects', id: false, force: true do |t|
      t.integer 'custom_field_id', default: 0, null: false
      t.integer 'project_id',      default: 0, null: false
    end

    add_index 'custom_fields_projects', ['custom_field_id', 'project_id'], name: 'index_custom_fields_projects_on_custom_field_id_and_project_id'

    create_table 'custom_fields_trackers', id: false, force: true do |t|
      t.integer 'custom_field_id', default: 0, null: false
      t.integer 'tracker_id',      default: 0, null: false
    end

    add_index 'custom_fields_trackers', ['custom_field_id', 'tracker_id'], name: 'index_custom_fields_trackers_on_custom_field_id_and_tracker_id'

    create_table 'custom_values', force: true do |t|
      t.string 'customized_type', limit: 30, default: '', null: false
      t.integer 'customized_id',                 default: 0,  null: false
      t.integer 'custom_field_id',               default: 0,  null: false
      t.text 'value'
    end

    add_index 'custom_values', ['custom_field_id'], name: 'index_custom_values_on_custom_field_id'
    add_index 'custom_values', ['customized_type', 'customized_id'], name: 'custom_values_customized'

    create_table 'documents', force: true do |t|
      t.integer 'project_id',                default: 0,  null: false
      t.integer 'category_id',               default: 0,  null: false
      t.string 'title',       limit: 60, default: '', null: false
      t.text 'description'
      t.datetime 'created_on'
    end

    add_index 'documents', ['category_id'], name: 'index_documents_on_category_id'
    add_index 'documents', ['created_on'], name: 'index_documents_on_created_on'
    add_index 'documents', ['project_id'], name: 'documents_project_id'

    create_table 'enabled_modules', force: true do |t|
      t.integer 'project_id'
      t.string 'name',       null: false
    end

    add_index 'enabled_modules', ['project_id'], name: 'enabled_modules_project_id'

    create_table 'enumerations', force: true do |t|
      t.string 'name',       limit: 30, default: '',    null: false
      t.integer 'position',                 default: 1
      t.boolean 'is_default',               default: false, null: false
      t.string 'type'
      t.boolean 'active',                   default: true,  null: false
      t.integer 'project_id'
      t.integer 'parent_id'
    end

    add_index 'enumerations', ['id', 'type'], name: 'index_enumerations_on_id_and_type'
    add_index 'enumerations', ['project_id'], name: 'index_enumerations_on_project_id'

    create_table 'groups_users', id: false, force: true do |t|
      t.integer 'group_id', null: false
      t.integer 'user_id',  null: false
    end

    add_index 'groups_users', ['group_id', 'user_id'], name: 'groups_users_ids', unique: true

    create_table 'issue_categories', force: true do |t|
      t.integer 'project_id',                   default: 0,  null: false
      t.string 'name',           limit: 30, default: '', null: false
      t.integer 'assigned_to_id'
    end

    add_index 'issue_categories', ['assigned_to_id'], name: 'index_issue_categories_on_assigned_to_id'
    add_index 'issue_categories', ['project_id'], name: 'issue_categories_project_id'

    create_table 'issue_relations', force: true do |t|
      t.integer 'issue_from_id',                 null: false
      t.integer 'issue_to_id',                   null: false
      t.string 'relation_type', default: '', null: false
      t.integer 'delay'
    end

    add_index 'issue_relations', ['issue_from_id'], name: 'index_issue_relations_on_issue_from_id'
    add_index 'issue_relations', ['issue_to_id'], name: 'index_issue_relations_on_issue_to_id'

    create_table 'issue_statuses', force: true do |t|
      t.string 'name',               limit: 30, default: '',    null: false
      t.boolean 'is_closed',                        default: false, null: false
      t.boolean 'is_default',                       default: false, null: false
      t.integer 'position',                         default: 1
      t.integer 'default_done_ratio'
    end

    add_index 'issue_statuses', ['is_closed'], name: 'index_issue_statuses_on_is_closed'
    add_index 'issue_statuses', ['is_default'], name: 'index_issue_statuses_on_is_default'
    add_index 'issue_statuses', ['position'], name: 'index_issue_statuses_on_position'

    create_table 'issues', force: true do |t|
      t.integer 'tracker_id',       default: 0,  null: false
      t.integer 'project_id',       default: 0,  null: false
      t.string 'subject',          default: '', null: false
      t.text 'description'
      t.date 'due_date'
      t.integer 'category_id'
      t.integer 'status_id',        default: 0,  null: false
      t.integer 'assigned_to_id'
      t.integer 'priority_id',      default: 0,  null: false
      t.integer 'fixed_version_id'
      t.integer 'author_id',        default: 0,  null: false
      t.integer 'lock_version',     default: 0,  null: false
      t.datetime 'created_on'
      t.datetime 'updated_on'
      t.date 'start_date'
      t.integer 'done_ratio',       default: 0,  null: false
      t.float 'estimated_hours'
      t.integer 'parent_id'
      t.integer 'root_id'
      t.integer 'lft'
      t.integer 'rgt'
    end

    add_index 'issues', ['assigned_to_id'], name: 'index_issues_on_assigned_to_id'
    add_index 'issues', ['author_id'], name: 'index_issues_on_author_id'
    add_index 'issues', ['category_id'], name: 'index_issues_on_category_id'
    add_index 'issues', ['created_on'], name: 'index_issues_on_created_on'
    add_index 'issues', ['fixed_version_id'], name: 'index_issues_on_fixed_version_id'
    add_index 'issues', ['priority_id'], name: 'index_issues_on_priority_id'
    add_index 'issues', ['project_id'], name: 'issues_project_id'
    add_index 'issues', ['root_id', 'lft', 'rgt'], name: 'index_issues_on_root_id_and_lft_and_rgt'
    add_index 'issues', ['status_id'], name: 'index_issues_on_status_id'
    add_index 'issues', ['tracker_id'], name: 'index_issues_on_tracker_id'

    create_table 'journal_details', force: true do |t|
      t.integer 'journal_id',               default: 0,  null: false
      t.string 'property',   limit: 30, default: '', null: false
      t.string 'prop_key',   limit: 30, default: '', null: false
      t.text 'old_value'
      t.text 'value'
    end

    add_index 'journal_details', ['journal_id'], name: 'journal_details_journal_id'

    create_table 'journals', force: true do |t|
      t.integer 'journaled_id',  default: 0, null: false
      t.integer 'user_id',       default: 0, null: false
      t.text 'notes'
      t.datetime 'created_at',                   null: false
      t.integer 'version',       default: 0, null: false
      t.string 'activity_type'
      t.text 'changes'
      t.string 'type'
    end

    add_index 'journals', ['activity_type'], name: 'index_journals_on_activity_type'
    add_index 'journals', ['created_at'], name: 'index_journals_on_created_at'
    add_index 'journals', ['created_at'], name: 'index_journals_on_created_on'
    add_index 'journals', ['journaled_id'], name: 'index_journals_on_journaled_id'
    add_index 'journals', ['journaled_id'], name: 'index_journals_on_journalized_id'
    add_index 'journals', ['type'], name: 'index_journals_on_type'
    add_index 'journals', ['user_id'], name: 'index_journals_on_user_id'

    create_table 'member_roles', force: true do |t|
      t.integer 'member_id',      null: false
      t.integer 'role_id',        null: false
      t.integer 'inherited_from'
    end

    add_index 'member_roles', ['member_id'], name: 'index_member_roles_on_member_id'
    add_index 'member_roles', ['role_id'], name: 'index_member_roles_on_role_id'

    create_table 'members', force: true do |t|
      t.integer 'user_id',           default: 0,     null: false
      t.integer 'project_id',        default: 0,     null: false
      t.datetime 'created_on'
      t.boolean 'mail_notification', default: false, null: false
    end

    add_index 'members', ['project_id'], name: 'index_members_on_project_id'
    add_index 'members', ['user_id', 'project_id'], name: 'index_members_on_user_id_and_project_id', unique: true
    add_index 'members', ['user_id'], name: 'index_members_on_user_id'

    create_table 'messages', force: true do |t|
      t.integer 'board_id',                         null: false
      t.integer 'parent_id'
      t.string 'subject',       default: '',    null: false
      t.text 'content'
      t.integer 'author_id'
      t.integer 'replies_count', default: 0,     null: false
      t.integer 'last_reply_id'
      t.datetime 'created_on',                       null: false
      t.datetime 'updated_on',                       null: false
      t.boolean 'locked',        default: false
      t.integer 'sticky',        default: 0
    end

    add_index 'messages', ['author_id'], name: 'index_messages_on_author_id'
    add_index 'messages', ['board_id'], name: 'messages_board_id'
    add_index 'messages', ['created_on'], name: 'index_messages_on_created_on'
    add_index 'messages', ['last_reply_id'], name: 'index_messages_on_last_reply_id'
    add_index 'messages', ['parent_id'], name: 'messages_parent_id'

    create_table 'news', force: true do |t|
      t.integer 'project_id'
      t.string 'title',          limit: 60, default: '', null: false
      t.string 'summary',                      default: ''
      t.text 'description'
      t.integer 'author_id',                    default: 0,  null: false
      t.datetime 'created_on'
      t.integer 'comments_count',               default: 0,  null: false
    end

    add_index 'news', ['author_id'], name: 'index_news_on_author_id'
    add_index 'news', ['created_on'], name: 'index_news_on_created_on'
    add_index 'news', ['project_id'], name: 'news_project_id'

    create_table 'open_id_authentication_associations', force: true do |t|
      t.integer 'issued'
      t.integer 'lifetime'
      t.string 'handle'
      t.string 'assoc_type'
      t.binary 'server_url'
      t.binary 'secret'
    end

    create_table 'open_id_authentication_nonces', force: true do |t|
      t.integer 'timestamp',  null: false
      t.string 'server_url'
      t.string 'salt',       null: false
    end

    create_table 'projects', force: true do |t|
      t.string 'name',        default: '',   null: false
      t.text 'description'
      t.string 'homepage',    default: ''
      t.boolean 'is_public',   default: true, null: false
      t.integer 'parent_id'
      t.datetime 'created_on'
      t.datetime 'updated_on'
      t.string 'identifier'
      t.integer 'status',      default: 1,    null: false
      t.integer 'lft'
      t.integer 'rgt'
    end

    add_index 'projects', ['lft'], name: 'index_projects_on_lft'
    add_index 'projects', ['rgt'], name: 'index_projects_on_rgt'

    create_table 'projects_trackers', id: false, force: true do |t|
      t.integer 'project_id', default: 0, null: false
      t.integer 'tracker_id', default: 0, null: false
    end

    add_index 'projects_trackers', ['project_id', 'tracker_id'], name: 'projects_trackers_unique', unique: true
    add_index 'projects_trackers', ['project_id'], name: 'projects_trackers_project_id'

    create_table 'queries', force: true do |t|
      t.integer 'project_id'
      t.string 'name',          default: '',    null: false
      t.text 'filters'
      t.integer 'user_id',       default: 0,     null: false
      t.boolean 'is_public',     default: false, null: false
      t.text 'column_names'
      t.text 'sort_criteria'
      t.string 'group_by'
    end

    add_index 'queries', ['project_id'], name: 'index_queries_on_project_id'
    add_index 'queries', ['user_id'], name: 'index_queries_on_user_id'

    create_table 'repositories', force: true do |t|
      t.integer 'project_id',                  default: 0,  null: false
      t.string 'url',                         default: '', null: false
      t.string 'login',         limit: 60, default: ''
      t.string 'password',                    default: ''
      t.string 'root_url',                    default: ''
      t.string 'type'
      t.string 'path_encoding', limit: 64
      t.string 'log_encoding',  limit: 64
    end

    add_index 'repositories', ['project_id'], name: 'index_repositories_on_project_id'

    create_table 'roles', force: true do |t|
      t.string 'name',        limit: 30, default: '',   null: false
      t.integer 'position',                  default: 1
      t.boolean 'assignable',                default: true
      t.integer 'builtin',                   default: 0,    null: false
      t.text 'permissions'
    end

    create_table 'settings', force: true do |t|
      t.string 'name',       default: '', null: false
      t.text 'value'
      t.datetime 'updated_on'
    end

    add_index 'settings', ['name'], name: 'index_settings_on_name'

    create_table 'time_entries', force: true do |t|
      t.integer 'project_id',  null: false
      t.integer 'user_id',     null: false
      t.integer 'issue_id'
      t.float 'hours',       null: false
      t.string 'comments'
      t.integer 'activity_id', null: false
      t.date 'spent_on',    null: false
      t.integer 'tyear',       null: false
      t.integer 'tmonth',      null: false
      t.integer 'tweek',       null: false
      t.datetime 'created_on',  null: false
      t.datetime 'updated_on',  null: false
    end

    add_index 'time_entries', ['activity_id'], name: 'index_time_entries_on_activity_id'
    add_index 'time_entries', ['created_on'], name: 'index_time_entries_on_created_on'
    add_index 'time_entries', ['issue_id'], name: 'time_entries_issue_id'
    add_index 'time_entries', ['project_id'], name: 'time_entries_project_id'
    add_index 'time_entries', ['user_id'], name: 'index_time_entries_on_user_id'

    create_table 'tokens', force: true do |t|
      t.integer 'user_id',                  default: 0,  null: false
      t.string 'action',     limit: 30, default: '', null: false
      t.string 'value',      limit: 40, default: '', null: false
      t.datetime 'created_on',                               null: false
    end

    add_index 'tokens', ['user_id'], name: 'index_tokens_on_user_id'

    create_table 'trackers', force: true do |t|
      t.string 'name',          limit: 30, default: '',    null: false
      t.boolean 'is_in_chlog',                 default: false, null: false
      t.integer 'position',                    default: 1
      t.boolean 'is_in_roadmap',               default: true,  null: false
    end

    create_table 'user_preferences', force: true do |t|
      t.integer 'user_id',   default: 0,     null: false
      t.text 'others'
      t.boolean 'hide_mail', default: false
      t.string 'time_zone'
    end

    add_index 'user_preferences', ['user_id'], name: 'index_user_preferences_on_user_id'

    create_table 'users', force: true do |t|
      t.string 'login',             limit: 30, default: '',    null: false
      t.string 'hashed_password',   limit: 40, default: '',    null: false
      t.string 'firstname',         limit: 30, default: '',    null: false
      t.string 'lastname',          limit: 30, default: '',    null: false
      t.string 'mail',              limit: 60, default: '',    null: false
      t.boolean 'admin',                           default: false, null: false
      t.integer 'status',                          default: 1,     null: false
      t.datetime 'last_login_on'
      t.string 'language',          limit: 5,  default: ''
      t.integer 'auth_source_id'
      t.datetime 'created_on'
      t.datetime 'updated_on'
      t.string 'type'
      t.string 'identity_url'
      t.string 'mail_notification',               default: '',    null: false
      t.string 'salt',              limit: 64
    end

    add_index 'users', ['auth_source_id'], name: 'index_users_on_auth_source_id'
    add_index 'users', ['id', 'type'], name: 'index_users_on_id_and_type'
    add_index 'users', ['type'], name: 'index_users_on_type'

    create_table 'versions', force: true do |t|
      t.integer 'project_id',      default: 0,      null: false
      t.string 'name',            default: '',     null: false
      t.string 'description',     default: ''
      t.date 'effective_date'
      t.datetime 'created_on'
      t.datetime 'updated_on'
      t.string 'wiki_page_title'
      t.string 'status',          default: 'open'
      t.string 'sharing',         default: 'none', null: false
      t.date 'start_date'
    end

    add_index 'versions', ['project_id'], name: 'versions_project_id'
    add_index 'versions', ['sharing'], name: 'index_versions_on_sharing'

    create_table 'watchers', force: true do |t|
      t.string 'watchable_type', default: '', null: false
      t.integer 'watchable_id',   default: 0,  null: false
      t.integer 'user_id'
    end

    add_index 'watchers', ['user_id', 'watchable_type'], name: 'watchers_user_id_type'
    add_index 'watchers', ['user_id'], name: 'index_watchers_on_user_id'
    add_index 'watchers', ['watchable_id', 'watchable_type'], name: 'index_watchers_on_watchable_id_and_watchable_type'

    create_table 'wiki_content_versions', force: true do |t|
      t.integer 'wiki_content_id',                                        null: false
      t.integer 'page_id',                                                null: false
      t.integer 'author_id'
      t.binary 'data',            limit: 16.megabytes
      t.string 'compression',     limit: 6,           default: ''
      t.string 'comments',                               default: ''
      t.datetime 'updated_on',                                             null: false
      t.integer 'version',                                                null: false
    end

    add_index 'wiki_content_versions', ['updated_on'], name: 'index_wiki_content_versions_on_updated_on'
    add_index 'wiki_content_versions', ['wiki_content_id'], name: 'wiki_content_versions_wcid'

    create_table 'wiki_contents', force: true do |t|
      t.integer 'page_id',                              null: false
      t.integer 'author_id'
      t.text 'text',         limit: 16.megabytes
      t.datetime 'updated_on',                           null: false
      t.integer 'lock_version',                         null: false
    end

    add_index 'wiki_contents', ['author_id'], name: 'index_wiki_contents_on_author_id'
    add_index 'wiki_contents', ['page_id'], name: 'wiki_contents_page_id'

    create_table 'wiki_pages', force: true do |t|
      t.integer 'wiki_id',                       null: false
      t.string 'title',                         null: false
      t.datetime 'created_on',                    null: false
      t.boolean 'protected',  default: false, null: false
      t.integer 'parent_id'
    end

    add_index 'wiki_pages', ['parent_id'], name: 'index_wiki_pages_on_parent_id'
    add_index 'wiki_pages', ['wiki_id', 'title'], name: 'wiki_pages_wiki_id_title'
    add_index 'wiki_pages', ['wiki_id'], name: 'index_wiki_pages_on_wiki_id'

    create_table 'wiki_redirects', force: true do |t|
      t.integer 'wiki_id',      null: false
      t.string 'title'
      t.string 'redirects_to'
      t.datetime 'created_on',   null: false
    end

    add_index 'wiki_redirects', ['wiki_id', 'title'], name: 'wiki_redirects_wiki_id_title'
    add_index 'wiki_redirects', ['wiki_id'], name: 'index_wiki_redirects_on_wiki_id'

    create_table 'wikis', force: true do |t|
      t.integer 'project_id',                null: false
      t.string 'start_page',                null: false
      t.integer 'status',     default: 1, null: false
    end

    add_index 'wikis', ['project_id'], name: 'wikis_project_id'

    create_table 'workflows', force: true do |t|
      t.integer 'tracker_id',    default: 0,     null: false
      t.integer 'old_status_id', default: 0,     null: false
      t.integer 'new_status_id', default: 0,     null: false
      t.integer 'role_id',       default: 0,     null: false
      t.boolean 'assignee',      default: false, null: false
      t.boolean 'author',        default: false, null: false
    end

    add_index 'workflows', ['new_status_id'], name: 'index_workflows_on_new_status_id'
    add_index 'workflows', ['old_status_id'], name: 'index_workflows_on_old_status_id'
    add_index 'workflows', ['role_id', 'tracker_id', 'old_status_id'], name: 'wkfs_role_tracker_old_status'
    add_index 'workflows', ['role_id'], name: 'index_workflows_on_role_id'

    true
  end

  def aggregated_versions
    @@aggregated_versions ||= @@migrations.split.map { |m|
      m.gsub(/_.*\z/, '').to_i
    }
  end

  def all_versions
    @@all_versions ||= ActiveRecord::Migrator.get_all_versions
  end

  def schema_migrations_table_name
    ActiveRecord::Migrator.schema_migrations_table_name
  end

  def quoted_schema_migrations_table_name
    ActiveRecord::Base.connection.quote_table_name(schema_migrations_table_name)
  end

  def quoted_version_column_name
    ActiveRecord::Base.connection.quote_table_name('version')
  end

  def version_column_for_comparison
    "#{quoted_schema_migrations_table_name}.#{quoted_version_column_name}"
  end

  def quote_value(s)
    ActiveRecord::Base.connection.quote(s)
  end
end
