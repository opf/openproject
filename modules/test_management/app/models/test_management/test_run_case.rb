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
  # A test case inside a test run, with its execution status and assignee.
  class TestRunCase < ApplicationRecord
    self.table_name = "tm_test_run_cases"

    # "skipped" comes from automation (a test skipped by the runner). It is shown
    # separately and excluded from the pass rate (see TestRun.pass_rate).
    STATUSES = %w[passed failed blocked retest in_progress skipped untested].freeze
    # Worst-first: when several reported results hit one case in an import
    # (e.g. chromium + firefox), the worst wins.
    PRECEDENCE = %w[failed blocked retest in_progress passed skipped untested].freeze

    belongs_to :test_run, class_name: "TestManagement::TestRun", inverse_of: :run_cases
    belongs_to :test_case, class_name: "TestManagement::TestCase", inverse_of: :run_cases
    belongs_to :assigned_to, class_name: "User", optional: true

    has_many :results,
             -> { order(:created_at, :id) },
             class_name: "TestManagement::TestResult",
             foreign_key: :run_case_id,
             inverse_of: :run_case,
             dependent: :delete_all

    delegate :project, to: :test_run, allow_nil: true

    validates :status, inclusion: { in: STATUSES }
    validates :final_status, inclusion: { in: STATUSES }, allow_nil: true
    validates :test_case_id, uniqueness: { scope: :test_run_id }

    # SQL for the status that counts: the frozen one when the run is finished.
    def self.effective_status_sql
      Arel.sql("COALESCE(tm_test_run_cases.final_status, tm_test_run_cases.status)")
    end

    def effective_status
      final_status.presence || status
    end

    # NB: not named `frozen?`, which ActiveRecord uses internally.
    def status_frozen?
      final_status.present? || test_run&.finished?
    end

    def last_result
      results.last
    end

    def self.worst_status(statuses)
      Array(statuses).compact.min_by { |status| PRECEDENCE.index(status) || PRECEDENCE.size }
    end

    def title
      test_case&.title
    end
  end
end
