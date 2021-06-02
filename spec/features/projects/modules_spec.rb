#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) 2012-2021 the OpenProject GmbH
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
# See docs/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe 'Projects module administration',
         type: :feature do

  let!(:project) do
    FactoryBot.create(:project,
                      enabled_module_names: [])
  end

  let(:role) do
    FactoryBot.create(:role,
                      permissions: permissions)
  end
  let(:permissions) { %i(edit_project select_project_modules) }
  let(:settings_page) { Pages::Projects::Settings.new(project) }

  current_user do
    FactoryBot.create(:user,
                      member_in_project: project,
                      member_with_permissions: permissions)
  end

  it 'allows adding and removing modules' do
    settings_page.visit_tab!('modules')

    expect(page)
      .to have_unchecked_field 'Activity'

    expect(page)
      .to have_unchecked_field 'Calendar'

    expect(page)
      .to have_unchecked_field 'Time and costs'

    check 'Activity'

    click_button 'Save'

    settings_page.expect_notification message: I18n.t(:notice_successful_update)

    expect(page)
      .to have_checked_field 'Activity'

    expect(page)
      .to have_unchecked_field 'Calendar'

    expect(page)
      .to have_unchecked_field 'Time and costs'

    check 'Calendar'

    click_button 'Save'

    expect(page)
      .to have_selector '.notification-box.-error',
                        text: I18n.t(:'activerecord.errors.models.project.attributes.enabled_modules.dependency_missing',
                                     dependency: 'Work package tracking',
                                     module: 'Calendar')

    check 'Work package tracking'

    click_button 'Save'

    settings_page.expect_notification message: I18n.t(:notice_successful_update)

    expect(page)
      .to have_checked_field 'Activity'

    expect(page)
      .to have_checked_field 'Calendar'

    expect(page)
      .to have_checked_field 'Work package tracking'
  end
end
