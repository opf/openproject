#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2013 the OpenProject Foundation (OPF)
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
# See doc/COPYRIGHT.rdoc for more details.
#++

require 'spec_helper'

describe WikiMenuItemsController do
  render_views

  let(:current_user) { FactoryGirl.create(:admin) }
  let(:wiki_page) { FactoryGirl.create(:wiki_page) } # first wiki page without child pages
  let!(:top_level_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => wiki_page.title) }
  let(:wiki) { wiki_page.wiki }
  let(:project) { FactoryGirl.create(:project, :wiki => wiki) }
  let(:another_wiki_page) { FactoryGirl.create(:wiki_page, :wiki => wiki) } # second wiki page with two child pages
  let!(:another_wiki_page_top_level_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => another_wiki_page.title) }

  # child pages of another_wiki_page
  let(:child_page) { FactoryGirl.create(:wiki_page, :parent => another_wiki_page, :wiki => wiki) }
  let!(:child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => child_page.title) }
  let(:another_child_page) { FactoryGirl.create(:wiki_page, :parent => another_wiki_page, :wiki => wiki) }
  let!(:another_child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => another_child_page.title, :parent => top_level_wiki_menu_item) }

  let(:grand_child_page) { FactoryGirl.create(:wiki_page, :parent => child_page, :wiki => wiki) }
  let!(:grand_child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :wiki => wiki, :title => grand_child_page.title) }
 
  before :each do
    # log in user
    User.stub(:current).and_return current_user
  end

  describe :edit do
    context 'when no parent wiki menu item has been configured yet' do
      context 'and it is a child page' do
        before { get :edit, project_id: project.id, id: child_page.title }
        subject { response }

        it 'preselects the wiki menu item of the parent page as parent wiki menu item option' do
          assert_select 'select#parent_wiki_menu_item option[selected]', another_wiki_page_top_level_wiki_menu_item.name
          # see FIXME in menu_helper.rb
        end
      end

      context 'and it is a grand child page the parent of which is not a main item' do
        before do
          # ensure the parent page of grand_child_page is not a main item
          child_page_wiki_menu_item.tap {|page| page.parent = top_level_wiki_menu_item}.save
          get :edit, project_id: project.id, id: grand_child_page.title
        end

        subject { response }

        it 'preselects the wiki menu item of the grand parent page as parent wiki menu item option' do
          assert_select 'select#parent_wiki_menu_item option[selected]', another_wiki_page_top_level_wiki_menu_item.name
        end
      end
    end

    context 'when a parent wiki menu item has already been configured' do
      before { get :edit, project_id: project.id, id: another_child_page.title }
      subject { response }

      it 'preselects the parent wiki menu item that is already assigned' do
        assert_select 'select#parent_wiki_menu_item option[selected]', top_level_wiki_menu_item.name
      end
    end
  end
end
