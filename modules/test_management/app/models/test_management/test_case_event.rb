# frozen_string_literal: true

module TestManagement
  # One row per create/update of a test case (History tab).
  # details: { "title" => [old, new], "status" => [old, new], "description" => true,
  #            "steps" => true, "work_packages" => { "added" => [ids], "removed" => [ids] }, ... }
  class TestCaseEvent < ApplicationRecord
    self.table_name = "tm_test_case_events"
    self.record_timestamps = false

    # run_completed / run_cancelled: written for every case of a run when the run is
    # finished; details: { "run_id", "run_name", "status" }.
    ACTIONS = %w[created updated deleted restored run_completed run_cancelled automation_result].freeze

    belongs_to :test_case, class_name: "TestManagement::TestCase", inverse_of: :events
    belongs_to :user, optional: true

    validates :action, inclusion: { in: ACTIONS }

    before_create { self.created_at ||= Time.current }

    scope :chronological, -> { order(:created_at, :id) }
  end
end
