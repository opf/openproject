#-- copyright
# OpenProject is a project management system.
# Copyright (C) 2012-2014 the OpenProject Foundation (OPF)
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

describe SettingsController do
  before :each do
    allow(@controller).to receive(:set_localization)
    @params = {}

    @user = FactoryGirl.create(:admin)
    allow(User).to receive(:current).and_return @user
  end

  describe 'edit' do
    render_views

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

    before(:all) do
      @previous_projects_modules = Setting.default_projects_modules
    end

    after(:all) do
      Setting.default_projects_modules = @previous_projects_modules
    end

    it 'contains a check box for the activity module on the projects tab' do
      get 'edit', :tab => 'projects'

      expect(response).to be_success
      expect(response).to render_template 'edit'
      expect(response.body).to have_selector "input[@name='settings[default_projects_modules][]'][@value='activity']"
    end

    it 'does not store the activity in the default_projects_modules if unchecked' do
      post 'edit', :tab => 'projects', :settings => {
        :default_projects_modules => ['wiki']
      }

      expect(response).to be_redirect
      expect(response).to redirect_to :action => 'edit', :tab => 'projects'

      expect(Setting.default_projects_modules).to eq(['wiki'])
    end

    it 'stores the activity in the default_projects_modules if checked' do
      post 'edit', :tab => 'projects', :settings => {
        :default_projects_modules => ['activity', 'wiki']
      }

      expect(response).to be_redirect
      expect(response).to redirect_to :action => 'edit', :tab => 'projects'

      expect(Setting.default_projects_modules).to eq(['activity', 'wiki'])
    end

    describe 'with activity in Setting.default_projects_modules' do
      before do
        Setting.default_projects_modules = %w[activity wiki]
      end

      it 'contains a checked checkbox for activity' do
        get 'edit', :tab => 'projects'

        expect(response).to be_success
        expect(response).to render_template 'edit'

        expect(response.body).to have_selector "input[@name='settings[default_projects_modules][]'][@value='activity'][@checked='checked']"
      end
    end

    describe 'without activated activity module' do
      before do
        Setting.default_projects_modules = %w[wiki]
      end

      it 'contains an unchecked checkbox for activity' do
        get 'edit', :tab => 'projects'

        expect(response).to be_success
        expect(response).to render_template 'edit'

        expect(response.body).not_to have_selector "input[@name='settings[default_projects_modules][]'][@value='activity'][@checked='checked']"
      end
    end
  end
end
