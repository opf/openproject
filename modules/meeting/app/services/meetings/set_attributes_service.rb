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

module Meetings
  class SetAttributesService < ::BaseServices::SetAttributes
    def set_attributes(params)
      participants = params.delete(:participants_attributes)

      super

      if participants.present?
        set_participants(participants)
      else
        set_default_participant
      end
    end

    def set_default_attributes(_params) # rubocop:disable Metrics/AbcSize
      model.change_by_system do
        model.author = user
        model.duration ||= 1
        model.state = "draft" if !model.recurring? || model.template?
        model.notify = false
        model.sharing = "none" if model.onetime_template?
        model.recurrence_start_time ||= model.start_time if model.recurring? && !model.template?
      end
    end

    private

    def set_participants(participants_attributes)
      if model.new_record?
        model.participants.clear
        model.participants_attributes = participants_attributes
      else
        replace_participants(participants_attributes)
      end
    end

    def replace_participants(participants_attributes)
      incoming_user_ids = participants_attributes.to_set { |attrs| attrs[:user_id].to_i }
      existing_participants = model.participants.index_by { |p| p.user_id.to_i }

      mark_removed_participants(incoming_user_ids, existing_participants)
      model.participants_attributes = added_participant_attributes(participants_attributes, existing_participants)
    end

    def mark_removed_participants(incoming_user_ids, existing_participants)
      existing_participants.each do |user_id, participant|
        participant.mark_for_destruction unless incoming_user_ids.include?(user_id)
      end
    end

    def added_participant_attributes(participants_attributes, existing_participants)
      participants_attributes.reject { |attrs| existing_participants.key?(attrs[:user_id].to_i) }
    end

    def set_default_participant
      return if model.participants.present? || model.persisted?
      return if user.builtin?

      model.participants.build(user:, invited: true)
    end
  end
end
