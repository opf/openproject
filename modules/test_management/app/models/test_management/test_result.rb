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

module TestManagement
  # One status change of a case inside a run (result history within the run).
  class TestResult < ApplicationRecord
    self.table_name = "tm_test_results"
    self.record_timestamps = false

    belongs_to :run_case, class_name: "TestManagement::TestRunCase", inverse_of: :results
    belongs_to :iteration, class_name: "TestManagement::TestRunIteration", optional: true, inverse_of: :results
    belongs_to :user, optional: true
    belongs_to :import, class_name: "TestManagement::AutomationImport", optional: true, inverse_of: :results

    SOURCES = %w[manual automation].freeze
    ERROR_MESSAGE_LIMIT = 4000
    ERROR_TRACE_LIMIT = 16_000

    validates :status, inclusion: { in: TestRunCase::STATUSES }
    validates :source, inclusion: { in: SOURCES }

    # { run_case_id => latest result } in two queries (MAX(id) per run case, optionally within
    # one iteration). Used by the run page instead of preloading every result.
    def self.latest_by_run_case(run_case_ids, iteration_id: nil)
      scope = where(run_case_id: run_case_ids)
      scope = scope.where(iteration_id:) if iteration_id
      where(id: scope.group(:run_case_id).select(Arel.sql("MAX(id)"))).includes(:user).index_by(&:run_case_id)
    end

    def automation?
      source == "automation"
    end

    def error?
      error_message.present? || error_trace.present?
    end

    def details_hash
      (details || {}).stringify_keys
    end

    before_create { self.created_at ||= Time.current }
    before_save :cap_error

    private

    def cap_error
      return unless has_attribute?(:error_message)

      self.error_message = error_message.to_s.first(ERROR_MESSAGE_LIMIT).presence if error_message_changed?
      self.error_trace = error_trace.to_s.first(ERROR_TRACE_LIMIT).presence if error_trace_changed?
    end
  end
end
