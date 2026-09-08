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
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Import::JiraFetchCustomFieldJob do
  include_context "with jira project import data"

  subject(:fetch_custom_fields) { described_class.perform_now(jira_import.id) }

  let(:jira_client) { instance_double(Import::JiraClient) }

  let(:select_field_payload) do
    {
      "id" => "customfield_10264",
      "name" => "CF List",
      "custom" => true,
      "schema" => {
        "type" => "option",
        "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select",
        "customId" => 10264
      }
    }
  end

  let!(:select_field) do
    create(:jira_field, jira_import:, origin_id: "customfield_10264", payload: select_field_payload)
  end

  def issue(key:, issuetype_id:, fields: { "customfield_10264" => { "value" => "Red" } })
    create(:jira_issue,
           jira_import:,
           jira_project:,
           payload: {
             "key" => key,
             "fields" => {
               "project" => { "id" => jira_project_id, "key" => jira_project_key },
               "issuetype" => { "id" => issuetype_id }
             }.merge(fields)
           })
  end

  def option(id, value, children_ids: [], disabled: false)
    { "self" => "https://jira.example.com/rest/api/2/customFieldOption/#{id}",
      "value" => value,
      "disabled" => disabled,
      "id" => id,
      "childrenIds" => children_ids }
  end

  before do
    allow(Import::JiraClient).to receive(:new).and_return(jira_client)
    allow(jira_client).to receive(:fields).and_return([select_field_payload])
  end

  describe "collecting the fields to import" do
    let(:unused_field_payload) do
      { "id" => "customfield_10888", "name" => "CF Unused", "custom" => true,
        "schema" => { "type" => "option", "customId" => 10888 } }
    end

    before { allow(jira_client).to receive(:custom_field_options).and_return([]) }

    it "stores only the custom fields an imported issue carries a value for" do
      allow(jira_client).to receive(:fields).and_return([select_field_payload, unused_field_payload])
      issue(key: "#{jira_project_key}-1", issuetype_id: "10100")

      fetch_custom_fields

      expect(Import::JiraField.where(jira_import:).pluck(:origin_id)).to eq(["customfield_10264"])
    end

    it "ignores a field the API does not flag as custom" do
      not_custom = { "id" => "customfield_10999", "name" => "CF Not Custom", "custom" => false,
                     "schema" => { "type" => "option", "customId" => 10999 } }
      allow(jira_client).to receive(:fields).and_return([select_field_payload, not_custom])
      issue(key: "#{jira_project_key}-1", issuetype_id: "10100",
            fields: { "customfield_10264" => { "value" => "Red" }, "customfield_10999" => { "value" => "Blue" } })

      fetch_custom_fields

      expect(Import::JiraField.where(jira_import:, origin_id: "customfield_10999")).not_to exist
    end

    it "ignores issues of projects the import run does not cover" do
      other_project = create(:jira_project, jira_import:, origin_id: "10500",
                                            payload: { "id" => "10500", "key" => "OTHER" })
      create(:jira_issue, jira_import:, jira_project: other_project,
                          payload: { "key" => "OTHER-1",
                                     "fields" => { "project" => { "id" => "10500", "key" => "OTHER" },
                                                   "issuetype" => { "id" => "10100" },
                                                   "customfield_10888" => { "value" => "Red" } } })
      allow(jira_client).to receive(:fields).and_return([select_field_payload, unused_field_payload])
      issue(key: "#{jira_project_key}-1", issuetype_id: "10100")

      fetch_custom_fields

      expect(Import::JiraField.where(jira_import:, origin_id: "customfield_10888")).not_to exist
      expect(jira_client).not_to have_received(:custom_field_options).with(10888, any_args)
    end

    it "does not touch Jira when no imported issue carries a custom field value" do
      issue(key: "#{jira_project_key}-1", issuetype_id: "10100", fields: { "summary" => "no custom fields here" })

      fetch_custom_fields

      expect(jira_client).not_to have_received(:fields)
      expect(select_field.reload.payload).not_to have_key("contextGroups")
    end

    it "does not store a field twice when the job runs again" do
      issue(key: "#{jira_project_key}-1", issuetype_id: "10100")
      described_class.perform_now(jira_import.id)

      expect { described_class.perform_now(jira_import.id) }
        .not_to change(Import::JiraField.where(jira_import:), :count)
    end
  end

  context "when Jira provides the custom field options endpoint (Jira DC >= 9.3)" do
    let!(:task) { issue(key: "#{jira_project_key}-1", issuetype_id: "10100") }
    let!(:bug) { issue(key: "#{jira_project_key}-2", issuetype_id: "10200") }

    # Stubbed so that a fallback to the editmeta route would show up as a received call.
    before { allow(jira_client).to receive(:issue_editmeta).and_return({ "fields" => {} }) }

    def context_groups
      select_field.reload.payload["contextGroups"]
    end

    it "asks the options endpoint per (project, issue type) the field is used in" do
      allow(jira_client).to receive(:custom_field_options).and_return([option(10200, "Red")])

      fetch_custom_fields

      expect(jira_client).to have_received(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10100"]).once
      expect(jira_client).to have_received(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10200"]).once
      expect(jira_client).not_to have_received(:issue_editmeta)
    end

    it "does not ask for issue types no imported issue carries a value for" do
      issue(key: "#{jira_project_key}-3", issuetype_id: "10300", fields: { "customfield_10264" => nil })
      allow(jira_client).to receive(:custom_field_options).and_return([option(10200, "Red")])

      fetch_custom_fields

      expect(jira_client).not_to have_received(:custom_field_options)
        .with(anything, hash_including(issue_type_ids: ["10300"]))
    end

    it "merges identical option sets into a single context group" do
      allow(jira_client).to receive(:custom_field_options)
        .and_return([option(10200, "Red"), option(10201, "Purple")])

      fetch_custom_fields

      expect(context_groups.size).to eq(1)
      expect(context_groups.first["issuetypes"]).to contain_exactly("10100", "10200")
      expect(context_groups.first["projects"]).to eq([jira_project_key])
      expect(context_groups.first["allowedValues"].pluck("value")).to eq(%w[Red Purple])
    end

    it "keeps differing option sets as separate context groups" do
      allow(jira_client).to receive(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10100"])
        .and_return([option(10200, "Red")])
      allow(jira_client).to receive(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10200"])
        .and_return([option(10201, "Purple")])

      fetch_custom_fields

      expect(context_groups.map { |group| [group["issuetypes"], group["allowedValues"].pluck("value")] })
        .to contain_exactly([["10100"], ["Red"]], [["10200"], ["Purple"]])
    end

    it "omits options that are disabled in Jira" do
      allow(jira_client).to receive(:custom_field_options)
        .and_return([option(10200, "Red"), option(10201, "Purple", disabled: true)])

      fetch_custom_fields

      expect(context_groups.first["allowedValues"].pluck("value")).to eq(["Red"])
    end

    it "nests the children of a cascading select from their childrenIds" do
      allow(jira_client).to receive(:custom_field_options).and_return(
        [option(10200, "Animals", children_ids: [10202, 10203]),
         option(10202, "Cat"),
         option(10203, "Dog"),
         option(10201, "Plants", children_ids: [10204]),
         option(10204, "Fern")]
      )

      fetch_custom_fields

      expect(context_groups.first["allowedValues"]).to eq(
        [{ "id" => "10200", "value" => "Animals",
           "children" => [{ "id" => "10202", "value" => "Cat" }, { "id" => "10203", "value" => "Dog" }] },
         { "id" => "10201", "value" => "Plants", "children" => [{ "id" => "10204", "value" => "Fern" }] }]
      )
    end

    it "skips a field whose options cannot be fetched once the endpoint has answered" do
      allow(jira_client).to receive(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10100"])
        .and_return([option(10200, "Red")])
      allow(jira_client).to receive(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10200"])
        .and_raise(Import::JiraClient::ApiError.new("boom", status: 500))

      expect { fetch_custom_fields }.not_to raise_error
      expect(context_groups.map { |group| group["allowedValues"].pluck("value") }).to eq([["Red"]])
      expect(jira_client).not_to have_received(:issue_editmeta)
    end

    it "records no context group for a context without options" do
      allow(jira_client).to receive(:custom_field_options).and_return([])

      fetch_custom_fields

      expect(select_field.reload.payload).not_to have_key("contextGroups")
    end

    it "falls back to editmeta when the very first options request fails outright" do
      allow(jira_client).to receive(:custom_field_options)
        .and_raise(Import::JiraClient::ApiError.new("boom", status: 500))
      allow(jira_client).to receive(:issue_editmeta).and_return(
        { "fields" => { "customfield_10264" => { "allowedValues" => [{ "id" => "1", "value" => "Red" }] } } }
      )

      fetch_custom_fields

      expect(jira_client).to have_received(:issue_editmeta).at_least(:once)
      expect(context_groups.first["allowedValues"]).to eq([{ "id" => "1", "value" => "Red" }])
    end

    it "keeps cascading contexts apart when they share their parents but differ in children" do
      allow(jira_client).to receive(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10100"])
        .and_return([option(10200, "Animals", children_ids: [10202]), option(10202, "Cat")])
      allow(jira_client).to receive(:custom_field_options)
        .with(10264, project_ids: [jira_project_id], issue_type_ids: ["10200"])
        .and_return([option(10200, "Animals", children_ids: [10203]), option(10203, "Dog")])

      fetch_custom_fields

      expect(context_groups.map { |group| group["allowedValues"].first["children"].pluck("value") })
        .to contain_exactly(["Cat"], ["Dog"])
    end

    it "ignores childrenIds the response carries no option for" do
      allow(jira_client).to receive(:custom_field_options)
        .and_return([option(10200, "Animals", children_ids: [10999])])

      fetch_custom_fields

      expect(context_groups.first["allowedValues"]).to eq([{ "id" => "10200", "value" => "Animals" }])
    end

    it "drops a disabled option together with its children" do
      allow(jira_client).to receive(:custom_field_options)
        .and_return([option(10200, "Animals", children_ids: [10202], disabled: true), option(10202, "Cat")])

      fetch_custom_fields

      expect(select_field.reload.payload).not_to have_key("contextGroups")
    end

    # An option listing itself is a child of something and therefore no root of the tree.
    it "drops an option that lists itself as its own child" do
      allow(jira_client).to receive(:custom_field_options)
        .and_return([option(10200, "Animals", children_ids: [10200])])

      expect { fetch_custom_fields }.not_to raise_error
      expect(select_field.reload.payload).not_to have_key("contextGroups")
    end

    it "stops descending when the option tree loops back on itself" do
      allow(jira_client).to receive(:custom_field_options).and_return(
        [option(10200, "Animals", children_ids: [10202]),
         option(10202, "Cat", children_ids: [10203]),
         option(10203, "Kitten", children_ids: [10202])]
      )

      expect { fetch_custom_fields }.not_to raise_error
      expect(context_groups.first["allowedValues"]).to eq(
        [{ "id" => "10200", "value" => "Animals",
           "children" => [{ "id" => "10202", "value" => "Cat",
                            "children" => [{ "id" => "10203", "value" => "Kitten" }] }] }]
      )
    end

    it "does not ask for the options of a field that has none" do
      create(:jira_field, jira_import:, origin_id: "customfield_10555",
                          payload: { "id" => "customfield_10555", "name" => "CF Text",
                                     "schema" => { "type" => "string", "customId" => 10555,
                                                   "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield" } })
      issue(key: "#{jira_project_key}-3", issuetype_id: "10100",
            fields: { "customfield_10555" => "some text" })
      allow(jira_client).to receive(:custom_field_options).and_return([option(10200, "Red")])

      fetch_custom_fields

      expect(jira_client).not_to have_received(:custom_field_options).with(10555, any_args)
    end

    it "recognises an option field of a third-party plugin by its schema type" do
      create(:jira_field, jira_import:, origin_id: "customfield_10666",
                          payload: { "id" => "customfield_10666", "name" => "CF Plugin",
                                     "schema" => { "type" => "option", "customId" => 10666,
                                                   "custom" => "com.acme.plugin:fancy-picker" } })
      issue(key: "#{jira_project_key}-4", issuetype_id: "10100",
            fields: { "customfield_10666" => { "value" => "Red" } })
      allow(jira_client).to receive(:custom_field_options).and_return([option(10200, "Red")])

      fetch_custom_fields

      expect(jira_client).to have_received(:custom_field_options).with(10666, any_args).at_least(:once)
    end

    it "derives the custom field id from the field key when the schema carries none" do
      create(:jira_field, jira_import:, origin_id: "customfield_10777",
                          payload: { "id" => "customfield_10777", "name" => "CF No CustomId",
                                     "schema" => { "type" => "option" } })
      issue(key: "#{jira_project_key}-5", issuetype_id: "10100",
            fields: { "customfield_10777" => { "value" => "Red" } })
      allow(jira_client).to receive(:custom_field_options).and_return([option(10200, "Red")])

      fetch_custom_fields

      expect(jira_client).to have_received(:custom_field_options).with("10777", any_args).at_least(:once)
    end

    context "with a second project in the import run" do
      let(:second_project_id) { "10500" }
      let(:second_project_key) { "SEC" }

      before do
        jira_import.update!(projects: jira_import.projects +
                                      [{ "id" => second_project_id, "key" => second_project_key, "name" => "Second" }])
        second_project = create(:jira_project, jira_import:, origin_id: second_project_id,
                                               payload: { "id" => second_project_id, "key" => second_project_key })
        create(:jira_issue, jira_import:, jira_project: second_project,
                            payload: { "key" => "#{second_project_key}-1",
                                       "fields" => { "project" => { "id" => second_project_id,
                                                                    "key" => second_project_key },
                                                     "issuetype" => { "id" => "10100" },
                                                     "customfield_10264" => { "value" => "Red" } } })
      end

      it "merges an option set shared by both projects into one context group" do
        allow(jira_client).to receive(:custom_field_options).and_return([option(10200, "Red")])

        fetch_custom_fields

        expect(context_groups.size).to eq(1)
        expect(context_groups.first["projects"]).to contain_exactly(jira_project_key, second_project_key)
      end

      it "keeps a per-project option set in its own context group" do
        allow(jira_client).to receive(:custom_field_options)
          .with(10264, hash_including(project_ids: [jira_project_id])).and_return([option(10200, "Red")])
        allow(jira_client).to receive(:custom_field_options)
          .with(10264, hash_including(project_ids: [second_project_id])).and_return([option(10201, "Purple")])

        fetch_custom_fields

        expect(context_groups.map { |group| [group["projects"], group["allowedValues"].pluck("value")] })
          .to contain_exactly([[jira_project_key], ["Red"]], [[second_project_key], ["Purple"]])
      end
    end
  end

  context "when Jira has no custom field options endpoint (Jira DC < 9.3)" do
    let!(:task) { issue(key: "#{jira_project_key}-1", issuetype_id: "10100") }

    before do
      allow(jira_client).to receive(:custom_field_options)
        .and_raise(Import::JiraClient::UnsupportedEndpointError, "no such endpoint")
      allow(jira_client).to receive(:issue_editmeta).and_return(
        { "fields" => { "customfield_10264" => { "allowedValues" => [{ "id" => "1", "value" => "Red" }] } } }
      )
    end

    it "falls back to deriving the contexts from editmeta" do
      fetch_custom_fields

      expect(jira_client).to have_received(:issue_editmeta).with("#{jira_project_key}-1")
      expect(select_field.reload.payload["contextGroups"])
        .to eq([{ "projects" => [jira_project_key],
                  "issuetypes" => ["10100"],
                  "allowedValues" => [{ "id" => "1", "value" => "Red" }] }])
    end

    it "samples only one issue per project and issue type" do
      issue(key: "#{jira_project_key}-2", issuetype_id: "10100")

      fetch_custom_fields

      expect(jira_client).to have_received(:issue_editmeta).once
    end

    it "keeps going when editmeta fails for one of the sampled issues" do
      issue(key: "#{jira_project_key}-2", issuetype_id: "10200")
      allow(jira_client).to receive(:issue_editmeta).with("#{jira_project_key}-1")
        .and_raise(Import::JiraClient::ApiError.new("boom", status: 500))

      expect { fetch_custom_fields }.not_to raise_error
      expect(select_field.reload.payload["contextGroups"].pluck("issuetypes")).to eq([["10200"]])
    end

    it "ignores an editmeta field that reports no allowed values" do
      allow(jira_client).to receive(:issue_editmeta)
        .and_return({ "fields" => { "customfield_10264" => { "allowedValues" => [] } } })

      fetch_custom_fields

      expect(select_field.reload.payload).not_to have_key("contextGroups")
    end

    it "ignores editmeta fields the import does not track" do
      allow(jira_client).to receive(:issue_editmeta).and_return(
        { "fields" => { "customfield_19999" => { "allowedValues" => [{ "id" => "9", "value" => "Ghost" }] } } }
      )

      fetch_custom_fields

      expect(select_field.reload.payload).not_to have_key("contextGroups")
      expect(Import::JiraField.where(jira_import:, origin_id: "customfield_19999")).not_to exist
    end
  end
end
