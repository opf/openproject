# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::StepMatcher do
  let(:case_step) { Struct.new(:id, :position, :action) }
  let(:case_steps) do
    [case_step.new(11, 1, "Open the login page"), case_step.new(12, 2, "Enter the user name and password"),
     case_step.new(13, 3, "Press Sign in"), case_step.new(14, 4, "See the dashboard")]
  end

  def step(title, status = "passed", **)
    TestManagement::Automation::Parsers::Steps.step(title:, raw_status: status, **)
  end

  def match(steps, **)
    described_class.new(case_steps:, **).call(steps)
  end

  describe "markers" do
    it "maps marked steps by number and marks the others not run" do
      rows = match([step("[step:2] type the credentials"), step("[step:3] click", "failed", message: "Boom")])

      expect(rows.pluck(:status)).to eq(%w[untested passed failed untested])
      expect(rows.third).to include(match_method: "marker", error_message: "Boom")
      expect(rows.second[:reported_title]).to eq("type the credentials")
      expect(rows.pluck(:test_step).map(&:id)).to eq([11, 12, 13, 14])
    end

    it "blocks the case steps after the failed one with stepsAfterFailure blocked" do
      rows = match([step("[step:2] a", "failed")], steps_after_failure: "blocked")
      expect(rows.pluck(:status)).to eq(%w[untested failed blocked blocked])
    end

    it "uses the worst status for several steps on one case step and keeps out-of-range markers as reported" do
      rows = match([step("[step:1] a"), step("[step:1] b", "failed"), step("[step:9] beyond")])

      expect(rows.first[:status]).to eq("failed")
      expect(rows.first[:details]["reported"]).to eq(%w[a b])
      expect(rows.last).to include(kind: "reported", reported_title: "beyond")
    end

    it "finds marked steps nested in groups" do
      rows = match([step("group", "failed", steps: [step("[step:4] see", "failed", message: "nope")])])

      expect(rows.fourth).to include(status: "failed", error_message: "nope")
      expect(rows.none? { |row| row[:kind] == "reported" }).to be(true)
    end
  end

  it "maps by position when the counts match" do
    rows = match([step("a"), step("b"), step("c", "failed"), step("d", "skipped")])

    expect(rows.map { |row| [row[:status], row[:match_method]] })
      .to eq([%w[passed position], %w[passed position], %w[failed position], %w[skipped position]])
  end

  it "maps by title otherwise and keeps the rest as reported steps" do
    rows = match([step("Given I open the login page"), step("When I press sign-in", "failed"), step("Totally unrelated thing")])

    expect(rows.size).to eq(5)
    expect(rows.first(4).pluck(:status)).to eq(%w[passed untested failed untested])
    expect(rows.first[:match_method]).to eq("title")
    expect(rows.last).to include(kind: "reported", reported_title: "Totally unrelated thing", position: 4)
  end

  it "writes only reported rows when nothing matches" do
    expect(match([step("nothing like it"), step("zzz")]).pluck(:kind)).to eq(%w[reported reported])
  end

  it "never matches hooks and keeps failed ones" do
    rows = match([step("a"), step("b"), step("c"), step("d"), step("hooks.rb:9", "failed", hook: true)])

    expect(rows.first(4).pluck(:match_method).uniq).to eq(["position"])
    expect(rows.last[:details]["hook"]).to be(true)
  end

  it "maps raw step statuses" do
    expect(%w[broken timedOut undefined pending SKIPPED unknown interrupted].map { |s| described_class.step_status(s) })
      .to eq(%w[failed failed failed skipped skipped untested blocked])
  end

  it "compares titles without Gherkin keywords, case and punctuation" do
    expect(described_class.similarity("Then the Loan is due!", "the loan is due")).to eq(1.0)
    expect(described_class.similarity("abc", "xyz")).to be < described_class::TITLE_THRESHOLD
  end

  it "returns nothing for a test without steps" do
    expect(match([])).to eq([])
  end
end
