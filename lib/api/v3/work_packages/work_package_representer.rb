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
            href: "#{root_path}api/v3/work_packages/#{represented.id}",
            title: "#{represented.subject}"
          }
        end

        link :update do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}",
            method: :patch,
            title: "Update #{represented.subject}"
          } if current_user_allowed_to(:edit_work_packages, represented)
        end

        link :delete do
          {
            href: work_packages_bulk_path(ids: represented),
            method: :delete,
            title: "Delete #{represented.subject}"
          } if current_user_allowed_to(:delete_work_packages, represented)
        end

        link :log_time do
          {
            href: new_work_package_time_entry_path(represented),
            type: 'text/html',
            title: "Log time on #{represented.subject}"
          } if current_user_allowed_to(:log_time, represented)
        end

        link :duplicate do
          {
            href: new_project_work_package_path(represented.project, copy_from: represented),
            type: 'text/html',
            title: "Duplicate #{represented.subject}"
          } if current_user_allowed_to(:add_work_packages, represented)
        end

        link :move do
          {
            href: new_work_package_move_path(represented),
            type: 'text/html',
            title: "Move #{represented.subject}"
          } if current_user_allowed_to(:move_work_packages, represented)
        end

        link :author do
          {
            href: "#{root_path}api/v3/users/#{represented.author.id}",
            title: "#{represented.author.name} - #{represented.author.login}"
          } unless represented.author.nil?
        end

        link :responsible do
          {
            href: "#{root_path}api/v3/users/#{represented.responsible.id}",
            title: "#{represented.responsible.name} - #{represented.responsible.login}"
          } unless represented.responsible.nil?
        end

        link :assignee do
          {
            href: "#{root_path}api/v3/users/#{represented.assigned_to.id}",
            title: "#{represented.assigned_to.name} - #{represented.assigned_to.login}"
          } unless represented.assigned_to.nil?
        end

        link :availableStatuses do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}/available_statuses",
            title: 'Available Statuses'
          } if @current_user.allowed_to?({ controller: :work_packages, action: :update },
                                         represented.project)
        end

        link :availableWatchers do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}/available_watchers",
            title: 'Available Watchers'
          }
        end

        link :watchChanges do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}/watchers",
            method: :post,
            data: { user_id: @current_user.id },
            title: 'Watch work package'
          } if !@current_user.anonymous? &&
               current_user_allowed_to(:view_work_packages, represented) &&
               !represented.watcher_users.include?(@current_user)
        end

        link :unwatchChanges do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}/watchers/#{@current_user.id}",
            method: :delete,
            title: 'Unwatch work package'
          } if current_user_allowed_to(:view_work_packages, represented) && represented.watcher_users.include?(@current_user)
        end

        link :addWatcher do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}/watchers{?user_id}",
            method: :post,
            title: 'Add watcher',
            templated: true
          } if current_user_allowed_to(:add_work_package_watchers, represented)
        end

        link :addRelation do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}/relations",
            method: :post,
            title: 'Add relation'
          } if current_user_allowed_to(:manage_work_package_relations, represented)
        end

        link :addChild do
          {
            href: new_project_work_package_path(represented.project, work_package: { parent_id: represented }),
            type: 'text/html',
            title: "Add child of #{represented.subject}"
          } if current_user_allowed_to(:add_work_packages, represented)
        end

        link :changeParent do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}",
            method: :patch,
            title: "Change parent of #{represented.subject}"
          } if current_user_allowed_to(:manage_subtasks, represented)
        end

        link :addComment do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.id}/activities",
            method: :post,
            title: 'Add comment'
          } if current_user_allowed_to(:add_work_package_notes, represented)
        end

        link :parent do
          {
            href: "#{root_path}api/v3/work_packages/#{represented.parent.id}",
            title:  represented.parent.subject
          } unless represented.parent.nil? || !represented.parent.visible?
        end

        link :version do
          {
            href: version_path(represented.fixed_version),
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
        property :type, render_nil: true
        property :description, exec_context: :decorator, render_nil: true, writeable: false
        property :raw_description,
                 getter: -> (*) { description },
                 setter: -> (value, *) { self.description = value },
                 render_nil: true
        property :status, render_nil: true
        property :is_closed, getter: -> (*) { closed? }
        property :priority, render_nil: true
        property :start_date, getter: -> (*) { start_date.to_datetime.utc.iso8601 unless start_date.nil? }, render_nil: true
        property :due_date, getter: -> (*) { due_date.to_datetime.utc.iso8601 unless due_date.nil? }, render_nil: true
        property :estimated_time,
                 getter: -> (*) { { units: I18n.t(:'datetime.units.hour', count: estimated_hours.to_i),
                                    value: estimated_hours } },
                 setter: -> (value, *) { estimated_hours = ActiveSupport::JSON.decode(value)['value'] },
                 render_nil: true
        property :percentage_done,
                 render_nil: true,
                 exec_context: :decorator,
                 setter: -> (value, *) { done_ratio = value },
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

        property :author, embedded: true, class: ::User, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !author.nil? }
        property :responsible, embedded: true, class: ::User, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !responsible.nil? }
        property :assigned_to, as: :assignee, embedded: true, class: ::User, decorator: ::API::V3::Users::UserRepresenter, if: -> (*) { !assigned_to.nil? }
        property :category, embedded: true, class: ::Category, decorator: ::API::V3::Categories::CategoryRepresenter, if: -> (*) { !category.nil? }

        property :activities, embedded: true, exec_context: :decorator
        property :watchers, embedded: true, exec_context: :decorator, if: -> (*) { current_user_allowed_to(:view_work_package_watchers, represented) }
        collection :attachments, embedded: true, class: ::Attachment, decorator: ::API::V3::Attachments::AttachmentRepresenter
        property :relations, embedded: true, exec_context: :decorator

        def _type
          'WorkPackage'
        end

        def description
          format_text(represented, :description)
        end

        def activities
          represented.journals.map{ |activity| ::API::V3::Activities::ActivityRepresenter.new(activity, current_user: @current_user) }
        end

        def watchers
          watchers = represented.watcher_users.order(User::USER_FORMATS_STRUCTURE[Setting.user_format])
          watchers.map { |watcher| ::API::V3::Users::UserRepresenter.new(watcher, work_package: represented, current_user: @current_user) }
        end

        def relations
          relations = represented.relations
          visible_relations = relations.find_all { |relation| relation.other_work_package(represented).visible? }
          visible_relations.map{ |relation| RelationRepresenter.new(relation, work_package: represented, current_user: @current_user) }
        end

        def custom_properties
            values = represented.custom_field_values
            values.map { |v| { name: v.custom_field.name, format: v.custom_field.field_format, value: v.value }}
        end

        def current_user_allowed_to(permission, work_package)
          @current_user && @current_user.allowed_to?(permission, represented.project)
        end

        def visible_children
          @visible_children ||= represented.children.find_all { |child| child.visible? }
        end

        def percentage_done
          represented.done_ratio unless Setting.work_package_done_ratio == 'disabled'
        end
      end
    end
  end
end
