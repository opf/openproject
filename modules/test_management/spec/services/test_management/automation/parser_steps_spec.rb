# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::Parser, "test steps" do
  def fixture(name, case_id = 1, second_id = 2)
    File.read(File.expand_path("../../../fixtures/files/test_management/steps/#{name}", __dir__))
        .gsub("__CASE_ID__", case_id.to_s).gsub("__CASE2_ID__", second_id.to_s)
  end

  def parse(name, format = "auto")
    described_class.parse(fixture(name), format)
  end

  def code_of
    yield
    nil
  rescue TestManagement::Automation::Error => e
    e.code
  end

  describe "Playwright JSON" do
    let(:record) { parse("playwright-steps.json").last.first }

    it "reads test.step steps with markers, sub-steps and the failing step's error" do
      expect(record.steps.map(&:title)).to eq(["Open the cart", "Enter the card number", "Confirm the payment"])
      expect(record.steps.map(&:marker)).to eq([1, 2, 3])
      expect(record.steps.map(&:raw_status)).to eq(%w[passed passed failed])
      expect(record.steps.second.steps.first.title).to eq("Fill the card field")
      expect(record.steps.third.message).to eq("Timed out waiting for the receipt")
      expect(record.steps.third.stack).to include("checkout.spec.ts:21:7")
    end

    it "keeps the test error without color codes" do
      expect(record.message).to eq("Timed out waiting for the receipt")
      expect(record.stack).to include("checkout.spec.ts:21:7")
    end
  end

  describe "Allure results" do
    let(:parsed) { parse("allure-results.json") }
    let(:records) { parsed.last }
    let(:order) { records.find { |r| r.title == "Cancel an order" } }
    let(:profile) { records.find { |r| r.title == "Rename profile" } }

    it "detects the format and groups retries" do
      expect(parsed.first).to eq("allure")
      expect(records.size).to eq(2)
      expect(profile.raw_status).to eq("flaky")
      expect(profile.retry).to eq(1)
    end

    it "reads status details, labels, step durations and step attachments" do
      expect(order.raw_status).to eq("broken")
      expect(order.message).to eq("Element not found: #cancel")
      expect(order.stack).to include("OrdersTest.java:40")
      expect(order.properties["tm_case"]).to eq(["1"])
      expect(order.tags).to eq(["orders"])
      expect(order.steps.first.duration_ms).to eq(500)
      expect(order.steps.second.attachments.first["path"]).to eq("orders-1-attachment.png")
      expect(order.attachments.pluck("path")).to include("orders-1-attachment.png")
    end

    it "uses the tm_step parameter as marker" do
      expect(profile.steps.first.marker).to eq(2)
    end
  end

  describe "Cucumber JSON" do
    let(:parsed) { parse("cucumber.json") }
    let(:record) { parsed.last.first }

    it "merges the background, keeps failed hooks and leaves out passed ones" do
      expect(parsed.first).to eq("cucumber_json")
      expect(record.steps.map(&:title)).to eq(["Given a member named Olena", "When she borrows \"Kobzar\"",
                                               "Then the loan is due in 14 days", "And a receipt is printed", "hooks.rb:9"])
      expect(record.steps.last.hook).to be(true)
      expect(record.steps.third.duration_ms).to eq(3)
    end

    it "builds the reference, status, error and tag properties" do
      expect(record.reference).to eq("features/library.feature#Library loans › Borrow a book")
      expect(record.raw_status).to eq("failed")
      expect(record.message).to start_with("expected 14 but got 7")
      expect(record.properties["tm_case"]).to eq(["1"])
      expect(record.tags).to include("@smoke")
    end
  end

  describe "Cucumber messages" do
    let(:parsed) { parse("cucumber-messages.ndjson") }
    let(:record) { parsed.last.first }

    it "uses the last attempt with step statuses, durations and the exception" do
      expect(parsed.first).to eq("cucumber_messages")
      expect(record.retry).to eq(1)
      expect(record.raw_status).to eq("failed")
      expect(record.steps.map(&:title)).to eq(["a member named Olena", "she returns \"Kobzar\"", "the loan is closed"])
      expect(record.steps.map(&:raw_status)).to eq(%w[passed failed skipped])
      expect(record.steps.second.duration_ms).to eq(1000)
      expect(record.message).to eq("Book not on loan")
      expect(record.stack).to include("steps.js:4")
      expect(record.reference).to eq("features/library.feature#Library loans › Return a book")
    end

    it "rejects a stream without test cases" do
      expect(code_of { described_class.parse(%({"meta":{}}\n), "cucumber_messages") }).to eq(:unprocessable)
    end
  end

  describe "native format" do
    let(:record) { parse("native-steps.json").last.first }

    it "reads the step field as marker and merges step attachments" do
      expect(record.steps.map(&:marker)).to eq([1, 2])
      expect(record.steps.second.raw_status).to eq("failed")
      expect(record.attachments.pluck("path")).to include("logs/close-account.json")
    end

    it "caps the number of steps, their depth and texts" do
      many = { tests: [{ title: "big", status: "failed",
                         steps: Array.new(300) { |i| { title: "s#{i}", message: "x" * 9000 } } }] }.to_json
      record = described_class.parse(many, "native").last.first
      expect(record.steps.size).to eq(200)
      expect(record.steps.first.message.size).to be <= 4000

      deep = { title: "d0" }
      (1..6).each { |i| deep = { title: "d#{i}", steps: [deep] } }
      record = described_class.parse({ tests: [{ title: "deep", status: "passed", steps: [deep] }] }.to_json, "native").last.first
      expect(record.steps.first.each_step.count).to eq(5)
    end
  end

  it "rejects a report that does not fit the requested format" do
    expect(code_of { described_class.parse(%({"a":1}), "allure") }).to eq(:unprocessable)
  end
end
