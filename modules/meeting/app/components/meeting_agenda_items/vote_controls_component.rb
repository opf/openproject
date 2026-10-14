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

module MeetingAgendaItems
  class VoteControlsComponent < ApplicationComponent
    include OpPrimer::ComponentHelpers

    def initialize(meeting_agenda_item:, voting_enabled:)
      super()

      @meeting_agenda_item = meeting_agenda_item
      @meeting = meeting_agenda_item.meeting
      @voting_enabled = voting_enabled
    end

    private

    def vote_selected?(reaction)
      @current_vote = @meeting_agenda_item.vote_by(User.current) unless defined?(@current_vote)
      @current_vote == reaction
    end

    def vote_label(reaction)
      label_key = vote_selected?(reaction) ? "remove_#{reaction}" : reaction
      t("meeting.agenda_sorting.#{label_key}")
    end

    def vote_icon(reaction)
      reaction == "thumbs_up" ? "👍" : "👎"
    end
  end
end
