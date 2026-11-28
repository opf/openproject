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

RSpec.describe Import::JiraCreateProjectWorkPackagesJob,
               :webmock,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with jira project import data"

  let(:issue_payload) do
    JSON.parse(Rails.root.join("spec/fixtures/import/jira/issue_with_custom_fields.json").read)
  end

  let!(:jira_issue_type) do
    create(:jira_issue_type, jira_import:, origin_id: "10100", payload: { "id" => "10100", "name" => "Task" })
  end
  let!(:jira_status) do
    create(:jira_status, jira_import:, origin_id: "3", payload: { "id" => "3", "name" => "In Progress" })
  end
  let!(:jira_priority) do
    create(:jira_priority, jira_import:, origin_id: "1", payload: { "id" => "1", "name" => "Highest" })
  end
  let!(:jira_user) do
    create(:jira_user, jira_import:, origin_id: "JIRAUSER10000", payload: jira_user_payload)
  end
  let!(:op_user) { create(:user, login: "e.xample", mail: "e.xample@example.com") }
  let!(:jira_user_reference) do
    create(:jira_open_project_reference,
           jira_import:,
           jira_entity_class: "Import::JiraUser",
           jira_entity_id: jira_user.id.to_s,
           op_entity_class: "User",
           op_entity_id: op_user.id.to_s)
  end
  let!(:jira_field) do
    create(:jira_field, jira_import:,
                        origin_id: "customfield_10255",
                        payload: {
                          "id" => "customfield_10255",
                          "name" => "CF String",
                          "schema" => {
                            "type" => "string",
                            "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:textfield",
                            "customId" => 10255
                          }
                        })
  end
  let!(:jira_issue) do
    create(:jira_issue, jira_import:, origin_id: "10200", jira_project:, payload: issue_payload)
  end

  before do
    create_project_role
    create_project
  end

  def cf_value(cf_name)
    cf = WorkPackageCustomField.find_by!(name: cf_name)
    WorkPackage.find_by!(subject: "Issue with all custom field types").send(cf.attribute_getter)
  end

  context "when two issues of a type bring a field its form doesn't have yet" do
    let!(:another_jira_issue) do
      create(:jira_issue, jira_import:, origin_id: "10201", jira_project:,
                          payload: issue_payload.merge("key" => "DYX-3"))
    end

    it "updates the type's form only for the first issue" do
      allow(OpenProject::Mutex).to receive(:with_advisory_lock_transaction).and_call_original

      create_work_packages

      expect(OpenProject::Mutex).to have_received(:with_advisory_lock_transaction)
        .with(an_instance_of(FormConfiguration), WorkPackageTypes::FormConfiguration::LayoutLock::SUFFIX).once
    end
  end

  context "when another job adds the field to the type's form first" do
    def add_custom_field(name, type:)
      form = Type.find_by!(name: type).default_variant.form_configuration
      form.custom_field_ids |= [WorkPackageCustomField.find_by!(name:).id]
    end

    def form_groups_of(type)
      Type.find_by!(name: type).default_variant.attribute_groups.map { |group| [group.key, group.attributes] }
    end

    it "sets the issue's value and leaves the form unchanged" do
      groups_from_other_job = nil
      as_concurrent_job(FormConfiguration) do
        add_custom_field("CF String", type: "Task")
        groups_from_other_job = form_groups_of("Task")
      end

      with_query_cache { create_work_packages }

      expect(cf_value("CF String")).to eq("my plain string value")
      expect(form_groups_of("Task")).to eq(groups_from_other_job)
    end
  end
end
