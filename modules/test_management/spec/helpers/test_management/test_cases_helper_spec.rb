# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestCasesHelper do
  let(:project) { create(:project) }

  def event(action, details)
    TestManagement::TestCaseEvent.new(action:, details:)
  end

  describe "#tm_history_lines" do
    it "describes value changes, text changes, steps, work packages and labels" do
      lines = helper.tm_history_lines(event("updated", {
                                              "status" => %w[draft ready],
                                              "description" => true,
                                              "steps" => true,
                                              "work_packages" => { "added" => [5], "removed" => [7] },
                                              "labels" => { "added" => ["smoke"], "removed" => [] }
                                            }))

      expect(lines.join("\n")).to include("draft", "ready", "#5", "#7", "smoke")
      expect(lines.size).to eq(5)
    end

    it "describes run results" do
      lines = helper.tm_history_lines(event("run_completed", { "run_id" => 4, "run_name" => "Smoke", "status" => "blocked" }))
      expect(lines).to eq(["Run R4 \u201CSmoke\u201D completed: Blocked"])
    end

    it "describes cancelled runs" do
      lines = helper.tm_history_lines(event("run_cancelled", { "run_id" => 4, "run_name" => "Smoke", "status" => "untested" }))
      expect(lines.first).to include("cancelled: Untested")
    end
  end

  describe "labels" do
    it "renders sorted Primer labels" do
      labels = [build(:tm_label, name: "zeta", color: "accent"), build(:tm_label, name: "Alpha", color: "success")]
      html = helper.tm_labels(labels)

      expect(html.index("Alpha")).to be < html.index("zeta")
      expect(html).to include("tm-label")
    end

    it "renders nothing for no labels" do
      expect(helper.tm_labels([])).to eq("")
    end
  end

  it "detects defects by type name" do
    bug = build(:work_package, type: build(:type, name: "Bug"))
    task = build(:work_package, type: build(:type, name: "Task"))

    expect(helper.tm_defect_work_package?(bug)).to be(true)
    expect(helper.tm_defect_work_package?(task)).to be(false)
  end

  it "renders a dash for an unknown user" do
    expect(helper.tm_user_and_time(nil, Time.current)).to include("—")
  end
end
