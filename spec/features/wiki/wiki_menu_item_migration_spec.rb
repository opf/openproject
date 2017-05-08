#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2017 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'
require Rails.root.join('db/migrate/20160803094931_wiki_menu_titles_to_slug.rb')

describe 'Wiki menu_items migration', type: :feature do
  let(:project) { FactoryGirl.create :project }
  let(:wiki_page) {
    FactoryGirl.create :wiki_page_with_content,
                       wiki: project.wiki,
                       title: 'Base de donées'
  }
  let!(:menu_item) {
    FactoryGirl.create(:wiki_menu_item,
                       :with_menu_item_options,
                       wiki: project.wiki,
                       name: 'My linked page',
                       title: wiki_page.title)
  }

  before do
    project.wiki.pages << wiki_page

    # Run the title replacement of the migration
    ::WikiMenuTitlesToSlug.new.migrate_menu_items

    menu_item.reload
  end

  it 'updates the menu item' do
    expect(menu_item.name).to eq(wiki_page.slug)
    expect(menu_item.title).to eq('My linked page')
  end


  describe 'visiting the wiki' do
    let(:user) { FactoryGirl.create :admin }

    before do
      login_as(user)
    end

    it 'shows the menu item' do
      visit project_wiki_path(project, project.wiki)
      link = page.find('#menu-sidebar a.wiki-menu--main-item', text: menu_item.title)
      link.click

      expect(page).to have_selector('.title-container h2', text: wiki_page.title)
      expect(current_path).to eq(project_wiki_path(project, wiki_page.slug))
    end
  end
end
