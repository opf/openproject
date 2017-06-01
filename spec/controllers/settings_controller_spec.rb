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

describe SettingsController, type: :controller do
  before :each do
    allow(@controller).to receive(:set_localization)
    @params = {}

    @user = FactoryGirl.create(:admin)
    allow(User).to receive(:current).and_return @user
  end

  describe 'edit' do
    render_views

    before do
      @previous_projects_modules = Setting.default_projects_modules
    end

    after do
      Setting.default_projects_modules = @previous_projects_modules
    end

    it 'contains a check box for the activity module on the projects tab' do
      get 'edit', params: { tab: 'projects' }

      expect(response).to be_success
      expect(response).to render_template 'edit'
      expect(response.body).to have_selector "input[@name='settings[default_projects_modules][]'][@value='activity']"
    end

    it 'does not store the activity in the default_projects_modules if unchecked' do
      post 'edit',
           params: {
             tab: 'projects',
             settings: {
               default_projects_modules: ['wiki']
             }
           }

      expect(response).to be_redirect
      expect(response).to redirect_to action: 'edit', tab: 'projects'

      expect(Setting.default_projects_modules).to eq(['wiki'])
    end

    it 'stores the activity in the default_projects_modules if checked' do
      post 'edit',
           params: {
             tab: 'projects',
             settings: {
               default_projects_modules: ['activity', 'wiki']
             }
           }

      expect(response).to be_redirect
      expect(response).to redirect_to action: 'edit', tab: 'projects'

      expect(Setting.default_projects_modules).to eq(['activity', 'wiki'])
    end

    describe 'with activity in Setting.default_projects_modules' do
      before do
        Setting.default_projects_modules = %w[activity wiki]
      end

      it 'contains a checked checkbox for activity' do
        get 'edit', params: { tab: 'projects' }

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
        get 'edit', params: { tab: 'projects' }

        expect(response).to be_success
        expect(response).to render_template 'edit'

        expect(response.body).not_to have_selector "input[@name='settings[default_projects_modules][]'][@value='activity'][@checked='checked']"
      end
    end

    describe 'password settings' do
      let(:old_settings) do
        {
          password_min_length: 10,
          password_active_rules: [],
          password_min_adhered_rules: 0,
          password_days_valid: 365,
          password_count_former_banned: 2,
          lost_password: 1
        }
      end

      let(:new_settings) do
        {
          password_min_length: 42,
          password_active_rules: %w(uppercase lowercase),
          password_min_adhered_rules: 7,
          password_days_valid: 13,
          password_count_former_banned: 80,
          lost_password: 3
        }
      end

      let(:original_settings) { Hash.new }

      before do
        old_settings.keys.each do |key|
          original_settings[key] = Setting[key]
        end

        old_settings.keys.each do |key|
          Setting[key] = old_settings[key]
        end
      end

      after do
        # restore settings
        old_settings.keys.each do |key|
          Setting[key] = original_settings[key]
        end
      end

      describe 'POST #edit with password login enabled' do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)

          post 'edit', params: { tab: 'authentication', settings: new_settings }
        end

        it 'is successful' do
          expect(response).to be_redirect # to auth tab
        end

        it 'sets the minimum password length to 42' do
          expect(Setting[:password_min_length]).to eq 42
        end

        it 'sets the active character classes to lowercase and uppercase' do
          expect(Setting[:password_active_rules]).to eq ['uppercase', 'lowercase']
        end

        it 'sets the required number of classes to 7' do
          expect(Setting[:password_min_adhered_rules]).to eq 7
        end

        it 'sets passwords to expire after 13 days' do
          expect(Setting[:password_days_valid]).to eq 13
        end

        it 'bans the last 80 passwords' do
          expect(Setting[:password_count_former_banned]).to eq 80
        end

        it 'sets the lost password option to the nonsensical 3' do
          expect(Setting[:lost_password]).to eq 3
        end
      end

      describe 'POST #edit with password login disabled' do
        before do
          allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)

          post 'edit', params: { tab: 'authentication', settings: new_settings }
        end

        it 'is successful' do
          expect(response).to be_redirect # to auth tab
        end

        it 'does not set the minimum password length to 42' do
          expect(Setting[:password_min_length]).to eq 10
        end

        it 'does not set the active character classes to lowercase and uppercase' do
          expect(Setting[:password_active_rules]).to eq []
        end

        it 'does not set the required number of classes to 7' do
          expect(Setting[:password_min_adhered_rules]).to eq 0
        end

        it 'does not set passwords to expire after 13 days' do
          expect(Setting[:password_days_valid]).to eq 365
        end

        it 'does not ban the last 80 passwords' do
          expect(Setting[:password_count_former_banned]).to eq 2
        end

        it 'does not set the lost password option to the nonsensical 3' do
          expect(Setting[:lost_password]).to eq 1
        end
      end
    end
  end
end
