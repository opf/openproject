#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2023 the OpenProject GmbH
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

require 'spec_helper'

describe DemoData::WorkPackageSeeder do
  shared_let(:work_week) { week_with_saturday_and_sunday_as_weekend }
  shared_let(:seeding) do
    [
      # Color records needed by StatusSeeder and TypeSeeder
      BasicData::ColorSeeder,
      BasicData::ColorSchemeSeeder,

      # Status records needed by WorkPackageSeeder
      StandardSeeder::BasicData::StatusSeeder,

      # Type records needed by WorkPackageSeeder
      StandardSeeder::BasicData::TypeSeeder,

      # IssuePriority records needed by WorkPackageSeeder
      StandardSeeder::BasicData::PrioritySeeder,

      # User admin needed by WorkPackageSeeder
      AdminUserSeeder
    ].each { |seeder| seeder.new.seed! }
  end
  let(:project) { create(:project) }
  let(:new_project_role) { Role.find_by(name: I18n.t(:default_role_project_admin)) }
  let(:closed_status) { Status.find_by(name: I18n.t(:default_status_closed)) }
  let(:work_packages_data) { [] }

  def work_package_data(**attributes)
    {
      start: 0,
      subject: "Some subject",
      status: "default_status_new",
      type: "default_type_task"
    }.merge(attributes)
  end

  before do
    work_package_seeder = described_class.new(project, "dummy-project")
    allow(work_package_seeder)
      .to receive(:project_data_for).with('dummy-project', 'work_packages')
          .and_return(work_packages_data)
    work_package_seeder.seed!
  end

  # available for debugging purposes, to see what real world data looks like
  def real_work_package_data
    seeder.send(:translate_with_base_url, "seeders.standard.demo_data.projects.demo-project.work_packages")
  end

  context 'with work package data with start: 0' do
    let(:work_packages_data) do
      [
        work_package_data(start: 0)
      ]
    end

    it 'start on the Monday of the current week' do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.start_date).to eq(current_week_monday)
    end
  end

  context 'with work package data with start: n' do
    let(:work_packages_data) do
      [
        work_package_data(start: 2),
        work_package_data(start: 42)
      ]
    end

    it 'will start n days after the Monday of the current week' do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.start_date).to eq(current_week_monday + 2.days)
      expect(WorkPackage.second.start_date).to eq(current_week_monday + 42.days)
    end
  end

  context 'with work package data with start: -n' do
    let(:work_packages_data) do
      [
        work_package_data(start: -3),
        work_package_data(start: -17)
      ]
    end

    it 'will start n days before the Monday of the current week' do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.start_date).to eq(current_week_monday - 3.days)
      expect(WorkPackage.second.start_date).to eq(current_week_monday - 17.days)
    end
  end

  context 'with work package data with duration' do
    let(:work_packages_data) do
      [
        work_package_data(start: 0, duration: 1), # from Monday to Saturday
        work_package_data(start: 0, duration: 6), # from Monday to Saturday
        work_package_data(start: 0, duration: 15) # from Monday to next next Monday
      ]
    end

    it 'will have finish date calculated being start + duration - 1' do
      current_week_monday = Date.current.monday
      expect(WorkPackage.first.due_date).to eq(current_week_monday)
      expect(WorkPackage.second.due_date).to eq(current_week_monday + 5.days)
      expect(WorkPackage.third.due_date).to eq(current_week_monday + 14.days)
    end
  end

  context 'with work package data without duration' do
    let(:work_packages_data) do
      [
        work_package_data(duration: nil)
      ]
    end

    it 'will have no duration' do
      expect(WorkPackage.first.duration).to be_nil
    end

    it 'will have no finish date' do
      expect(WorkPackage.first.due_date).to be_nil
    end
  end

  context 'when both start date and due date are on a working day' do
    let(:work_packages_data) do
      [
        work_package_data(start: 1, duration: 10) # from Tuesday to next Thursday
      ]
    end

    it 'will have ignore_non_working_day set to true' do
      expect(WorkPackage.first.ignore_non_working_days).to be(false)
    end

    it 'will have finish date calculated from duration based on real days' do
      work_package = WorkPackage.first
      expect(work_package.due_date).to eq(work_package.start_date + 9.days)
      expect(work_package.due_date.wday).to eq(4)
    end

    it 'will have duration adjusted to count only working days' do
      expect(WorkPackage.first.duration).to eq(8)
    end
  end

  context 'when either start date or finish date is on a non-working day' do
    let(:work_packages_data) do
      [
        work_package_data(start: -1, duration: 3), # start date non working: from Sunday to Tuesday
        work_package_data(start: 0, duration: 7) # finish date non working: from Monday to Sunday
      ]
    end

    it 'will have ignore_non_working_day set to true' do
      expect(WorkPackage.first.ignore_non_working_days).to be(true)
      expect(WorkPackage.second.ignore_non_working_days).to be(true)
    end

    it 'will have duration being the same as defined' do
      expect(WorkPackage.first.duration).to eq(3)
      expect(WorkPackage.second.duration).to eq(7)
    end
  end

  context 'with work package data with estimated_hours' do
    let(:work_packages_data) do
      [
        work_package_data(estimated_hours: 3)
      ]
    end

    it 'sets estimated_hours to the given value' do
      expect(WorkPackage.first.estimated_hours).to eq(3)
    end
  end

  context 'with work package data without estimated_hours' do
    let(:work_packages_data) do
      [
        work_package_data(estimated_hours: nil)
      ]
    end

    it 'does not set estimated_hours' do
      expect(WorkPackage.first.estimated_hours).to be_nil
    end
  end
end
