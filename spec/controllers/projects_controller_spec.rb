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

describe ProjectsController, type: :controller do
  before do
    Role.delete_all
    User.delete_all
  end

  before do
    allow(@controller).to receive(:set_localization)

    @role = FactoryGirl.create(:non_member)
    @user = FactoryGirl.create(:admin)
    allow(User).to receive(:current).and_return @user

    @params = {}
  end

  def clear_settings_cache
    Rails.cache.clear
  end

  # this is the base method for get, post, etc.
  def process(*args)
    clear_settings_cache
    result = super
    clear_settings_cache
    result
  end

  describe 'show' do
    render_views

    describe 'without wiki' do
      before do
        @project = FactoryGirl.create(:project)
        @project.reload # project contains wiki by default
        @project.wiki.destroy
        @project.reload
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', @params
        expect(response).to be_success
        expect(response).to render_template 'show'
      end

      it 'renders main menu without wiki menu item' do
        get 'show', @params

        assert_select '#main-menu a.Wiki-menu-item', false # assert_no_select
      end
    end

    describe 'with wiki' do
      before do
        @project = FactoryGirl.create(:project)
        @project.reload # project contains wiki by default
        @params[:id] = @project.id
      end

      describe 'without custom wiki menu items' do
        it 'renders show' do
          get 'show', @params
          expect(response).to be_success
          expect(response).to render_template 'show'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', @params

          assert_select '#main-menu a.Wiki-menu-item', 'Wiki'
        end
      end

      describe 'with custom wiki menu item' do
        before do
          main_item = FactoryGirl.create(:wiki_menu_item, navigatable_id: @project.wiki.id, name: 'Example', title: 'Example')
          sub_item = FactoryGirl.create(:wiki_menu_item, navigatable_id: @project.wiki.id, name: 'Sub', title: 'Sub', parent_id: main_item.id)
        end

        it 'renders show' do
          get 'show', @params
          expect(response).to be_success
          expect(response).to render_template 'show'
        end

        it 'renders main menu with wiki menu item' do
          get 'show', @params

          assert_select '#main-menu a.Example-menu-item', 'Example'
        end

        it 'renders main menu with sub wiki menu item' do
          get 'show', @params

          assert_select '#main-menu a.Sub-menu-item', 'Sub'
        end
      end
    end

    describe 'with activated activity module' do
      before do
        @project = FactoryGirl.create(:project, enabled_module_names: %w[activity])
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', @params
        expect(response).to be_success
        expect(response).to render_template 'show'
      end

      it 'renders main menu with activity tab' do
        get 'show', @params
        assert_select '#main-menu a.activity-menu-item'
      end
    end

    describe 'without activated activity module' do
      before do
        @project = FactoryGirl.create(:project, enabled_module_names: %w[wiki])
        @params[:id] = @project.id
      end

      it 'renders show' do
        get 'show', @params
        expect(response).to be_success
        expect(response).to render_template 'show'
      end

      it 'renders main menu without activity tab' do
        get 'show', @params
        expect(response.body).not_to have_selector '#main-menu a.activity-menu-item'
      end
    end
  end

  describe 'new' do

    it "renders 'new'" do
      get 'new', @params
      expect(response).to be_success
      expect(response).to render_template 'new'
    end

  end

  describe 'settings' do
    render_views

    describe '#type' do
      let(:user) { FactoryGirl.create(:admin) }
      let(:type_standard) { FactoryGirl.create(:type_standard) }
      let(:type_bug) { FactoryGirl.create(:type_bug) }
      let(:type_feature) { FactoryGirl.create(:type_feature) }
      let(:types) { [type_standard, type_bug, type_feature] }
      let(:project) {
        FactoryGirl.create(:project,
                           types: types)
      }
      let(:work_package_standard) {
        FactoryGirl.create(:work_package,
                           project: project,
                           type: type_standard)
      }
      let(:work_package_bug) {
        FactoryGirl.create(:work_package,
                           project: project,
                           type: type_bug)
      }
      let(:work_package_feature) {
        FactoryGirl.create(:work_package,
                           project: project,
                           type: type_feature)
      }

      shared_examples_for :redirect do
        subject { response }

        it { is_expected.to be_redirect }
      end

      before { allow(User).to receive(:current).and_return user }

      shared_context 'work_packages' do
        before do
          work_package_standard
          work_package_bug
          work_package_feature
        end
      end

      shared_examples_for :success do
        let(:regex) { Regexp.new(I18n.t(:notice_successful_update)) }

        subject { flash[:notice].last }

        it { is_expected.to match(regex) }
      end

      context 'no type missing' do
        include_context 'work_packages'

        let(:type_ids) { types.map(&:id) }

        before {
          put :types,
              id: project.id,
              project: { 'type_ids' => type_ids }
        }

        it_behaves_like :redirect

        it_behaves_like :success
      end

      context 'all types missing' do
        include_context 'work_packages'

        let(:missing_types) { types }

        before {
          put :types,
              id: project.id,
              project: { 'type_ids' => [] }
        }

        it_behaves_like :redirect

        describe 'shows missing types' do
          let(:regex) { Regexp.new(I18n.t(:error_types_in_use_by_work_packages).sub('%{types}', '')) }

          subject { flash[:error] }

          it { is_expected.to match(regex) }

          it { is_expected.to match(Regexp.new(type_standard.name)) }

          it { is_expected.to match(Regexp.new(type_bug.name)) }

          it { is_expected.to match(Regexp.new(type_feature.name)) }
        end
      end

      context 'no type selected' do
        before { put :types, id: project.id }

        it_behaves_like :success

        describe 'automatic selection of standard type' do
          let(:regex) { Regexp.new(I18n.t(:notice_automatic_set_of_standard_type)) }

          subject { flash[:notice].all? { |n| regex.match(n).nil? } }

          it { is_expected.to be_falsey }
        end
      end
    end
  end
end
