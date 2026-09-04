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
  class Run < ApplicationRecord
    KINDS = %w[text_transform].freeze
    TERMINAL_STATUSES = %w[succeeded failed cancelled].freeze
    MAX_INPUT_LENGTH = 100_000

    belongs_to :user
    belongs_to :action,
               class_name: "AI::TextTransformAction",
               foreign_key: :ai_text_transform_action_id,
               inverse_of: false
    belongs_to :work_package, optional: true
    belongs_to :project, optional: true
    belongs_to :type, optional: true
    has_many :events,
             class_name: "AI::RunEvent",
             inverse_of: :run,
             dependent: :delete_all

    enum :status, {
      queued: "queued",
      running: "running",
      succeeded: "succeeded",
      failed: "failed",
      cancelled: "cancelled"
    }, default: "queued", validate: true

    attribute :uuid, :string, default: -> { SecureRandom.uuid }

    validates :kind, inclusion: { in: KINDS }
    validates :input, presence: true, length: { maximum: MAX_INPUT_LENGTH }
    validate :context_present

    scope :expired, ->(retention) do
      where(finished_at: ...retention.ago)
        .or(where(finished_at: nil, created_at: ...retention.ago))
    end

    def terminal?
      TERMINAL_STATUSES.include?(status)
    end

    def append_event(kind, payload = {})
      OpenProject::Mutex.with_advisory_lock(self.class, "ai_run_#{id}_events") do
        events.create!(kind:, payload:, seq: events.maximum(:seq).to_i + 1)
      end
    end

    def events_after(seq)
      events.where(seq: (seq + 1)..).order(:seq)
    end

    def start!
      update!(status: "running")
    end

    def finish!(status, error_message: nil)
      raise ArgumentError, "#{status} is not a terminal status" unless TERMINAL_STATUSES.include?(status.to_s)

      update!(status:, error_message:, finished_at: Time.current)
    end

    private

    def context_present
      errors.add(:work_package, :blank) if work_package.nil? && (project.nil? || type.nil?)
    end
  end
end
