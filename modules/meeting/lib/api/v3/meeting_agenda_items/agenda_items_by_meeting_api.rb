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
      class AgendaItemsByMeetingAPI < ::API::OpenProjectAPI
        resources :agenda_items do
          get do
            items = @meeting.agenda_items.includes(:author, :presenter, :work_package, :meeting_section)
            MeetingAgendaItemCollectionRepresenter.new(items,
                                                       self_link: api_v3_paths.meeting_agenda_items(meeting_id: @meeting.id),
                                                       current_user:)
          end

          route_param :agenda_item_id, type: Integer, desc: "Agenda item ID" do
            after_validation do
              @meeting_agenda_item = @meeting.agenda_items.find(declared_params[:agenda_item_id])
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: MeetingAgendaItem).mount

            mount ::API::V3::MeetingOutcomes::OutcomesByAgendaItemAPI
          end
        end
      end
    end
  end
end
