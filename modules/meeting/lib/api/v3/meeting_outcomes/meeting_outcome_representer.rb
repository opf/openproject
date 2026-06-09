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
    module MeetingOutcomes
      class MeetingOutcomeRepresenter < ::API::Decorators::Single
        include API::Decorators::LinkedResource
        include API::Decorators::DateProperty
        include API::Decorators::FormattableProperty
        include ::API::Caching::CachedRepresenter

        self.to_eager_load = [{ meeting_agenda_item: :meeting }, :author, :work_package]

        self_link path: :meeting_outcome,
                  title_getter: ->(*) { represented.id.to_s }

        property :id

        property :kind

        formattable_property :notes

        associated_resource :author,
                            v3_path: :user,
                            representer: ::API::V3::Users::UserRepresenter,
                            skip_render: ->(*) { represented.author_id.nil? }

        associated_resource :meeting_agenda_item,
                            as: :agendaItem,
                            link: ->(*) {
                              next if represented.meeting_agenda_item_id.nil?

                              {
                                href: api_v3_paths.meeting_agenda_item(represented.meeting_agenda_item_id),
                                title: represented.meeting_agenda_item.title
                              }
                            }

        associated_visible_resource :work_package

        date_time_property :created_at
        date_time_property :updated_at

        def _type
          "MeetingOutcome"
        end
      end
    end
  end
end
