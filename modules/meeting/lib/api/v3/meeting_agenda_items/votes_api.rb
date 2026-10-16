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
      class VotesAPI < ::API::OpenProjectAPI
        helpers do
          def vote_on_agenda_item(reaction)
            result = ::MeetingAgendaItems::VoteService
              .new(user: current_user, meeting_agenda_item: @meeting_agenda_item)
              .call(reaction:)

            raise_vote_error(result.errors) unless result.success?

            status :ok
            MeetingAgendaItemRepresenter.new(result.result, current_user:)
          end

          def raise_vote_error(errors)
            if errors.of_kind?(:base, :vote_based_sorting_required)
              raise ::API::Errors::BadRequest.new(errors.full_messages.join(" "))
            end

            raise ::API::Errors::ErrorBase.create_and_merge_errors(errors)
          end
        end

        post :upvote do
          vote_on_agenda_item("thumbs_up")
        end

        post :downvote do
          vote_on_agenda_item("thumbs_down")
        end
      end
    end
  end
end
