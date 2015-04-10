#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2015 the OpenProject Foundation (OPF)
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

describe WikiMenuItemsController, type: :controller do
  let(:current_user) { FactoryGirl.create(:admin) }

  # create project with wiki
  let(:project) { FactoryGirl.create(:project).reload } # a wiki is created for project, but the object doesn't know of it (FIXME?)
  let(:wiki) { project.wiki }

  let(:wiki_page) { FactoryGirl.create(:wiki_page, wiki: wiki) } # first wiki page without child pages
  let!(:top_level_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, :with_menu_item_options, wiki: wiki, title: wiki_page.title) }

  before :each do
    # log in user
    allow(User).to receive(:current).and_return current_user
  end

  describe '#edit' do
    # more wiki pages with menu items
    let(:another_wiki_page) { FactoryGirl.create(:wiki_page, wiki: wiki) } # second wiki page with two child pages
    let!(:another_wiki_page_top_level_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, wiki: wiki, title: another_wiki_page.title) }

    # child pages of another_wiki_page
    let(:child_page) { FactoryGirl.create(:wiki_page, parent: another_wiki_page, wiki: wiki) }
    let!(:child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, wiki: wiki, title: child_page.title) }
    let(:another_child_page) { FactoryGirl.create(:wiki_page, parent: another_wiki_page, wiki: wiki) }
    let!(:another_child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, wiki: wiki, title: another_child_page.title, parent: top_level_wiki_menu_item) }

    let(:grand_child_page) { FactoryGirl.create(:wiki_page, parent: child_page, wiki: wiki) }
    let!(:grand_child_page_wiki_menu_item) { FactoryGirl.create(:wiki_menu_item, wiki: wiki, title: grand_child_page.title) }

    context 'when no parent wiki menu item has been configured yet' do
      context 'and it is a child page' do
        before { get :edit, project_id: project.id, id: child_page.title }
        subject { response }

        it 'preselects the wiki menu item of the parent page as parent wiki menu item option' do
          expect(assigns['selected_parent_menu_item_id']).to eq(another_wiki_page_top_level_wiki_menu_item.id)
          # see FIXME in menu_helper.rb
        end
      end

      context 'and it is a grand child page the parent of which is not a main item' do
        before do
          # ensure the parent page of grand_child_page is not a main item
          child_page_wiki_menu_item.tap { |page| page.parent = top_level_wiki_menu_item }.save
          get :edit, project_id: project.id, id: grand_child_page.title
        end

        subject { response }

        it 'preselects the wiki menu item of the grand parent page as parent wiki menu item option' do
          expect(assigns['selected_parent_menu_item_id']).to eq(another_wiki_page_top_level_wiki_menu_item.id)
        end
      end
    end

    context 'when a parent wiki menu item has already been configured' do
      before { get :edit, project_id: project.id, id: another_child_page.title }
      subject { response }

      it 'preselects the parent wiki menu item that is already assigned' do
        expect(assigns['selected_parent_menu_item_id']).to eq(top_level_wiki_menu_item.id)
      end
    end
  end

  shared_context 'when there is one more wiki page with a child page' do
    let!(:child_page) { FactoryGirl.create(:wiki_page, parent: wiki_page, wiki: wiki) }

    let!(:another_wiki_page) { FactoryGirl.create(:wiki_page, wiki: wiki) } # second wiki page with two child pages
    let!(:another_child_page) { FactoryGirl.create(:wiki_page, parent: another_wiki_page, wiki: wiki) }
  end

  describe '#select_main_menu_item' do
    include_context 'when there is one more wiki page with a child page'

    before { get :select_main_menu_item, project_id: project, id: wiki_page.id }
    subject { assigns['possible_wiki_pages'] }

    context 'when selecting a new wiki page to replace the current main menu item' do
      it { is_expected.to include wiki_page }
      it { is_expected.to include child_page }
      it { is_expected.to include another_wiki_page }
      it { is_expected.to include another_child_page }
    end
  end

  describe '#replace_main_menu_item' do
    include_context 'when there is one more wiki page with a child page'

    context 'when another wiki page is selected for replacement' do
      let(:selected_page) { child_page }
      let(:new_menu_item) { selected_page.menu_item }

      before do
        post :replace_main_menu_item, project_id: project,
                                      id: wiki_page.id,
                                      wiki_page: { id: selected_page.id }
      end

      it 'destroys the current wiki menu item' do
        expect(wiki_page.menu_item).to be_nil
      end

      it 'creates a new main menu item for the selected wiki page' do
        expect(selected_page.menu_item).to be_present
        expect(selected_page.menu_item.parent).to be_nil
      end

      it 'transfers the menu item options to the selected wiki page' do
        expect(new_menu_item.options).to eq(index_page: true, new_wiki_page: true)
      end
    end

    context 'when its own wiki page is selected for replacement' do
      let!(:wiki_menu_item) { wiki_page.menu_item }

      before do
        post :replace_main_menu_item, project_id: project,
                                      id: wiki_page.id,
                                      wiki_page: { id: wiki_page.id }
      end

      it 'does not destroy the wiki menu item' do
        expect(wiki_menu_item.reload).to be_present
      end
    end
  end
end
