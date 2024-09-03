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

RSpec.describe DemoData::WorkPackageSeeder do
  include_context "with basic seed data"

  shared_let(:work_week) { week_with_saturday_and_sunday_as_weekend }

  let(:project) { create(:project) }
  let(:new_project_role) { seed_data.find_reference(:default_role_project_admin) }
  let(:closed_status) { seed_data.find_reference(:default_status_closed) }
  let(:work_packages_data) { [] }
  let(:seed_data) { basic_seed_data.merge(Source::SeedData.new("work_packages" => work_packages_data)) }

  def work_package_data(**attributes)
    {
      start: 0,
      subject: "Some subject",
      status: :default_status_new,
      type: :default_type_task
    }.merge(attributes).deep_stringify_keys
  end

  before do
    work_package_seeder = described_class.new(project, seed_data)
    work_package_seeder.seed!
  end

  context "with work package data with start: 0" do
    let(:work_packages_data) do
      [
        work_package_data(start: 0)
      ]
    end

    it "start on the Monday of the current week" do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.start_date).to eq(current_week_monday)
    end
  end

  context "with work package data with start: n" do
    let(:work_packages_data) do
      [
        work_package_data(start: 2),
        work_package_data(start: 42)
      ]
    end

    it "starts n days after the Monday of the current week" do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.start_date).to eq(current_week_monday + 2.days)
      expect(WorkPackage.second.start_date).to eq(current_week_monday + 42.days)
    end
  end

  context "with work package data with start: -n" do
    let(:work_packages_data) do
      [
        work_package_data(start: -3),
        work_package_data(start: -17)
      ]
    end

    it "starts n days before the Monday of the current week" do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.start_date).to eq(current_week_monday - 3.days)
      expect(WorkPackage.second.start_date).to eq(current_week_monday - 17.days)
    end
  end

  context "with work package data with duration" do
    let(:work_packages_data) do
      [
        work_package_data(start: 0, duration: 1), # from Monday to Saturday
        work_package_data(start: 0, duration: 6), # from Monday to Saturday
        work_package_data(start: 0, duration: 15) # from Monday to next next Monday
      ]
    end

    it "has finish date calculated being start + duration - 1" do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.due_date).to eq(current_week_monday)
      expect(WorkPackage.second.due_date).to eq(current_week_monday + 5.days)
      expect(WorkPackage.third.due_date).to eq(current_week_monday + 14.days)
    end
  end

  context "with work package data without duration" do
    let(:work_packages_data) do
      [
        work_package_data(duration: nil)
      ]
    end

    it "has no duration" do
      expect(WorkPackage.first.duration).to be_nil
    end

    it "has no finish date" do
      expect(WorkPackage.first.due_date).to be_nil
    end
  end

  context "when both start date and due date are on a working day" do
    let(:work_packages_data) do
      [
        work_package_data(start: 1, duration: 10) # from Tuesday to next Thursday
      ]
    end

    it "has ignore_non_working_day set to true" do
      expect(WorkPackage.first.ignore_non_working_days).to be(false)
    end

    it "has finish date calculated from duration based on real days" do
      work_package = WorkPackage.first
      expect(work_package.due_date).to eq(work_package.start_date + 9.days)
      expect(work_package.due_date.wday).to eq(4)
    end

    it "has duration adjusted to count only working days" do
      expect(WorkPackage.first.duration).to eq(8)
    end
  end

  context "when either start date or finish date is on a non-working day" do
    let(:work_packages_data) do
      [
        work_package_data(start: -1, duration: 3), # start date non working: from Sunday to Tuesday
        work_package_data(start: 0, duration: 7) # finish date non working: from Monday to Sunday
      ]
    end

    it "has ignore_non_working_day set to true" do
      expect(WorkPackage.first.ignore_non_working_days).to be(true)
      expect(WorkPackage.second.ignore_non_working_days).to be(true)
    end

    it "has duration being the same as defined" do
      expect(WorkPackage.first.duration).to eq(3)
      expect(WorkPackage.second.duration).to eq(7)
    end
  end

  context "with work package data with estimated_hours" do
    let(:work_packages_data) do
      [
        work_package_data(estimated_hours: 3)
      ]
    end

    it "sets estimated_hours to the given value" do
      expect(WorkPackage.first.estimated_hours).to eq(3)
    end
  end

  context "with work package data without estimated_hours" do
    let(:work_packages_data) do
      [
        work_package_data(estimated_hours: nil)
      ]
    end

    it "does not set estimated_hours" do
      expect(WorkPackage.first.estimated_hours).to be_nil
    end
  end

  context "with a parent relation by reference" do
    let(:work_packages_data) do
      [
        work_package_data(subject: "Parent", reference: :wp_parent),
        work_package_data(subject: "Child", parent: :wp_parent)
      ]
    end

    it "creates a parent-child relation between work packages" do
      expect(WorkPackage.count).to eq(2)
      expect(WorkPackage.second.parent).to eq(WorkPackage.first)
    end
  end

  context "with a parent relation by reference inside a nested children property" do
    let(:work_packages_data) do
      [
        work_package_data(subject: "Grand-parent",
                          children: [
                            work_package_data(subject: "Parent", reference: :this_one)
                          ]),
        work_package_data(subject: "Child", parent: :this_one)
      ]
    end

    it "creates parent-child relations between work packages" do
      expect(WorkPackage.find_by(subject: "Child").parent).to eq(WorkPackage.find_by(subject: "Parent"))
      expect(WorkPackage.find_by(subject: "Parent").parent).to eq(WorkPackage.find_by(subject: "Grand-parent"))
    end
  end

  context "with a parent relation by reference inside a nested children property with a bcf uuid" do
    let(:bcf_work_package) { create(:work_package, project:) }
    let(:bcf_issue) { create(:bcf_issue, work_package: bcf_work_package, uuid: "fbbf9ecf-5721-4bf1-a08c-aed50dc19353") }
    let(:work_packages_data) do
      [
        work_package_data(subject: "Grand-parent",
                          children: [
                            work_package_data(subject: "Parent", reference: :this_one)
                          ]),
        work_package_data(bcf_issue_uuid: bcf_issue.uuid, parent: :this_one)
      ]
    end

    it "creates parent-child relations between work packages" do
      expect(bcf_work_package.reload.parent).to eq(WorkPackage.find_by(subject: "Parent"))
      expect(WorkPackage.find_by(subject: "Parent").parent).to eq(WorkPackage.find_by(subject: "Grand-parent"))
    end
  end

  context "with a work package description referencing a work package with ##wp:ref notation" do
    let(:work_packages_data) do
      [
        work_package_data(subject: "Major thing to do",
                          reference: :major_thing),
        work_package_data(subject: "Other thing",
                          description: "Check [this work package](##wp:major_thing) of id ##wp.id:major_thing.")
      ]
    end

    it "creates parent-child relations between work packages" do
      wp_major, wp_other = WorkPackage.order(:id).to_a
      expect(wp_other.description)
        .to eq("Check [this work package](/projects/#{project.identifier}/" \
               "work_packages/#{wp_major.id}/activity) of id #{wp_major.id}.")
    end
  end

  context "with a work package description referencing a query with ##query:ref notation" do
    let(:seed_data) do
      seed_data = basic_seed_data.merge(Source::SeedData.new("work_packages" => work_packages_data))
      seed_data.store_reference(:q_project_plan, query)
      seed_data
    end
    let(:query) { create(:query, project:) }
    let(:work_packages_data) do
      [
        work_package_data(subject: "Referencing query",
                          description: "The [query](##query:q_project_plan) of id ##query.id:q_project_plan.")
      ]
    end

    it "creates link to the query with the right id" do
      expect(WorkPackage.last.description)
        .to eq("The [query](/projects/#{project.identifier}/work_packages?query_id=#{query.id}) of id #{query.id}.")
    end
  end

  context "with a work package description referencing a sprint with ##sprint:ref notation" do
    let(:seed_data) do
      seed_data = basic_seed_data.merge(Source::SeedData.new("work_packages" => work_packages_data))
      seed_data.store_reference(:sprint_backlog, sprint)
      seed_data
    end
    let(:sprint) { create(:sprint, project:) }
    let(:work_packages_data) do
      [
        work_package_data(subject: "Referencing sprint",
                          description: "The [sprint](##sprint:sprint_backlog) of id ##sprint.id:sprint_backlog.")
      ]
    end

    it "creates link to the sprint with the right id" do
      expect(WorkPackage.last.description)
        .to eq("The [sprint](/projects/#{project.identifier}/sprints/#{sprint.id}/taskboard) of id #{sprint.id}.")
    end
  end

  describe "assigned_to" do
    let(:seed_data) do
      seed_data = basic_seed_data.merge(Source::SeedData.new("work_packages" => work_packages_data))
      seed_data.store_reference(:user_bernard, a_user)
      seed_data
    end
    let(:a_user) { create(:user, lastname: "Bernard") }
    let(:work_packages_data) do
      [
        work_package_data(subject: "without assigned_to"),
        work_package_data(subject: "with assigned_to", assigned_to: :user_bernard)
      ]
    end

    it "assigns work packages without assigned_to to the admin user" do
      work_package = WorkPackage.find_by(subject: "without assigned_to")
      expect(work_package.assigned_to).to eq(User.user.admin.last)
    end

    it "assigns work packages with assigned_to referencing the user" do
      work_package = WorkPackage.find_by(subject: "with assigned_to")
      expect(work_package.assigned_to).to eq(a_user)
    end

    context "with a BCF work package data" do
      let(:bcf_work_package_without_assigned_to) { create(:work_package, project:) }
      let(:bcf_issue_without_assigned_to) do
        create(:bcf_issue, work_package: bcf_work_package_without_assigned_to, uuid: "aaaaaaaa-5721-4bf1-a08c-aed50dc19353")
      end
      let(:bcf_work_package_with_assigned_to) { create(:work_package, project:) }
      let(:bcf_issue_with_assigned_to) do
        create(:bcf_issue, work_package: bcf_work_package_with_assigned_to, uuid: "bbbbbbbb-5721-4bf1-a08c-aed50dc19353")
      end
      let(:work_packages_data) do
        [
          work_package_data(bcf_issue_uuid: bcf_issue_without_assigned_to.uuid),
          work_package_data(bcf_issue_uuid: bcf_issue_with_assigned_to.uuid, assigned_to: :user_bernard)
        ]
      end

      it "assigns work packages without assigned_to to the admin user" do
        expect(bcf_work_package_without_assigned_to.reload.assigned_to)
          .to eq(User.user.admin.last)
      end

      it "assigns work packages with assigned_to referencing the user lastname" do
        expect(bcf_work_package_with_assigned_to.reload.assigned_to)
          .to eq(a_user)
      end
    end
  end
end
