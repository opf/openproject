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

RSpec.describe ResourceManagement::DevelopmentData::ResourcePlannerSeeder do
  include_context "with basic seed data"

  shared_let(:admin) { create(:admin) }
  shared_let(:project) { create(:project, enabled_module_names: %w[work_package_tracking]) }
  shared_let(:monday) { Date.new(2026, 6, 1).beginning_of_week }

  shared_let(:wanda) { create(:user) }
  shared_let(:olga) { create(:user) }
  shared_let(:adam) { create(:user) }

  shared_let(:setup_website) { create(:work_package, project:, start_date: monday, due_date: monday + 11) }
  shared_let(:set_date) { create(:work_package, project:, start_date: monday, due_date: monday + 3) }
  shared_let(:invite_attendees) { create(:work_package, project:, start_date: monday + 4, due_date: monday + 4) }
  shared_let(:follow_up) { create(:work_package, project:, start_date: monday + 21, due_date: monday + 30) }
  shared_let(:upload) { create(:work_package, project:, start_date: monday + 21, due_date: monday + 30) }

  shared_let(:job_title) do
    create(:user_custom_field, :list, name: "Job title", semantic_key: "job_title",
                                      possible_values: ["Software Developer", "Marketing Manager"])
  end

  let(:planner_config) do
    {
      "name" => "Team allocations",
      "work_package_list" => { "name" => "Work packages" },
      "work_package_timeline" => { "name" => "Work package timeline" },
      "user_card" => { "name" => "Team members" },
      "user_timeline" => { "name" => "Team timeline" },
      "generic_allocation" => { "filter_name" => "Software Developer" }
    }
  end
  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new("resource_planner" => planner_config)) }
  let(:seeder) { described_class.new(project, seed_data) }

  before do
    # Working hours are required for Wanda so the overbooking can be computed.
    UserWorkingHours.create!(
      user: wanda, valid_from: Date.new(2026, 1, 1),
      monday: 480, tuesday: 480, wednesday: 480, thursday: 480, friday: 480,
      saturday: 0, sunday: 0, availability_factor: 100
    )

    {
      setup_conference_website: setup_website,
      set_date_and_location_of_conference: set_date,
      invite_attendees_to_conference: invite_attendees,
      follow_up_tasks: follow_up,
      upload_presentations_to_website: upload,
      user__wanda_web: wanda,
      user__olga_ops: olga,
      user__adam_admin: adam
    }.each { |reference, record| seed_data.store_reference(reference, record) }

    seeder.seed!
  end

  it "does not run without resource_planner seed data" do
    other_seeder = described_class.new(project, basic_seed_data)
    expect(other_seeder.applicable?).to be(false)
  end

  describe "the planner and its views" do
    let(:planner) { ResourcePlanner.last }

    it "creates a single planner with the configured name" do
      expect(ResourcePlanner.count).to eq(1)
      expect(planner.name).to eq("Team allocations")
      expect(planner.project).to eq(project)
    end

    it "creates one of each of the four views" do
      expect(planner.children.map { |view| view.class.name }).to contain_exactly(
        "ResourceWorkPackageList",
        "ResourceWorkPackageTimeline",
        "ResourceUserCard",
        "ResourceUserTimeline"
      )
    end

    it "uses the work package list as the default view" do
      list = ResourceWorkPackageList.last
      expect(planner.default_view_id).to eq(list.id)
    end

    it "enables the resource_management module on the project" do
      expect(project.reload.enabled_module_names).to include("resource_management")
    end
  end

  describe "the allocations" do
    it "creates explicit allocations for concrete users" do
      expect(ResourceAllocation.where(principal: olga, entity: set_date)).to exist
      expect(ResourceAllocation.where(principal: adam, entity: follow_up)).to exist
    end

    it "creates a filter-based allocation without a concrete user" do
      generic = ResourceAllocation.find_by(principal_explicit: false)

      expect(generic).to have_attributes(
        principal: nil,
        entity: upload,
        filter_name: "Software Developer"
      )
      expect(generic.user_filter).to be_present
    end

    it "overbooks Wanda through two overlapping full allocations" do
      wanda_allocations = ResourceAllocation.where(principal: wanda)

      expect(wanda_allocations.count).to eq(2)
      expect(ResourceAllocation.overbooked_ids(wanda_allocations)).not_to be_empty
    end
  end
end
