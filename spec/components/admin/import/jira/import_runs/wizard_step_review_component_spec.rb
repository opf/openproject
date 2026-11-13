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

require "rails_helper"

RSpec.describe Admin::Import::Jira::ImportRuns::WizardStepReviewComponent, type: :component do
  subject(:stats) { component.imported_stats }

  let(:component) { described_class.new(jira_import) }
  let(:jira) { create(:jira) }
  let(:jira_import) { create(:jira_import, jira:, author: create(:user)) }

  before { allow(component).to receive(:helpers).and_return(vc_test_controller.view_context) }

  def reference_for(op_entity_class, op_entity_id, uses_existing: false, import: jira_import)
    create(:jira_open_project_reference, jira_import: import, op_entity_class:, op_entity_id:, uses_existing:)
  end

  def labels_and_values
    stats.pluck(:label, :value)
  end

  it "returns no entries when nothing was imported" do
    expect(stats).to be_empty
  end

  it "lists the entries in a fixed order with label and subtitle" do
    reference_for("Status", 1)
    reference_for("User", 1)
    reference_for("Sprint", 1)
    reference_for("Version", 1)
    reference_for("WorkPackage", 1)
    reference_for("Project", 1)

    expect(stats.pluck(:label)).to eq(["Projects", "Work packages", "Versions", "Sprints", "Users & groups", "Other settings"])
    expect(stats.first).to include(subtitle: "Selected as scope")
  end

  it "counts users and groups together" do
    reference_for("User", 1)
    reference_for("User", 2)
    reference_for("Group", 1)

    expect(labels_and_values).to eq([["Users & groups", 3]])
  end

  it "counts types, statuses, priorities and custom fields as other settings" do
    %w[Type Status IssuePriority WorkPackageCustomField].each { reference_for(it, 1) }

    expect(labels_and_values).to eq([["Other settings", 4]])
  end

  it "counts the imported versions and sprints" do
    reference_for("Version", 1)
    reference_for("Sprint", 1)
    reference_for("Sprint", 2)

    expect(labels_and_values).to eq([["Versions", 1], ["Sprints", 2]])
  end

  it "leaves out records the import did not create" do
    %w[Project WorkPackage Version Sprint User Status].each { reference_for(it, 1, uses_existing: true) }

    expect(stats).to be_empty
  end

  it "leaves out records of another import" do
    other_import = create(:jira_import, jira:, author: jira_import.author)
    %w[Project WorkPackage Version Sprint User Status].each { reference_for(it, 1, import: other_import) }

    expect(stats).to be_empty
  end

  describe "links" do
    it "links a single project to the project" do
      reference_for("Project", 7)

      expect(stats.first).to include(label: "Projects", value: 1, url: "/projects/7")
    end

    it "links several projects to the project list filtered by them" do
      reference_for("Project", 7)
      reference_for("Project", 8)

      url = stats.first[:url]
      expect(url).to start_with("/projects?")
      filter = JSON.parse(Rack::Utils.parse_query(URI(url).query)["filters"]).sole["id"]
      expect(filter).to include("operator" => "=", "values" => contain_exactly("7", "8"))
    end

    it "links a single work package to the work package" do
      reference_for("WorkPackage", 42)

      expect(stats.first).to include(label: "Work packages", value: 1, url: "/work_packages/42")
    end

    it "links several work packages to the work package list of the imported projects" do
      reference_for("Project", 7)
      reference_for("WorkPackage", 42)
      reference_for("WorkPackage", 43)

      url = stats.second[:url]
      expect(url).to start_with("/work_packages?")
      expect(JSON.parse(Rack::Utils.parse_query(URI(url).query)["query_props"]))
        .to eq({ "f" => [{ "n" => "project", "o" => "=", "v" => %w[7] }] })
    end

    it "does not link the other entries" do
      reference_for("Version", 1)
      reference_for("Sprint", 1)
      reference_for("User", 1)
      reference_for("Status", 1)

      expect(stats.pluck(:url)).to all(be_nil)
    end
  end
end
