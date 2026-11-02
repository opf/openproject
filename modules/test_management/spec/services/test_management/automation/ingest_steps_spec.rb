# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::IngestService, "step results" do
  include FileHelpers

  shared_let(:project) { create(:project, enabled_module_names: %i[test_management]) }
  shared_let(:user) do
    create(:user, member_with_permissions: { project => %i[view_test_cases view_test_runs upload_test_results] })
  end

  let(:pay) do
    case_with_steps("Pay by card", "Open the cart", "Enter the card number", "Confirm the payment", "Check the e-mail")
  end
  let(:total) { case_with_steps("Basket total", "Open the basket page", "Check the total amount") }

  def case_with_steps(title, *actions)
    create(:tm_test_case, project:, title:).tap do |test_case|
      actions.each_with_index { |action, index| create(:tm_test_step, test_case:, position: index, action:) }
    end
  end

  def fixture(name, case_id, second_id = 0)
    File.read(File.expand_path("../../../fixtures/files/test_management/steps/#{name}", __dir__))
        .gsub("__CASE_ID__", case_id.to_s).gsub("__CASE2_ID__", second_id.to_s)
  end

  def ingest(content, options = {}, files = [])
    described_class.new(user:, project:).call(content:, options:, files:)
  end

  def result_for(outcome, test_case)
    outcome.run.run_cases.find_by(test_case_id: test_case.id).results.last
  end

  describe "a Playwright report with marked steps" do
    let(:outcome) { ingest(fixture("playwright-steps.json", pay.id, total.id)) }
    let(:result) { result_for(outcome, pay) }

    it "stores the error message and trace on the result and keeps the comment" do
      expect(result.error_message).to eq("Timed out waiting for the receipt")
      expect(result.error_trace).to include("checkout.spec.ts:21:7")
      expect(result.comment).to start_with("[chromium] Timed out")
    end

    it "writes one step result per case step, linked to the case steps" do
      steps = result.step_results.to_a

      expect(steps.map(&:test_step_id)).to eq(pay.steps.map(&:id))
      expect(steps.map(&:status)).to eq(%w[passed passed failed untested])
      expect(steps.map(&:match_method)).to eq(["marker", "marker", "marker", nil])
      expect(steps.third.error_message).to eq("Timed out waiting for the receipt")
      expect(steps.second.substeps.first["title"]).to eq("Fill the card field")
      expect(result.failed_step.number).to eq(3)
      expect(outcome.run.run_cases.find_by(test_case_id: pay.id).status).to eq("failed")
    end

    it "maps the unmarked steps of the second test by position" do
      second = result_for(outcome, total)

      expect(second.step_results.map(&:match_method).uniq).to eq(["position"])
      expect(second.error_message).to be_nil
    end
  end

  it "marks the steps after the failure blocked with stepsAfterFailure" do
    outcome = ingest(fixture("playwright-steps.json", pay.id, total.id), { "stepsAfterFailure" => "blocked" })
    expect(result_for(outcome, pay).step_results.last.status).to eq("blocked")
  end

  it "links step attachments to the uploaded files" do
    close = case_with_steps("Close account", "Create the account", "Close it")
    outcome = ingest(fixture("native-steps.json", close.id), {}, [mock_uploaded_file(name: "close-account.json", content: "{}")])
    ref = result_for(outcome, close).step_results.second.attachment_refs.first

    expect(ref["name"]).to eq("response body")
    expect(ref["attachmentId"]).to be_present
  end

  it "maps Cucumber steps (background first) and keeps failed hooks as reported steps" do
    book = case_with_steps("Borrow a book", "a member named Olena", "she borrows a book", "the loan is due in 14 days",
                           "a receipt is printed")
    result = result_for(ingest(fixture("cucumber.json", book.id)), book)

    expect(result.step_results.select(&:case_step?).map(&:status)).to eq(%w[passed passed failed skipped])
    expect(result.step_results.select(&:reported?).map { |row| row.details_hash["hook"] }).to eq([true])
  end

  it "accepts Allure results and Cucumber messages" do
    order = case_with_steps("Cancel an order", "I am signed in as a customer", "Open my orders", "Press cancel")
    outcome = ingest(fixture("allure-results.json", order.id))
    rows = result_for(outcome, order).step_results.to_a

    expect(outcome.import.format).to eq("allure")
    expect(rows.select(&:case_step?).map { |row| [row.status, row.match_method] })
      .to eq([%w[passed title], %w[passed title], %w[failed title]])
    expect(rows.select(&:reported?).map(&:reported_title)).to eq(["Unrelated cleanup helper"])

    book = case_with_steps("Return a book", "a member named Olena", "she returns the book", "the loan is closed")
    outcome = ingest(fixture("cucumber-messages.ndjson", book.id))
    expect(outcome.import.format).to eq("cucumber_messages")
    expect(result_for(outcome, book).step_results.map(&:status)).to eq(%w[passed failed skipped])
  end

  it "writes no step results for tests without steps" do
    outcome = ingest({ tests: [{ caseId: pay.id, status: "failed", message: "boom" }] }.to_json)
    result = result_for(outcome, pay)

    expect(result.step_results).to be_empty
    expect(result.error_message).to eq("boom")
  end
end
