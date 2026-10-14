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
  class VoteContract < ::ModelContract
    validate :validate_voting_permission
    validate :validate_sorting_mode, if: -> { errors.empty? }
    validate :validate_voting_available, if: -> { errors.empty? }
    validate :validate_reaction, if: -> { errors.empty? }

    protected

    def validate_model?
      false
    end

    private

    def validate_voting_permission
      if (options[:meeting_id] && model.meeting_id != options[:meeting_id]) ||
         !user.allowed_in_project?(:view_meetings, model.meeting.project)
        errors.add :base, :error_unauthorized
      end
    end

    def validate_sorting_mode
      errors.add :base, :vote_based_sorting_required unless model.meeting.agenda_sorting_vote_based?
    end

    def validate_voting_available
      errors.add :base, :error_unauthorized unless model.votable?(user)
    end

    def validate_reaction
      unless MeetingAgendaItem.allowed_emoji_reactions.include?(options[:reaction].to_s)
        errors.add :base, I18n.t("meeting.agenda_sorting.invalid_reaction")
      end
    end
  end
end
