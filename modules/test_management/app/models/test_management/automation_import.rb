# frozen_string_literal: true

module TestManagement
  # One upload of automated test results (a CI report) into a test run.
  # Keeps the audit trail of an ingest: who uploaded what (format, sha256 digest of
  # the payload – never the payload itself), how many tests were parsed, matched,
  # created and which ones could not be matched (and why).
  class AutomationImport < ApplicationRecord
    self.table_name = "tm_automation_imports"

    FORMATS = %w[playwright_json junit native allure cucumber_json cucumber_messages].freeze
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
