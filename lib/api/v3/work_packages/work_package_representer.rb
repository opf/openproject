#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'roar/decorator'
require 'roar/json/hal'

module API
  module V3
    module WorkPackages
      class WorkPackageRepresenter < ::API::Decorators::Single
        class << self
          def create_class(work_package, embed_links: false)
            injector_class = ::API::V3::Utilities::CustomFieldInjector
            injector_class.create_value_representer(work_package,
                                                    WorkPackageRepresenter,
                                                    embed_links: embed_links)
          end

          def create(work_package, current_user:, embed_links: false)
            create_class(work_package,
                         embed_links: embed_links)
              .new(work_package,
                   current_user: current_user,
                   embed_links: embed_links)
          end
        end

        def initialize(model, current_user:, embed_links: false)
          # Define all accessors on the customizable as they
          # will be used afterwards anyway. Otherwise, we will have to
          # go through method_missing which will take more time.
          model.define_all_custom_field_accessors

          super
        end

        self_link title_getter: ->(*) { represented.subject }

        link :update do
          {
            href: api_v3_paths.work_package_form(represented.id),
            method: :post
          } if current_user_allowed_to(:edit_work_packages, context: represented.project)
        end

        link :schema do
          {
            href: api_v3_paths.work_package_schema(represented.project.id, represented.type.id)
          }
        end

        link :updateImmediately do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch
          } if current_user_allowed_to(:edit_work_packages, context: represented.project)
        end

        link :delete do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :delete
          } if current_user_allowed_to(:delete_work_packages, context: represented.project)
        end

        link :logTime do
          {
            href: new_work_package_time_entry_path(represented),
            type: 'text/html',
            title: "Log time on #{represented.subject}"
          } if current_user_allowed_to(:log_time, context: represented.project)
        end

        link :move do
          {
            href: new_work_package_move_path(represented),
            type: 'text/html',
            title: "Move #{represented.subject}"
          } if current_user_allowed_to(:move_work_packages, context: represented.project)
        end

        link :copy do
          {
            href: new_work_package_move_path(represented, copy: true, ids: [represented.id]),
            type: 'text/html',
            title: "Copy #{represented.subject}"
          } if current_user_allowed_to(:move_work_packages, context: represented.project)
        end

        link :pdf do
          {
            href: work_package_path(id: represented.id, format: :pdf),
            type: 'application/pdf',
            title: 'Export as PDF'
          } if current_user_allowed_to(:export_work_packages, context: represented.project)
        end

        link :atom do
          {
            href: work_package_path(id: represented.id, format: :atom),
            type: 'application/rss+xml',
            title: 'Atom feed'
          } if Setting.feeds_enabled? &&
               current_user_allowed_to(:export_work_packages, context: represented.project)
        end

        link :available_relation_candidates do
          {
            href: "/api/v3/work_packages/#{represented.id}/available_relation_candidates",
            title: "Potential work packages to relate to"
          }
        end

        link :customFields do
          {
            href: settings_project_path(represented.project.identifier, tab: 'custom_fields'),
            type: 'text/html',
            title: "Custom fields"
          } if current_user_allowed_to(:edit_project, context: represented.project)
        end

        link :configureForm do
          {
            href: edit_type_path(represented.type_id, tab: 'form_configuration'),
            type: 'text/html',
            title: "Configure form"
          } if current_user.admin?
        end

        linked_property :type, embed_as: ::API::V3::Types::TypeRepresenter
        linked_property :status, embed_as: ::API::V3::Statuses::StatusRepresenter

        linked_property :author, path: :user, embed_as: ::API::V3::Users::UserRepresenter
        linked_property :responsible, path: :user, embed_as: ::API::V3::Users::UserRepresenter
        linked_property :assigned_to, path: :user, embed_as: ::API::V3::Users::UserRepresenter

        link :activities do
          {
            href: api_v3_paths.work_package_activities(represented.id)
          }
        end

        link :attachments do
          {
            href: api_v3_paths.attachments_by_work_package(represented.id)
          }
        end

        link :addAttachment do
          {
            href: api_v3_paths.attachments_by_work_package(represented.id),
            method: :post
          } if current_user_allowed_to(:edit_work_packages, context: represented.project) ||
               current_user_allowed_to(:add_work_packages, context: represented.project)
        end

        link :availableWatchers do
          {
            href: api_v3_paths.available_watchers(represented.id)
          } if current_user_allowed_to(:add_work_package_watchers, context: represented.project)
        end

        link :relations do
          {
            href: api_v3_paths.work_package_relations(represented.id)
          }
        end

        link :revisions do
          {
            href: api_v3_paths.work_package_revisions(represented.id)
          }
        end

        link :watch do
          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            payload: { user: { href: api_v3_paths.user(current_user.id) } }
          } unless current_user.anonymous? || represented.watcher_users.include?(current_user)
        end

        link :unwatch do
          {
            href: api_v3_paths.watcher(current_user.id, represented.id),
            method: :delete
          } if represented.watcher_users.include?(current_user)
        end

        link :watchers do
          {
            href: api_v3_paths.work_package_watchers(represented.id)
          } if current_user_allowed_to(:view_work_package_watchers, context: represented.project)
        end

        link :addWatcher do
          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            payload: { user: { href: api_v3_paths.user('{user_id}') } },
            templated: true
          } if current_user_allowed_to(:add_work_package_watchers, context: represented.project)
        end

        link :removeWatcher do
          {
            href: api_v3_paths.watcher('{user_id}', represented.id),
            method: :delete,
            templated: true
          } if current_user_allowed_to(:delete_work_package_watchers, context: represented.project)
        end

        link :addRelation do
          {
            href: api_v3_paths.work_package_relations(represented.id),
            method: :post,
            title: 'Add relation'
          } if current_user_allowed_to(:manage_work_package_relations,
                                       context: represented.project)
        end

        link :addChild do
          {
            href: api_v3_paths.work_packages_by_project(represented.project.identifier),
            method: :post,
            title: "Add child of #{represented.subject}"
          } if current_user_allowed_to(:add_work_packages, context: represented.project)
        end

        link :changeParent do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch,
            title: "Change parent of #{represented.subject}"
          } if current_user_allowed_to(:manage_subtasks, context: represented.project)
        end

        link :addComment do
          {
            href: api_v3_paths.work_package_activities(represented.id),
            method: :post,
            title: 'Add comment'
          } if current_user_allowed_to(:add_work_package_notes, context: represented.project)
        end

        link :previewMarkup do
          {
            href: api_v3_paths.render_markup(link: api_v3_paths.work_package(represented.id)),
            method: :post
          }
        end

        linked_property :parent,
                        path: :work_package,
                        title_getter: ->(*) { represented.parent.subject },
                        show_if: ->(*) { represented.parent.nil? || represented.parent.visible? }

        link :timeEntries do
          {
            href: work_package_time_entries_path(represented.id),
            type: 'text/html',
            title: 'Time entries'
          } if current_user_allowed_to(:view_time_entries, context: represented.project)
        end

        linked_property :category, embed_as: ::API::V3::Categories::CategoryRepresenter
        linked_property :priority, embed_as: ::API::V3::Priorities::PriorityRepresenter
        linked_property :project, embed_as: ::API::V3::Projects::ProjectRepresenter

        linked_property :version,
                        getter: :fixed_version,
                        title_getter: ->(*) {
                          represented.fixed_version.to_s
                        },
                        embed_as: ::API::V3::Versions::VersionRepresenter

        links :children do
          visible_children.map do |child|
            {
              href: api_v3_paths.work_package(child.id),
              title: child.subject
            }
          end unless visible_children.empty?
        end

        links :ancestors do
          represented.visible_ancestors(current_user).map do |ancestor|
            {
              href: api_v3_paths.work_package(ancestor.id),
              title: ancestor.subject
            }
          end
        end

        property :id, render_nil: true
        property :lock_version
        property :subject, render_nil: true
        property :description,
                 exec_context: :decorator,
                 getter: ->(*) {
                   ::API::Decorators::Formattable.new(represented.description, object: represented)
                 },
                 setter: ->(value, *) { represented.description = value['raw'] },
                 render_nil: true

        property :start_date,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.start_date, allow_nil: true)
                 end,
                 render_nil: true,
                 if: ->(_) {
                   !represented.is_milestone?
                 }
        property :due_date,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.due_date, allow_nil: true)
                 end,
                 render_nil: true,
                 if: ->(_) {
                   !represented.is_milestone?
                 }
        property :date,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.due_date, allow_nil: true)
                 end,
                 render_nil: true,
                 if: ->(_) {
                   represented.is_milestone?
                 }
        property :estimated_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.estimated_hours,
                                                                 allow_nil: true)
                 end,
                 render_nil: true,
                 writeable: false
        property :spent_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.spent_hours)
                 end,
                 writeable: false,
                 if: ->(_) {
                   current_user_allowed_to(:view_time_entries, context: represented.project)
                 }
        property :done_ratio,
                 as: :percentageDone,
                 render_nil: true,
                 writeable: false,
                 if: ->(*) { Setting.work_package_done_ratio != 'disabled' }
        property :created_at,
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.created_at) }
        property :updated_at,
                 exec_context: :decorator,
                 getter: ->(*) { datetime_formatter.format_datetime(represented.updated_at) }

        property :watchers,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) {
                   current_user_allowed_to(:view_work_package_watchers,
                                           context: represented.project) &&
                     embed_links
                 }

        property :attachments,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) { embed_links }

        property :relations,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) { embed_links }

        def _type
          'WorkPackage'
        end

        def watchers
          # TODO/LEGACY: why do we need to ensure a specific order here?
          watchers = represented.watcher_users.order(User::USER_FORMATS_STRUCTURE[Setting.user_format])
          self_link = api_v3_paths.work_package_watchers(represented.id)

          Users::UserCollectionRepresenter.new(watchers,
                                               self_link,
                                               current_user: current_user)
        end

        def attachments
          self_path = api_v3_paths.attachments_by_work_package(represented.id)
          attachments = represented.attachments
          ::API::V3::Attachments::AttachmentCollectionRepresenter.new(attachments,
                                                                      self_path,
                                                                      current_user: current_user)
        end

        def relations
          self_path = api_v3_paths.work_package_relations(represented.id)
          relations = represented.relations
          visible_relations = relations.select do |relation|
            relation.other_work_package(represented).visible?
          end

          ::API::V3::Relations::RelationCollectionRepresenter.new(visible_relations,
                                                                  self_path,
                                                                  current_user: current_user)
        end

        def visible_children
          @visible_children ||= represented.children.select(&:visible?)
        end

        self.to_eager_load = [{ children: { project: :enabled_modules } },
                              { parent: { project: :enabled_modules } },
                              { project: %i(enabled_modules work_package_custom_fields) },
                              :status,
                              :priority,
                              { type: :custom_fields },
                              :fixed_version,
                              { custom_values: :custom_field },
                              :author,
                              :assigned_to,
                              :responsible,
                              :watcher_users,
                              :category,
                              :attachments]
      end
    end
  end
end
