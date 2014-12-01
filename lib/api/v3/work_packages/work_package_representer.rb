#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      class WorkPackageRepresenter < Roar::Decorator
        include Roar::JSON::HAL
        include Roar::Hypermedia
        include API::V3::Utilities::PathHelper
        include OpenProject::TextFormatting

        self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

        def initialize(model, options = {}, *expand)
          @current_user = options[:current_user]
          @expand = expand

          super(model)
        end

        property :_type, exec_context: :decorator, writeable: false

        link :self do
          {
            href: api_v3_paths.work_package(represented.id),
            title: "#{represented.subject}"
          }
        end

        link :update do
          {
            href: api_v3_paths.work_package_form(represented.id),
            method: :post,
            title: "Update #{represented.subject}"
          } if current_user_allowed_to(:edit_work_packages)
        end

        link :updateImmediately do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch,
            title: "Update #{represented.subject}"
          } if current_user_allowed_to(:edit_work_packages)
        end

        link :delete do
          {
            href: work_packages_bulk_path(ids: represented),
            method: :delete,
            title: "Delete #{represented.subject}"
          } if current_user_allowed_to(:delete_work_packages)
        end

        link :log_time do
          {
            href: new_work_package_time_entry_path(represented),
            type: 'text/html',
            title: "Log time on #{represented.subject}"
          } if current_user_allowed_to(:log_time)
        end

        link :duplicate do
          {
            href: new_project_work_package_path(represented.project, copy_from: represented),
            type: 'text/html',
            title: "Duplicate #{represented.subject}"
          } if current_user_allowed_to(:add_work_packages)
        end

        link :move do
          {
            href: new_work_package_move_path(represented),
            type: 'text/html',
            title: "Move #{represented.subject}"
          } if current_user_allowed_to(:move_work_packages)
        end

        link :status do
          {
            href: api_v3_paths.status(represented.status_id),
            title: "#{represented.status.name}"
          }
        end

        link :author do
          {
            href: api_v3_paths.user(represented.author.id),
            title: "#{represented.author.name} - #{represented.author.login}"
          } unless represented.author.nil?
        end

        link :responsible do
          {
            href: api_v3_paths.user(represented.responsible.id),
            title: "#{represented.responsible.name} - #{represented.responsible.login}"
          } unless represented.responsible.nil?
        end

        link :assignee do
          {
            href: api_v3_paths.user(represented.assigned_to.id),
            title: "#{represented.assigned_to.name} - #{represented.assigned_to.login}"
          } unless represented.assigned_to.nil?
        end

        link :availableWatchers do
          {
            href: api_v3_paths.available_watchers(represented.id),
            title: 'Available Watchers'
          }
        end

        link :watchChanges do
          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            data: { user_id: @current_user.id },
            title: 'Watch work package'
          } if !@current_user.anonymous? &&
               current_user_allowed_to(:view_work_packages) &&
               !represented.watcher_users.include?(@current_user)
        end

        link :unwatchChanges do
          {
            href: "#{api_v3_paths.work_package_watchers(represented.id)}/#{@current_user.id}",
            method: :delete,
            title: 'Unwatch work package'
          } if current_user_allowed_to(:view_work_packages) &&
               represented.watcher_users.include?(@current_user)
        end

        link :addWatcher do
          {
            href: "#{api_v3_paths.work_package_watchers(represented.id)}{?user_id}",
            method: :post,
            title: 'Add watcher',
            templated: true
          } if current_user_allowed_to(:add_work_package_watchers)
        end

        link :addRelation do
          {
            href: api_v3_paths.work_package_relations(represented.id),
            method: :post,
            title: 'Add relation'
          } if current_user_allowed_to(:manage_work_package_relations)
        end

        link :addChild do
          {
            href: new_project_work_package_path(represented.project, work_package: { parent_id: represented }),
            type: 'text/html',
            title: "Add child of #{represented.subject}"
          } if current_user_allowed_to(:add_work_packages)
        end

        link :changeParent do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch,
            title: "Change parent of #{represented.subject}"
          } if current_user_allowed_to(:manage_subtasks)
        end

        link :addComment do
          {
            href: api_v3_paths.work_package_activities(represented.id),
            method: :post,
            title: 'Add comment'
          } if current_user_allowed_to(:add_work_package_notes)
        end

        link :parent do
          {
            href: api_v3_paths.work_package(represented.parent.id),
            title:  represented.parent.subject
          } unless represented.parent.nil? || !represented.parent.visible?
        end

        link :timeEntries do
          {
            href: work_package_time_entries_path(represented.id),
            type: 'text/html',
            title: 'Time entries'
          } if current_user_allowed_to(:view_time_entries)
        end

        link :version do
          {
            href: api_v3_paths.versions(represented.fixed_version),
            type: 'text/html',
            title: "#{represented.fixed_version.to_s_for_project(represented.project)}"
          } if represented.fixed_version && @current_user.allowed_to?({ controller: 'versions', action: 'show' }, represented.fixed_version.project, global: false)
        end

        links :children do
          visible_children.map do |child|
            { href: "#{root_path}api/v3/work_packages/#{child.id}", title: child.subject }
          end unless visible_children.empty?
        end

        property :id, render_nil: true
        property :lock_version
        property :subject, render_nil: true
        property :type, getter: -> (*) { type.try(:name) }, render_nil: true
        property :description, exec_context: :decorator, render_nil: true, writeable: false
        property :raw_description,
                 getter: -> (*) { description },
                 setter: -> (value, *) { self.description = value },
                 render_nil: true
        property :priority, getter: -> (*) { priority.try(:name) }, render_nil: true
        property :start_date, getter: -> (*) { start_date.to_datetime.utc.iso8601 unless start_date.nil? }, render_nil: true
        property :due_date, getter: -> (*) { due_date.to_datetime.utc.iso8601 unless due_date.nil? }, render_nil: true
        property :estimated_time,
                 getter: -> (*) do
                   Duration.new(hours_and_minutes(represented.estimated_hours)).iso8601
                 end,
                 exec_context: :decorator,
                 render_nil: true,
                 writeable: false
        property :spent_time,
                 getter: -> (*) do
                   Duration.new(hours_and_minutes(represented.spent_hours)).iso8601
                 end,
                 writeable: false,
                 exec_context: :decorator,
                 if: -> (_) { current_user_allowed_to(:view_time_entries) }
        property :percentage_done,
                 render_nil: true,
                 exec_context: :decorator,
                 setter: -> (value, *) { self.done_ratio = value },
                 writeable: false
        property :version_id,
                 getter: -> (*) { fixed_version.try(:id) },
                 setter: -> (value, *) { self.fixed_version_id = value },
                 render_nil: true
        property :version_name,  getter: -> (*) { fixed_version.try(:name) }, render_nil: true
        property :project_id, getter: -> (*) { project.id }
        property :project_name, getter: -> (*) { project.try(:name) }
        property :parent_id, writeable: true
        property :created_at, getter: -> (*) { created_at.utc.iso8601 }, render_nil: true
        property :updated_at, getter: -> (*) { updated_at.utc.iso8601 }, render_nil: true

        collection :custom_properties, exec_context: :decorator, render_nil: true

        property :status,
                 embedded: true,
                 class: ::Status,
                 decorator: ::API::V3::Statuses::StatusRepresenter
        property :author, embedded: true, class: ::User, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !author.nil? }
        property :responsible, embedded: true, class: ::User, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !responsible.nil? }
        property :assigned_to, as: :assignee, embedded: true, class: ::User, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !assigned_to.nil? }
        property :category, embedded: true, class: ::Category, decorator: ::API::V3::Categories::CategoryRepresenter, if: -> (*) { !category.nil? }

        property :activities, embedded: true, exec_context: :decorator
        property :watchers, embedded: true, exec_context: :decorator, if: -> (*) { current_user_allowed_to(:view_work_package_watchers) }
        collection :attachments, embedded: true, class: ::Attachment, decorator: ::API::V3::Attachments::AttachmentRepresenter
        property :relations, embedded: true, exec_context: :decorator

        def _type
          'WorkPackage'
        end

        def description
          format_text(represented, :description)
        end

        def activities
          represented.journals.map { |activity| ::API::V3::Activities::ActivityRepresenter.new(activity, current_user: @current_user) }
        end

        def watchers
          watchers = represented.watcher_users.order(User::USER_FORMATS_STRUCTURE[Setting.user_format])
          watchers.map { |watcher| ::API::V3::Users::UserRepresenter.new(watcher, work_package: represented, current_user: @current_user) }
        end

        def relations
          relations = represented.relations
          visible_relations = relations.select { |relation| relation.other_work_package(represented).visible? }
          visible_relations.map { |relation| RelationRepresenter.new(relation, work_package: represented, current_user: @current_user) }
        end

        def custom_properties
          values = represented.custom_field_values
          values.map do |v|
            { name: v.custom_field.name, format: v.custom_field.field_format, value: v.value }
          end
        end

        def current_user_allowed_to(permission)
          @current_user && @current_user.allowed_to?(permission, represented.project)
        end

        def visible_children
          @visible_children ||= represented.children.select { |child| child.visible? }
        end

        def percentage_done
          represented.done_ratio unless Setting.work_package_done_ratio == 'disabled'
        end

        private

        def hours_and_minutes(hours)
          hours = hours.to_f
          minutes = (hours - hours.to_i) * 60

          { hours: hours.to_i, minutes: minutes }
        end
      end
    end
  end
end
