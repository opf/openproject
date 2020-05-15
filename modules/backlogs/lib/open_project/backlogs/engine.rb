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

require 'open_project/plugins'
require_relative './patches/api/work_package_representer'
require_relative './patches/api/work_package_schema_representer'
require_relative './patches/api/work_package_sums_representer'
require_relative './patches/api/work_package_sums_schema_representer'

module OpenProject::Backlogs
  class Engine < ::Rails::Engine
    engine_name :openproject_backlogs

    def self.settings
      { default: { 'story_types'  => nil,
                   'task_type'    => nil,
                   'card_spec'    => nil
      },
        partial: 'shared/settings',
        menu_item: :backlogs_settings }
    end

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-backlogs',
             author_url: 'https://www.openproject.com',
             bundled: true,
             settings: settings do
      OpenProject::AccessControl.permission(:edit_project).tap do |add|
        add.actions << 'projects/project_done_statuses'
        add.actions << 'projects/rebuild_positions'
        add.actions << 'backlogs_settings/show'
      end

      OpenProject::AccessControl.permission(:add_work_packages).tap do |add|
        add.actions << 'rb_stories/create'
        add.actions << 'rb_tasks/create'
        add.actions << 'rb_impediments/create'
      end

      OpenProject::AccessControl.permission(:edit_work_packages).tap do |edit|
        edit.actions << 'rb_stories/update'
        edit.actions << 'rb_tasks/update'
        edit.actions << 'rb_impediments/update'
      end

      project_module :backlogs do
        # SYNTAX: permission :name_of_permission, { :controller_name => [:action1, :action2] }

        # Master backlog permissions
        permission :view_master_backlog,           rb_master_backlogs:  :index,
                                                   rb_sprints:          [:index, :show],
                                                   rb_wikis:            :show,
                                                   rb_stories:          [:index, :show],
                                                   rb_queries:          :show,
                                                   rb_burndown_charts:  :show,
                                                   rb_export_card_configurations: [:index, :show]

        permission :view_taskboards,               rb_taskboards:       :show,
                                                   rb_sprints:          :show,
                                                   rb_stories:          :show,
                                                   rb_tasks:            [:index, :show],
                                                   rb_impediments:      [:index, :show],
                                                   rb_wikis:            :show,
                                                   rb_burndown_charts:  :show,
                                                   rb_export_card_configurations: [:index, :show]

        # Sprint permissions
        # :show_sprints and :list_sprints are implicit in :view_master_backlog permission
        permission :update_sprints,                rb_sprints: [:edit, :update],
                                                   rb_wikis:   [:edit, :update]
      end

      menu :project_menu,
           :backlogs,
           { controller: '/rb_master_backlogs', action: :index },
           caption: :project_module_backlogs,
           before: :calendar,
           param: :project_id,
           icon: 'icon2 icon-backlogs'
    end

    assets %w(
      backlogs/backlogs.css
      backlogs/backlogs.js
      backlogs/master_backlog.css
      backlogs/taskboard.css
      backlogs/jquery.flot/excanvas.js
      backlogs/burndown.js
    )

    # We still override version and project settings views from the core! URH
    override_core_views!

    patches %i[PermittedParams
               WorkPackage
               Status
               Type
               Project
               ProjectsController
               ProjectSettingsHelper
               User
               VersionsController
               Version]

    patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema
    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :DemoData, :ProjectSeeder
    patch_with_namespace :WorkPackages, :UpdateAncestorsService
    patch_with_namespace :WorkPackages, :UpdateService
    patch_with_namespace :WorkPackages, :SetAttributesService
    patch_with_namespace :WorkPackages, :BaseContract
    patch_with_namespace :Versions, :RowCell

    config.to_prepare do
      next if Versions::BaseContract.included_modules.include?(OpenProject::Backlogs::Patches::Versions::BaseContractPatch)

      Versions::BaseContract.prepend(OpenProject::Backlogs::Patches::Versions::BaseContractPatch)
    end

    extend_api_response(:v3, :work_packages, :work_package,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageRepresenter.extension)

    extend_api_response(:v3, :work_packages, :work_package_payload,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageRepresenter.extension)

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageSchemaRepresenter.extension)

    extend_api_response(:v3, :work_packages, :schema, :work_package_sums_schema,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageSumsSchemaRepresenter.extension)

    extend_api_response(:v3, :work_packages, :work_package_sums,
                        &::OpenProject::Backlogs::Patches::API::WorkPackageSumsRepresenter.extension)

    add_api_attribute on: :work_package, ar_name: :story_points
    add_api_attribute on: :work_package, ar_name: :remaining_hours, writeable: ->(*) { model.leaf? }

    add_api_path :backlogs_type do |id|
      # There is no api endpoint for this url
      "#{root}/backlogs_types/#{id}"
    end

    initializer 'backlogs.register_hooks' do
      require 'open_project/backlogs/hooks'
      require 'open_project/backlogs/hooks/user_settings_hook'
    end

    config.to_prepare do
      ::Type.add_constraint :position, ->(type, project: nil) do
        if project.present?
          project.backlogs_enabled? && type.story?
        else
          # Allow globally configuring the attribute if story
          type.story?
        end
      end

      ::Type.add_constraint :story_points, ->(type, project: nil) do
        if project.present?
          project.backlogs_enabled? && type.story?
        else
          # Allow globally configuring the attribute if story
          type.story?
        end
      end

      ::Type.add_constraint :remaining_time, ->(_type, project: nil) do
        project.nil? || project.backlogs_enabled?
      end

      ::Type.add_default_mapping(:estimates_and_time, :story_points, :remaining_time)
      ::Type.add_default_mapping(:other, :position)

      Queries::Register.filter Query, OpenProject::Backlogs::WorkPackageFilter
      Queries::Register.column Query, OpenProject::Backlogs::QueryBacklogsColumn
    end
  end
end
