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
  # One upload of automated test results (a CI report) into a test run.
  # Keeps the audit trail of an ingest: who uploaded what (format, sha256 digest of
  # the payload – never the payload itself), how many tests were parsed, matched,
  # created and which ones could not be matched (and why).
  class AutomationImport < ApplicationRecord
    self.table_name = "tm_automation_imports"

    FORMATS = %w[junit playwright_json].freeze
    STATES = %w[queued processing done failed].freeze

    belongs_to :project
    belongs_to :test_run, class_name: "TestManagement::TestRun", optional: true, inverse_of: :automation_imports
    belongs_to :user, optional: true
    belongs_to :iteration, class_name: "TestManagement::TestRunIteration", optional: true,
                           inverse_of: :automation_imports
    has_many :results, class_name: "TestManagement::TestResult", foreign_key: :import_id,
                       inverse_of: :import, dependent: :nullify

    validates :format, inclusion: { in: FORMATS }
    validates :state, inclusion: { in: STATES }

    scope :newest_first, -> { order(id: :desc) }

    def done?
      state == "done"
    end

    def unmatched_list
      Array(unmatched)
    end

    def warnings_list
      Array(warnings)
    end
  end
end
