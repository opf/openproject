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

    it "builds the reference from file and title path, keeps status and duration" do
      firefox = records.find { |r| r.project_name == "firefox" }

      expect(firefox.reference).to eq("login.spec.ts#Login › signs in with valid credentials")
      expect(firefox.raw_status).to eq("failed")
      expect(firefox.duration_ms).to eq(2300)
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

    it "maps testcases, times and properties" do
      expect(records.map(&:raw_status)).to eq(%w[passed failed passed skipped])
      expect(records[0].properties["tm_case"]).to eq(["7"])
      expect(records[1].duration_ms).to eq(750)
      expect(records[1].reference).to eq("UsersApiTest#rejects duplicate e-mail")
    end
  end


  describe "invalid input" do
    it "rejects empty and unreadable reports with :bad_request" do
      expect(code_of { described_class.parse("", "auto") }).to eq(:bad_request)
      expect(code_of { described_class.parse("{nope", "auto") }).to eq(:bad_request)
    end

    it "refuses XML with a DTD (no external entities)" do
      xml = %(<?xml version="1.0"?><!DOCTYPE x [<!ENTITY e SYSTEM "file:///etc/passwd">]>) +
            %(<testsuite><testcase name="&e;"/></testsuite>)

      expect(code_of { described_class.parse(xml, "auto") }).to eq(:bad_request)
    end

    it "answers :unprocessable for a report without tests" do
      expect(code_of { described_class.parse(%({"suites":[]}), "auto") }).to eq(:unprocessable)
    end
  end
end
