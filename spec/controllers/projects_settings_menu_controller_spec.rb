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

describe ProjectSettings::ModulesController, 'menu', type: :controller do
  let(:current_user) do
    FactoryBot.build_stubbed(:user).tap do |u|
      allow(u)
        .to receive(:allowed_to?)
        .and_return(true)
    end
  end

  before do
    login_as(current_user)

    @params = {}
  end

  describe 'show' do
    render_views

    describe 'without wiki' do
      before do
        @project = FactoryBot.create(:project)
        @project.reload # project contains wiki by default
        @project.wiki.destroy
        @project.reload
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', params: @params
        expect(response).to be_successful
        expect(response).to render_template 'project_settings/modules'
      end

      it 'renders main menu without wiki menu item' do
        get 'show', params: @params

        assert_select '#main-menu a.wiki-Wiki-menu-item', false # assert_no_select
      end
    end

    describe 'with wiki' do
      before do
        @project = FactoryBot.create(:project)
        @project.reload # project contains wiki by default
        @params[:id] = @project.id
      end

      describe 'without custom wiki menu items' do
        it 'renders show' do
          get 'show', params: @params
          expect(response).to be_successful
          expect(response).to render_template 'project_settings/modules'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', params: @params

          assert_select '#main-menu a.wiki-wiki-menu-item', 'Wiki'
        end
      end

      describe 'with custom wiki menu item' do
        before do
          main_item = FactoryBot.create(:wiki_menu_item,
                                        navigatable_id: @project.wiki.id,
                                        name: 'example',
                                        title: 'Example Title')
          FactoryBot.create(:wiki_menu_item,
                            navigatable_id: @project.wiki.id,
                            name: 'sub',
                            title: 'Sub Title',
                            parent_id: main_item.id)
        end

        it 'renders show' do
          get 'show', params: @params
          expect(response).to be_successful
          expect(response).to render_template 'project_settings/modules'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', params: @params

          assert_select '#main-menu a.wiki-example-menu-item', 'Example Title'
        end

        it 'renders main menu with sub wiki menu item' do
          get 'show', params: @params

          assert_select '#main-menu a.wiki-sub-menu-item', 'Sub Title'
        end
      end
    end

    describe 'with activated activity module' do
      before do
        @project = FactoryBot.create(:project, enabled_module_names: %w[activity])
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', params: @params
        expect(response).to be_successful
        expect(response).to render_template 'project_settings/modules'
      end

      it 'renders main menu with activity tab' do
        get 'show', params: @params
        assert_select '#main-menu a.activity-menu-item'
      end
    end

    describe 'without activated activity module' do
      before do
        @project = FactoryBot.create(:project, enabled_module_names: %w[wiki])
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', params: @params
        expect(response).to be_successful
        expect(response).to render_template 'project_settings/modules'
      end

      it 'renders main menu without activity tab' do
        get 'show', params: @params
        expect(response.body).not_to have_selector '#main-menu a.activity-menu-item'
      end
    end
  end
end
