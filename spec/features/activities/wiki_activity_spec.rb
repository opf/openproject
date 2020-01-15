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

feature 'Wiki activities' do
  let(:user) do
    FactoryBot.create :user,
                      member_in_project: project,
                      member_with_permissions: %w[view_wiki_pages
                                                  edit_wiki_pages
                                                  view_wiki_edits]
  end
  let(:project) { FactoryBot.create :project, enabled_module_names: %w[wiki activity] }
  let(:wiki) { project.wiki }
  let(:editor) { Components::WysiwygEditor.new }

  before do
    login_as user
  end

  it 'tracks the wiki\'s activities', js: true do
    # create a wiki page
    visit project_wiki_path(project, 'mypage')

    fill_in 'content_page_title', with: 'My page'

    editor.set_markdown('First content')

    click_button 'Save'

    # alter the page
    click_link 'Edit'

    editor.set_markdown('Second content')

    click_button 'Save'

    # After creating and altering the page, there
    # will be two activities to see
    visit project_activity_index_path(project)

    check 'Wiki edits'

    click_button 'Apply'

    expect(page)
      .to have_link('Wiki edit: My page (#1)')

    expect(page)
      .to have_link('Wiki edit: My page (#2)')

    click_link('Wiki edit: My page (#2)')

    expect(page)
      .to have_current_path(project_wiki_path(project.id, 'My page', version: 2))

    # disable the wiki module

    project.enabled_module_names = %w[activity]
    project.save!

    # Go to activity page again to see that
    # there is no more option to see wiki edits.

    visit project_activity_index_path(project)

    expect(page)
      .to have_no_content('Wiki edits')
  end
end
