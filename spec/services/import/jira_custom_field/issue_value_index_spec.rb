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
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraCustomField::IssueValueIndex do
  include_context "with jira project import data"

  def issue(fields = {}, jira_project: nil, key: "#{jira_project_key}-1", issuetype_id: "10100")
    create(:jira_issue,
           jira_import:,
           jira_project: jira_project || self.jira_project,
           payload: { "key" => key,
                      "fields" => { "project" => { "id" => jira_project_id, "key" => jira_project_key },
                                    "issuetype" => { "id" => issuetype_id } }.merge(fields) })
  end

  describe ".scan" do
    it "collects the custom field keys the issues carry a value for" do
      issue({ "customfield_10001" => { "value" => "Red" }, "customfield_10002" => "text", "summary" => "no" })

      expect(described_class.scan(jira_import)[:used_keys])
        .to contain_exactly("customfield_10001", "customfield_10002")
    end

    it "ignores a custom field whose value is blank" do
      issue({ "customfield_10001" => nil, "customfield_10002" => "", "customfield_10003" => [] })

      expect(described_class.scan(jira_import)[:used_keys]).to be_empty
    end

    it "keeps only the value and child of an option, dropping what nothing reads again" do
      issue({ "customfield_10001" => { "self" => "https://jira.example.com/rest/api/2/customFieldOption/1",
                                       "id" => "1",
                                       "disabled" => false,
                                       "value" => "Animals",
                                       "child" => { "self" => "https://jira.example.com/x", "id" => "2",
                                                    "value" => "Cat" } } })

      expect(described_class.scan(jira_import)[:options]["customfield_10001"])
        .to eq([[{ "value" => "Animals", "child" => { "value" => "Cat" } },
                 [[jira_project_key, jira_project.id, "10100"]]]])
    end

    it "holds an option chain once, with every scope it occurs in" do
      issue({ "customfield_10001" => { "value" => "Red" } }, key: "#{jira_project_key}-1")
      issue({ "customfield_10001" => { "value" => "Red" } }, key: "#{jira_project_key}-2")
      issue({ "customfield_10001" => { "value" => "Red" } }, key: "#{jira_project_key}-3", issuetype_id: "10200")

      expect(described_class.scan(jira_import)[:options]["customfield_10001"])
        .to eq([[{ "value" => "Red" },
                 [[jira_project_key, jira_project.id, "10100"], [jira_project_key, jira_project.id, "10200"]]]])
    end

    it "collects the distinct strings of an array field, sorted" do
      issue({ "customfield_10002" => ["beta", " alpha ", "beta"] }, key: "#{jira_project_key}-1")

      expect(described_class.scan(jira_import)[:strings]["customfield_10002"]).to eq(%w[alpha beta])
    end

    it "records the project and issue type a field carries a value in" do
      issue({ "customfield_10001" => { "value" => "Red" } }, issuetype_id: "10200")

      expect(described_class.scan(jira_import)[:scopes]["customfield_10001"])
        .to eq([[jira_project_key, jira_project.id, "10200"]])
    end

    it "ignores issues of projects the import run does not cover" do
      other = create(:jira_project, jira_import:, origin_id: "99999", payload: { "id" => "99999", "key" => "OTHER" })
      issue({ "customfield_10001" => { "value" => "Red" } }, jira_project: other)

      expect(described_class.scan(jira_import)[:used_keys]).to be_empty
    end
  end

  describe ".sample_issue_keys" do
    it "keeps one issue key per project and issue type" do
      issue(key: "#{jira_project_key}-1")
      issue(key: "#{jira_project_key}-2")
      issue(key: "#{jira_project_key}-3", issuetype_id: "10200")

      expect(described_class.sample_issue_keys(jira_import))
        .to eq([jira_project_key, "10100"] => "#{jira_project_key}-1",
               [jira_project_key, "10200"] => "#{jira_project_key}-3")
    end

    it "samples an issue that carries no custom field value at all" do
      issue(key: "#{jira_project_key}-1")

      expect(described_class.sample_issue_keys(jira_import)).to eq([jira_project_key, "10100"] => "#{jira_project_key}-1")
    end

    it "falls back to the origin id of an issue whose payload has no key" do
      create(:jira_issue, jira_import:, origin_id: "12345", jira_project:,
                          payload: { "fields" => { "project" => { "key" => jira_project_key },
                                                   "issuetype" => { "id" => "10100" } } })

      expect(described_class.sample_issue_keys(jira_import)).to eq([jira_project_key, "10100"] => "12345")
    end

    it "ignores issues of projects the import run does not cover" do
      other = create(:jira_project, jira_import:, origin_id: "99999", payload: { "id" => "99999", "key" => "OTHER" })
      issue(jira_project: other)

      expect(described_class.sample_issue_keys(jira_import)).to be_empty
    end
  end

  describe ".serialize" do
    it "stores a field that carries neither options nor strings as used with empty buckets" do
      issue({ "customfield_10002" => "a value" })

      expect(described_class.serialize(described_class.scan(jira_import)))
        .to eq("customfield_10002" => { "used" => true,
                                        "options" => [],
                                        "strings" => [],
                                        "scopes" => [[jira_project_key, jira_project.id, "10100"]] })
    end
  end

  describe ".load" do
    let!(:jira_field) { create(:jira_field, jira_import:, origin_id: "customfield_10001") }

    it "returns an empty index for a run without fields" do
      Import::JiraField.where(jira_import:).delete_all

      expect(described_class.load(jira_import)).to include(used_keys: be_empty, options: {}, strings: {}, scopes: {})
    end

    it "returns nil while any field has no stored index" do
      expect(described_class.load(jira_import)).to be_nil
    end

    it "leaves out a field stored as unused" do
      jira_field.update!(issue_values: { "used" => false })

      expect(described_class.load(jira_import)[:used_keys]).to be_empty
    end

    it "reproduces what serialize wrote" do
      issue({ "customfield_10001" => { "value" => "Animals", "child" => { "value" => "Cat" } } })
      scanned = described_class.scan(jira_import)
      jira_field.update!(issue_values: described_class.serialize(scanned).fetch("customfield_10001"))

      expect(buckets(described_class.load(jira_import))).to eq(buckets(scanned))
    end

    # What the registry reads back per field, so that a stored and a scanned index are compared
    # the way their consumers use them.
    def buckets(index)
      index[:used_keys].index_with do |field_key|
        index.values_at(:options, :strings, :scopes).map { |bucket| bucket.fetch(field_key, []) }
      end
    end
  end
end
