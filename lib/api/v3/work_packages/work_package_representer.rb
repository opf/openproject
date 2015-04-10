#-- encoding: UTF-8
#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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
      class WorkPackageRepresenter < ::API::Decorators::Single
        class << self
          def create_class(work_package)
            injector_class = ::API::V3::Utilities::CustomFieldInjector
            injector_class.create_value_representer(work_package,
                                                    WorkPackageRepresenter)
          end

          def create(work_package, context = {})
            create_class(work_package).new(work_package, context)
          end
        end

        self_link title_getter: -> (*) { represented.subject }

        link :update do
          {
            href: api_v3_paths.work_package_form(represented.id),
            method: :post,
            title: "Update #{represented.subject}"
          } if current_user_allowed_to(:edit_work_packages)
        end

        link :schema do
          {
            href: api_v3_paths.work_package_schema(represented.project.id, represented.type.id)
          }
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

        linked_property :type, embed_as: ::API::V3::Types::TypeRepresenter
        linked_property :status, embed_as: ::API::V3::Statuses::StatusRepresenter

        linked_property :author, path: :user, embed_as: ::API::V3::Users::UserRepresenter
        linked_property :responsible, path: :user, embed_as: ::API::V3::Users::UserRepresenter
        linked_property :assignee,
                        path: :user,
                        getter: :assigned_to,
                        embed_as: ::API::V3::Users::UserRepresenter

        link :availableWatchers do
          {
            href: api_v3_paths.available_watchers(represented.id),
            title: 'Available Watchers'
          } if current_user_allowed_to(:add_work_package_watchers)
        end

        link :watchChanges do
          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            data: { user_id: current_user.id },
            title: 'Watch work package'
          } if !current_user.anonymous? &&
               current_user_allowed_to(:view_work_packages) &&
               !represented.watcher_users.include?(current_user)
        end

        link :unwatchChanges do
          {
            href: "#{api_v3_paths.work_package_watchers(represented.id)}/#{current_user.id}",
            method: :delete,
            title: 'Unwatch work package'
          } if current_user_allowed_to(:view_work_packages) &&
               represented.watcher_users.include?(current_user)
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
            href: new_project_work_package_path(represented.project,
                                                work_package: { parent_id: represented }),
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

        linked_property :parent,
                        path: :work_package,
                        title_getter: -> (*) { represented.parent.subject },
                        show_if: -> (*) { represented.parent.nil? || represented.parent.visible? }

        link :timeEntries do
          {
            href: work_package_time_entries_path(represented.id),
            type: 'text/html',
            title: 'Time entries'
          } if current_user_allowed_to(:view_time_entries)
        end

        linked_property :category, embed_as: ::API::V3::Categories::CategoryRepresenter
        linked_property :priority, embed_as: ::API::V3::Priorities::PriorityRepresenter
        linked_property :project, embed_as: ::API::V3::Projects::ProjectRepresenter

        linked_property :version,
                        getter: :fixed_version,
                        title_getter: -> (*) {
                          represented.fixed_version.to_s_for_project(represented.project)
                        }

        links :children do
          visible_children.map do |child|
            { href: "#{root_path}api/v3/work_packages/#{child.id}", title: child.subject }
          end unless visible_children.empty?
        end

        property :id, render_nil: true
        property :lock_version
        property :subject, render_nil: true
        property :description,
                 exec_context: :decorator,
                 getter: -> (*) {
                   ::API::Decorators::Formattable.new(represented.description, object: represented)
                 },
                 setter: -> (value, *) { represented.description = value['raw'] },
                 render_nil: true

        property :start_date,
                 exec_context: :decorator,
                 getter: -> (*) do
                   datetime_formatter.format_date(represented.start_date, allow_nil: true)
                 end,
                 render_nil: true
        property :due_date,
                 exec_context: :decorator,
                 getter: -> (*) do
                   datetime_formatter.format_date(represented.due_date, allow_nil: true)
                 end,
                 render_nil: true
        property :estimated_time,
                 exec_context: :decorator,
                 getter: -> (*) do
                   datetime_formatter.format_duration_from_hours(represented.estimated_hours,
                                                                 allow_nil: true)
                 end,
                 render_nil: true,
                 writeable: false
        property :spent_time,
                 exec_context: :decorator,
                 getter: -> (*) do
                   datetime_formatter.format_duration_from_hours(represented.spent_hours)
                 end,
                 writeable: false,
                 if: -> (_) { current_user_allowed_to(:view_time_entries) }
        property :done_ratio,
                 as: :percentageDone,
                 render_nil: true,
                 writeable: false,
                 if: -> (*) { Setting.work_package_done_ratio != 'disabled' }
        property :parent_id, writeable: true
        property :created_at,
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.created_at) }
        property :updated_at,
                 exec_context: :decorator,
                 getter: -> (*) { datetime_formatter.format_datetime(represented.updated_at) }

        property :activities, embedded: true, exec_context: :decorator

        property :version,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) { represented.fixed_version.present? }
        property :watchers,
                 embedded: true,
                 exec_context: :decorator,
                 if: -> (*) { current_user_allowed_to(:view_work_package_watchers) }
        collection :attachments,
                   embedded: true,
                   class: ::Attachment,
                   decorator: ::API::V3::Attachments::AttachmentRepresenter

        property :relations, embedded: true, exec_context: :decorator

        def _type
          'WorkPackage'
        end

        def activities
          represented.journals.map do |activity|
            ::API::V3::Activities::ActivityRepresenter.new(activity, current_user: current_user)
          end
        end

        def watchers
          watchers =
            represented.watcher_users.order(User::USER_FORMATS_STRUCTURE[Setting.user_format])
          watchers.map do |watcher|
            ::API::V3::Users::UserRepresenter.new(watcher,
                                                  work_package: represented,
                                                  current_user: current_user)
          end
        end

        def relations
          relations = represented.relations
          visible_relations = relations.select do |relation|
            relation.other_work_package(represented).visible?
          end

          visible_relations.map do |relation|
            Relations::RelationRepresenter.new(relation,
                                               work_package: represented,
                                               current_user: current_user)
          end
        end

        def version
          if represented.fixed_version.present?
            Versions::VersionRepresenter.new(represented.fixed_version, current_user: current_user)
          end
        end

        def current_user_allowed_to(permission)
          current_user && current_user.allowed_to?(permission, represented.project)
        end

        def visible_children
          @visible_children ||= represented.children.select(&:visible?)
        end

        private

        def version_policy
          @version_policy ||= ::VersionPolicy.new(current_user)
        end
      end
    end
  end
end
