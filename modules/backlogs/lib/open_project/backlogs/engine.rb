# frozen_string_literal: true

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

require "open_project/plugins"
require_relative "patches/api/work_package_representer"
require_relative "patches/api/work_package_schema_representer"

module OpenProject::Backlogs
  class Engine < ::Rails::Engine
    engine_name :openproject_backlogs

    def self.settings
      {
        default: {
          "points_burn_direction" => "up"
        },
        menu_item: :backlogs_settings
      }
    end

    include OpenProject::Plugins::ActsAsOpEngine

    register("openproject-backlogs",
             author_url: "https://www.openproject.org",
             bundled: true,
             settings:) do
      project_module :backlogs, dependencies: :work_package_tracking do
        permission :view_sprints,
                   { "backlogs/backlog": %i[show details],
                     "backlogs/work_packages": %i[index show menu],
                     "backlogs/inbox": :menu,
                     "backlogs/burndown_chart": :show,
                     "backlogs/sprints": :index,
                     "backlogs/taskboard": :show },
                   permissible_on: :project,
                   dependencies: %i[view_work_packages show_board_views]

        permission :select_backlog_types_and_statuses,
                   {
                     "projects/settings/backlogs": %i[show update rebuild_positions]
                   },
                   permissible_on: :project,
                   require: :member

        permission :create_sprints,
                   { "backlogs/buckets": %i[new_dialog create edit_dialog update destroy_dialog destroy],
                     "backlogs/sprints": %i[new_dialog refresh_form create edit_dialog update] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :view_sprints

        permission :start_complete_sprint,
                   { "backlogs/sprints": %i[start finish] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: %i[view_sprints manage_board_views manage_sprint_items]

        permission :manage_sprint_items,
                   { "backlogs/work_packages": %i[move move_to_sprint_dialog move_to_bucket_dialog] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: %i[view_sprints edit_work_packages]

        permission :share_sprint,
                   { "projects/settings/backlog_sharings": %i[show update] },
                   permissible_on: :project,
                   require: :member,
                   dependencies: :create_sprints
      end

      ::Redmine::MenuManager.map(:admin_menu) do |menu|
        menu.push :admin_backlogs,
                  { controller: "/backlogs/settings", action: :show },
                  if: ->(_) { User.current.admin? },
                  caption: :label_backlogs,
                  icon: "op-backlogs"
      end

      menu :project_menu,
           :backlogs,
           { controller: "/backlogs/backlog", action: :show },
           if: Proc.new { |project| project.module_enabled?(:backlogs) },
           caption: :project_module_backlogs,
           after: :work_packages,
           icon: "op-backlogs"

      menu :project_menu,
           :backlog,
           { controller: "/backlogs/backlog", action: :show },
           if: Proc.new { |project| project.module_enabled?(:backlogs) },
           caption: :label_backlog_and_sprints,
           parent: :backlogs

      menu :project_menu,
           :all_sprints,
           { controller: "/backlogs/sprints", action: :index },
           if: Proc.new { |project| project.module_enabled?(:backlogs) },
           caption: :label_all_sprints,
           parent: :backlogs

      # Menu items that are always present
      menu :project_menu,
           :settings_backlogs,
           { controller: "/projects/settings/backlogs", action: :show },
           if: Proc.new { |project| project.module_enabled?(:backlogs) },
           caption: :label_backlogs,
           parent: :settings,
           before: :settings_storage
    end

    patches %i[PermittedParams
               WorkPackage
               Project]

    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :Projects, :CopyService
    patch_with_namespace :Projects, :SetAttributesService
    patch_with_namespace :WorkPackages, :SetAttributesService
    patch_with_namespace :WorkPackages, :BaseContract
    patch_with_namespace :WorkPackages, :UpdateContract
    patch_with_namespace :Projects, :CopyService
    patch_with_namespace :API, :V3, :WorkPackages, :EagerLoading, :Checksum
    patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema

    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageRepresenter.extension)

    # TODO: This should not be necessary as the WorkPackagePayloadRepresenter already inherits from
    # the WorkPackageRepresenter. But removing this line makes tests fail. It appears that the
    # patch on the WorkPackageRepresenter in GitHubIntegration is failing if this is removed.
    extend_api_response(:v3, :work_packages, :work_package_payload,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageRepresenter.extension)

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageSchemaRepresenter.extension)

    add_api_path :sprint do |id|
      "#{root}/sprints/#{id}"
    end

    add_api_path :sprints do
      "#{root}/sprints"
    end

    add_api_path :project_sprints do |id|
      "#{root}/projects/#{id}/sprints"
    end

    add_api_path :backlog_buckets do
      "#{root}/backlog_buckets"
    end

    add_api_path :backlog_bucket do |id|
      "#{root}/backlog_buckets/#{id}"
    end

    add_api_path :project_backlog_buckets do |id|
      "#{root}/projects/#{id}/backlog_buckets"
    end

    add_api_endpoint "API::V3::Root" do
      mount ::API::V3::Sprints::SprintsAPI
      mount ::API::V3::BacklogBuckets::BacklogBucketsAPI
    end

    add_api_endpoint "API::V3::Projects::ProjectsAPI", :id do
      mount ::API::V3::Sprints::SprintsByProjectAPI
      mount ::API::V3::BacklogBuckets::BacklogBucketsByProjectAPI
    end

    initializer "openproject_backlogs.event_subscriptions" do
      Rails.application.config.after_initialize do
        # When the backlogs module is first enabled on a project, automatically populate
        # the project's done_statuses with all statuses that are globally marked as closed
        # (is_closed: true). This mirrors the form behavior where these statuses are
        # pre-selected and disabled, so users never have to visit the settings page just
        # to get sensible defaults.
        OpenProject::Notifications.subscribe(OpenProject::Events::MODULE_ENABLED) do |payload|
          enabled_module = payload[:enabled_module]
          next unless enabled_module.name == "backlogs"

          project = enabled_module.project
          next unless project

          mandatory_ids = Status.where(is_closed: true).pluck(:id)
          next if mandatory_ids.empty?

          merged_ids = project.done_statuses.reorder(nil).pluck(:id) | mandatory_ids

          project.class.transaction do
            project.done_statuses = [] # explicit clearing is necessary due to HABTM cache behavior
            project.done_statuses = Status.where(id: merged_ids)
          end
        end

        OpenProject::Notifications.subscribe(OpenProject::Events::MODULE_DISABLED) do |payload|
          disabled_module = payload[:disabled_module]
          next unless disabled_module.name == "backlogs"

          disabled_module.project.not_sharing_sprints!
        end

        OpenProject::Notifications.subscribe(OpenProject::Events::PROJECT_ARCHIVED) do |payload|
          payload[:project].not_sharing_sprints!
        end
      end
    end

    config.to_prepare do
      %i[position story_points sprint backlog_bucket].each do |attribute|
        ::Type.add_constraint attribute, ->(_type, project: nil) { project.nil? || project.backlogs_enabled? }
      end

      ::Type.add_default_mapping(:estimates_and_progress, :story_points)
      ::Type.add_default_mapping(:other, :position)
      ::Type.add_default_mapping(:details, :sprint)
      ::Type.add_default_mapping(:details, :backlog_bucket)

      ::Queries::Register.register(::Query) do
        filter Queries::WorkPackages::Filter::BacklogBucketFilter
        filter Queries::WorkPackages::Filter::SprintFilter

        select OpenProject::Backlogs::QueryBacklogsSelect
        select OpenProject::Backlogs::WorkPackageBucketSelect
        select OpenProject::Backlogs::WorkPackageSprintSelect
      end
    end
  end
end
