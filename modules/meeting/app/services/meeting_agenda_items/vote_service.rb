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
  class VoteService < ::BaseServices::BaseContracted
    def initialize(user:, meeting_agenda_item:, contract_class: nil, contract_options: {})
      super(user:, contract_class:, contract_options:)
      self.model = meeting_agenda_item
      @meeting_id = meeting_agenda_item.meeting_id
    end

    protected

    def service_context(send_notifications:, &)
      super { model.with_lock(&) }
    end

    def before_perform(call)
      @reaction = params[:reaction].to_s
      self.contract_options = contract_options.merge(reaction: @reaction, meeting_id: @meeting_id)
      call
    end

    def persist(call)
      model.transaction(requires_new: true) { toggle_vote }
      call
    rescue ActiveRecord::RecordInvalid => e
      call.success = false
      call.errors = e.record.errors
      call
    end

    def default_contract_class
      MeetingAgendaItems::VoteContract
    end

    private

    def toggle_vote
      vote = model.emoji_reactions.find_or_initialize_by(user:)

      if vote.persisted? && vote.reaction == @reaction
        # voted again with the same reaction, so deleting the entry
        vote.destroy!
      else
        # new reaction, either update existing or vote freshly
        vote.reaction = @reaction
        vote.save!
      end
    end
  end
end
