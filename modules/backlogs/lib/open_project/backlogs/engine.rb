#-- copyright
# OpenProject Backlogs Plugin
#
# Copyright (C)2013-2014 the OpenProject Foundation (OPF)
# Copyright (C)2011 Stephan Eckardt, Tim Felgentreff, Marnen Laibow-Koser, Sandro Munda
# Copyright (C)2010-2011 friflaj
# Copyright (C)2010 Maxime Guilbot, Andrew Vit, Joakim Kolsjö, ibussieres, Daniel Passos, Jason Vasquez, jpic, Emiliano Heyns
# Copyright (C)2009-2010 Mark Maglana
# Copyright (C)2009 Joe Heck, Nate Lowrie
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public License version 3.
#
# OpenProject Backlogs is a derivative work based on ChiliProject Backlogs.
# The copyright follows:
# Copyright (C) 2010-2011 - Emiliano Heyns, Mark Maglana, friflaj
# Copyright (C) 2011 - Jens Ulferts, Gregor Schmidt - Finn GmbH - Berlin, Germany
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

require 'open_project/plugins'


require 'acts_as_silent_list'

module OpenProject::Backlogs
  class Engine < ::Rails::Engine
    engine_name :openproject_backlogs

    def self.settings
      { default: { 'story_types'  => nil,
                   'task_type'    => nil,
                   'card_spec'    => nil
      },
        partial: 'shared/settings' }
    end

    include OpenProject::Plugins::ActsAsOpEngine

    register 'openproject-backlogs',
             author_url: 'http://finn.de',
             requires_openproject: "= #{OpenProject::Backlogs::VERSION}",
             settings: settings do
      Redmine::AccessControl.permission(:edit_project).actions << 'projects/project_done_statuses'
      Redmine::AccessControl.permission(:edit_project).actions << 'projects/rebuild_positions'

      Redmine::AccessControl.permission(:add_work_packages).tap do |add|
        add.actions << 'rb_stories/create'
        add.actions << 'rb_tasks/create'
        add.actions << 'rb_impediments/create'
      end

      Redmine::AccessControl.permission(:edit_work_packages).tap do |edit|
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

    patches [:PermittedParams,
             :WorkPackage,
             :Status,
             :Type,
             :Project,
             :ProjectsController,
             :ProjectsHelper,
             :User,
             :VersionsController,
             :Version]

    patch_with_namespace :API, :V3, :WorkPackages, :Schema, :SpecificWorkPackageSchema
    patch_with_namespace :BasicData, :SettingSeeder
    patch_with_namespace :DemoData, :ProjectSeeder
    patch_with_namespace :WorkPackages, :UpdateAncestorsService
    patch_with_namespace :WorkPackages, :UpdateService
    patch_with_namespace :WorkPackages, :SetAttributesService
    patch_with_namespace :WorkPackages, :BaseContract

    extend_api_response(:v3, :work_packages, :work_package) do
      property :position,
               render_nil: true,
               skip_render: ->(*) { !(backlogs_enabled? && type && type.passes_attribute_constraint?(:position)) }

      property :story_points,
               render_nil: true,
               skip_render: ->(*) { !(backlogs_enabled? && type && type.passes_attribute_constraint?(:story_points)) }

      property :remaining_time,
               exec_context: :decorator,
               render_nil: true,
               skip_render: ->(represented:, **) { !represented.backlogs_enabled? }

      # cannot use def here as it wouldn't define the method on the representer
      define_method :remaining_time do
        datetime_formatter.format_duration_from_hours(represented.remaining_hours,
                                                      allow_nil: true)
      end

      define_method :remaining_time= do |value|
        remaining = datetime_formatter.parse_duration_to_hours(value,
                                                               'remainingTime',
                                                               allow_nil: true)
        represented.remaining_hours = remaining
      end
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_schema) do
      schema :position,
             type: 'Integer',
             required: false,
             writable: false,
             show_if: ->(*) {
               represented.project && represented.project.backlogs_enabled? &&
                 (!represented.type || represented.type.passes_attribute_constraint?(:position))
             }

      schema :story_points,
             type: 'Integer',
             required: false,
             show_if: ->(*) {
               represented.project && represented.project.backlogs_enabled? &&
                 (!represented.type || represented.type.passes_attribute_constraint?(:story_points))
             }

      schema :remaining_time,
             type: 'Duration',
             name_source: :remaining_hours,
             required: false,
             show_if: ->(*) { represented.project && represented.project.backlogs_enabled? }
    end

    extend_api_response(:v3, :work_packages, :schema, :work_package_sums_schema) do
      schema :story_points,
             type: 'Integer',
             required: false,
             show_if: ->(*) {
               ::Setting.work_package_list_summable_columns.include?('story_points')
             }

      schema :remaining_time,
             type: 'Duration',
             name_source: :remaining_hours,
             required: false,
             writable: false,
             show_if: ->(*) {
               ::Setting.work_package_list_summable_columns.include?('remaining_hours')
             }
    end

    extend_api_response(:v3, :work_packages, :work_package_sums) do
      property :story_points,
               render_nil: true,
               if: ->(*) {
                 ::Setting.work_package_list_summable_columns.include?('story_points')
               }

      property :remaining_time,
               render_nil: true,
               exec_context: :decorator,
               getter: ->(*) {
                 datetime_formatter.format_duration_from_hours(represented.remaining_hours,
                                                               allow_nil: true)
               },
               if: ->(*) {
                 ::Setting.work_package_list_summable_columns.include?('remaining_hours')
               }
    end

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
