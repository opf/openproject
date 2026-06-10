# frozen_string_literal: true

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
    module RecurringMeetings
      class RecurringMeetingRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::V3::Workspaces::LinkedResource
        include API::Decorators::DateProperty
        include ::API::Caching::CachedRepresenter

        cached_representer key_parts: %i[project]

        self.to_eager_load = [:author, :template, { project: :enabled_modules }]

        self_link title_getter: ->(*) { represented.title }

        link :updateImmediately,
             cache_if: -> { current_user.allowed_in_project?(:edit_meetings, represented.project) } do
          {
            href: api_v3_paths.recurring_meeting(represented.id),
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { current_user.allowed_in_project?(:delete_meetings, represented.project) } do
          {
            href: api_v3_paths.recurring_meeting(represented.id),
            method: :delete
          }
        end

        link :template do
          next unless represented.template

          {
            href: api_v3_paths.meeting(represented.template.id),
            title: represented.template.title
          }
        end

        link :occurrencesUpcoming do
          {
            href: api_v3_paths.recurring_meeting_occurrences_upcoming(represented.id)
          }
        end

        link :occurrencesPast do
          {
            href: api_v3_paths.recurring_meeting_occurrences_past(represented.id)
          }
        end

        link :occurrencesCancelled do
          {
            href: api_v3_paths.recurring_meeting_occurrences_cancelled(represented.id)
          }
        end

        link :occurrencesOpen do
          {
            href: api_v3_paths.recurring_meeting_occurrences_open(represented.id)
          }
        end

        property :id

        property :title

        property :frequency

        property :monthly_day

        property :monthly_ordinal

        property :monthly_weekday

        property :interval

        property :end_after

        date_property :end_date

        property :iterations

        property :time_zone,
                 getter: ->(*) { time_zone.name }

        date_time_property :start_time

        property :location,
                 getter: ->(*) { template&.location }

        property :duration,
                 getter: ->(*) { template&.duration }

        property :notify,
                 getter: ->(*) { template&.notify }

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_project

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "RecurringMeeting"
        end
      end
    end
  end
end
