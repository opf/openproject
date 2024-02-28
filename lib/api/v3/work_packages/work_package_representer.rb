#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2024 the OpenProject GmbH
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

module API
  module V3
    module WorkPackages
      class WorkPackageRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include API::Caching::CachedRepresenter
        include ::API::V3::Attachments::AttachableRepresenterMixin
        include ::API::V3::FileLinks::FileLinkRelationRepresenter
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass
        include TimestampedRepresenter

        cached_representer key_parts: %i(project),
                           disabled: false

        attr_accessor :timestamps, :query

        def initialize(model, current_user:, embed_links: false, timestamps: nil, query: nil)
          @query = query
          @timestamps = timestamps || query.try(:timestamps) || []

          model = load_complete_model(model)

          super(model, current_user:, embed_links:)
        end

        def self_v3_path(*)
          api_v3_paths.work_package(represented.id, timestamps:)
        end

        self_link title_getter: ->(*) { represented.subject },
                  uncacheable: true

        link :update,
             cache_if: -> { current_user_update_allowed? } do
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

        link :updateImmediately,
             cache_if: -> { current_user_update_allowed? } do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { current_user.allowed_in_project?(:delete_work_packages, represented.project) } do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :delete
          }
        end

        link :logTime,
             cache_if: -> { log_time_allowed? } do
          next if represented.new_record?

          {
            href: api_v3_paths.time_entries,
            title: "Log time on #{represented.subject}"
          }
        end

        link :move,
             cache_if: -> { current_user.allowed_in_project?(:move_work_packages, represented.project) } do
          next if represented.new_record?

          {
            href: new_work_package_move_path(represented),
            type: 'text/html',
            title: "Move #{represented.subject}"
          }
        end

        link :copy,
             cache_if: -> { add_work_packages_allowed? } do
          next if represented.new_record?

          {
            href: work_package_path(represented, 'copy'),
            title: "Copy #{represented.subject}"
          }
        end

        link :pdf,
             cache_if: -> { export_work_packages_allowed? } do
          next if represented.new_record?

          {
            href: work_package_path(id: represented.id, format: :pdf),
            type: 'application/pdf',
            title: 'Export as PDF'
          }
        end

        link :atom,
             cache_if: -> { export_work_packages_allowed? } do
          next if represented.new_record? || !Setting.feeds_enabled?

          {
            href: work_package_path(id: represented.id, format: :atom),
            type: 'application/rss+xml',
            title: 'Atom feed'
          }
        end

        link :availableRelationCandidates do
          next if represented.new_record?

          {
            href: api_v3_paths.work_package_available_relation_candidates(represented.id),
            title: "Potential work packages to relate to"
          }
        end

        link :customFields,
             cache_if: -> { current_user.allowed_in_project?(:select_custom_fields, represented.project) } do
          next if represented.project.nil?

          {
            href: project_settings_custom_fields_path(represented.project.identifier),
            type: 'text/html',
            title: "Custom fields"
          }
        end

        link :configureForm,
             cache_if: -> { current_user.admin? } do
          next unless represented.type_id

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

        link :availableWatchers,
             cache_if: -> { current_user.allowed_in_project?(:add_work_package_watchers, represented.project) } do
          {
            href: api_v3_paths.available_watchers(represented.id)
          }
        end

        link :relations do
          {
            href: api_v3_paths.work_package_relations(represented.id)
          }
        end

        link :revisions,
             cache_if: -> { current_user.allowed_in_project?(:view_changesets, represented.project) } do
          {
            href: api_v3_paths.work_package_revisions(represented.id)
          }
        end

        link :watch,
             uncacheable: true do
          next if current_user.anonymous? || current_user_watcher?

          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            payload: { user: { href: api_v3_paths.user(current_user.id) } }
          }
        end

        link :unwatch,
             uncacheable: true do
          next unless current_user_watcher?

          {
            href: api_v3_paths.watcher(current_user.id, represented.id),
            method: :delete
          }
        end

        link :watchers,
             cache_if: -> { current_user.allowed_in_project?(:view_work_package_watchers, represented.project) } do
          {
            href: api_v3_paths.work_package_watchers(represented.id)
          }
        end

        link :addWatcher,
             cache_if: -> { current_user.allowed_in_project?(:add_work_package_watchers, represented.project) } do
          {
            href: api_v3_paths.work_package_watchers(represented.id),
            method: :post,
            payload: { user: { href: api_v3_paths.user('{user_id}') } },
            templated: true
          }
        end

        link :removeWatcher,
             cache_if: -> { current_user.allowed_in_project?(:delete_work_package_watchers, represented.project) } do
          {
            href: api_v3_paths.watcher('{user_id}', represented.id),
            method: :delete,
            templated: true
          }
        end

        link :addRelation,
             cache_if: -> { current_user.allowed_in_work_package?(:manage_work_package_relations, represented) } do
          {
            href: api_v3_paths.work_package_relations(represented.id),
            method: :post,
            title: 'Add relation'
          }
        end

        link :addChild,
             cache_if: -> { add_work_packages_allowed? } do
          next if represented.milestone? || represented.new_record?

          {
            href: api_v3_paths.work_packages_by_project(represented.project.identifier),
            method: :post,
            title: "Add child of #{represented.subject}"
          }
        end

        link :changeParent,
             cache_if: -> { current_user.allowed_in_project?(:manage_subtasks, represented.project) } do
          {
            href: api_v3_paths.work_package(represented.id),
            method: :patch,
            title: "Change parent of #{represented.subject}"
          }
        end

        link :addComment,
             cache_if: -> { current_user.allowed_in_work_package?(:add_work_package_notes, represented) } do
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

        link :timeEntries,
             cache_if: -> { view_time_entries_allowed? } do
          next if represented.new_record?

          filters = [{ work_package_id: { operator: "=", values: [represented.id.to_s] } }]

          {
            href: api_v3_paths.path_for(:time_entries, filters:),
            title: 'Time entries'
          }
        end

        links :children,
              uncacheable: true do
          next if visible_children.empty?

          visible_children.map do |child|
            {
              href: api_v3_paths.work_package(child.id),
              title: child.subject
            }
          end
        end

        links :ancestors,
              uncacheable: true do
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

        formattable_property :description

        property :schedule_manually,
                 exec_context: :decorator,
                 getter: ->(*) { represented.schedule_manually? }

        date_property :start_date,
                      skip_render: ->(represented:, **) {
                        represented.milestone?
                      }

        date_property :due_date,
                      skip_render: ->(represented:, **) {
                        represented.milestone?
                      }

        # Using setter: does not work in case the provided date fragment is nil.
        date_property :date,
                      getter: default_date_getter(:due_date),
                      setter: ->(*) {
                        # handled in reader
                      },
                      reader: ->(decorator:, doc:, **) {
                        next unless doc.key?('date')

                        date = decorator
                          .datetime_formatter
                          .parse_date(doc['date'],
                                      name.to_s.camelize(:lower),
                                      allow_nil: true)

                        self.due_date = self.start_date = date
                      },
                      skip_render: ->(represented:, **) {
                        !represented.milestone?
                      }

        date_property :derived_start_date,
                      skip_render: ->(represented:, **) {
                        represented.milestone?
                      },
                      uncacheable: true

        date_property :derived_due_date,
                      skip_render: ->(represented:, **) {
                        represented.milestone?
                      },
                      uncacheable: true

        property :estimated_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.estimated_hours,
                                                                 allow_nil: true)
                 end,
                 render_nil: true

        property :derived_estimated_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.derived_estimated_hours,
                                                                 allow_nil: true)
                 end,
                 render_nil: true

        property :remaining_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.remaining_hours,
                                                                 allow_nil: true)
                 end,
                 writable: ->(*) { !WorkPackage.use_status_for_done_ratio? },
                 render_nil: true

        property :derived_remaining_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.derived_remaining_hours,
                                                                 allow_nil: true)
                 end,
                 writable: ->(*) { !WorkPackage.use_status_for_done_ratio? },
                 render_nil: true

        property :duration,
                 exec_context: :decorator,
                 if: ->(represented:, **) { !represented.milestone? },
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.duration_in_hours,
                                                                 allow_nil: true)
                 end,
                 render_nil: true

        property :ignore_non_working_days

        property :spent_time,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.spent_hours)
                 end,
                 if: ->(*) {
                   view_time_entries_allowed?
                 },
                 uncacheable: true

        property :done_ratio,
                 as: :percentageDone,
                 render_nil: true,
                 if: ->(*) { Setting.work_package_done_ratio != 'disabled' }

        property :derived_done_ratio,
                 as: :derivedPercentageDone,
                 render_nil: true,
                 if: ->(*) { Setting.work_package_done_ratio != 'disabled' }

        date_time_property :created_at

        date_time_property :updated_at

        property :relations,
                 embedded: true,
                 exec_context: :decorator,
                 if: ->(*) { embed_links },
                 uncacheable: true

        property :readonly,
                 writable: false,
                 render_nil: false,
                 if: ->(*) { ::Status.can_readonly? },
                 getter: ->(*) do
                   status_id && status.is_readonly?
                 end

        associated_resource :category

        associated_resource :type

        associated_resource :priority

        associated_resource :project

        associated_resource :status

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resource :responsible,
                            getter: ::API::V3::Principals::PrincipalRepresenterFactory
                              .create_getter_lambda(:responsible),
                            setter: ::API::V3::Principals::PrincipalRepresenterFactory
                              .create_setter_lambda(:responsible),
                            link: ::API::V3::Principals::PrincipalRepresenterFactory
                              .create_link_lambda(:responsible)

        associated_resource :assignee,
                            getter: ::API::V3::Principals::PrincipalRepresenterFactory
                              .create_getter_lambda(:assigned_to),
                            setter: ::API::V3::Principals::PrincipalRepresenterFactory
                              .create_setter_lambda(:assigned_to, property_name: :assignee),
                            link: ::API::V3::Principals::PrincipalRepresenterFactory
                              .create_link_lambda(:assigned_to)

        associated_resource :version,
                            v3_path: :version,
                            representer: ::API::V3::Versions::VersionRepresenter

        associated_resource :parent,
                            v3_path: :work_package,
                            representer: ::API::V3::WorkPackages::WorkPackageRepresenter,
                            skip_render: ->(*) { represented.parent && !represented.parent.visible? },
                            link_title_attribute: :subject,
                            uncacheable_link: true,
                            link: ->(*) {
                              if represented.parent&.visible?
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

                              new_parent =
                                if href
                                  id = ::API::Utilities::ResourceLinkParser
                                    .parse_id href,
                                              property: 'parent',
                                              expected_version: '3',
                                              expected_namespace: 'work_packages'

                                  WorkPackage.find_by(id:) ||
                                    ::WorkPackage::InexistentWorkPackage.new(id:)
                                end

                              represented.parent = new_parent
                            end

        associated_resource :budget,
                            as: :budget,
                            v3_path: :budget,
                            link_title_attribute: :subject,
                            representer: ::API::V3::Budgets::BudgetRepresenter,
                            skip_render: ->(*) { !view_budgets_allowed? }

        resources :customActions,
                  uncacheable_link: true,
                  link: ->(*) {
                    ordered_custom_actions.map do |action|
                      {
                        href: api_v3_paths.custom_action(action.id),
                        title: action.name
                      }
                    end
                  },
                  getter: ->(*) {
                    ordered_custom_actions.map do |action|
                      ::API::V3::CustomActions::CustomActionRepresenter.new(action, current_user:)
                    end
                  },
                  setter: ->(*) do
                    # noop
                  end

        def _type
          'WorkPackage'
        end

        def to_hash(*args)
          # Define all accessors on the customizable as they
          # will be used afterwards anyway. Otherwise, we will have to
          # go through method_missing which will take more time.
          represented.define_all_custom_field_accessors

          super
        end

        # Permissions
        def current_user_watcher?
          @current_user_watcher ||= represented.watchers.any? { |w| w.user_id == current_user.id }
        end

        def current_user_update_allowed?
          @current_user_update_allowed ||=
            current_user.allowed_in_work_package?(:edit_work_packages, represented) ||
              current_user.allowed_in_project?(:change_work_package_status, represented.project) ||
              current_user.allowed_in_project?(:assign_versions, represented.project)
        end

        def view_time_entries_allowed?
          @view_time_entries_allowed ||=
            current_user.allowed_in_project?(:view_time_entries, represented.project) ||
            view_own_time_entries_allowed?
        end

        def view_own_time_entries_allowed?
          @view_own_time_entries_allowed ||= if represented.new_record?
                                               current_user.allowed_in_any_work_package?(:view_own_time_entries,
                                                                                         in_project: represented.project)
                                             else
                                               current_user.allowed_in_work_package?(:view_own_time_entries, represented)
                                             end
        end

        def log_time_allowed?
          @log_time_allowed ||=
            current_user.allowed_in_project?(:log_time, represented.project) ||
              current_user.allowed_in_work_package?(:log_own_time, represented)
        end

        def view_budgets_allowed?
          @view_budgets_allowed ||= current_user.allowed_in_project?(:view_budgets, represented.project)
        end

        def export_work_packages_allowed?
          @export_work_packages_allowed ||=
            current_user.allowed_in_work_package?(:export_work_packages, represented)
        end

        def add_work_packages_allowed?
          @add_work_packages_allowed ||=
            current_user.allowed_in_project?(:add_work_packages, represented.project)
        end

        def relations
          self_path = api_v3_paths.work_package_relations(represented.id)
          visible_relations = represented
            .visible_relations(current_user)
            .includes(::API::V3::Relations::RelationCollectionRepresenter.to_eager_load)

          ::API::V3::Relations::RelationCollectionRepresenter.new(visible_relations,
                                                                  self_link: self_path,
                                                                  current_user:)
        end

        def visible_children
          @visible_children ||= represented.children.select(&:visible?)
        end

        delegate :schedule_manually=, to: :represented

        def estimated_time=(value)
          represented.estimated_hours =
            datetime_formatter.parse_duration_to_hours(value, 'estimatedTime', allow_nil: true)
        end

        def derived_estimated_time=(value)
          represented.derived_estimated_hours =
            datetime_formatter.parse_duration_to_hours(value, 'derivedEstimatedTime', allow_nil: true)
        end

        def remaining_time=(value)
          represented.remaining_hours =
            datetime_formatter.parse_duration_to_hours(value, 'remainingTime', allow_nil: true)
        end

        def derived_remaining_time=(value)
          represented.derived_remaining_hours =
            datetime_formatter.parse_duration_to_hours(value, 'derivedRemainingTime', allow_nil: true)
        end

        def spent_time=(value)
          # noop
        end

        def duration=(value)
          represented.duration = datetime_formatter.parse_duration_to_days(value,
                                                                           'duration',
                                                                           allow_nil: true)
        end

        def ordered_custom_actions
          # As the custom actions are sometimes set as an array
          @ordered_custom_actions ||= represented.custom_actions(current_user).to_a.sort_by(&:position)
        end

        # Attachments need to be eager loaded for the description
        self.to_eager_load = %i[parent
                                type
                                watchers
                                attachments
                                budget]

        # The dynamic class generation introduced because of the custom fields interferes with
        # the class naming as well as prevents calls to super
        def json_cache_key
          ['API',
           'V3',
           'WorkPackages',
           'WorkPackageRepresenter',
           'json',
           I18n.locale,
           json_key_representer_parts,
           represented.cache_checksum,
           Setting.work_package_done_ratio,
           Setting.feeds_enabled?]
        end

        def load_complete_model(model)
          ::API::V3::WorkPackages::WorkPackageEagerLoadingWrapper.wrap_one(model, current_user, timestamps:, query:)
        end
      end
    end
  end
end
