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

RSpec.describe DemoData::ProjectSeeder do
  include_context "with basic seed data"

  subject(:project_seeder) { described_class.new(seed_data.lookup("projects.my-project")) }

  let(:seed_data) do
    basic_seed_data.merge(Source::SeedData.new(
                            "projects" => {
                              "my-project" => project_data
                            }
                          ))
  end
  let(:project_data) { project_data_with_a_version }
  let(:project_data_with_a_version) do
    {
      "name" => "Some project",
      "versions" => [
        {
          "name" => "The product backlog",
          "reference" => :product_backlog,
          "sharing" => "none",
          "status" => "open"
        }
      ]
    }
  end

  it "stores references to created versions in the seed data" do
    project_seeder.seed!
    created_version = Version.find_by(name: "The product backlog")
    expect(seed_data.find_reference(:product_backlog)).to eq(created_version)
  end

  context "for a version with a wiki" do
    before do
      project_data.update(
        "modules" => %w[work_package_tracking wiki],
        "wiki" => "root wiki page content",
        "versions" => [
          {
            "name" => "First sprint",
            "reference" => :first_sprint,
            "sharing" => "none",
            "status" => "open",
            "wiki" => {
              "title" => "Sprint 1",
              "content" => "Please see the [Task board](##sprint:first_sprint)."
            }
          }
        ]
      )
    end

    it "can self-reference the version link in the wiki" do
      project_seeder.seed!
      created_version = Version.find_by!(name: "First sprint")
      expect(created_version.wiki_page.text)
        .to eq("Please see the [Task board](/projects/some-project/sprints/#{created_version.id}/taskboard).")
    end
  end

  context "with work packages linking to a version by its reference" do
    let(:project_data) do
      project_data_with_a_version.merge(
        "work_packages" => [
          {
            "subject" => "Some work package",
            "status" => :default_status_new,
            "type" => :default_type_task,
            "version" => :product_backlog
          }
        ]
      )
    end

    it "creates the link" do
      project_seeder.seed!
      version = Version.find_by!(name: "The product backlog")
      work_package = WorkPackage.find_by!(subject: "Some work package")
      expect(work_package.version).to eq(version)
    end
  end

  context "with query linking to a version by its reference" do
    let(:project_data) do
      project_data_with_a_version.merge(
        "queries" => [
          {
            "name" => "Product Backlog query",
            "status" => "open",
            "version" => :product_backlog
          }
        ]
      )
    end

    it "creates the appropriate version filter" do
      project_seeder.seed!
      version = Version.find_by(name: "The product backlog")
      query = Query.find_by(name: "Product Backlog query")
      expect(query.filters)
        .to include(a_filter(Queries::WorkPackages::Filter::VersionFilter, values: [version.id.to_s]))
    end
  end

  context "with query linking to an assignee by its reference" do
    let(:project_data) do
      {
        "name" => "Some project",
        "queries" => [
          {
            "name" => "Team planner",
            "assigned_to" => :openproject_admin
          }
        ]
      }
    end

    it "creates the appropriate assigned_to filter" do
      project_seeder.seed!
      user = User.admin.last
      query = Query.find_by(name: "Team planner")
      expect(query.filters)
        .to include(a_filter(Queries::WorkPackages::Filter::AssignedToFilter, values: [user.id.to_s]))
    end
  end

  context "with query linking to a type by its reference" do
    let(:project_data) do
      YAML.load <<~PROJECT_SEEDING_DATA_YAML
        name: Some project
        types:
          - :default_type_task
          - :default_type_milestone
          - :default_type_phase
        queries:
          - name: Project plan
            type:
              - :default_type_milestone
              - :default_type_phase
          - name: Milestones
            type: :default_type_milestone
      PROJECT_SEEDING_DATA_YAML
    end

    it "creates the appropriate type filter" do
      project_seeder.seed!
      query = Query.find_by(name: "Milestones")
      milestone_type = seed_data.find_reference(:default_type_milestone)
      expect(query.filters)
        .to include(a_filter(Queries::WorkPackages::Filter::TypeFilter, values: [milestone_type.id.to_s]))
    end

    it "accepts an array of types" do
      project_seeder.seed!
      query = Query.find_by(name: "Project plan")
      milestone_type = seed_data.find_reference(:default_type_milestone)
      phase_type = seed_data.find_reference(:default_type_phase)
      expect(query.filters)
        .to include(a_filter(Queries::WorkPackages::Filter::TypeFilter,
                             values: contain_exactly(milestone_type.id.to_s, phase_type.id.to_s)))
    end
  end

  def a_filter(filter_class, attributes)
    an_instance_of(filter_class).and having_attributes(attributes)
  end
end
