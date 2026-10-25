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

module AI
  # One conversation of a user: about a work package, in a project, or on a page without
  # either (see AI::Assistance::Place). Only that user sees it.
  class AssistantChat < ApplicationRecord
    belongs_to :skill, class_name: "AI::AssistantSkill", inverse_of: :chats
    belongs_to :user
    belongs_to :work_package, optional: true
    belongs_to :project, optional: true
    has_many :messages,
             -> { order(:id) },
             class_name: "AI::AssistantChatMessage",
             foreign_key: :chat_id,
             inverse_of: :chat,
             dependent: :delete_all

    before_validation { self.project = work_package.project if work_package }

    scope :at, ->(place) do
      place.work_package ? where(work_package: place.work_package) : where(work_package_id: nil, project: place.project)
    end
    scope :for, ->(user, place) { where(user:).at(place) }

    def self.latest_for(user, place, skill)
      self.for(user, place).where(skill:).order(created_at: :desc, id: :desc).first
    end

    def place
      AI::Assistance::Place.new(work_package:, project:)
    end

    # An answer that is still pending after this time has failed, for example after a crash.
    ANSWER_TIMEOUT = 10.minutes

    def pending?
      messages.any?(&:pending?)
    end

    scope :with_pending_answer, -> { where(id: AI::AssistantChatMessage.pending.select(:chat_id)) }

    def fail_stale_answers!
      stale = messages.where(status: "pending", created_at: ...ANSWER_TIMEOUT.ago)
      return if stale.none?

      stale.update_all(status: "failed", updated_at: Time.current)
      messages.reset
    end
  end
end
