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

describe WikiPage, type: :model do
  let(:project) { FactoryGirl.create(:project).reload } # a wiki is created for project, but the object doesn't know of it (FIXME?)
  let(:wiki) { project.wiki }
  let(:wiki_page) { FactoryGirl.create(:wiki_page, wiki: wiki, title: wiki.wiki_menu_items.first.title) }

  it_behaves_like 'acts_as_watchable included' do
    let(:model_instance) { FactoryGirl.create(:wiki_page) }
    let(:watch_permission) { :view_wiki_pages }
    let(:project) { model_instance.wiki.project }
  end

  describe '#create' do

    context 'when another project with same title exists' do
      let(:project2) { FactoryGirl.create(:project) }
      let(:wiki2) { project2.wiki }
      let!(:wiki_page1) { FactoryGirl.create(:wiki_page, wiki: wiki, title: 'asdf') }
      let!(:wiki_page2) { FactoryGirl.create(:wiki_page, wiki: wiki2, title: 'asdf') }

      it 'scopes the slug correctly' do
        pages = WikiPage.where(title: 'asdf')
        expect(pages.count).to eq(2)
        expect(pages.first.slug).to eq('asdf')
        expect(pages.last.slug).to eq('asdf')
      end
    end
  end

  describe '#nearest_parent_menu_item' do
    let(:child_page) { FactoryGirl.create(:wiki_page, parent: wiki_page, wiki: wiki) }
    let!(:child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, wiki: wiki, name: child_page.slug, parent: wiki_page.menu_item) }
    let(:grand_child_page) { FactoryGirl.create(:wiki_page, parent: child_page, wiki: wiki) }
    let!(:grand_child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, wiki: wiki, name: grand_child_page.slug) }

    context 'when called without options' do
      it 'returns the menu item of the parent page' do
        expect(grand_child_page.nearest_parent_menu_item).to eq(child_page_wiki_menu_item)
      end
    end

    context 'when called with {is_main_item => true}' do
      it 'returns the menu item of the grand parent if the menu item of its parent is not a main item' do
        expect(grand_child_page.nearest_parent_menu_item(is_main_item: true)).to eq(wiki_page.menu_item)
      end
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
        another_wiki_page = FactoryGirl.create(:wiki_page, wiki: wiki)
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
end
