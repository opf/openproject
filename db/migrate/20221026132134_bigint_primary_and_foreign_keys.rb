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

require_relative "migration_utils/column"

class BigintPrimaryAndForeignKeys < ActiveRecord::Migration[7.0]
  KEY_CHANGES = {
    Announcement => [:id],
    Journal::AttachableJournal => %i[id journal_id attachment_id],
    Journal::AttachmentJournal => %i[id container_id author_id],
    Attachment => %i[id container_id author_id],
    AttributeHelpText => [:id],
    :auth_sources => [:id],
    Journal::BudgetJournal => %i[id project_id author_id],
    Budget => %i[id project_id author_id],
    Category => %i[id project_id assigned_to_id],
    Change => %i[id changeset_id],
    Journal::ChangesetJournal => %i[id repository_id user_id],
    Changeset => %i[id repository_id user_id],
    :changesets_work_packages => %i[changeset_id work_package_id],
    Color => [:id],
    Comment => %i[id commented_id author_id],
    CostEntry => %i[id user_id project_id work_package_id cost_type_id rate_id],
    CostQuery => %i[id user_id project_id],
    CostType => [:id],
    CustomAction => [:id],
    :custom_actions_projects => %i[id project_id custom_action_id],
    :custom_actions_roles => %i[id role_id custom_action_id],
    :custom_actions_statuses => %i[id status_id custom_action_id],
    :custom_actions_types => %i[id type_id custom_action_id],
    CustomField => [:id],
    :custom_fields_projects => %i[custom_field_id project_id],
    :custom_fields_types => %i[custom_field_id type_id],
    CustomOption => %i[id custom_field_id],
    CustomStyle => [:id],
    CustomValue => %i[id customized_id custom_field_id],
    Journal::CustomizableJournal => %i[id journal_id custom_field_id],
    DesignColor => [:id],
    :delayed_jobs => [:id], # delayed job removed in favour of good_job see WP #42 or PR #42
    Journal::DocumentJournal => %i[id project_id category_id],
    Document => %i[id project_id category_id],
    :done_statuses_for_project => %i[project_id status_id],
    EnabledModule => %i[id project_id],
    EnterpriseToken => [:id],
    Enumeration => %i[id project_id parent_id color_id],
    Forum => %i[id project_id last_message_id],
    Grids::Widget => [:grid_id],
    Grids::Grid => %i[user_id project_id],
    GroupUser => %i[group_id user_id],
    Journal => %i[id journable_id user_id],
    LaborBudgetItem => %i[id budget_id user_id],
    LdapGroups::Membership => %i[id user_id group_id],
    LdapGroups::SynchronizedGroup => %i[id group_id auth_source_id],
    MaterialBudgetItem => %i[id budget_id cost_type_id],
    Journal::MeetingContentJournal => %i[id meeting_id author_id],
    MeetingContent => %i[id meeting_id author_id],
    Journal::MeetingJournal => %i[id project_id author_id],
    MeetingParticipant => %i[id user_id meeting_id],
    Meeting => %i[id author_id project_id],
    MemberRole => %i[id member_id role_id inherited_from],
    Member => %i[id user_id project_id],
    MenuItem => %i[id parent_id navigatable_id],
    Journal::MessageJournal => %i[id forum_id parent_id author_id],
    Message => %i[id forum_id parent_id author_id last_reply_id],
    News => %i[id project_id author_id],
    Journal::NewsJournal => %i[id project_id author_id],
    Doorkeeper::AccessGrant => %i[resource_owner_id application_id],
    Doorkeeper::AccessToken => %i[resource_owner_id application_id],
    Doorkeeper::Application => %i[owner_id client_credentials_user_id],
    OrderedWorkPackage => %i[query_id work_package_id],
    Project => %i[id parent_id],
    :projects_types => %i[project_id type_id],
    Query => %i[id project_id user_id],
    Rate => %i[id project_id user_id cost_type_id],
    Relation => [:id],
    Repository => %i[id project_id],
    RolePermission => %i[id role_id],
    Role => [:id],
    :sessions => %i[id user_id],
    Setting => [:id],
    Status => %i[id color_id],
    TimeEntry => %i[id project_id user_id work_package_id activity_id rate_id],
    Journal::TimeEntryJournal => %i[id project_id user_id work_package_id activity_id rate_id],
    Token::Base => [:id],
    ::TwoFactorAuthentication::Device => %i[id user_id],
    Type => %i[id color_id],
    UserPassword => %i[id user_id],
    UserPreference => %i[id user_id],
    User => %i[id auth_source_id],
    VersionSetting => %i[id project_id version_id],
    Version => %i[id project_id],
    Watcher => %i[id watchable_id user_id],
    Webhooks::Event => %i[id webhooks_webhook_id],
    Webhooks::Log => %i[id webhooks_webhook_id],
    Webhooks::Project => %i[id project_id webhooks_webhook_id],
    Webhooks::Webhook => [:id],
    :wiki_content_journals => %i[id page_id author_id],
    :wiki_contents => %i[id page_id author_id],
    WikiPage => %i[id wiki_id parent_id],
    WikiRedirect => %i[id wiki_id],
    Wiki => %i[id project_id],
    Journal::WorkPackageJournal => %i[id
                                      type_id
                                      project_id
                                      category_id
                                      status_id
                                      assigned_to_id
                                      priority_id
                                      version_id
                                      author_id
                                      parent_id
                                      responsible_id
                                      budget_id],
    WorkPackage => %i[id
                      type_id
                      project_id
                      category_id
                      status_id
                      assigned_to_id
                      priority_id
                      version_id
                      author_id
                      parent_id
                      responsible_id
                      budget_id],
    Workflow => %i[id type_id old_status_id new_status_id role_id]
  }.freeze

  DEFAULT_CHANGES = {
    Journal::AttachmentJournal => [:author_id],
    Attachment => [:author_id],
    Category => [:project_id],
    Comment => %i[commented_id author_id],
    :custom_fields_projects => %i[custom_field_id project_id],
    :custom_fields_types => %i[custom_field_id type_id],
    CustomValue => %i[customized_id custom_field_id],
    Journal::DocumentJournal => %i[project_id category_id],
    Document => %i[project_id category_id],
    Journal => [:user_id],
    Member => [:user_id],
    News => [:author_id],
    Journal::NewsJournal => [:author_id],
    :projects_types => %i[project_id type_id],
    Query => [:user_id],
    Repository => [:project_id],
    UserPreference => [:user_id],
    Version => [:project_id],
    Watcher => [:watchable_id],
    Journal::WorkPackageJournal => %i[type_id project_id status_id priority_id author_id],
    WorkPackage => %i[type_id project_id status_id priority_id author_id],
    Workflow => %i[type_id old_status_id new_status_id role_id]
  }.freeze

  def up
    KEY_CHANGES.each do |klass, columns|
      change_columns_type(klass, columns, :bigint)
    end

    DEFAULT_CHANGES.each do |klass, columns|
      change_columns_default(klass, columns, from: 0, to: nil)
    end
  end

  def down
    KEY_CHANGES.each do |klass, columns|
      change_columns_type(klass, columns, :integer)
    end

    DEFAULT_CHANGES.each do |klass, columns|
      change_columns_default(klass, columns, from: nil, to: 0)
    end
  end

  private

  def change_columns_type(klass, columns, type)
    for_each_klass_and_columns(klass, columns) do |table, column|
      change_column_type(table, column, type)
    end
  end

  def change_columns_default(klass, columns, from:, to:)
    for_each_klass_and_columns(klass, columns) do |table, column|
      change_column_default(table, column, from:, to:)
    end
  end

  def change_column_type(table, column, type)
    Migration::MigrationUtils::Column.new(connection, table, column).change_type! type
  end

  def for_each_klass_and_columns(klass, columns)
    table = klass.respond_to?(:table_name) ? klass.table_name : klass

    columns.each do |column|
      yield table, column
    end

    klass.reset_column_information if klass.respond_to?(:reset_column_information)
  end
end
