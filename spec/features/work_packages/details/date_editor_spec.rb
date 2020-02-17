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

  let(:due_date) { work_packages_page.edit_field(:dueDate) }
  let(:start_date) { work_packages_page.edit_field(:startDate) }

  before do
    login_as(user)

    work_packages_page.visit!
    work_packages_page.ensure_page_loaded
  end

  it 'uses the start date as a placeholder for the end date' do
    due_date.activate!

    within('.ui-datepicker') do
      expect(page).to have_selector('.ui-datepicker-month option', text: 'Jan')
      expect(page).to have_selector('.ui-datepicker-year option', text: '2016')
      day = find('td a', text: '25')
      scroll_to_and_click(day)
    end

    due_date.expect_inactive!
    due_date.expect_state_text '2016-01-25'
  end

  it 'saves the date when clearing and then confirming' do
    start_date.activate!

    sleep 1

    start_date.input_element.click
    start_date.clear with_backspace: true
    start_date.input_element.send_keys :backspace

    within('.ui-datepicker') do
      find('button', text: 'Confirm').click
    end

    work_packages_page.expect_and_dismiss_notification message: 'Successful update.'

    start_date.expect_inactive!
    start_date.expect_state_text 'no start date'

    work_package.reload
    expect(work_package.start_date).to be_nil
  end
end
