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
    module MeetingAgendaItems
      class MeetingAgendaItemRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include ::API::Caching::CachedRepresenter

        self.to_eager_load = [
          :author, :presenter, :work_package, :meeting_section, :meeting,
          { outcomes: %i[author work_package] }
        ]

        self_link title_getter: ->(*) { represented.title }

        property :id

        property :title

        formattable_property :notes

        property :position

        property :duration_in_minutes

        property :item_type

        property :lock_version,
                 render_nil: true,
                 getter: ->(*) {
                   lock_version.to_i
                 }

        associated_resource :meeting,
                            link: ->(*) {
                              {
                                href: api_v3_paths.meeting(represented.meeting_id),
                                title: represented.meeting.title
                              }
                            }

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter

        associated_resource :presenter,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter,
                            skip_render: ->(*) { represented.presenter_id.nil? }

        associated_visible_resource :work_package

        associated_resource :meeting_section,
                            as: :section,
                            link: ->(*) {
                              next if represented.meeting_section_id.nil?

                              {
                                href: api_v3_paths.meeting_section(represented.meeting_section_id),
                                title: represented.meeting_section&.title
                              }
                            }

        associated_resources :outcomes,
                             getter: ->(*) {
                               represented.outcomes.map do |outcome|
                                 ::API::V3::MeetingOutcomes::MeetingOutcomeRepresenter.new(outcome, current_user:)
                               end
                             },
                             link: ->(*) {
                               represented.outcomes.map do |outcome|
                                 {
                                   href: api_v3_paths.meeting_outcome(outcome.id),
                                   title: outcome.id.to_s
                                 }
                               end
                             }

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "MeetingAgendaItem"
        end
      end
    end
  end
end
