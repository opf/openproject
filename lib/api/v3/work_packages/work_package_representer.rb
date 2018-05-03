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

module API
  module V3
    module WorkPackages
      class WorkPackageRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource

        class << self
          def create_class(work_package)
            injector_class = ::API::V3::Utilities::CustomFieldInjector
            injector_class.create_value_representer(work_package,
                                                    self)
          end

          def create(work_package, current_user:, embed_links: false)
            create_class(work_package)
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
          next unless current_user_allowed_to(:edit_work_packages, context: represented.project)
          {
            href: api_v3_paths.work_package_form(represented.id),
            method: :post
          }
        end

        link :schema do
          {
            href: api_v3_paths.work_package_schema(represented.project_id, represented.type_id)
          }
        end

        link :updateImmediately do
          next unless current_user_allowed_to(:edit_work_packages, context: represented.project)
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch
          }
        end

        link :delete do
          next unless current_user_allowed_to(:delete_work_packages, context: represented.project)
          {
            href: api_v3_paths.work_package(represented.id),
            method: :delete
          }
        end

        link :logTime do
          next unless current_user_allowed_to(:log_time, context: represented.project) &&
                      represented.id
          {
            href: new_work_package_time_entry_path(represented),
            type: 'text/html',
            title: "Log time on #{represented.subject}"
          }
        end

        link :move do
          next unless current_user_allowed_to(:move_work_packages, context: represented.project) &&
                      represented.id

          {
            href: new_work_package_move_path(represented),
            type: 'text/html',
            title: "Move #{represented.subject}"
          }
        end

        link :copy do
          next unless current_user_allowed_to(:move_work_packages, context: represented.project) &&
                      represented.id
          {
            href: new_work_package_move_path(represented, copy: true, ids: [represented.id]),
            type: 'text/html',
            title: "Copy #{represented.subject}"
          }
        end

        link :pdf do
          next unless current_user_allowed_to(:export_work_packages, context: represented.project) &&
                      represented.id

          {
            href: work_package_path(id: represented.id, format: :pdf),
            type: 'application/pdf',
            title: 'Export as PDF'
          }
        end

        link :atom do
          next unless Setting.feeds_enabled? &&
                      current_user_allowed_to(:export_work_packages, context: represented.project) &&
                      represented.id
          {
            href: work_package_path(id: represented.id, format: :atom),
            type: 'application/rss+xml',
            title: 'Atom feed'
          }
        end

        link :available_relation_candidates do
          next unless represented.id

          {
            href: "/api/v3/work_packages/#{represented.id}/available_relation_candidates",
            title: "Potential work packages to relate to"
          }
        end

        link :customFields do
          next unless current_user_allowed_to(:edit_project, context: represented.project)
          {
            href: settings_project_path(represented.project.identifier, tab: 'custom_fields'),
            type: 'text/html',
            title: "Custom fields"
          }
        end

        link :configureForm do
          next unless current_user.admin? && represented.type_id
          {
            href: edit_type_path(represented.type_id, tab: 'form_configuration'),
            type: 'text/html',
            title: "Configure form"
          }
        end

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
          next unless current_user_allowed_to(:edit_work_packages, context: represented.project) ||
                      current_user_allowed_to(:add_work_packages, context: represented.project)
          {
            href: api_v3_paths.attachments_by_work_package(represented.id),
            method: :post
          }
        end

        link :availableWatchers do
          next unless current_user_allowed_to(:add_work_package_watchers, context: represented.project)
          {
            href: api_v3_paths.available_watchers(represented.id)
          }
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
          next if current_user.anonymous? || represented.watcher_users.include?(current_user)
          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            payload: { user: { href: api_v3_paths.user(current_user.id) } }
          }
        end

        link :unwatch do
          next unless represented.watcher_users.include?(current_user)
          {
            href: api_v3_paths.watcher(current_user.id, represented.id),
            method: :delete
          }
        end

        link :watchers do
          next unless  current_user_allowed_to(:view_work_package_watchers, context: represented.project)
          {
            href: api_v3_paths.work_package_watchers(represented.id)
          }
        end

        link :addWatcher do
          next unless current_user_allowed_to(:add_work_package_watchers, context: represented.project)
          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            payload: { user: { href: api_v3_paths.user('{user_id}') } },
            templated: true
          }
        end

        link :removeWatcher do
          next unless current_user_allowed_to(:delete_work_package_watchers, context: represented.project)
          {
            href: api_v3_paths.watcher('{user_id}', represented.id),
            method: :delete,
            templated: true
          }
        end

        link :addRelation do
          next unless current_user_allowed_to(:manage_work_package_relations,
                                              context: represented.project)
          {
            href: api_v3_paths.work_package_relations(represented.id),
            method: :post,
            title: 'Add relation'
          }
        end

        link :addChild do
          next unless current_user_allowed_to(:add_work_packages, context: represented.project)
          {
            href: api_v3_paths.work_packages_by_project(represented.project.identifier),
            method: :post,
            title: "Add child of #{represented.subject}"
          }
        end

        link :changeParent do
          next unless current_user_allowed_to(:manage_subtasks, context: represented.project)
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch,
            title: "Change parent of #{represented.subject}"
          }
        end

        link :addComment do
          next unless current_user_allowed_to(:add_work_package_notes, context: represented.project)
          {
            href: api_v3_paths.work_package_activities(represented.id),
            method: :post,
            title: 'Add comment'
          }
        end

        link :previewMarkup do
          {
            href: api_v3_paths.render_markup(link: api_v3_paths.work_package(represented.id)),
            method: :post
          }
        end

        link :timeEntries do
          next unless current_user_allowed_to(:view_time_entries, context: represented.project) &&
                      represented.id
          {
            href: work_package_time_entries_path(represented.id),
            type: 'text/html',
            title: 'Time entries'
          }
        end

        links :children do
          next if visible_children.empty?

          visible_children.map do |child|
            {
              href: api_v3_paths.work_package(child.id),
              title: child.subject
            }
          end
        end

        links :ancestors do
          represented.visible_ancestors(current_user).map do |ancestor|
            {
              href: api_v3_paths.work_package(ancestor.id),
              title: ancestor.subject
            }
          end
        end

        property :id,
                 render_nil: true

        property :lock_version,
                 render_nil: true,
                 getter: ->(*) {
                   lock_version.to_i
                 }

        property :subject,
                 render_nil: true

        property :description,
                 exec_context: :decorator,
                 getter: ->(*) {
                   ::API::Decorators::Formattable.new(represented.description, object: represented)
                 },
                 setter: ->(fragment:, **) {
                   represented.description = fragment['raw']
                 },
                 render_nil: true

        property :start_date,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.start_date, allow_nil: true)
                 end,
                 render_nil: true,
                 if: ->(_) {
                   !represented.milestone?
                 }

        property :due_date,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.due_date, allow_nil: true)
                 end,
                 render_nil: true,
                 if: ->(_) {
                   !represented.milestone?
                 }

        property :date,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.due_date, allow_nil: true)
                 end,
                 render_nil: true,
                 if: ->(*) {
                   represented.milestone?
                 }

        property :estimated_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.estimated_hours,
                                                                 allow_nil: true)
                 end,
                 render_nil: true

        property :spent_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.spent_hours)
                 end,
                 if: ->(_) {
                   current_user_allowed_to(:view_time_entries, context: represented.project)
                 }

        property :done_ratio,
                 as: :percentageDone,
                 render_nil: true,
                 if: ->(*) { Setting.work_package_done_ratio != 'disabled' }

        property :created_at,
                 exec_context: :decorator,
                 getter: ->(*) {
                   next unless represented.created_at
                   datetime_formatter.format_datetime(represented.created_at)
                 }

        property :updated_at,
                 exec_context: :decorator,
                 getter: ->(*) {
                   next unless represented.updated_at
                   datetime_formatter.format_datetime(represented.updated_at)
                 }

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

        associated_resource :category

        associated_resource :type

        associated_resource :priority

        associated_resource :project

        associated_resource :status

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resource :responsible,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resource :assigned_to,
                            as: :assignee,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resource :fixed_version,
                            as: :version,
                            v3_path: :version,
                            representer: ::API::V3::Versions::VersionRepresenter

        associated_resource :parent,
                            v3_path: :work_package,
                            representer: ::API::V3::WorkPackages::WorkPackageRepresenter,
                            skip_render: ->(*) { represented.parent && !represented.parent.visible? },
                            link_title_attribute: :subject,
                            link: ->(*) {
                              next if represented.parent && !represented.parent.visible?

                              if represented.parent
                                {
                                  href: api_v3_paths.work_package(represented.parent.id),
                                  title: represented.parent.subject
                                }
                              else
                                {
                                  href: nil,
                                  title: nil
                                }
                              end
                            },
                            setter: ->(fragment:, **) do
                              next if fragment.empty?

                              href = fragment['href']

                              new_parent = if href
                                             id = ::API::Utilities::ResourceLinkParser
                                                  .parse_id href,
                                                            property: 'parent',
                                                            expected_version: '3',
                                                            expected_namespace: 'work_packages'

                                             WorkPackage.find_by(id: id) ||
                                               ::WorkPackage::InexistentWorkPackage.new(id: id)
                                           end

                              represented.parent = new_parent
                            end

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
          visible_relations = represented.visible_relations(current_user).non_hierarchy

          ::API::V3::Relations::RelationCollectionRepresenter.new(visible_relations,
                                                                  self_path,
                                                                  current_user: current_user)
        end

        def visible_children
          @visible_children ||= represented.children.select(&:visible?)
        end

        def date=(value)
          new_date = datetime_formatter.parse_date(value,
                                                   'date',
                                                   allow_nil: true)

          represented.due_date = represented.start_date = new_date
        end

        def due_date=(value)
          represented.due_date = datetime_formatter.parse_date(value,
                                                               'dueDate',
                                                               allow_nil: true)
        end

        def start_date=(value)
          represented.start_date = datetime_formatter.parse_date(value,
                                                                 'startDate',
                                                                 allow_nil: true)
        end

        def estimated_time=(value)
          represented.estimated_hours = datetime_formatter.parse_duration_to_hours(value,
                                                                                   'estimatedTime',
                                                                                   allow_nil: true)
        end

        def created_at=(value)
          represented.created_at = datetime_formatter.parse_datetime(value,
                                                                     'createdAt',
                                                                     allow_nil: true)
        end

        def updated_at=(value)
          represented.updated_at = datetime_formatter.parse_datetime(value,
                                                                     'updatedAt',
                                                                     allow_nil: true)
        end

        def spent_time=(value)
          # noop
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
