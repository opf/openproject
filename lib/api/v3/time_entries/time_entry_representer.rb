#-- encoding: UTF-8

#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

module API
  module V3
    module TimeEntries
      class TimeEntryRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        extend ::API::V3::Utilities::CustomFieldInjector::RepresenterClass

        self_link title_getter: ->(*) { nil }

        defaults render_nil: true

        link :updateImmediately do
          next unless update_allowed?

          {
            href: api_v3_paths.time_entry(represented.id),
            method: :patch
          }
        end

        link :delete do
          next unless update_allowed?

          {
            href: api_v3_paths.time_entry(represented.id),
            method: :delete
          }
        end

        property :id

        property :comments,
                 as: :comment

        property :spent_on,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_date(represented.spent_on, allow_nil: false)
                 end,
                 setter: ->(fragment:, **) do
                   represented.spent_on = datetime_formatter.parse_date(fragment,
                                                                        'spentOn',
                                                                        allow_nil: false)
                 end

        property :hours,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_duration_from_hours(represented.hours)
                 end,
                 setter: ->(fragment:, **) do
                   represented.hours = datetime_formatter.parse_duration_to_hours(fragment,
                                                                                  'hours')
                 end

        property :created_at,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_datetime(represented.created_on, allow_nil: true)
                 end

        property :updated_at,
                 exec_context: :decorator,
                 getter: ->(*) do
                   datetime_formatter.format_datetime(represented.updated_on, allow_nil: true)
                 end

        associated_resource :project

        associated_resource :work_package,
                            link_title_attribute: :subject

        associated_resource :user

        associated_resource :activity,
                            representer: TimeEntriesActivityRepresenter,
                            v3_path: :time_entries_activity,
                            getter: associated_resource_default_getter(:authoritativ_activity, TimeEntriesActivityRepresenter),
                            link: ->(*) {
                              activity = represented.authoritativ_activity
                              {
                                href: api_v3_paths.time_entries_activity(activity.id),
                                title: activity.name
                              }
                            },
                            setter: ->(fragment:, **) {
                              ::API::Decorators::LinkObject
                                .new(represented,
                                     path: :time_entries_activity,
                                     property_name: :time_entries_activity,
                                     namespace: 'time_entries/activities',
                                     getter: :activity_id,
                                     setter: :"activity_id=")
                                .from_hash(fragment)
                            }

        def _type
          'TimeEntry'
        end

        def update_allowed?
          current_user_allowed_to(:edit_time_entries, context: represented.project) ||
            represented.user_id == current_user.id && current_user_allowed_to(:edit_own_time_entries, context: represented.project)
        end

        def current_user_allowed_to(permission, context:)
          current_user.allowed_to?(permission, context)
        end
      end
    end
  end
end
