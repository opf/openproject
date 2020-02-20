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

describe WikiPage, type: :model do
  let(:project) { FactoryBot.create(:project).reload } # a wiki is created for project, but the object doesn't know of it (FIXME?)
  let(:wiki) { project.wiki }
  let(:wiki_page) { FactoryBot.create(:wiki_page, wiki: wiki, title: wiki.wiki_menu_items.first.title) }

  it_behaves_like 'acts_as_watchable included' do
    let(:model_instance) { FactoryBot.create(:wiki_page) }
    let(:watch_permission) { :view_wiki_pages }
    let(:project) { model_instance.project }
  end

  it_behaves_like 'acts_as_attachable included' do
    let(:model_instance) { FactoryBot.create(:wiki_page_with_content) }
    let(:project) { model_instance.project }
  end

  describe '#create' do
    context 'when another project with same title exists' do
      let(:project2) { FactoryBot.create(:project) }
      let(:wiki2) { project2.wiki }
      let!(:wiki_page1) { FactoryBot.create(:wiki_page, wiki: wiki, title: 'asdf') }
      let!(:wiki_page2) { FactoryBot.create(:wiki_page, wiki: wiki2, title: 'asdf') }

      it 'scopes the slug correctly' do
        pages = WikiPage.where(title: 'asdf')
        expect(pages.count).to eq(2)
        expect(pages.first.slug).to eq('asdf')
        expect(pages.last.slug).to eq('asdf')
      end
    end
  end

  describe '#nearest_main_item' do
    let(:child_page) { FactoryBot.create(:wiki_page, parent: wiki_page, wiki: wiki) }
    let!(:child_page_wiki_menu_item) { FactoryBot.create(:wiki_menu_item, wiki: wiki, name: child_page.slug, parent: wiki_page.menu_item) }
    let(:grand_child_page) { FactoryBot.create(:wiki_page, parent: child_page, wiki: wiki) }
    let!(:grand_child_page_wiki_menu_item) { FactoryBot.create(:wiki_menu_item, wiki: wiki, name: grand_child_page.slug) }

    it 'returns the menu item of the grand parent if the menu item of its parent is not a main item' do
      expect(grand_child_page.nearest_main_item).to eq(wiki_page.menu_item)
    end
  end

  describe '#destroy' do
    context 'when the only wiki page is destroyed' do
      before :each do
        wiki_page.destroy
      end

      it 'ensures there is still a wiki menu item' do
        expect(wiki.wiki_menu_items).to be_one
        expect(wiki.wiki_menu_items.first.is_main_item?).to be_truthy
      end
    end

    context 'when one of two wiki pages is destroyed' do
      before :each do
        FactoryBot.create(:wiki_page, wiki: wiki)
        wiki_page.destroy
      end

      it 'ensures that there is still a wiki menu item named like the wiki start page' do
        expect(wiki.wiki_menu_items).to be_one
        expect(wiki.wiki_menu_items.first.name).to eq(wiki.start_page.to_url)
      end
    end
  end

  describe '#project' do
    it 'is the same as the project on wiki' do
      expect(wiki_page.project).to eql(wiki.project)
    end
  end

  describe '.visible' do
    let(:other_project) { FactoryBot.create(:project).reload }
    let(:other_wiki) { project.wiki }
    let(:other_wiki_page) { FactoryBot.create(:wiki_page, wiki: wiki, title: wiki.wiki_menu_items.first.title) }
    let(:role) { FactoryBot.create(:role, permissions: [:view_wiki_pages]) }
    let(:user) do
      FactoryBot.create(:user,
                        member_in_project: project,
                        member_through_role: role)
    end

    it 'returns all pages for which the user has the \'view_wiki_pages\' permission' do
      expect(WikiPage.visible(user))
        .to match_array [wiki_page]
    end
  end
end
