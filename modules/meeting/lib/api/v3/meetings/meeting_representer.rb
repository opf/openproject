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
    module Meetings
      class MeetingRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::V3::Workspaces::LinkedResource
        include API::Caching::CachedRepresenter
        include API::V3::Attachments::AttachableRepresenterMixin
        include API::Decorators::DateProperty

        self.to_eager_load = [:author, { project: :enabled_modules }, { participants: :user }]

        cached_representer key_parts: %i(project participants)

        self_link title_getter: ->(*) { represented.title }

        link :schema do
          {
            href: api_v3_paths.meeting_schema
          }
        end

        link :update,
             cache_if: -> { current_user.allowed_in_project?(:edit_meetings, represented.project) } do
          {
            href: api_v3_paths.meeting_form(represented.id),
            method: :post
          }
        end

        link :updateImmediately,
             cache_if: -> { current_user.allowed_in_project?(:edit_meetings, represented.project) } do
          {
            href: api_v3_paths.meeting(represented.id),
            method: :patch
          }
        end

        link :delete,
             cache_if: -> { current_user.allowed_in_project?(:delete_meetings, represented.project) } do
          {
            href: api_v3_paths.meeting(represented.id),
            method: :delete
          }
        end

        link :agendaItems do
          {
            href: api_v3_paths.meeting_agenda_items(meeting_id: represented.id)
          }
        end

        link :sections do
          {
            href: api_v3_paths.meeting_sections(meeting_id: represented.id)
          }
        end

        link :recurringMeeting do
          next unless represented.recurring_meeting_id

          {
            href: api_v3_paths.recurring_meeting(represented.recurring_meeting_id)
          }
        end

        property :id
        property :title
        property :location

        property :lock_version,
                 render_nil: true,
                 getter: ->(*) {
                   lock_version.to_i
                 }

        date_time_property :start_time
        date_time_property :end_time

        property :duration,
                 exec_context: :decorator,
                 render_nil: true,
                 getter: ->(*) {
                   datetime_formatter.format_duration_from_hours(represented.duration, allow_nil: true)
                 },
                 setter: ->(fragment:, **) {
                   represented.duration = datetime_formatter.parse_duration_to_hours(fragment, "duration", allow_nil: true)
                 }
        property :state

        property :sharing

        property :template

        property :notify,
                 getter: ->(*) { notify? }

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resources :users,
                             as: :participants,
                             getter: ->(*) {
                               represented.participants.map do |participant|
                                 ::API::V3::Users::UserRepresenter.create(participant.user, current_user:)
                               end
                             },
                             setter: ->(fragment:, **) {
                               ids = parse_link_ids_from_fragment(fragment, :user)
                               represented[:participants_attributes] =
                                 ids.map { |id| { user_id: id, invited: true } }
                             },
                             link: ->(*) {
                               represented.participants.map do |participant|
                                 ::API::Decorators::LinkObject
                                   .new(participant.user,
                                        property_name: :itself,
                                        path: :user,
                                        getter: :id,
                                        title_attribute: :name)
                                   .to_hash
                               end
                             }

        associated_project

        date_time_property :created_at

        date_time_property :updated_at

        def _type
          "Meeting"
        end
      end
    end
  end
end
