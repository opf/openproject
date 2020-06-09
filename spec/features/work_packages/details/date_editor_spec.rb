#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2020 the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2017 Jean-Philippe Lang
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require 'features/page_objects/notification'
require 'features/work_packages/details/inplace_editor/shared_examples'
require 'features/work_packages/shared_contexts'
require 'support/edit_fields/edit_field'
require 'features/work_packages/work_packages_page'

describe 'date inplace editor',
         with_settings: { date_format: '%Y-%m-%d' },
         js: true, selenium: true do
  let(:project) { FactoryBot.create :project_with_types, public: true }
  let(:work_package) { FactoryBot.create :work_package, project: project, start_date: '2016-01-01' }
  let(:user) { FactoryBot.create :admin }
  let(:work_packages_page) { Pages::FullWorkPackage.new(work_package,project) }
  let(:wp_table) { Pages::WorkPackagesTable.new(project) }

  let(:start_date) { work_packages_page.edit_field(:startDate) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it 'uses the start date as a placeholder for the end date' do
    start_date.activate!
    start_date.expect_active!

    start_date.datepicker.expect_year '2016'
    start_date.datepicker.expect_month 'January'
    start_date.datepicker.select_day '25'

    start_date.save!
    start_date.expect_inactive!
    start_date.expect_state_text '2016-01-25'
  end

  it 'saves the date when clearing and then confirming' do
    start_date.activate!

    sleep 1

    start_date.input_element.click
    start_date.clear with_backspace: true
    start_date.input_element.send_keys :backspace

    start_date.save!

    work_packages_page.expect_and_dismiss_notification message: 'Successful update.'

    start_date.expect_inactive!
    start_date.expect_state_text 'no start date'

    work_package.reload
    expect(work_package.start_date).to be_nil
  end

  it 'closes the date picker when moving away' do
    wp_table.visit!
    wp_table.open_full_screen_by_doubleclick work_package

    start_date.activate!
    start_date.expect_active!

    page.execute_script('window.history.back()')
    work_packages_page.accept_alert_dialog! if work_packages_page.has_alert_dialog?

    # Ensure no modal survives
    expect(page).to have_no_selector('.op-modal--modal-container')
  end

  context 'with a date custom field' do
    let!(:type) { FactoryBot.create :type }
    let!(:project) { FactoryBot.create :project, types: [type] }
    let!(:priority) { FactoryBot.create :default_priority }
    let!(:status) { FactoryBot.create :default_status }

    let!(:date_cf) do
      FactoryBot.create(
        :date_wp_custom_field,
        name: "My date",
        types: [type],
        projects: [project]
      )
    end

    let(:cf_field) { EditField.new page, :"customField#{date_cf.id}" }
    let(:datepicker) { ::Components::Datepicker.new }
    let(:create_page) { ::Pages::FullWorkPackageCreate.new(project: project) }

    it 'can handle creating a CF date' do
      create_page.visit!

      type_field = create_page.edit_field(:type)
      type_field.activate!
      type_field.set_value type.name

      cf_field.expect_active!

      # When cancelling, expect there to be no notification
      create_page.cancel!
      create_page.expect_no_notification type: nil

      create_page.visit!
      cf_field.expect_active!

      # Open date picker
      cf_field.input_element.click
      datepicker.set_date Date.today

      create_page.edit_field(:subject).set_value 'My subject!'
      create_page.save!
      create_page.expect_and_dismiss_notification message: 'Successful creation'

      wp = WorkPackage.last
      expect(wp.custom_value_for(date_cf.id).value).to eq Date.today.iso8601
    end
  end
end
