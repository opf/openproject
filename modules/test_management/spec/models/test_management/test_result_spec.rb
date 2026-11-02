# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestResult do
  it "stores status, comment, user and time" do
    result = create(:tm_test_result, status: "blocked", comment: "env down")

    expect(result.reload).to have_attributes(status: "blocked", comment: "env down")
    expect(result.user).to be_present
    expect(result.created_at).to be_within(1.minute).of(Time.current)
  end

  describe ".latest_by_run_case" do
    let(:run) { create(:tm_test_run, :in_progress) }
    let(:case_a) { create(:tm_test_run_case, test_run: run) }
    let(:case_b) { create(:tm_test_run_case, test_run: run) }
    let(:iteration) { create(:tm_test_run_iteration, test_run: run, number: 1) }

    it "returns the newest result per run case, optionally within one iteration" do
      in_iteration = create(:tm_test_result, run_case: case_a, status: "failed", iteration:)
      newest_a = create(:tm_test_result, run_case: case_a, status: "passed")
      newest_b = create(:tm_test_result, run_case: case_b, status: "blocked")

      expect(described_class.latest_by_run_case([case_a.id, case_b.id]))
        .to eq(case_a.id => newest_a, case_b.id => newest_b)
      expect(described_class.latest_by_run_case([case_a.id, case_b.id], iteration_id: iteration.id))
        .to eq(case_a.id => in_iteration)
    end
  end

  it "requires a known status" do
    expect(build(:tm_test_result, status: "unknown")).not_to be_valid
  end

  # Deleting a real user row trips other core FKs (notification settings, …);
  # OpenProject deletes users via Principals::DeleteJob. Check the FK instead.
  it "keeps the result when the user is deleted (user_id FK nullifies)" do
    fk = ActiveRecord::Base.connection.foreign_keys(:tm_test_results).find { |key| key.column == "user_id" }

    expect(fk).to be_present
    expect(fk.on_delete).to eq(:nullify)
  end
end
