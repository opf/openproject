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
  class AssistantRun < ApplicationRecord
    TERMINAL_STATUSES = %w[finished failed].freeze

    belongs_to :skill, class_name: "AI::AssistantSkill", inverse_of: :runs
    belongs_to :user
    belongs_to :work_package
    belongs_to :automation, optional: true
    has_many :findings,
             -> { order(:id) },
             class_name: "AI::AssistantRunFinding",
             inverse_of: :run,
             dependent: :delete_all

    # running: the rules run. ai_running: the rules are done and the AI review job runs.
    enum :status, {
      running: "running",
      ai_running: "ai_running",
      finished: "finished",
      failed: "failed"
    }, default: "running", validate: true

    enum :trigger, {
      menu: "menu",
      automation: "automation",
      schedule: "schedule"
    }, default: "menu", validate: true, prefix: :triggered_by

    attribute :uuid, default: -> { SecureRandom.uuid }

    validates :locale, presence: true

    before_save :stamp_finished_at, if: -> { status_changed? && terminal? }

    scope :for, ->(user, work_package) { where(user:, work_package:) }
    scope :newest_first, -> { order(created_at: :desc, id: :desc) }

    def terminal?
      TERMINAL_STATUSES.include?(status)
    end

    # Appends one entry in a single statement, so a job and a request that both write
    # events never overwrite each other.
    def log_event(kind, **data)
      entry = { "at" => Time.current.iso8601(3), "kind" => kind.to_s, "data" => data.deep_stringify_keys }
      self.class.where(id:).update_all(["events = events || ?::jsonb", [entry].to_json])
      events << entry
    end

    def add_not_checked(area, reason)
      not_checked << { "area" => area.to_s, "reason" => reason.to_s }
    end

    private

    def stamp_finished_at
      self.finished_at ||= Time.current
    end
  end
end
