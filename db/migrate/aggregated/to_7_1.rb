#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
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
# See COPYRIGHT and LICENSE files for more details.
#++

require_relative "base"

# rubocop:disable Naming/ClassAndModuleCamelCase
class Aggregated::To_7_1 < Aggregated::Base
  def self.migrations
    <<-MIGRATIONS
      0_aggregated_migrations.rb
      20110211160100_add_summary_to_projects.rb
      20110817142220_add_display_sums_field_to_migration.rb
      20111114124552_add_user_first_logged_in_and_impaired_fields.rb
      20120319095930_localize_email_header_and_footer.rb
      20120319135006_add_custom_field_translation_table.rb
      20120529090411_create_delayed_jobs.rb
      20120731091543_use_the_full_sti_class_names_for_repositories.rb
      20120731135140_create_wiki_menu_items.rb
      20120802152122_rename_auth_source_ldap.rb
      20120809131659_create_wiki_menu_item_for_existing_wikis.rb
      20120828171423_make_groups_users_a_model.rb
      20121004054229_add_wiki_list_attachments.rb
      20121030111651_rename_acts_as_journalized_changes_column.rb
      20121101111303_add_missing_indexes_on_wiki_menu_items.rb
      20121114100641_aggregated_announcements_migrations.rb
      20130204140624_add_index_on_identifier_to_projects.rb
      20130315124655_add_longer_login_to_users.rb
      20130325165622_remove_gantt_related_data_from_database.rb
      20130409133700_add_timelines_project_type_id_to_projects.rb
      20130409133701_create_timelines_project_types.rb
      20130409133702_create_timelines_planning_element_types.rb
      20130409133703_create_timelines_planning_elements.rb
      20130409133704_create_timelines_scenarios.rb
      20130409133705_create_timelines_alternate_dates.rb
      20130409133706_add_timelines_responsible_id_to_projects.rb
      20130409133707_create_timelines_colors.rb
      20130409133708_create_timelines_reportings.rb
      20130409133709_create_timelines_available_project_statuses.rb
      20130409133710_create_timelines_project_associations.rb
      20130409133711_create_timelines_enabled_planning_element_types.rb
      20130409133712_create_timelines_default_planning_element_types.rb
      20130409133713_migrate_planning_element_type_to_project_association.rb
      20130409133714_remove_project_type_id_from_timelines_planning_element_types.rb
      20130409133715_create_timelines_timelines.rb
      20130409133717_add_options_to_timelines_timelines.rb
      20130409133718_remove_content_from_timelines_timelines.rb
      20130409133719_add_indexes_to_timelines_alternate_dates_to_secure_at_scope.rb
      20130409133720_add_deleted_at_to_timelines_planning_elements.rb
      20130409133721_allow_null_position_in_colors.rb
      20130409133722_allow_null_position_in_planning_element_types.rb
      20130409133723_allow_null_position_in_project_types.rb
      20130611154020_remove_timelines_namespace.rb
      20130612120042_migrate_serialized_yaml_from_syck_to_psych.rb
      20130613075253_add_force_password_change_to_user.rb
      20130619081234_create_user_passwords.rb
      20130620082322_create_work_packages.rb
      20130625124242_work_package_custom_field_data_migration.rb
      20130628092725_add_failed_login_count_last_failed_login_on_to_user.rb
      20130709084751_rename_end_date_on_alternate_dates.rb
      20130710145350_remove_end_date_from_work_packages.rb
      20130717134318_rename_changeset_wp_join_table.rb
      20130719133922_rename_trackers_to_types.rb
      20130722154555_rename_work_package_sti_column.rb
      20130723092240_add_activity_module.rb
      20130723134527_increase_journals_changed_data_limit.rb
      20130724143418_add_planning_element_type_properties_to_type.rb
      20130729114110_move_planning_element_types_to_legacy_planning_element_types.rb
      20130806075000_add_standard_column_to_type_table.rb
      20130807081927_move_journals_to_legacy_journals.rb
      20130807082645_create_normalized_journals.rb
      20130807083715_create_attachment_journals.rb
      20130807083716_change_attachment_journals_description_length.rb
      20130807084417_create_work_package_journals.rb
      20130807084708_create_message_journals.rb
      20130807085108_create_news_journals.rb
      20130807085245_create_wiki_content_journals.rb
      20130807085430_create_time_entry_journals.rb
      20130807085714_create_changeset_journals.rb
      20130807141542_remove_files_attached_to_projects_and_versions.rb
      20130813062401_add_attachable_journal.rb
      20130813062513_add_customizable_journal.rb
      20130813062523_fix_customizable_journal_value_column.rb
      20130814130142_remove_documents.rb
      20130828093647_remove_alternate_dates_and_scenarios.rb
      20130829084747_drop_model_journals_updated_on_column.rb
      20130916094339_legacy_issues_to_work_packages.rb
      20130916123916_planning_element_types_data_to_types.rb
      20130917101922_migrate_query_tracker_references_to_type.rb
      20130917122118_remove_is_in_chlog_from_types.rb
      20130917131710_planning_element_data_to_work_packages.rb
      20130918111753_migrate_user_rights.rb
      20130919105841_migrate_settings_to_work_package.rb
      20130919145142_rename_issue_relations_to_relations.rb
      20130920081120_journal_indices.rb
      20130920081135_legacy_attachment_journal_data.rb
      20130920085055_legacy_changeset_journal_data.rb
      20130920090201_legacy_news_journal_data.rb
      20130920090641_legacy_message_journal_data.rb
      20130920092800_legacy_time_entry_journal_data.rb
      20130920093823_legacy_wiki_content_journal_data.rb
      20130920094524_legacy_issue_journal_data.rb
      20130920095747_legacy_planning_element_journal_data.rb
      20130920142714_update_attachment_container.rb
      20130920150143_journal_activities_data.rb
      20131001075217_rename_issue_category_to_category.rb
      20131001105659_rename_issue_statuses_to_statuses.rb
      20131004141959_generalize_wiki_menu_items.rb
      20131007062401_migrate_text_references_to_issues_and_planning_elements.rb
      20131009083648_work_package_indices.rb
      20131015064141_migrate_timelines_end_date_property_in_options.rb
      20131015121430_index_on_users.rb
      20131016075650_add_queue_to_delayed_jobs.rb
      20131017064039_repair_work_packages_initial_attachable_journal.rb
      20131018134525_repair_messages_initial_attachable_journal.rb
      20131018134530_repair_customizable_journals.rb
      20131018134545_add_missing_attachable_journals.rb
      20131018134590_add_missing_customizable_journals.rb
      20131024115743_migrate_remaining_core_settings.rb
      20131024140048_migrate_timelines_options.rb
      20131031170857_fix_watcher_work_package_associations.rb
      20131101125921_migrate_default_values_in_work_package_journals.rb
      20131108124300_add_index_to_all_the_journals.rb
      20131114132911_migrate_planning_element_links_in_journal_notes.rb
      20131115155147_fix_parent_ids_in_work_package_journals_of_former_planning_elements.rb
      20131126112911_migrate_update_create_column_reference_in_queries.rb
      20131202094511_delete_former_deleted_planning_elements.rb
      20131210113056_repair_invalid_default_work_package_custom_values.rb
      20131216171110_migrate_timelines_enumerations.rb
      20131219084934_add_enabled_modules_name_index.rb
      20140122161742_remove_journal_columns.rb
      20140127134733_fix_issue_in_notifications.rb
      20140203141127_rename_modulename_issue_tracking.rb
      20140311120609_add_sticked_on_field_to_messages.rb
      20140411142338_clear_identity_urls_on_users.rb
      20140414141459_remove_openid_entirely.rb
      20140429152018_add_sessions_table.rb
      20140430125956_reset_content_types.rb
      20140602112515_drop_work_packages_priority_not_null_constraint.rb
      20140610125207_add_updated_at_index_to_work_packages.rb
      20141215104802_migrate_attachments_to_carrier_wave.rb
      20150116095004_patch_corrupt_attachments.rb
      20150623151337_hide_mail_by_default.rb
      20150629075221_add_scm_type_to_repositories.rb
      20150716133712_add_unique_index_on_journals.rb
      20150716163704_remove_filesystem_repositories.rb
      20150729145732_add_storage_information_to_repository.rb
      20150819143300_underscore_scm_settings.rb
      20150820133700_denullify_display_sums.rb
      20150827133700_remove_project_homepage.rb
      20151005113102_remove_summary_from_project.rb
      20151028063433_boolearlize_bool_custom_values.rb
      20151116110245_fix_customizable_bool_values.rb
      20160125143638_index_member_roles_inherited_from.rb
      20160419103544_add_attribute_visibility_to_types.rb
      20160503150449_add_indexes_for_latest_activity.rb
      20160726090624_add_slug_to_wiki_pages.rb
      20160803094931_wiki_menu_titles_to_slug.rb
      20160824121151_add_user_id_to_sessions.rb
      20160829225633_introduce_bcrypt_passwords.rb
      20160907113604_normalize_permissions.rb
      20160913081236_type_attribute_visibility_to_hash.rb
      20160913125802_timeline_options_to_hash.rb
      20160914124514_harmonize_bool_custom_values.rb
      20160926102618_setting_value_to_hash.rb
      20161017102547_add_description_to_relations.rb
      20161025135400_query_empty_column_names_to_array.rb
      20161102160032_create_enterprise_token.rb
      20161116130657_create_custom_styles.rb
      20161213191919_remove_category_name_restriction.rb
      20161219134700_add_attr_admin_to_ldap.rb
      20170116105342_add_custom_options.rb
      20170117112648_create_design_colors.rb
      20170222094032_add_attribute_groups_to_type.rb
      20170308120915_migrate_missed_list_custom_values.rb
      20170330084810_remove_translations_from_custom_fields.rb
      20170404110156_extend_query_model.rb
      20170407074032_add_hierarchy_to_query.rb
      20170411065946_v3_to_internal_group_by.rb
      20170418064453_add_timestamp_to_custom_fields.rb
      20170420082944_remove_legacy_tables.rb
      20170421071136_set_empty_columns_to_null.rb
      20170421071137_migrate_query_custom_field_filters.rb
      20170602073043_save_zoom_level_in_query.rb
      20170614131555_add_favicon_touch_icon_to_custom_style.rb
    MIGRATIONS
  end
end
# rubocop:enable Naming/ClassAndModuleCamelCase
