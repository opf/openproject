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

describe MenuItems::WikiMenuItem, type: :model do
  before(:each) do
    @project = FactoryBot.create(:project, enabled_module_names: %w[activity])
    @current = FactoryBot.create(:user, login: 'user1', mail: 'user1@users.com')

    allow(User).to receive(:current).and_return(@current)
  end

  it 'should create a default wiki menu item when enabling the wiki' do
    expect(MenuItems::WikiMenuItem.all).not_to be_any

    @project.enabled_modules << EnabledModule.new(name: 'wiki')
    @project.reload

    wiki_item = @project.wiki.wiki_menu_items.first
    expect(wiki_item.name).to eql 'wiki'
    expect(wiki_item.title).to eql 'Wiki'
    expect(wiki_item.slug).to eql 'wiki'
    expect(wiki_item.options[:index_page]).to eql true
    expect(wiki_item.options[:new_wiki_page]).to eql true
  end

  it 'should change title when a wikipage is renamed' do
    wikipage = FactoryBot.create(:wiki_page, title: 'Oldtitle')

    menu_item_1 = FactoryBot.create(:wiki_menu_item, navigatable_id: wikipage.wiki.id,
                                                      title:    'Item 1',
                                                      name:   wikipage.slug)

    wikipage.title = 'Newtitle'
    wikipage.save!

    menu_item_1.reload
    expect(menu_item_1.title).to eq(wikipage.title)
  end

  it 'should not allow duplicate sibling entries' do
    wikipage = FactoryBot.create(:wiki_page, title: 'Parent Page')

    parent = FactoryBot.create(
      :wiki_menu_item, navigatable_id: wikipage.wiki.id, title: 'Item 1', name: wikipage.slug)
    child_1 = parent.children.create name: "child-1", title: "Child 1"

    child_2 = parent.children.build name: "child-1", title: "Child 2"

    expect { child_2.save! }.to raise_error /Name has already been taken/
  end

  describe 'it should destroy' do
    before(:each) do
      @project.enabled_modules << EnabledModule.new(name: 'wiki')
      @project.reload

      @menu_item_1 = FactoryBot.create(:wiki_menu_item, wiki: @project.wiki,
                                                         name:    'Item 1',
                                                         title:   'Item 1')

      @menu_item_2 = FactoryBot.create(:wiki_menu_item, wiki: @project.wiki,
                                                         name:    'Item 2',
                                                         parent_id:    @menu_item_1.id,
                                                         title:   'Item 2')
    end

    it 'all children when deleting the parent' do
      @menu_item_1.destroy

      expect { MenuItems::WikiMenuItem.find(@menu_item_1.id) }.to raise_error(ActiveRecord::RecordNotFound)
      expect { MenuItems::WikiMenuItem.find(@menu_item_2.id) }.to raise_error(ActiveRecord::RecordNotFound)
    end

    describe 'all items when destroying' do
      it 'the associated project' do
        @project.destroy
        expect(MenuItems::WikiMenuItem.all).not_to be_any
      end

      it 'the associated wiki' do
        @project.wiki.destroy
        expect(MenuItems::WikiMenuItem.all).not_to be_any
      end
    end
  end
end
