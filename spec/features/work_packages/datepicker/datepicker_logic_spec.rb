#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2022 the OpenProject GmbH
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
require 'support/edit_fields/edit_field'

describe 'Datepicker modal logic test cases (WP #43539)',
         with_settings: { date_format: '%Y-%m-%d' },
         with_flag: { work_packages_duration_field_active: true },
         js: true do
  shared_let(:user) { create :admin }

  shared_let(:type_bug) { create(:type_bug) }
  shared_let(:type_milestone) { create(:type_milestone) }
  shared_let(:project) { create(:project, types: [type_bug, type_milestone]) }

  shared_let(:bug_wp) { create :work_package, project:, type: type_bug, ignore_non_working_days: false }
  shared_let(:milestone_wp) { create :work_package, project:, type: type_milestone, ignore_non_working_days: false }

  # assume sat+sun are non working days
  shared_let(:weekdays) { create :week_days }

  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package, project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:date_field) { work_packages_page.edit_field(:combinedDate) }
  let(:datepicker) { date_field.datepicker }

  let(:work_package) { bug_wp }

  def apply_and_expect_saved(attributes)
    date_field.save!

    work_packages_page.expect_and_dismiss_toaster message: I18n.t('js.notice_successful_update')

    work_package.reload

    attributes.each do |attr, value|
      expect(work_package.send(attr)).to eq value
    end
  end

  before do
    work_package.update_columns(current_attributes)
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded

    date_field.activate!
    date_field.expect_active!
  end

  context 'when start_date set, update due_date (test case 1)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: nil,
        duration: nil
      }
    end

    it 'sets finish date to 19th if duration of 10 set' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      datepicker.set_duration 10

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-19')
    end
  end

  describe 'when no values set, update duration (test case 2)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: nil
      }
    end

    it 'sets only the duration' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration ''

      datepicker.set_duration 10

      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: nil,
                             due_date: nil
    end
  end

  describe 'when due date set, update duration (test case 3)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: Date.parse('2021-02-19'),
        duration: nil
      }
    end

    it 'sets the start date to 2021-02-08' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration ''

      datepicker.set_duration 10

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-19')
    end
  end

  describe 'when all values set, changing duration (test case 4)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-19'),
        duration: 10
      }
    end

    it 'sets the duration to 11 days' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      datepicker.set_duration 11

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-22'
      datepicker.expect_duration 11

      apply_and_expect_saved duration: 11,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-22')
    end
  end

  describe 'when all values set, reduce duration (test case 5)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-22'),
        duration: 11
      }
    end

    it 'sets the duration to 10' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-22'
      datepicker.expect_duration 11

      datepicker.set_duration 10

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-19'
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 10,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-19')
    end
  end

  describe 'when all values set and include NWD, reduce duration (test case 5a)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-22'),
        duration: 11,
        ignore_non_working_days: true
      }
    end

    it 'sets the duration to 10' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-22'
      datepicker.expect_duration 11

      datepicker.set_duration 10

      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-21'
      datepicker.expect_duration 10

      apply_and_expect_saved duration: 12,
                             start_date: Date.parse('2021-02-08'),
                             due_date: Date.parse('2021-02-21')
    end
  end

  describe 'when all values set, remove duration (test case 6)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-12'),
        duration: 3
      }
    end

    it 'also unsets the due date' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 3

      datepicker.clear_duration

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date ''
      datepicker.expect_duration nil
    end
  end

  describe 'when all values set, change start date (test case 7)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-08'),
        due_date: Date.parse('2021-02-11'),
        duration: 4
      }
    end

    it 'adjusts the duration' do
      datepicker.expect_start_date '2021-02-08'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 4

      datepicker.set_start_date '2021-02-09'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3
    end
  end

  describe 'when all values set, change due date (test case 8)' do
    let(:current_attributes) do
      {
        start_date: Date.parse('2021-02-09'),
        due_date: Date.parse('2021-02-12'),
        duration: 4
      }
    end

    it 'adjusts the duration' do
      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 4

      datepicker.set_due_date '2021-02-11'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-11'
      datepicker.expect_duration 3
    end
  end

  describe 'when only duration set, set finish date (test case 9)' do
    let(:current_attributes) do
      {
        start_date: nil,
        due_date: nil,
        duration: 4
      }
    end

    it 'derives the start date' do
      datepicker.expect_start_date ''
      datepicker.expect_due_date ''
      datepicker.expect_duration 4

      datepicker.set_due_date '2021-02-12'

      datepicker.expect_start_date '2021-02-09'
      datepicker.expect_due_date '2021-02-12'
      datepicker.expect_duration 4
    end
  end
end
