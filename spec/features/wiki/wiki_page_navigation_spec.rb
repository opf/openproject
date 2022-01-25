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
# See COPYRIGHT and LICENSE files for more details.
#++

require 'spec_helper'

describe 'Wiki page navigation spec', type: :feature, js: true do
  shared_let(:admin) { create :admin }
  current_user { admin }

  let(:project) { create :project, enabled_module_names: %w[wiki] }
  let!(:wiki_page_55) do
    create :wiki_page_with_content,
                      wiki: project.wiki,
                      title: 'Wiki Page No. 55'
  end
  let!(:wiki_pages) do
    create_list(:wiki_page_with_content, 30, wiki: project.wiki)
  end

  # Always use the same user for the wiki pages
  # that otherwise gets created
  before do
    FactoryBot.set_factory_default(:author, admin)
  end

  it 'scrolls to the selected page on load (Regression #36937)' do
    visit project_wiki_path(project, wiki_page_55)

    expect(page).to have_selector('div.wiki-content')

    expect(page).to have_selector('.title-container h2', text: 'Wiki Page No. 55')

    # Expect scrolled to menu node
    expect_element_in_view page.find('.tree-menu--item.-selected', text: 'Wiki Page No. 55')
  end
end
