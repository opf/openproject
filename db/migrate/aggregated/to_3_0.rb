#-- encoding: UTF-8

#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require_relative 'base'

# rubocop:disable Naming/ClassAndModuleCamelCase
class Aggregated::To_3_0 < Aggregated::Base
  def self.migrations
    <<-MIGRATIONS
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
  end
end
# rubocop:enable Naming/ClassAndModuleCamelCase
