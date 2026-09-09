# frozen_string_literal: true

# -- copyright
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
# ++

Dir[Rails.root.join("db/migrate/tables/*.rb").to_s].each { |file| require file }
Dir[Rails.root.join("db/migrate/extensions/*.rb").to_s].each { |file| require file }
require Rails.root.join("db/migrate/migration_utils/squashed_migration").to_s

# This migration aggregates a set of former migrations
class AggregatedMigrations < SquashedMigration
  extensions Extensions::BtreeGist,
             Extensions::PgTrgm,
             Extensions::Unaccent,
             Extensions::VersionNameCollation

  tables Tables::Projects,
         Tables::Colors,
         Tables::Types,
         Tables::Statuses,
         Tables::WorkPackages,
         Tables::Users,
         Tables::GroupUsers,
         Tables::Categories,
         Tables::Relations,
         Tables::WorkPackageHierarchies,
         Tables::Sessions,
         Tables::Announcements,
         Tables::Attachments,
         Tables::LdapAuthSources,
         Tables::Forums,
         Tables::Messages,
         Tables::CustomFieldSections,
         Tables::CustomFields,
         Tables::CustomFieldsProjects,
         Tables::CustomFieldsTypes,
         Tables::CustomOptions,
         Tables::CustomValues,
         Tables::Changesets,
         Tables::ChangesetsWorkPackages,
         Tables::Journals,
         Tables::WorkPackageJournals,
         Tables::ProjectJournals,
         Tables::MessageJournals,
         Tables::NewsJournals,
         Tables::WikiPageJournals,
         Tables::ChangesetJournals,
         Tables::AttachmentJournals,
         Tables::AttachableJournals,
         Tables::CustomizableJournals,
         Tables::Comments,
         Tables::Changes,
         Tables::Repositories,
         Tables::Enumerations,
         Tables::Roles,
         Tables::RolePermissions,
         Tables::MemberRoles,
         Tables::Members,
         Tables::News,
         Tables::ProjectsTypes,
         Tables::Queries,
         Tables::Settings,
         Tables::Tokens,
         Tables::UserPreferences,
         Tables::UserPasswords,
         Tables::Versions,
         Tables::Watchers,
         Tables::WikiPages,
         Tables::WikiRedirects,
         Tables::Wikis,
         Tables::Workflows,
         Tables::Exports,
         Tables::MenuItems,
         Tables::CustomStyles,
         Tables::DesignColors,
         Tables::EnterpriseTokens,
         Tables::EnabledModules,
         Tables::AttributeHelpTexts,
         Tables::CustomActions,
         Tables::CustomActionsProjects,
         Tables::CustomActionsRoles,
         Tables::CustomActionsStatuses,
         Tables::CustomActionsTypes,
         Tables::OAuthApplications,
         Tables::OAuthAccessGrants,
         Tables::OAuthAccessTokens,
         Tables::OrderedWorkPackages,
         Tables::Notifications,
         Tables::NotificationSettings,
         Tables::Views,
         Tables::OAuthClients,
         Tables::OAuthClientTokens,
         Tables::NonWorkingDays,
         Tables::PaperTrailAudits,
         Tables::ProjectCustomFieldProjectMappings,
         Tables::ProjectQueries,
         Tables::GoodJobs,
         Tables::GoodJobProcesses,
         Tables::GoodJobSettings,
         Tables::GoodJobBatches,
         Tables::GoodJobExecutions,
         Tables::Favorites,
         Tables::EmojiReactions,
         Tables::AuthProviders,
         Tables::UserAuthProviderLinks,
         Tables::ScimClients,
         Tables::CalculatedValueErrors,
         Tables::RemoteIdentities,
         Tables::HierarchicalItems,
         Tables::HierarchicalItemHierarchies,
         Tables::ProjectPhaseDefinitions,
         Tables::ProjectPhases,
         Tables::Reminders,
         Tables::ReminderNotifications,
         Tables::ProjectPhaseJournals,
         Tables::ServiceAccountAssociations,
         Tables::ExportSettings

  squashed_migrations *%w[
    1000016_aggregated_migrations
    20250403150639_link_wp_to_project_phase_definition
    20250411104802_add_duration_to_project_phases
    20250422072119_rename_comment_permissions
    20250423123519_add_index_to_sessions
    20250428135623_disallow_null_in_project_phases_references
    20250512114003_move_users_identity_url_to_user_auth_provider_links
    20250605133700_create_scim_clients
    20250610111413_add_validity_period_to_enterprise_token
    20250612133700_service_account_association_foreign_keys
    20250613141234_add_formula_to_custom_fields
    20250627121119_change_default_main_menu_color
    20250731144436_add_workspace_type_to_project
    20250804133700_migrate_auth_provider_urls_again
    20250806132912_add_export_footer_to_custom_styles
    20250811102200_add_pdf_fonts_to_custom_styles
    20250818133654_add_list_item_score
    20250905204438_migrate_theme_preferences
    20250908072653_create_calculated_value_errors
    20250908151957_rename_favorites_favored_to_favorited
  ]
end
