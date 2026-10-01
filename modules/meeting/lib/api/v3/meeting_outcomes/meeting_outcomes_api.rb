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
      class MeetingOutcomesAPI < ::API::OpenProjectAPI
        resources :meeting_outcomes do
          post &::API::V3::Utilities::Endpoints::Create.new(model: MeetingOutcome).mount

          route_param :id, type: Integer, desc: "Outcome ID" do
            after_validation do
              @meeting_outcome = MeetingOutcome
                .joins(meeting_agenda_item: { meeting: :project })
                .merge(Meeting.visible)
                .find(declared_params[:id])
            end

            get &::API::V3::Utilities::Endpoints::Show.new(model: MeetingOutcome).mount

            patch &::API::V3::Utilities::Endpoints::Update.new(model: MeetingOutcome).mount

            delete &::API::V3::Utilities::Endpoints::Delete.new(model: MeetingOutcome).mount
          end
        end
      end
    end
  end
end
