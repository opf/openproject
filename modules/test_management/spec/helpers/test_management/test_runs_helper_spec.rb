# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::TestRunsHelper do
  let(:counts) { { "passed" => 2, "failed" => 1, "blocked" => 0, "retest" => 0, "in_progress" => 0, "untested" => 1 } }

  describe "#tm_run_pie_chart" do
    it "draws one slice per non-empty status with 'NN% (count)' labels" do
      html = helper.tm_run_pie_chart(counts)

      expect(html).to include("<svg", 'data-test-selector="tm-run-pie"')
      expect(html.scan("<path").size).to eq(3)
      expect(html).to include("50% (2)", "25% (1)")
      expect(html).not_to include('data-status="blocked"')
    end

    it "draws a full circle for a single status and for an empty run" do
      expect(helper.tm_run_pie_chart(counts.merge("passed" => 0, "failed" => 0))).to include("<circle", "100% (1)")
      expect(helper.tm_run_pie_chart(counts.transform_values { 0 })).to include("<circle")
    end
  end

  describe "#tm_run_progress_bar" do
    it "stacks segments proportionally" do
      html = helper.tm_run_progress_bar(counts, width: 100)

      expect(html.scan("<rect").size).to eq(3)
      expect(html).to include('width="50.0"', 'width="25.0"')
      expect(html).to include(described_class::STATUS_COLORS["passed"])
    end

    it "renders a grey bar for an empty run" do
      expect(helper.tm_run_progress_bar(counts.transform_values { 0 })).to include(described_class::STATUS_COLORS["untested"])
    end
  end

  describe "automation helpers" do
    it "badges automation runs only" do
      expect(helper.tm_run_source_label(build(:tm_test_run, :automation)))
        .to include(I18n.t("test_management.runs.automation.badge"), "tm-run-source")
      expect(helper.tm_run_source_label(build(:tm_test_run))).to be_blank
    end

    it "only lets http(s) CI links through" do
      expect(helper.tm_safe_url("https://github.com/org/repo/actions/runs/1")).to eq("https://github.com/org/repo/actions/runs/1")
      expect(helper.tm_safe_url("javascript:alert(1)")).to be_nil
      expect(helper.tm_safe_url("https://x.test/a b")).to be_nil
      expect(helper.tm_safe_url(nil)).to be_nil
    end

    it "leaves skipped cases out of the pass rate" do
      expect(helper.tm_pass_rate(counts.merge("skipped" => 4))).to eq(50)
      expect(helper.tm_pass_rate(counts.transform_values { 0 }.merge("skipped" => 3))).to eq(0)
    end
  end

  it "computes rounded percentages" do
    expect(helper.tm_status_percent(1, 3)).to eq(33)
    expect(helper.tm_status_percent(0, 0)).to eq(0)
  end

  it "renders state and status labels" do
    run = build(:tm_test_run, :completed)

    expect(helper.tm_run_state_label(run)).to include("Completed")
    expect(helper.tm_run_status_label("retest")).to include("Retest", "tm-run-status--retest")
  end

  describe "#tm_run_case_tree" do
    let(:project) { create(:project) }
    let(:root) { create(:tm_suite, project:) }
    let(:child) { create(:tm_suite, project:, parent: root) }
    let(:empty) { create(:tm_suite, project:) }
    let(:run) { create(:tm_test_run, project:) }

    it "nests run cases by folder, skips empty folders and collects unfiled cases" do
      in_child = create(:tm_test_run_case, test_run: run, test_case: create(:tm_test_case, project:, suite: child))
      unfiled = create(:tm_test_run_case, test_run: run, test_case: create(:tm_test_case, project:))

      nodes, rest = helper.tm_run_case_tree([in_child, unfiled], [root, child, empty])

      expect(nodes.size).to eq(1)
      expect(nodes.first).to include(suite: root, count: 1, cases: [])
      expect(nodes.first[:children].first).to include(suite: child, cases: [in_child], count: 1)
      expect(rest).to eq([unfiled])
    end
  end

  it "collects case ids of a folder subtree in memory" do
    suites = { nil => [Struct.new(:id).new(1)], 1 => [Struct.new(:id).new(2)] }
    cases = { 1 => [Struct.new(:id).new(10)], 2 => [Struct.new(:id).new(20)] }

    expect(helper.tm_subtree_case_ids(1, suites, cases)).to eq([10, 20])
  end

  describe "#tm_error_block (0020)" do
    it "escapes the message and puts the trace in a collapsed details element" do
      html = helper.tm_error_block("<img src=x onerror=alert(1)>", "Error\n  at <b>x</b>")

      expect(html).to include("&lt;img src=x onerror=alert(1)&gt;", "at &lt;b&gt;x&lt;/b&gt;", "<details")
      expect(html).not_to include("<img", "<b>", " open")
    end

    it "renders nothing without an error and no trace equal to the message" do
      expect(helper.tm_error_block(nil, "")).to eq("")
      expect(helper.tm_error_block("boom", "boom")).not_to include("<details")
    end
  end

  describe "#tm_result_failure_line (0020)" do
    it "names the failed step and the first error line" do
      result = build(:tm_test_result, status: "failed", error_message: "\n  Expected 3\nReceived 2")
      allow(result).to receive(:failed_step).and_return(build(:tm_test_step_result, position: 1))

      expect(helper.tm_result_failure_line(result)).to eq("Failed at step 2: Expected 3")
      expect(helper.tm_result_failure_line(nil)).to be_nil
    end
  end
end
