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

# The import only produces valid data with semantic identifiers enabled: Jira project keys are
# uppercase, which Projects::Identifier rejects in classic mode.
RSpec.describe Import::JiraCreateProjectJob,
               with_settings: { work_packages_identifier: Setting::WorkPackageIdentifier::SEMANTIC } do
  include_context "with jira project import data"

  describe "#perform" do
    it "creates the project in OpenProject" do
      expect { create_project }.to change(Project, :count).by(1)

      project = Project.find_by(identifier: jira_project_key)
      expect(project).to be_present
      expect(project.name).to eq(jira_project_name)
      expect(project.slugs.pluck(:slug).uniq.sort).to eq(jira_project_keys.sort)
    end

    it "creates a reference for the imported project" do
      create_project

      project = Project.find_by!(identifier: jira_project_key)
      expect(Import::JiraOpenProjectReference.find_by(op_entity_class: "Project", op_entity_id: project.id.to_s))
        .to have_attributes(jira_entity_class: "Import::JiraProject",
                            jira_entity_id: jira_project.id.to_s,
                            uses_existing: false)
    end

    context "when a project with the same identifier already exists" do
      let!(:existing_project) { create(:project, identifier: jira_project_key, name: "Existing Project") }

      it "raises an error with the taken identifier and existing project info" do
        expect { create_project }
          .to raise_error("You are trying to import a project with an already used identifier: #{jira_project_key}. " \
                          "Please update the project identifier in Jira then click on Retry.")
      end
    end

    context "when project creation fails with a general error" do
      before do
        # rubocop:disable RSpec/AnyInstance
        allow_any_instance_of(Projects::CreateService).to receive(:call).and_return(
          ServiceResult.failure(message: "Something went wrong during project creation")
        )
        # rubocop:enable RSpec/AnyInstance
      end

      it "raises the error message" do
        expect { create_project }.to raise_error("Something went wrong during project creation")
      end
    end

    # Custom fields are built by Import::JiraCreateProjectWorkPackagesJob, which needs the
    # registry anyway to convert values. Building them here as well duplicated every list and
    # hierarchy custom field, because those are never looked up by name.
    context "with a jira issue carrying a list custom field" do
      let!(:jira_field) do
        create(:jira_field, jira_import:,
                            origin_id: "customfield_10264",
                            payload: {
                              "id" => "customfield_10264",
                              "name" => "CF List",
                              "schema" => {
                                "type" => "option",
                                "custom" => "com.atlassian.jira.plugin.system.customfieldtypes:select",
                                "customId" => 10264
                              }
                            })
      end

      let!(:jira_issue) do
        create(:jira_issue, jira_import:,
                            origin_id: "10200",
                            jira_project:,
                            payload: { "key" => "#{jira_project_key}-1",
                                       "fields" => { "customfield_10264" => { "value" => "Option A" } } })
      end

      it "does not create any custom field" do
        expect { create_project }.not_to change(WorkPackageCustomField, :count)
      end
    end
  end
end
