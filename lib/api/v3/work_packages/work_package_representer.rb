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
require 'roar/representer/json/hal'

module API
  module V3
    module WorkPackages
      class WorkPackageRepresenter < Roar::Decorator
        include Roar::Representer::JSON::HAL
        include Roar::Representer::Feature::Hypermedia
        include OpenProject::StaticRouting::UrlHelpers

        self.as_strategy = ::API::Utilities::CamelCasingStrategy.new

        def initialize(model, options = {}, *expand)
          @current_user = options[:current_user]
          @expand = expand

          super(model)
        end

        property :_type, exec_context: :decorator, writeable: false

        link :self do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}",
            title: "#{represented.subject}"
          }
        end

        link :update do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}",
            method: :patch,
            title: "Update #{represented.subject}"
          } if current_user_allowed_to(:edit_work_packages, represented.model)
        end

        link :delete do
          {
            href: work_packages_bulk_path(ids: represented.model),
            method: :delete,
            title: "Delete #{represented.subject}"
          } if current_user_allowed_to(:delete_work_packages, represented.model)
        end

        link :log_time do
          {
            href: new_work_package_time_entry_path(represented.model),
            type: 'text/html',
            title: "Log time on #{represented.subject}"
          } if current_user_allowed_to(:log_time, represented.model)
        end

        link :duplicate do
          {
            href: new_project_work_package_path(represented.model.project, copy_from: represented.model),
            type: 'text/html',
            title: "Duplicate #{represented.subject}"
          } if current_user_allowed_to(:add_work_packages, represented.model)
        end

        link :move do
          {
            href: new_work_package_move_path(represented.model),
            type: 'text/html',
            title: "Move #{represented.subject}"
          } if current_user_allowed_to(:move_work_packages, represented.model)
        end

        link :author do
          {
            href: "#{root_path}api/v3/users/#{represented.model.author.id}",
            title: "#{represented.model.author.name} - #{represented.model.author.login}"
          } unless represented.model.author.nil?
        end

        link :responsible do
          {
            href: "#{root_path}api/v3/users/#{represented.model.responsible.id}",
            title: "#{represented.model.responsible.name} - #{represented.model.responsible.login}"
          } unless represented.model.responsible.nil?
        end

        link :assignee do
          {
            href: "#{root_path}api/v3/users/#{represented.model.assigned_to.id}",
            title: "#{represented.model.assigned_to.name} - #{represented.model.assigned_to.login}"
          } unless represented.model.assigned_to.nil?
        end

        link :availableStatuses do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}/available_statuses",
            title: 'Available Statuses'
          } if @current_user.allowed_to?({ controller: :work_packages, action: :update },
                                         represented.model.project)
        end

        link :availableWatchers do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}/available_watchers",
            title: 'Available Watchers'
          }
        end

        link :watchChanges do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}/watchers",
            method: :post,
            data: { user_id: @current_user.id },
            title: 'Watch work package'
          } if !@current_user.anonymous? &&
             current_user_allowed_to(:view_work_packages, represented.model) &&
            !represented.model.watcher_users.include?(@current_user)
        end

        link :unwatchChanges do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}/watchers/#{@current_user.id}",
            method: :delete,
            title: 'Unwatch work package'
          } if current_user_allowed_to(:view_work_packages, represented.model) && represented.model.watcher_users.include?(@current_user)
        end

        link :addWatcher do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}/watchers{?user_id}",
            method: :post,
            title: 'Add watcher',
            templated: true
          } if current_user_allowed_to(:add_work_package_watchers, represented.model)
        end

        link :addRelation do
          {
              href: "#{root_path}api/v3/work_packages/#{represented.model.id}/relations",
              method: :post,
              title: 'Add relation'
          } if current_user_allowed_to(:manage_work_package_relations, represented.model)
        end

        link :addChild do
          {
            href: new_project_work_package_path(represented.model.project, work_package: {parent_id: represented.model}),
            type: 'text/html',
            title: "Add child of #{represented.subject}"
          } if current_user_allowed_to(:add_work_packages, represented.model)
        end

        link :changeParent do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.model.id}",
            method: :patch,
            title: "Change parent of #{represented.subject}"
          } if current_user_allowed_to(:manage_subtasks, represented.model)
        end

        link :addComment do
          {
              href: "#{root_path}api/v3/work_packages/#{represented.model.id}/activities",
              method: :post,
              title: 'Add comment'
          } if current_user_allowed_to(:add_work_package_notes, represented.model)
        end

        link :parent do
          {
              href: "#{root_path}api/v3/work_packages/#{represented.model.parent.id}",
              title:  represented.model.parent.subject
          } unless represented.model.parent.nil? || !represented.model.parent.visible?
        end

        link :version do
          {
            href: version_path(represented.model.fixed_version),
            type: 'text/html',
            title: "#{represented.model.fixed_version.to_s_for_project(represented.model.project)}"
          } if represented.model.fixed_version && @current_user.allowed_to?({controller: "versions", action: "show"}, represented.model.fixed_version.project, global: false)
        end

        links :children do
          visible_children.map do |child|
            { href: "#{root_path}api/v3/work_packages/#{child.id}", title: child.subject }
          end unless visible_children.empty?
        end

        property :id, getter: -> (*) { model.id }, render_nil: true, writeable: false
        property :subject, render_nil: true, writeable: false
        property :type, render_nil: true, writeable: false
        property :description, render_nil: true, writeable: false
        property :raw_description, render_nil: true, writeable: false
        property :status, render_nil: true, writeable: false
        property :is_closed, writeable: false
        property :priority, render_nil: true, writeable: false
        property :start_date, getter: -> (*) { model.start_date.to_datetime.utc.iso8601 unless model.start_date.nil? }, render_nil: true, writeable: false
        property :due_date, getter: -> (*) { model.due_date.to_datetime.utc.iso8601 unless model.due_date.nil? }, render_nil: true, writeable: false
        property :estimated_time, render_nil: true, writeable: false
        property :percentage_done,
                 render_nil: true,
                 exec_context: :decorator,
                 setter: -> (value, *) { represented.percentage_done = value },
                 writeable: false
        property :version_id, getter: -> (*) { model.fixed_version.try(:id) }, render_nil: true, writeable: false
        property :version_name,  getter: -> (*) { model.fixed_version.try(:name) }, render_nil: true, writeable: false
        property :project_id, getter: -> (*) { model.project.id }, writeable: false
        property :project_name, getter: -> (*) { model.project.try(:name) }, writeable: false
        property :parent_id, writeable: true
        property :created_at, getter: -> (*) { model.created_at.utc.iso8601 }, render_nil: true, writeable: false
        property :updated_at, getter: -> (*) { model.updated_at.utc.iso8601 }, render_nil: true, writeable: false

        collection :custom_properties, exec_context: :decorator, render_nil: true, writeable: false

        property :author, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !author.nil? }, writeable: false
        property :responsible, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !responsible.nil? }, writeable: false
        property :assignee, embedded: true, class: ::API::V3::Users::UserModel, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !assignee.nil? }, writeable: false
        property :category, embedded: true, class: ::API::V3::Categories::CategoryModel, decorator: ::API::V3::Categories::CategoryRepresenter, if: -> (*) { !category.nil? }, writeable: false

        property :activities, embedded: true, exec_context: :decorator, writeable: false
        property :watchers, embedded: true, exec_context: :decorator, if: -> (*) { current_user_allowed_to(:view_work_package_watchers, represented.model) }, writeable: false
        collection :attachments, embedded: true, class: ::API::V3::Attachments::AttachmentModel, decorator: ::API::V3::Attachments::AttachmentRepresenter, writeable: false
        property :relations, embedded: true, exec_context: :decorator, writeable: false

        def _type
          'WorkPackage'
        end

        def activities
          represented.activities.map{ |activity| ::API::V3::Activities::ActivityRepresenter.new(activity, current_user: @current_user) }
        end

        def watchers
          represented.watchers.map{ |watcher| ::API::V3::Users::UserRepresenter.new(watcher, work_package: represented.model, current_user: @current_user) }
        end

        def relations
          represented.relations.map{ |relation| RelationRepresenter.new(relation, work_package: represented.model, current_user: @current_user) }
        end

        def custom_properties
            values = represented.model.custom_field_values
            values.map { |v| { name: v.custom_field.name, format: v.custom_field.field_format, value: v.value }}
        end

        def current_user_allowed_to(permission, work_package)
          @current_user && @current_user.allowed_to?(permission, represented.model.project)
        end

        def visible_children
          @visible_children ||= represented.model.children.find_all { |child| child.visible? }
        end

        def percentage_done
          represented.percentage_done unless Setting.work_package_done_ratio == 'disabled'
        end
      end
    end
  end
end
