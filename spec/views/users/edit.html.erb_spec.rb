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

describe 'users/edit', type: :view do
  let(:current_user) { FactoryGirl.build :admin }

  context 'authentication provider' do
    let(:user)  {
      FactoryGirl.build :user, id: 1,  # id is required to create route to edit
                               identity_url: 'test_provider:veryuniqueid'
    }

    before do
      assign(:user, user)
      assign(:auth_sources, [])

      allow(view).to receive(:current_user).and_return(current_user)
    end

    it 'shows the authentication provider' do
      render

      expect(response.body).to include('Test Provider')
    end

    it 'does not show a no-login warning when password login is disabled' do
      allow(OpenProject::Configuration).to receive(:disable_password_login).and_return(true)
      render

      expect(response.body).not_to include I18n.t('user.no_login')
    end
  end

  context 'with password-based login' do
    let(:user) { FactoryGirl.build :user, id: 42 }

    before do
      assign :user, user
      assign :auth_sources, []

      allow(view).to receive(:current_user).and_return(current_user)
    end

    context 'with password login disabled' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(true)
      end

      it 'warns that the user cannot login' do
        render

        expect(response.body).to include I18n.t('user.no_login')
      end

      context 'with auth sources' do
        let(:auth_sources) { [FactoryGirl.create(:auth_source)] }

        before do
          assign :auth_sources, auth_sources
        end

        it 'does not show the auth source selection' do
          render

          expect(rendered).not_to have_selector('#user_auth_source_id')
        end
      end
    end

    context 'with password login enabled' do
      before do
        allow(OpenProject::Configuration).to receive(:disable_password_login?).and_return(false)
      end

      it 'shows password options' do
        render

        expect(rendered).to have_text I18n.t('user.assign_random_password')
      end

      context 'with auth sources' do
        let(:auth_sources) { [FactoryGirl.create(:auth_source)] }

        before do
          assign :auth_sources, auth_sources
        end

        it 'shows the auth source selection' do
          render

          expect(rendered).to have_selector('#user_auth_source_id')
        end
      end

      context 'with password choice enabled' do
        before do
          expect(OpenProject::Configuration)
            .to receive(:disable_password_choice?)
            .and_return(false)
        end

        it 'shows the password and password confirmation fields' do
          render

          expect(rendered).to have_text('Password')
          expect(rendered).to have_text('Confirmation')
        end
      end

      context 'with password choice enabled' do
        before do
          expect(OpenProject::Configuration).to receive(:disable_password_choice?).and_return(true)
        end

        it 'doesn not show the password and password confirmation fields' do
          render

          expect(rendered).not_to have_text('Password')
          expect(rendered).not_to have_text('Password confirmation')
        end
      end
    end
  end
end
