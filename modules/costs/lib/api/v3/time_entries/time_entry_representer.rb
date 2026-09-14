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

module API
  module V3
    module TimeEntries
      class TimeEntryRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::V3::Workspaces::LinkedResource
        include API::Decorators::FormattableProperty
        include API::Decorators::DateProperty
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

        self_link title_getter: ->(*) {}

        defaults render_nil: true

        link :updateImmediately do
          next unless update_allowed?

          {
            href: api_v3_paths.time_entry(represented.id),
            method: :patch
          }
        end

        link :update do
          next unless update_allowed?

          {
            href: api_v3_paths.time_entry_form(represented.id),
            method: :post
          }
        end

        link :delete do
          next unless update_allowed?

          {
            href: api_v3_paths.time_entry(represented.id),
            method: :delete
          }
        end

        link :schema do
          {
            href: api_v3_paths.time_entry_schema
          }
        end

        property :id

        property :ongoing

        formattable_property :comments,
                             as: :comment,
                             plain: true

        date_property :spent_on

        property :hours,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.hours) if represented.hours
                 end

        date_time_property :created_at
        date_time_property :updated_at

        associated_project

        associated_resource :entity,
                            getter: ::API::V3::TimeEntries::EntityRepresenterFactory.create_getter_lambda(:entity),
                            setter: ::API::V3::TimeEntries::EntityRepresenterFactory.create_setter_lambda(:entity),
                            link: ::API::V3::TimeEntries::EntityRepresenterFactory.create_link_lambda(:entity)

        # TODO: DEPRECATED!
        associated_resource :work_package,
                            skip_render: ->(*) { represented.entity_type != "WorkPackage" },
                            getter: ->(*) {
                              entity = represented.entity
                              entity if entity.is_a?(WorkPackage) && entity.visible?(current_user)
                            },
                            link: ::API::V3::TimeEntries::EntityRepresenterFactory.create_work_package_link_lambda,
                            setter: ::API::V3::TimeEntries::EntityRepresenterFactory.create_setter_lambda(:entity)

        associated_resource :user

        date_time_property :start_time,
                           exec_context: :decorator,
                           getter: ->(*) {
                             datetime_formatter.format_datetime(represented.start_timestamp, allow_nil: true)
                           },
                           if: ->(*) { TimeEntry.can_track_start_and_end_time? }

        # end_time is derived (start_time + hours), never its own column.
        date_time_property :end_time,
                           exec_context: :decorator,
                           getter: ->(*) {
                             datetime_formatter.format_datetime(represented.end_timestamp, allow_nil: true)
                           },
                           writable: false,
                           if: ->(*) { TimeEntry.can_track_start_and_end_time? }

        associated_resource :activity,
                            representer: TimeEntriesActivityRepresenter,
                            v3_path: :time_entries_activity,
                            setter: ->(fragment:, **) {
                              ::API::Decorators::LinkObject
                                .new(represented,
                                     path: :time_entries_activity,
                                     property_name: :time_entries_activity,
                                     namespace: "time_entries/activities",
                                     getter: :activity_id,
                                     setter: :"activity_id=")
                                .from_hash(fragment)
                            }

        def _type
          "TimeEntry"
        end

        def update_allowed?
          @update_allowed ||= begin
            contract = ::TimeEntries::UpdateContract.new(represented, current_user)
            contract.user_allowed_to_update?
          end
        end

        def hours=(value)
          represented.hours = datetime_formatter.parse_duration_to_hours(value,
                                                                         "hours",
                                                                         allow_nil: true)
        end

        def start_time=(value) # rubocop:disable Metrics/AbcSize, Metrics/PerceivedComplexity
          ts = datetime_formatter.parse_datetime(value, "start_time", allow_nil: true)

          if ts.nil?
            represented.start_time = nil
            return
          end

          tz_specific_time = if represented.user_id.present? && represented.user_id != current_user.id
                               user = User.visible.find_by(id: represented.user_id)
                               if user
                                 ts.in_time_zone(user.time_zone)
                               else
                                 ts.in_time_zone(current_user.time_zone)
                               end
                             else
                               ts.in_time_zone(current_user.time_zone)
                             end

          if tz_specific_time.to_date == represented.spent_on
            represented.start_time = tz_specific_time.strftime("%H:%M")
          else
            raise API::Errors::Validation.new("start_time",
                                              I18n.t("api_v3.errors.validation.start_time_different_date",
                                                     spent_on: represented.spent_on,
                                                     start_time: tz_specific_time.to_date))
          end
        end

        self.to_eager_load = [:user, :activity, { project: :enabled_modules }, { custom_values: :custom_field }]

        # entity is a polymorphic association and thus can't be eager-loaded, but it can be preloaded
        self.to_preload = [:entity]
      end
    end
  end
end
