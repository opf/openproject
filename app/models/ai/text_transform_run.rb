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
# along with this program. If not, see <https://www.gnu.org/licenses/>.
#
# See COPYRIGHT and LICENSE files for more details.
#++

module AI
  class TextTransformRun < ApplicationRecord
    TERMINAL_STATUSES = %w[succeeded failed cancelled].freeze
    ACTIVE_STATUSES = %w[queued running].freeze
    STALLED_AFTER = (AI::TextTransforms::Execution::BUDGET + 60).seconds
    MAX_INPUT_LENGTH = 100_000

    belongs_to :user
    belongs_to :action,
               class_name: "AI::TextAction",
               foreign_key: :ai_text_action_id,
               inverse_of: false
    has_many :events,
             class_name: "AI::TextTransformRunEvent",
             inverse_of: :run,
             dependent: :delete_all

    enum :status, {
      queued: "queued",
      running: "running",
      succeeded: "succeeded",
      failed: "failed",
      cancelled: "cancelled"
    }, default: "queued", validate: true

    attribute :uuid, default: -> { SecureRandom.uuid }

    validates :system_prompt, presence: true
    validates :input, presence: true, length: { maximum: MAX_INPUT_LENGTH }

    before_save :stamp_finished_at, if: -> { status_changed? && terminal? }

    scope :expired, ->(retention) do
      where(finished_at: ...retention.ago)
        .or(where(finished_at: nil, created_at: ...retention.ago))
    end

    def terminal?
      TERMINAL_STATUSES.include?(status)
    end

    def append_event(kind, payload = {})
      OpenProject::Mutex.with_advisory_lock_transaction(self, "events") do
        events.create!(kind:, payload:, seq: events.maximum(:seq).to_i + 1)
      end
    end

    # Locks the row as the terminal transitions do, so that no event follows the one that ended the run.
    def append_event_while_active(kind, payload = {})
      transaction do
        append_event(kind, payload) if self.class.lock.exists?(id:, status: ACTIVE_STATUSES)
      end
    end

    def events_after(seq)
      events.where(seq: (seq.to_i + 1)..).order(:seq)
    end

    def start!
      transaction do
        transition!(from: "queued", status: "running").tap do |started|
          append_event("status", status: "running") if started
        end
      end
    end

    def request_cancel!
      update_columns(cancel_requested: true, updated_at: Time.current) unless terminal?
    end

    def finish!(status, error_message: nil)
      raise ArgumentError, "#{status} is not a terminal status" unless TERMINAL_STATUSES.include?(status.to_s)

      transition!(from: ACTIVE_STATUSES, status:, error_message:, finished_at: Time.current)
    end

    def succeed!(text)
      transaction do
        finish!("succeeded").tap { |succeeded| append_event("completed", text:) if succeeded }
      end
    end

    def fail!(reason)
      message = OpenProject::LocaleHelper.with_locale_for(user) { I18n.t("ai.text_transform.errors.#{reason}") }
      transaction do
        finish!("failed", error_message: message).tap do |failed|
          append_event("error", message:, reason: reason.to_s) if failed
        end
      end
    end

    def stalled?
      running? && last_activity < STALLED_AFTER.ago
    end

    # The job takes the row lock for every write, so a job that started or wrote since the run was loaded keeps it.
    def fail_if_stalled!
      return false unless stalled?

      transaction do
        lock!
        stalled? && (cancel_requested? ? finish!("cancelled") : fail!(:interrupted))
      end
    end

    private

    def last_activity
      [(updated_at unless cancel_requested?), events.maximum(:created_at)].compact.max || created_at
    end

    # A live job and a poll that took it for dead may both try to end the run, so only one transition may win.
    def transition!(from:, **attributes)
      changed = self.class.where(id:, status: from).update_all(attributes.merge(updated_at: Time.current)).positive?
      reload if changed
      changed
    end

    def stamp_finished_at
      self.finished_at ||= Time.current
    end
  end
end
