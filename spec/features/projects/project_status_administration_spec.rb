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

describe 'Projects status administration', type: :feature, js: true do
  let(:current_user) do
    FactoryBot.create(:user).tap do |user|
      FactoryBot.create(:principal_role,
                        principal: user,
                        role: FactoryBot.create(:global_role, permissions: global_permissions))
    end
  end
  let(:global_permissions) { [:add_project] }
  let(:project_permissions) { [:edit_project] }
  let!(:project_role) do
    FactoryBot.create(:role, permissions: project_permissions).tap do |r|
      allow(Setting)
        .to receive(:new_project_user_role_id)
        .and_return(r.id.to_s)
    end
  end
  let(:create_status_description) { Components::WysiwygEditor.new('.form--field:nth-of-type(5)') }
  let(:edit_status_description) { Components::WysiwygEditor.new('.form--field:nth-of-type(6)') }

  before do
    login_as current_user
  end

  it 'allows setting the status on project creation' do
    visit new_project_path

    # Create the project with status
    click_link 'Advanced settings'

    fill_in 'Name', with: 'New project'
    select 'On track', from: 'Status'
    create_status_description.set_markdown 'Everything is fine at the start'
    create_status_description.expect_supports_no_macros

    click_button 'Create'

    expect(page)
      .to have_content('Successful creation.')

    # Check that the status has been set correctly
    visit settings_generic_project_path(Project.last)

    expect(page)
      .to have_select('Status', selected: 'On track')

    edit_status_description.expect_value 'Everything is fine at the start'

    select '', from: 'Status'
    edit_status_description.set_markdown 'Now we do not know'

    click_button 'Save'

    expect(page)
      .to have_select('Status', selected: '')

    edit_status_description.expect_value 'Now we do not know'

    select 'Off track', from: 'Status'
    edit_status_description.set_markdown 'Oh no'

    click_button 'Save'

    expect(page)
      .to have_select('Status', selected: 'Off track')

    edit_status_description.expect_value 'Oh no'
  end
end
