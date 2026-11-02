# frozen_string_literal: true

require "spec_helper"

RSpec.describe TestManagement::Automation::Parser do
  def fixture(name, case_id = 1)
    File.read(File.expand_path("../../../fixtures/files/test_management/#{name}", __dir__)).gsub("__CASE_ID__", case_id.to_s)
  end

  def code_of
    yield
    nil
  rescue TestManagement::Automation::Error => e
    e.code
  end

  describe "Playwright JSON" do
    subject(:parsed) { described_class.parse(fixture("playwright-report.json", 7), "auto") }

    let(:records) { parsed.last }

    it "detects the format and returns one record per project run" do
      expect(parsed.first).to eq("playwright_json")
      expect(records.size).to eq(5)
    end

    it "builds the reference from file and title path, keeps status, duration and attachments" do
      firefox = records.find { |r| r.project_name == "firefox" }

      expect(firefox.reference).to eq("login.spec.ts#Login › signs in with valid credentials")
      expect(firefox.raw_status).to eq("failed")
      expect(firefox.duration_ms).to eq(2300)
      expect(firefox.attachments.first["path"]).to end_with("login-firefox/test-failed-1.png")
    end

    it "strips ANSI color codes from error messages" do
      firefox = records.find { |r| r.project_name == "firefox" }

      expect(firefox.message).to start_with('Expected: "Welcome"')
      expect(firefox.message).not_to include("\e")
    end

    it "reports flaky tests with the tm_case annotation and the retry" do
      flaky = records.find { |r| r.title.include?("wrong") }

      expect(flaky.raw_status).to eq("flaky")
      expect(flaky.properties["tm_case"]).to eq(["7"])
      expect(flaky.retry).to eq(1)
    end

    it "keeps skipped tests and tags" do
      expect(records.find { |r| r.title == "remembers the user" }.raw_status).to eq("skipped")
      expect(records.find { |r| r.file == "reports.spec.ts" }.tags).to eq(["@reports"])
    end
  end

  describe "JUnit XML" do
    let(:records) { described_class.parse(fixture("junit-report.xml", 7), "auto").last }

    it "maps testcases, times, properties and attachments" do
      expect(records.map(&:raw_status)).to eq(%w[passed failed passed skipped])
      expect(records[0].properties["tm_case"]).to eq(["7"])
      expect(records[1].duration_ms).to eq(750)
      expect(records[1].reference).to eq("UsersApiTest#rejects duplicate e-mail")
      expect(records[1].attachments.first["path"]).to eq("/tmp/artifacts/duplicate.log")
    end
  end

  describe "native JSON" do
    it "reads caseId, reference and attachments" do
      format, records = described_class.parse(fixture("native-report.json", 7), "auto")

      expect(format).to eq("native")
      expect(records.size).to eq(3)
      expect(records[0].case_ids).to eq(["7"])
      expect(records[1].attachments.first["name"]).to eq("Health log")
    end
  end

  describe "invalid input" do
    it "rejects empty and unreadable reports with :bad_request" do
      expect(code_of { described_class.parse("", "auto") }).to eq(:bad_request)
      expect(code_of { described_class.parse("{nope", "auto") }).to eq(:bad_request)
    end

    it "refuses XML with a DTD (no external entities)" do
      xml = %(<?xml version="1.0"?><!DOCTYPE x [<!ENTITY e SYSTEM "file:///etc/passwd">]><testsuite><testcase name="&e;"/></testsuite>)

      expect(code_of { described_class.parse(xml, "auto") }).to eq(:bad_request)
    end

    it "answers :unprocessable for a report without tests" do
      expect(code_of { described_class.parse(%({"suites":[]}), "auto") }).to eq(:unprocessable)
    end
  end
end
