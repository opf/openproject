#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2018 the OpenProject Foundation (OPF)
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

describe 'wiki pages', type: :feature, js: true do
  let(:project) do
    FactoryBot.create(:project, enabled_module_names: [:news])
  end
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_through_role: role
  end
  let(:role) do
    FactoryBot.create(:role,
                      permissions: %i[view_wiki_pages
                                      edit_wiki_pages
                                      view_wiki_edits
                                      select_project_modules
                                      edit_project])
  end
  let(:content_first_version) do
    'The new content, first version'
  end
  let(:content_second_version) do
    'The new content, second version'
  end

  before do
    login_as user
  end

  scenario 'adding, editing and history' do
    visit settings_project_path(project, tab: 'modules')

    expect(page).to have_no_selector('.menu-sidebar .main-item-wrapper', text: 'Wiki')

    within '#content' do
      check 'Wiki'

      click_button 'Save'
    end

    expect(page).to have_selector('#menu-sidebar .main-item-wrapper', text: 'Wiki')

    # creating by accessing the page
    visit project_wiki_path(project, 'new page')

    find('.ck-content').set(content_first_version)

    click_button 'Save'

    expect(page).to have_selector('.title-container', text: 'New page')
    expect(page).to have_selector('.wiki-content', text: content_first_version)

    within '.toolbar-items' do
      click_on "Edit"
    end

    find('.ck-content').set(content_second_version)

    click_button 'Save'
    expect(page).to have_selector('.wiki-content', text: content_second_version)

    within '.toolbar-items' do
      click_on 'More'
      click_on 'History'
    end

    click_on 'View differences'

    within '.text-diff' do
      expect(page).to have_selector('ins.diffmod', text: 'second')
      expect(page).to have_selector('del.diffmod', text: 'first')
    end
  end
end
